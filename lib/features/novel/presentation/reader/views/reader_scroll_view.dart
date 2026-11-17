import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_controller.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';
import 'package:freepiv/ui/custom/reader/reader_paragraph.dart';
import 'package:freepiv/ui/custom/reader/reader_sliver.dart';
import 'package:frost_ui/frost_ui.dart';

/// Builds an uploaded image or embedded work filling the box it is given.
/// [onImageSize] receives a loaded image's pixel size, where the view uses it.
typedef ReaderBlockBuilder = Widget Function(BuildContext context, int block, ValueChanged<Size>? onImageSize);

/// The whole text as one scrolling column, its blocks laid out by a
/// [ReaderLayout]. The reading line is the top of the view.
///
/// The view reports where the reader is to the [controller] as it scrolls and
/// moves only when the controller asks it to ([showOffset], [turn]), when the
/// reader scrolls, or by [scrollLines] and [advance].
class ReaderScrollView extends StatefulWidget {
  const ReaderScrollView({required this.controller, required this.layout, required this.blockBuilder, this.onLink, this.onPageJump, super.key});

  final ReaderController controller;

  /// A layout in [ReaderFlow.scroll] at this view's width and height.
  final ReaderLayout layout;
  final ReaderBlockBuilder blockBuilder;
  final ValueChanged<Uri>? onLink;
  final ValueChanged<int>? onPageJump;

  @override
  State<ReaderScrollView> createState() => ReaderScrollViewState();
}

class ReaderScrollViewState extends State<ReaderScrollView> with SingleTickerProviderStateMixin implements ReaderViewport {
  /// How long background measuring may take in one frame.
  static const _measureBudget = Duration(milliseconds: 4);
  static const _turnDuration = Duration(milliseconds: 200);

  /// Replaces one frame's background measuring in tests, so a test decides
  /// how many blocks each pass measures; returns whether all are measured.
  @visibleForTesting
  static bool Function(ReaderLayout layout, int anchorBlock)? debugMeasurePass;

  late final ScrollController _scroll;

  /// Drives turns and line steps by distance rather than to a pixel, so a
  /// correction landing during the move (an image above, measuring) is kept.
  late final AnimationController _move = AnimationController(vsync: this)..addListener(_moved);
  double _moveDistance = 0;
  double _moveDone = 0;

  /// The pixels the view itself last moved to; the reader has not moved since
  /// while the position is still there, so nothing is reported.
  double? _placed;
  bool _measureScheduled = false;

  ReaderLayout get _layout => widget.layout;

  @override
  void initState() {
    super.initState();
    final pixels = _layout.pixelOfOffset(widget.controller.offset);
    _scroll = ScrollController(initialScrollOffset: pixels)..addListener(_scrolled);
    _placed = pixels;
    widget.controller.attach(this);
    _scheduleMeasure();
    _reportEndAfterFrame();
  }

