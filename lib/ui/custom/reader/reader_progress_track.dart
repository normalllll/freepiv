// app-owned: novel reader progress track
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// A slider over the whole text with a tick at the start of each chapter and
/// a dot for each illustration. Frost's slider has no decoration of that
/// kind, so the track is painted here; colours come from the Frost tokens and
/// the interaction follows Frost's slider (arrow keys one percent, Page keys
/// ten, Home and End, a semantic value that can be increased and decreased).
///
/// While a finger or the pointer drags, [bubbleLabel] names the place under
/// the thumb in a bubble above it; the position is committed with
/// [onChanged] once, when the drag ends or a key or tap picks a place.
class ReaderProgressTrack extends StatefulWidget {
  const ReaderProgressTrack({
    required this.repaint,
    required this.progress,
    required this.chapterMarks,
    required this.imageMarks,
    required this.semanticLabel,
    required this.valueLabel,
    required this.bubbleLabel,
    required this.onChanged,
    super.key,
  });

  /// Notifies when [progress] changes.
  final Listenable repaint;

  /// How far through the text the reader is, 0 to 1.
  final double Function() progress;

  /// Positions, 0 to 1, of the chapters' first characters.
  final List<double> chapterMarks;

  /// Positions, 0 to 1, of the illustrations.
  final List<double> imageMarks;
  final String semanticLabel;
  final String Function(double value) valueLabel;

  /// What the bubble above the thumb says for the place [value].
  final String Function(double value) bubbleLabel;

  /// Null while there is nothing to move through.
  final ValueChanged<double>? onChanged;

  static const height = 44.0;

  /// Space between the track's ends and its first and last position.
  static const inset = 12.0;

  @override
  State<ReaderProgressTrack> createState() => ReaderProgressTrackState();
}

class ReaderProgressTrackState extends State<ReaderProgressTrack> {
  static const _thumb = 7.0;
  final _drag = ValueNotifier<double?>(null);
  final _focus = FocusNode(debugLabel: 'reader-progress-track');

  /// The place under the thumb while dragging, for tests.
  double? get dragging => _drag.value;

