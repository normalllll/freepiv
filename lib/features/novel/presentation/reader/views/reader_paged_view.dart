import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_controller.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_scroll_view.dart' show ReaderBlockBuilder;
import 'package:freepiv/ui/custom/reader/reader_page_turn.dart';
import 'package:freepiv/ui/custom/reader/reader_paginator.dart';
import 'package:freepiv/ui/custom/reader/reader_paragraph.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';
import 'package:frost_ui/frost_ui.dart' show FrostGap;

/// How a text area of [size] is divided into pages: one page, or two side by
/// side when the area is at least 960 wide and wider than tall.
@immutable
class ReaderPageGeometry {
  factory ReaderPageGeometry.of(Size size, ReaderTypesetting typesetting) {
    final spread = size.width >= 960 && size.width > size.height;
    final gutter = spread ? 2 * typesetting.horizontalPadding : 0.0;
    final pageWidth = spread ? (size.width - gutter) / 2 : size.width;
    return ReaderPageGeometry._(spread: spread, pageWidth: math.max(0, pageWidth), pageHeight: math.max(0, size.height), gutter: gutter);
  }

  const ReaderPageGeometry._({required this.spread, required this.pageWidth, required this.pageHeight, required this.gutter});

  final bool spread;
  final double pageWidth;
  final double pageHeight;

  /// Between the two pages of a spread.
  final double gutter;

  @override
  bool operator ==(Object other) =>
      other is ReaderPageGeometry && other.spread == spread && other.pageWidth == pageWidth && other.pageHeight == pageHeight && other.gutter == gutter;

  @override
  int get hashCode => Object.hash(spread, pageWidth, pageHeight, gutter);
}

/// A page or a spread of a chapter: the unit one turn moves.
@immutable
class _Sheet {
  const _Sheet(this.chapter, this.index);

  final int chapter;

  /// The page index, or the spread index on spreads.
  final int index;

  @override
  bool operator ==(Object other) => other is _Sheet && other.chapter == chapter && other.index == index;

  @override
  int get hashCode => Object.hash(chapter, index);
}

/// The text on pages from a [ReaderPaginator], one at a time or two side by
/// side. A horizontal drag with a finger follows it and settles on the next or
/// previous page by speed or distance; taps and keys turn with [animation].
class ReaderPagedView extends StatefulWidget {
  const ReaderPagedView({
    required this.controller,
    required this.paginator,
    required this.geometry,
    required this.animation,
    required this.blockBuilder,
    this.endBuilder,
    this.onLink,
    this.onPageJump,
    this.onRepaginated,
    super.key,
  });

  final ReaderController controller;
  final ReaderPaginator paginator;
  final ReaderPageGeometry geometry;
  final ReaderPageAnimation animation;
  final ReaderBlockBuilder blockBuilder;

  /// A sheet after the last page, in the text column, with what follows the
  /// text. Reaching it is the end of the text; it holds no characters.
  final WidgetBuilder? endBuilder;
  final ValueChanged<Uri>? onLink;
  final ValueChanged<int>? onPageJump;

  /// Called when pictures changed the pages, with the page on show kept: what
  /// reads page numbers asks again.
  final VoidCallback? onRepaginated;

  @override
  State<ReaderPagedView> createState() => ReaderPagedViewState();
}

class ReaderPagedViewState extends State<ReaderPagedView> with SingleTickerProviderStateMixin implements ReaderViewport {
  static const _turnDuration = Duration(milliseconds: 260);

  /// A fling faster than this turns the page whatever the distance.
  static const _flingVelocity = 400.0;

  late final AnimationController _turn = AnimationController(vsync: this, duration: _turnDuration);
  _Sheet _sheet = const _Sheet(0, 0);

  /// The sheet coming in while a turn is shown, and its direction.
  _Sheet? _incoming;
  int _direction = 0;
  double _drag = 0;
  bool _dragging = false;