  @override
  void didUpdateWidget(ReaderScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach(this);
      widget.controller.attach(this);
    }
    if (oldWidget.layout != widget.layout) {
      // The new layout lays out before anything paints: the reading line
      // keeps its character.
      final pixels = _layout.pixelOfOffset(widget.controller.offset);
      if (_scroll.hasClients) _scroll.position.correctPixels(pixels);
      _placed = pixels;
      _scheduleMeasure();
      _reportEndAfterFrame();
    }
  }

  @override
  void dispose() {
    widget.controller.detach(this);
    _move.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---- ReaderViewport.

  @override
  void showOffset(int offset) {
    _move.stop();
    final pixels = _layout.pixelOfOffset(offset);
    _reportEndAfterFrame();
    if (!_scroll.hasClients) {
      _placed = pixels;
      return;
    }
    final position = _scroll.position;
    final target = position.hasContentDimensions ? pixels.clamp(position.minScrollExtent, position.maxScrollExtent) : pixels;
    _placed = target;
    position.jumpTo(target);
    _scheduleMeasure();
  }

  @override
  bool turn(int direction) {
    if (!_scroll.hasClients) return false;
    final position = _scroll.position;
    final distance = math.max(_layout.typesetting.bodyLinePx, position.viewportDimension - _layout.typesetting.bodyLinePx);
    return _moveBy(direction * distance, duration: _turnDuration);
  }

  // ---- Moves the page asks for.

  /// Scrolls three lines in [direction] (+1 down, -1 up).
  bool scrollLines(int direction) => _moveBy(direction * 3 * _layout.typesetting.bodyLinePx, duration: FrostMotion.reveal);

  /// Moves [pixels] down at once, for auto scroll; false at the end.
  bool advance(double pixels) {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return false;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - .5) return false;
    position.jumpTo(math.min(position.maxScrollExtent, position.pixels + pixels));
    return true;
  }

  bool _moveBy(double delta, {required Duration duration}) {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return false;
    final position = _scroll.position;
    final from = position.pixels;
    if (delta > 0 && from >= position.maxScrollExtent - .5) return false;
    if (delta < 0 && from <= position.minScrollExtent + .5) return false;
    final target = (from + delta).clamp(position.minScrollExtent, position.maxScrollExtent);
    final time = FrostMotion.duration(context, duration);
    _move.stop();
    if (time == Duration.zero) {
      position.jumpTo(target);
      return true;
    }
    _moveDistance = target - from;
    _moveDone = 0;
    _move.duration = time;
    unawaited(_move.forward(from: 0));
    return true;
  }

  /// Moves by what the curve has advanced since the last tick.
  void _moved() {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return;
    final position = _scroll.position;
    final done = Curves.easeOutCubic.transform(_move.value) * _moveDistance;
    final step = done - _moveDone;
    _moveDone = done;
    if (step == 0) return;
    position.jumpTo((position.pixels + step).clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  /// After a jump the view tells the controller whether it now shows the end
  /// (the offset stays, so nothing is saved): the end of the text may be on
  /// screen before the last character reaches the reading line.
  void _reportEndAfterFrame() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || !_scroll.position.hasContentDimensions) return;
      final position = _scroll.position;
      final placed = _placed;
      // The reader has moved since; the scroll report covers it.
      if (placed == null || (position.pixels - placed).abs() >= .5) return;
      final atEnd = position.pixels >= position.maxScrollExtent - .5;
      final controller = widget.controller;
      if (atEnd != controller.atEnd) controller.reportPosition(controller.offset, atEnd: atEnd);
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  // ---- Following the reader.

  void _scrolled() {
    final position = _scroll.position;
    final placed = _placed;
    if (placed != null && (position.pixels - placed).abs() < .5) return;
    _placed = null;
    final atEnd = position.hasContentDimensions && position.pixels >= position.maxScrollExtent - .5;
    widget.controller.reportPosition(_layout.offsetAtPixel(position.pixels), atEnd: atEnd);
    _scheduleMeasure();
  }

  /// Keeps measuring outward from the reading line, a little each frame.
  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (mounted) _measurePass();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void _measurePass() {
    if (!_scroll.hasClients || !_scroll.position.hasPixels) {
      _scheduleMeasure();
      return;
    }
    final layout = _layout;
    final pass = debugMeasurePass;
    final done = _keepingReadingLine(() {
      final anchor = layout.blockAtPixel(_scroll.position.pixels);
      return pass != null ? pass(layout, anchor) : layout.measureSome(anchor, _measureBudget);
    });
    if (!done) _scheduleMeasure();
  }

  /// Runs [change] to the layout and moves the scroll position so the reading
  /// line stays on the same character, at the same depth inside its line.
  T _keepingReadingLine<T>(T Function() change) {
    final position = _scroll.position;
    final pixels = position.pixels;
    final offset = _layout.offsetAtPixel(pixels);
    final within = pixels - _layout.pixelOfOffset(offset);
    final result = change();
    final correction = _layout.pixelOfOffset(offset) + within - pixels;
    if (correction.abs() > 1e-6) {
      position.correctBy(correction);
      if (_placed != null) _placed = _placed! + correction;
    }
    return result;
  }

  /// Takes the decoded size of the image in [block]: the layout grows or
  /// shrinks it and the reading line keeps its text.
  void imageSized(int block, Size size) {
    void apply() {
      if (!mounted || !_scroll.hasClients || !_scroll.position.hasPixels) return;
      final position = _scroll.position;
      final shift = _layout.updateImageSize(block, size, anchorBlock: _layout.blockAtPixel(position.pixels));
      if (shift != 0) {
        position.correctBy(shift);
        if (_placed != null) _placed = _placed! + shift;
      }
    }

    // During a build or layout the extents may not move under the sliver.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
      SchedulerBinding.instance.scheduleFrame();
    } else {
      apply();
    }
  }

  // ---- Building.

  Widget _block(BuildContext context, int index) {
    final layout = _layout;
    final block = layout.model.blocks[index];
    switch (block) {
      case NovelLine() || NovelChapterTitle():
        // The list also rebuilds its children during a build, before it has
        // measured the blocks it is about to show; the paragraph is made at
        // layout time, once the sliver has measured it and kept the reading
        // line in place.
        return LayoutBuilder(
          builder: (context, _) {
            final metrics = layout.metricsOf(index);
            return Padding(
              padding: EdgeInsets.only(top: metrics.topGap),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: layout.columnWidth,
                  child: ReaderParagraph(
                    text: layout.lineTextOf(index)!,
                    typesetting: layout.typesetting,
                    onLink: widget.onLink,
                    onPageJump: widget.onPageJump,
                  ),
                ),
              ),
            );
          },
        );
      case NovelPageBreak():
        return const Center(child: FrostDivider());
      case NovelUploadedImage() || NovelEmbeddedWork():
        return Padding(
          padding: EdgeInsets.only(bottom: layout.metricsOf(index).bottomGap),
          child: Center(
            child: SizedBox(
              // A picture scaled down by the height cap is narrower than the
              // column; its frame takes that width.
              width: layout.imageWidthOf(index),
              child: widget.blockBuilder(context, index, block is NovelUploadedImage ? (size) => imageSized(index, size) : null),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (notification) {
        // A drag takes over from a turn in progress.
        if (notification.dragDetails != null) _move.stop();
        return false;
      },
      child: CustomScrollView(
        controller: _scroll,
        slivers: [ReaderSliver(layout: _layout, itemBuilder: _block)],
      ),
    );
  }
}