  @override
  void dispose() {
    _drag.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onChanged != null;

  double _fractionAt(double x, double width, TextDirection direction) {
    final span = math.max(1.0, width - 2 * ReaderProgressTrack.inset);
    final value = ((x - ReaderProgressTrack.inset) / span).clamp(0.0, 1.0);
    return direction == TextDirection.rtl ? 1 - value : value;
  }

  void _commit(double value) => widget.onChanged?.call(value.clamp(0.0, 1.0));

  void _step(double delta) => _commit(widget.progress() + delta);

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (!_enabled || event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.arrowUp) {
      _step(.01);
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowDown) {
      _step(-.01);
    } else if (key == LogicalKeyboardKey.pageUp) {
      _step(.1);
    } else if (key == LogicalKeyboardKey.pageDown) {
      _step(-.1);
    } else if (key == LogicalKeyboardKey.home) {
      _commit(0);
    } else if (key == LogicalKeyboardKey.end) {
      _commit(1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _release() {
    final value = _drag.value;
    _drag.value = null;
    if (value != null) _commit(value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = FrostThemeTokens.of(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ListenableBuilder(
          listenable: widget.repaint,
          builder: (context, _) => Semantics(
            slider: true,
            enabled: _enabled,
            label: widget.semanticLabel,
            value: widget.valueLabel(widget.progress()),
            increasedValue: widget.valueLabel((widget.progress() + .01).clamp(0.0, 1.0)),
            decreasedValue: widget.valueLabel((widget.progress() - .01).clamp(0.0, 1.0)),
            onIncrease: _enabled ? () => _step(.01) : null,
            onDecrease: _enabled ? () => _step(-.01) : null,
            child: Focus(
              focusNode: _focus,
              canRequestFocus: _enabled,
              onKeyEvent: _key,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _enabled
                    ? (details) {
                        _focus.requestFocus();
                        _commit(_fractionAt(details.localPosition.dx, width, direction));
                      }
                    : null,
                onHorizontalDragStart: _enabled ? (details) => _drag.value = _fractionAt(details.localPosition.dx, width, direction) : null,
                onHorizontalDragUpdate: _enabled ? (details) => _drag.value = _fractionAt(details.localPosition.dx, width, direction) : null,
                onHorizontalDragEnd: _enabled ? (_) => _release() : null,
                onHorizontalDragCancel: _enabled ? () => _drag.value = null : null,
                child: SizedBox(
                  height: ReaderProgressTrack.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ListenableBuilder(
                          listenable: _drag,
                          builder: (context, _) => CustomPaint(
                            painter: _TrackPainter(
                              value: _drag.value ?? widget.progress(),
                              dragging: _drag.value != null,
                              chapterMarks: widget.chapterMarks,
                              imageMarks: widget.imageMarks,
                              track: tokens.line,
                              fill: tokens.accent,
                              mark: tokens.textSecondary,
                              thumbRing: tokens.surface,
                              rtl: direction == TextDirection.rtl,
                              enabled: _enabled,
                            ),
                          ),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: _drag,
                        builder: (context, _) {
                          final value = _drag.value;
                          if (value == null) return const SizedBox.shrink();
                          return _Bubble(
                            label: widget.bubbleLabel(value),
                            fraction: direction == TextDirection.rtl ? 1 - value : value,
                            width: width,
                            tokens: tokens,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.label, required this.fraction, required this.width, required this.tokens});

  static const _maxWidth = 168.0;

  final String label;
  final double fraction;
  final double width;
  final FrostThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final maxWidth = math.min(_maxWidth, width);
    final x = ReaderProgressTrack.inset + fraction * (width - 2 * ReaderProgressTrack.inset);
    final start = (x - maxWidth / 2).clamp(0.0, math.max(0.0, width - maxWidth)).toDouble();
    return Positioned(
      left: start,
      bottom: ReaderProgressTrack.height - 6,
      child: IgnorePointer(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceRaised,
              borderRadius: BorderRadius.circular(FrostRadius.sm),
              border: Border.all(color: tokens.line),
              boxShadow: [BoxShadow(color: tokens.shadow, blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: FrostText(label, role: FrostTextRole.footnote, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.value,
    required this.dragging,
    required this.chapterMarks,
    required this.imageMarks,
    required this.track,
    required this.fill,
    required this.mark,
    required this.thumbRing,
    required this.rtl,
    required this.enabled,
  });

  final double value;
  final bool dragging;
  final List<double> chapterMarks, imageMarks;
  final Color track, fill, mark, thumbRing;
  final bool rtl, enabled;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = ReaderProgressTrack.inset;
    final span = math.max(1.0, size.width - 2 * inset);
    double xOf(double fraction) => inset + (rtl ? 1 - fraction : fraction) * span;
    final y = size.height / 2;
    final opacity = enabled ? 1.0 : .38;
    final base = Paint()
      ..color = track.withValues(alpha: track.a * opacity)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(inset, y), Offset(inset + span, y), base);
    final done = Paint()
      ..color = fill.withValues(alpha: opacity)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(xOf(0), y), Offset(xOf(value.clamp(0.0, 1.0)), y), done);

    final ticks = Paint()
      ..color = mark.withValues(alpha: .7 * opacity)
      ..strokeWidth = 1.5;
    for (final fraction in chapterMarks) {
      if (fraction <= 0 || fraction >= 1) continue;
      final x = xOf(fraction);
      canvas.drawLine(Offset(x, y - 7), Offset(x, y + 7), ticks);
    }
    final dots = Paint()..color = fill.withValues(alpha: opacity);
    for (final fraction in imageMarks) {
      canvas.drawCircle(Offset(xOf(fraction.clamp(0.0, 1.0)), y + 13), 2, dots);
    }
    final thumbX = xOf(value.clamp(0.0, 1.0));
    final radius = dragging ? ReaderProgressTrackState._thumb + 2 : ReaderProgressTrackState._thumb;
    canvas.drawCircle(Offset(thumbX, y), radius + 2, Paint()..color = thumbRing);
    canvas.drawCircle(Offset(thumbX, y), radius, Paint()..color = fill.withValues(alpha: opacity));
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.value != value ||
      old.dragging != dragging ||
      !listEquals(old.chapterMarks, chapterMarks) ||
      !listEquals(old.imageMarks, imageMarks) ||
      old.track != track ||
      old.fill != fill ||
      old.mark != mark ||
      old.thumbRing != thumbRing ||
      old.rtl != rtl ||
      old.enabled != enabled;
}