  ReaderPaginator get _paginator => widget.paginator;
  bool get _spread => widget.geometry.spread;
  double get _width => widget.geometry.spread ? 2 * widget.geometry.pageWidth + widget.geometry.gutter : widget.geometry.pageWidth;

  /// The height of the end card at the text column's width, once measured.
  double? _endHeight;
  final _endProbe = GlobalKey();

  /// Whether the end card sits under the text of the last page: it is measured,
  /// and fits in what is left of that page after a section gap. Until it is
  /// measured, and when it does not fit, it has a sheet of its own.
  bool get _cardOnLast {
    final height = _endHeight;
    if (widget.endBuilder == null || height == null) return false;
    return _usedHeight(_lastPage) + FrostGap.section + height <= widget.geometry.pageHeight;
  }

  /// Whether the end card sits on the last text page, for tests.
  @visibleForTesting
  bool get endCardOnLastPage => _cardOnLast;

  /// Whether a sheet after the last page holds the end card.
  bool get _hasEndSheet => widget.endBuilder != null && !_cardOnLast;

  ReaderPage get _lastPage {
    final chapter = _paginator.layout.model.chapters.length - 1;
    return _paginator.pagesOfChapter(chapter).last;
  }

  static double _usedHeight(ReaderPage page) => page.items.fold(0.0, (used, item) => math.max(used, item.top + item.height));

  bool _isLastPage(ReaderPage page) {
    final last = _lastPage;
    return page.chapter == last.chapter && page.index == last.index;
  }

  /// The pages on show, for tests and the status line; none on the end sheet.
  List<ReaderPage> get visiblePages => _pagesOf(_sheet);

  /// Whether the sheet after the last page is on show.
  bool get showsEnd => _isEnd(_sheet);

  @override
  void initState() {
    super.initState();
    widget.controller.attach(this);
  }

  @override
  void didUpdateWidget(ReaderPagedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sheetWidgets.clear();
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach(this);
      widget.controller.attach(this);
    } else if (oldWidget.paginator != widget.paginator || oldWidget.geometry != widget.geometry) {
      // A turn or drag in progress belongs to the old pages.
      _turn.stop();
      _turn.value = 0;
      _incoming = null;
      _direction = 0;
      _drag = 0;
      _dragging = false;
      _place(widget.controller.offset);
      _reportEnd();
    }
  }

  @override
  void dispose() {
    widget.controller.detach(this);
    _turn.dispose();
    super.dispose();
  }

  // ---- ReaderViewport.

  @override
  void showOffset(int offset, {double depth = 0}) {
    _settle();
    _place(offset);
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks && mounted) setState(() {});
    _reportEnd();
  }

  @override
  bool turn(int direction) {
    _settle();
    final next = _neighbour(_sheet, direction);
    if (next == null) return false;
    if (!_animates) {
      _commit(next);
      return true;
    }
    setState(() {
      _incoming = next;
      _direction = direction;
    });
    _turn.value = 0;
    unawaited(_turn.animateTo(1, curve: Curves.easeOutCubic).then((_) => _finish()));
    return true;
  }

  // ---- Sheets.

  /// Tells the controller whether the sheet on show is the last one; the
  /// offset stays, so nothing is saved.
  void _reportEnd() {
    void report() {
      if (!mounted) return;
      final atEnd = _atTextEnd(_sheet);
      final controller = widget.controller;
      if (atEnd != controller.atEnd) controller.reportPosition(controller.offset, atEnd: atEnd);
    }

    // The controller's listeners rebuild; not while this view is built.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => report());
    } else {
      report();
    }
  }

  void _place(int offset) {
    // The end of the text is the end sheet, where the end card is.
    final chapters = _paginator.layout.model.chapters.length;
    if (chapters > 0 && offset >= _paginator.layout.model.totalLength && _hasEndSheet) {
      _sheet = _Sheet(chapters - 1, _sheetCount(chapters - 1));
      return;
    }
    final ref = _paginator.pageAt(offset);
    _sheet = _Sheet(ref.chapter, _spread ? ref.index ~/ 2 : ref.index);
  }

  int _sheetCount(int chapter) => _spread ? _paginator.spreadsOfChapter(chapter).length : _paginator.pagesOfChapter(chapter).length;

  /// The sheet after the last page of the text, when there is one.
  bool _isEnd(_Sheet sheet) =>
      widget.endBuilder != null && sheet.chapter == _paginator.layout.model.chapters.length - 1 && _hasEndSheet && sheet.index >= _sheetCount(sheet.chapter);

  /// Whether nothing of the text follows [sheet].
  bool _atTextEnd(_Sheet sheet) {
    final next = _neighbour(sheet, 1);
    return next == null || _isEnd(next);
  }

  _Sheet? _neighbour(_Sheet sheet, int direction) {
    final chapters = _paginator.layout.model.chapters.length;
    if (direction > 0) {
      if (_isEnd(sheet)) return null;
      if (sheet.index + 1 < _sheetCount(sheet.chapter)) return _Sheet(sheet.chapter, sheet.index + 1);
      if (sheet.chapter + 1 < chapters) return _Sheet(sheet.chapter + 1, 0);
      return _hasEndSheet ? _Sheet(sheet.chapter, _sheetCount(sheet.chapter)) : null;
    }
    if (_isEnd(sheet)) return _Sheet(sheet.chapter, _sheetCount(sheet.chapter) - 1);
    if (sheet.index > 0) return _Sheet(sheet.chapter, sheet.index - 1);
    return sheet.chapter > 0 ? _Sheet(sheet.chapter - 1, _sheetCount(sheet.chapter - 1) - 1) : null;
  }

  List<ReaderPage> _pagesOf(_Sheet sheet) {
    if (_isEnd(sheet)) return const [];
    if (!_spread) return [_paginator.pagesOfChapter(sheet.chapter)[sheet.index]];
    final spread = _paginator.spreadsOfChapter(sheet.chapter)[sheet.index];
    return [spread.left, ?spread.right];
  }

  bool get _animates => widget.animation != ReaderPageAnimation.none && !MediaQuery.disableAnimationsOf(context);

  /// Shows [sheet] and tells the controller where the reader now is.
  void _commit(_Sheet sheet) {
    setState(() {
      _sheet = sheet;
      _incoming = null;
      _direction = 0;
      _drag = 0;
    });
    _turn.value = 0;
    // The end sheet leaves the position where it was: it holds no text.
    final offset = _isEnd(sheet) ? widget.controller.offset : _pagesOf(sheet).first.startOffset;
    widget.controller.reportPosition(offset, atEnd: _atTextEnd(sheet));
  }

  void _finish() {
    if (!mounted) return;
    final incoming = _incoming;
    if (incoming != null && _turn.value >= 1) {
      _commit(incoming);
    } else if (_turn.value <= 0) {
      setState(() {
        _incoming = null;
        _direction = 0;
        _drag = 0;
      });
    }
  }

  /// Ends a turn in progress where it is headed.
  void _settle() {
    if (!_turn.isAnimating) return;
    final target = _turn.status == AnimationStatus.reverse ? 0.0 : 1.0;
    _turn.stop();
    _turn.value = target;
    _finish();
  }

  // ---- Dragging.

  void _dragStart(DragStartDetails details) {
    _settle();
    _dragging = true;
    _drag = 0;
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    _drag += details.primaryDelta ?? details.delta.dx;
    final direction = _drag < 0 ? 1 : -1;
    final next = _drag == 0 ? null : _neighbour(_sheet, direction);
    if (next == null) {
      // Nothing that way: the page stays.
      if (_incoming != null) setState(() => _incoming = null);
      _turn.value = 0;
      return;
    }
    if (next != _incoming) {
      setState(() {
        _incoming = next;
        _direction = direction;
      });
    }
    // A turn without animation does not follow the finger.
    if (_animates) _turn.value = (_drag.abs() / math.max(1, _width)).clamp(0.0, 1.0);
  }

  void _dragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final incoming = _incoming;
    if (incoming == null) return;
    final velocity = details.primaryVelocity ?? details.velocity.pixelsPerSecond.dx;
    final flung = velocity.abs() > _flingVelocity && velocity.sign == _drag.sign;
    final complete = flung || _drag.abs() > _width / 3;
    if (!_animates) {
      if (complete) {
        _commit(incoming);
      } else {
        _finish();
      }
      return;
    }
    if (complete) {
      unawaited(_turn.animateTo(1, curve: Curves.easeOutCubic).then((_) => _finish()));
    } else {
      unawaited(_turn.animateBack(0, curve: Curves.easeOutCubic).then((_) => _finish()));
    }
  }

  void _dragCancel() {
    if (!_dragging) return;
    _dragging = false;
    if (_incoming != null) unawaited(_turn.animateBack(0).then((_) => _finish()));
  }

  // ---- Building.

  Widget _page(ReaderPage page) {
    final layout = _paginator.layout;
    final typesetting = layout.typesetting;
    final geometry = widget.geometry;
    final column = layout.columnWidth;
    final left = (geometry.pageWidth - column) / 2;
    return SizedBox(
      width: geometry.pageWidth,
      height: geometry.pageHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final item in page.items)
            switch (item) {
              ReaderTextSlice(:final block, :final top, :final height, :final firstLine, :final lineCount) => Positioned(
                top: top,
                left: left,
                width: column,
                height: height,
                child: ReaderParagraph(
                  text: layout.lineTextOf(block)!,
                  typesetting: typesetting,
                  firstLine: firstLine,
                  lineCount: lineCount,
                  onLink: widget.onLink,
                  onPageJump: widget.onPageJump,
                ),
              ),
              ReaderBlockItem(:final block, :final top, :final height, :final scale) => Positioned(
                top: top,
                left: left + column * (1 - scale) / 2,
                width: column * scale,
                height: height,
                child: _picture(block),
              ),
            },
          if (_cardOnLast && _isLastPage(page))
            Positioned(top: _usedHeight(page) + FrostGap.section, left: left, width: column, height: _endHeight, child: widget.endBuilder!(context)),
        ],
      ),
    );
  }

  /// The block's picture or card, reporting a picture's size.
  Widget _picture(int block) =>
      widget.blockBuilder(context, block, _paginator.layout.model.blocks[block] is NovelUploadedImage ? (size) => _imageSized(block, size) : null);

  /// Takes the size of the picture in [block]: the layout and the pages follow
  /// it, and the page shown stays the one holding the reading offset.
  void _imageSized(int block, Size size) {
    void apply() {
      if (!mounted) return;
      final layout = _paginator.layout;
      final extent = layout.extentOf(block);
      final offset = widget.controller.offset;
      layout.updateImageSize(block, size, anchorBlock: 0);
      if (layout.extentOf(block) == extent) return;
      _paginator.invalidate();
      // A turn or drag in progress belongs to the old pages.
      _turn.stop();
      _turn.value = 0;
      _incoming = null;
      _direction = 0;
      _drag = 0;
      _dragging = false;
      _sheetWidgets.clear();
      _place(offset);
      setState(() {});
      _reportEnd();
      widget.onRepaginated?.call();
    }

    // The picture may report while the page is building.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
      SchedulerBinding.instance.scheduleFrame();
    } else {
      apply();
    }
  }

  /// The end card built out of sight at the text column's width, so its height
  /// is known before it is placed.
  Widget _endMeasure() {
    if (widget.endBuilder == null) return const SizedBox.shrink();
    SchedulerBinding.instance.addPostFrameCallback((_) => _measureEnd());
    return Offstage(
      // The card takes the height it needs, not the page's.
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 0,
        maxWidth: _paginator.layout.columnWidth,
        minHeight: 0,
        maxHeight: double.infinity,
        // The card may grow once what it shows has loaded.
        child: NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (_) {
            SchedulerBinding.instance.addPostFrameCallback((_) => _measureEnd());
            return true;
          },
          child: SizeChangedLayoutNotifier(
            child: SizedBox(key: _endProbe, width: _paginator.layout.columnWidth, child: widget.endBuilder!(context)),
          ),
        ),
      ),
    );
  }

  void _measureEnd() {
    if (!mounted) return;
    final box = _endProbe.currentContext?.findRenderObject();
    final height = box is RenderBox && box.hasSize ? box.size.height : null;
    if (height == null || height == _endHeight) return;
    final before = _hasEndSheet;
    _endHeight = height;
    _sheetWidgets.clear();
    setState(() {});
    if (before == _hasEndSheet) return;
    // The end moved between a sheet of its own and the last page.
    _place(widget.controller.offset);
    _reportEnd();
  }

  /// The pictures of the pages before and after the one shown, built out of
  /// sight so they load, and have their size, before they are turned to.
  Widget _preload() {
    final items = <ReaderBlockItem>[];
    for (final direction in [-1, 1]) {
      final sheet = _neighbour(_sheet, direction);
      if (sheet == null) continue;
      for (final page in _pagesOf(sheet)) {
        items.addAll(page.items.whereType<ReaderBlockItem>().where((item) => _paginator.layout.model.blocks[item.block] is NovelUploadedImage));
      }
    }
    if (items.isEmpty) return const SizedBox.shrink();
    final column = _paginator.layout.columnWidth;
    return Offstage(
      child: Column(
        children: [for (final item in items) SizedBox(key: ValueKey(item.block), width: column * item.scale, height: item.height, child: _picture(item.block))],
      ),
    );
  }

  /// The sheets on show, built once each; a turn only moves them.
  final _sheetWidgets = <_Sheet, Widget>{};

  Widget _sheetFor(_Sheet sheet) {
    _sheetWidgets.removeWhere((key, _) => key != _sheet && key != _incoming);
    return _sheetWidgets[sheet] ??= KeyedSubtree(key: ValueKey(sheet), child: _sheetWidget(sheet));
  }

  Widget _endSheet() {
    final geometry = widget.geometry;
    return SizedBox(
      width: _width,
      height: geometry.pageHeight,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: _paginator.layout.typesetting.bodyLinePx),
          child: SizedBox(width: _paginator.layout.columnWidth, child: widget.endBuilder!(context)),
        ),
      ),
    );
  }

  Widget _sheetWidget(_Sheet sheet) {
    if (_isEnd(sheet)) return _endSheet();
    final pages = _pagesOf(sheet);
    if (!_spread) return _page(pages.single);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _page(pages.first),
        SizedBox(width: widget.geometry.gutter),
        if (pages.length > 1) _page(pages[1]) else SizedBox(width: widget.geometry.pageWidth),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = _paginator.layout.typesetting.palette.background;
    final current = _sheetFor(_sheet);
    final incoming = _incoming;
    final next = incoming == null ? null : _sheetFor(incoming);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      supportedDevices: const {PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.invertedStylus},
      onHorizontalDragStart: _dragStart,
      onHorizontalDragUpdate: _dragUpdate,
      onHorizontalDragEnd: _dragEnd,
      onHorizontalDragCancel: _dragCancel,
      child: ClipRect(
        child: Stack(fit: StackFit.expand, children: [_animated(background, current, incoming, next), _preload(), _endMeasure()]),
      ),
    );
  }

  Widget _animated(Color background, Widget current, _Sheet? incoming, Widget? next) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _turn,
        builder: (context, _) {
          if (next == null || _direction == 0) return Center(child: current);
          return ReaderPageTurn(
            cover: widget.animation == ReaderPageAnimation.cover,
            direction: _direction,
            progress: _turn.value,
            width: _width,
            background: background,
            current: current,
            next: next,
          );
        },
      ),
    );
  }
}
