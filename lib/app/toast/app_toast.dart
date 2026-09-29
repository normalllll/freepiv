import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/core/platform/platform_info.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';
import 'package:freepiv/shared/ui/spring_builder.dart';

enum AppToastKind { success, info, warning, error }

/// In-app notices for the result of a user action (docs/MOTION_SPEC.md 9).
///
/// Touch platforms show one glass capsule under the status bar: it drops in
/// on a spring, a newer notice morphs the same capsule instead of queueing,
/// and it is swiped up to dismiss or held to keep it. Desktop shows glass
/// cards in the bottom-right corner, like the system's notifications: newer
/// cards stack in front with older ones peeking behind, and hovering spreads
/// the stack into a list and holds every timer.
///
/// Notices render in [AppToastHost], inside the app's theme and locale.
class AppToast {
  AppToast._();

  static void success(String message) => _show(AppToastKind.success, message, const Duration(milliseconds: 2500));

  /// The result of a successful copy. Skipped where the system already
  /// confirms clipboard writes (Android 13+), so one copy shows one notice.
  static Future<void> copied(String message) async {
    if (await systemConfirmsClipboardCopies()) return;
    success(message);
  }

  static void error(String message) => _show(AppToastKind.error, message, const Duration(seconds: 5));

  /// The action that failed plus a one-line, localized cause. Technical detail
  /// stays out of toasts; it lives in the collapsed error details.
  static void errorWithCause(String message, Object error) {
    AppToast.error(t.common.errorWithCause(message: message, cause: formatPixivError(error)));
  }

  static void info(String message) => _show(AppToastKind.info, message, const Duration(milliseconds: 2500));

  static void warning(String message) => _show(AppToastKind.warning, message, const Duration(seconds: 4));

  static void _show(AppToastKind kind, String message, Duration duration) => AppToastHost._key.currentState?._show(kind, message, duration);
}

/// Hosts the notices above [child] (the app's pages). Install once, inside
/// the app's theme and localizations.
class AppToastHost extends StatefulWidget {
  AppToastHost({required this.child}) : super(key: _key);

  static final _key = GlobalKey<_AppToastHostState>();

  final Widget child;

  @override
  State<AppToastHost> createState() => _AppToastHostState();
}

class _Notice {
  _Notice({required this.id, required this.kind, required this.message, required this.duration});

  final int id;
  final AppToastKind kind;
  final String message;
  final Duration duration;
  bool leaving = false;

  /// How many identical notices this card stands for (desktop only).
  int count = 1;
  _NoticeTimer? timer;
}

/// A pausable countdown.
class _NoticeTimer {
  _NoticeTimer(this._remaining, this._onDone) {
    resume();
  }

  Duration _remaining;
  final VoidCallback _onDone;
  Timer? _timer;
  final Stopwatch _running = Stopwatch();

  void pause() {
    if (_timer == null) return;
    _timer!.cancel();
    _timer = null;
    _running.stop();
    _remaining -= _running.elapsed;
    _running.reset();
  }

  void resume() {
    if (_timer != null) return;
    _running
      ..reset()
      ..start();
    _timer = Timer(_remaining.isNegative ? Duration.zero : _remaining, _onDone);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

class _AppToastHostState extends State<AppToastHost> {
  final List<_Notice> _notices = [];
  int _nextId = 0;

  /// Most desktop cards kept at once; older ones leave as new ones arrive.
  static const _maxCards = 5;

  bool get _touch => switch (Theme.of(context).platform) {
    TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.fuchsia => true,
    _ => false,
  };

  void _show(AppToastKind kind, String message, Duration duration) {
    var merged = false;
    final notice = _Notice(id: _nextId++, kind: kind, message: message, duration: duration);
    setState(() {
      if (_touch) {
        // One capsule: the newer notice replaces the older in place.
        for (final old in _notices) {
          old.timer?.cancel();
        }
        _notices
          ..clear()
          ..add(notice);
      } else {
        // The same notice again folds into the showing card with a count and a
        // fresh timer, instead of stacking identical cards.
        final same = _notices.where((old) => !old.leaving && old.kind == kind && old.message == message).lastOrNull;
        if (same != null) {
          same.count++;
          same.timer?.cancel();
          same.timer = _NoticeTimer(duration, () => _dismiss(same));
          merged = true;
          return;
        }
        _notices.add(notice);
        final active = _notices.where((notice) => !notice.leaving).toList();
        for (final old in active.take(math.max(0, active.length - _maxCards))) {
          _leave(old);
        }
      }
    });
    if (!merged) notice.timer = _NoticeTimer(duration, () => _dismiss(notice));
  }

  void _leave(_Notice notice) {
    notice.timer?.cancel();
    notice.leaving = true;
  }

  void _dismiss(_Notice notice) {
    if (!mounted || notice.leaving) return;
    setState(() => _leave(notice));
  }

  void _removed(_Notice notice) {
    if (!mounted) return;
    setState(() => _notices.remove(notice));
  }

  void _pauseAll() {
    for (final notice in _notices) {
      notice.timer?.pause();
    }
  }

  void _resumeAll() {
    for (final notice in _notices) {
      if (!notice.leaving) notice.timer?.resume();
    }
  }

  @override
  void dispose() {
    for (final notice in _notices) {
      notice.timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final touch = _touch;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (_notices.isNotEmpty)
          Positioned.fill(
            // Tooltips on the close buttons need an overlay of their own here.
            child: Overlay.wrap(
              child: touch
                  ? _CapsuleLayer(notice: _notices.last, onDismiss: _dismiss, onRemoved: _removed, onHold: _pauseAll, onRelease: _resumeAll)
                  : _CardStackLayer(notices: List.of(_notices), onDismiss: _dismiss, onRemoved: _removed, onHold: _pauseAll, onRelease: _resumeAll),
            ),
          ),
      ],
    );
  }
}

(IconData, Color) _toastGlyph(FreepivThemeTokens tokens, AppToastKind kind) => switch (kind) {
  AppToastKind.success => (Icons.check_circle_rounded, tokens.keyGraphicOn(tokens.surfaceRaised)),
  AppToastKind.info => (Icons.info_outline_rounded, tokens.textSecondary),
  AppToastKind.warning => (Icons.warning_amber_rounded, tokens.textPrimary),
  AppToastKind.error => (Icons.error_outline_rounded, tokens.textPrimary),
};

// ---------------------------------------------------------------------------
// Touch: the capsule.

class _CapsuleLayer extends StatefulWidget {
  const _CapsuleLayer({required this.notice, required this.onDismiss, required this.onRemoved, required this.onHold, required this.onRelease});

  final _Notice notice;
  final ValueChanged<_Notice> onDismiss;
  final ValueChanged<_Notice> onRemoved;
  final VoidCallback onHold;
  final VoidCallback onRelease;

  @override
  State<_CapsuleLayer> createState() => _CapsuleLayerState();
}

class _CapsuleLayerState extends State<_CapsuleLayer> with TickerProviderStateMixin {
  /// 0 hidden above, 1 in place.
  late final AnimationController _presence = AnimationController.unbounded(vsync: this);

  /// Upward drag while the finger is down; springs back or away on release.
  late final AnimationController _drag = AnimationController.unbounded(vsync: this);

  /// A swipe needs this much upward travel or speed to dismiss.
  static const _dismissDistance = 24.0;
  static const _dismissVelocity = 400.0;

  @override
  void initState() {
    super.initState();
    _enter();
  }

  @override
  void didUpdateWidget(_CapsuleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notice.leaving) {
      _exit();
    } else if (widget.notice != oldWidget.notice) {
      // A new notice while one is showing morphs the same capsule; it only
      // drops in again if the old one was already on its way out.
      _drag.value = 0;
      _enter();
    }
  }

  void _enter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.notice.leaving) AppMotion.springTo(context, _presence, 1, AppMotion.standard);
    });
  }

  Future<void> _exit() async {
    final notice = widget.notice;
    await AppMotion.springTo(context, _presence, 0, AppMotion.snappy).orCancel.catchError((_) {});
    if (mounted && widget.notice == notice && notice.leaving) widget.onRemoved(notice);
  }

  void _dragUpdate(DragUpdateDetails details) {
    final next = _drag.value + details.delta.dy;
    // Upward follows the finger; downward resists.
    _drag.value = next < 0 ? next : next * .25;
  }

  void _dragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_drag.value < -_dismissDistance || velocity < -_dismissVelocity) {
      widget.onDismiss(widget.notice);
    } else {
      _drag.animateWith(SpringSimulation(AppMotion.snappy, _drag.value, 0, velocity));
    }
    widget.onRelease();
  }

  @override
  void dispose() {
    _presence.dispose();
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = math.min(480.0, media.size.width - 32);
    final notice = widget.notice;
    final capsule = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => widget.onHold(),
      onVerticalDragUpdate: _dragUpdate,
      onVerticalDragEnd: _dragEnd,
      onLongPressStart: (_) => widget.onHold(),
      onLongPressEnd: (_) => widget.onRelease(),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, minHeight: 44),
        child: FpSurface(
          role: FpSurfaceRole.overlay,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedSize(
            duration: AppMotion.duration(context, const Duration(milliseconds: 350)),
            curve: SpringCurve(AppMotion.standard, const Duration(milliseconds: 350)),
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.hover),
              layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, ?current]),
              child: _CapsuleContent(key: ValueKey(notice.id), notice: notice),
            ),
          ),
        ),
      ),
    );
    return Positioned(
      top: media.padding.top + 8,
      left: 16,
      right: 16,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedBuilder(
          animation: Listenable.merge([_presence, _drag]),
          builder: (context, child) {
            final presence = _presence.value;
            return Transform.translate(
              offset: Offset(0, -24 * (1 - presence).clamp(0.0, 1.0) + _drag.value),
              child: Transform.scale(
                scale: .9 + .1 * presence,
                alignment: Alignment.topCenter,
                child: Opacity(opacity: presence.clamp(0.0, 1.0), child: child),
              ),
            );
          },
          child: capsule,
        ),
      ),
    );
  }
}

class _CapsuleContent extends StatelessWidget {
  const _CapsuleContent({required this.notice, super.key});

  final _Notice notice;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 18, 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToastGlyph(kind: notice.kind),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                notice.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop: the stacked cards.

class _CardStackLayer extends StatefulWidget {
  const _CardStackLayer({required this.notices, required this.onDismiss, required this.onRemoved, required this.onHold, required this.onRelease});

  /// Oldest first; the newest is painted on top.
  final List<_Notice> notices;
  final ValueChanged<_Notice> onDismiss;
  final ValueChanged<_Notice> onRemoved;
  final VoidCallback onHold;
  final VoidCallback onRelease;

  @override
  State<_CardStackLayer> createState() => _CardStackLayerState();
}

class _CardStackLayerState extends State<_CardStackLayer> {
  static const _width = 360.0;
  static const _gap = 8.0;

  /// How far each older card peeks out below the one in front.
  static const _peek = 8.0;
  static const _visibleBehind = 2;

  final Map<int, double> _heights = {};
  bool _expanded = false;
  int _hovered = 0;
  Timer? _collapse;

  void _enter() {
    _hovered++;
    _collapse?.cancel();
    if (!_expanded) {
      setState(() => _expanded = true);
      widget.onHold();
    }
  }

  void _exit() {
    _hovered = math.max(0, _hovered - 1);
    if (_hovered > 0) return;
    // Moving between spread cards crosses their gaps; wait before folding.
    _collapse?.cancel();
    _collapse = Timer(const Duration(milliseconds: 120), () {
      if (!mounted || _hovered > 0) return;
      setState(() => _expanded = false);
      widget.onRelease();
    });
  }

  void _measured(_Notice notice, Size size) {
    if (_heights[notice.id] == size.height) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _heights[notice.id] = size.height);
    });
  }

  @override
  void dispose() {
    _collapse?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final active = widget.notices.where((notice) => !notice.leaving).toList().reversed.toList();
    // Front-to-back position of each card; leaving cards keep their last slot.
    final depth = {for (final (index, notice) in active.indexed) notice.id: index};
    var lift = 0.0;
    final lifts = <int, double>{};
    for (final notice in active) {
      lifts[notice.id] = lift;
      lift += (_heights[notice.id] ?? 72) + _gap;
    }
    return Stack(
      children: [
        for (final notice in widget.notices)
          Positioned(
            key: ValueKey(notice.id),
            right: 16 + padding.right,
            bottom: 16 + _peek * _visibleBehind + padding.bottom,
            width: _width,
            child: _StackedCard(
              notice: notice,
              depth: depth[notice.id] ?? 0,
              lift: _expanded ? lifts[notice.id] ?? 0 : 0,
              expanded: _expanded,
              visibleBehind: _visibleBehind,
              peek: _peek,
              onSize: (size) => _measured(notice, size),
              onClose: () => widget.onDismiss(notice),
              onRemoved: () {
                _heights.remove(notice.id);
                widget.onRemoved(notice);
              },
              onEnter: _enter,
              onExit: _exit,
            ),
          ),
      ],
    );
  }
}

class _StackedCard extends StatefulWidget {
  const _StackedCard({
    required this.notice,
    required this.depth,
    required this.lift,
    required this.expanded,
    required this.visibleBehind,
    required this.peek,
    required this.onSize,
    required this.onClose,
    required this.onRemoved,
    required this.onEnter,
    required this.onExit,
  });

  final _Notice notice;

  /// 0 for the front card, 1 behind it, and so on.
  final int depth;

  /// Upward offset while the stack is spread into a list.
  final double lift;
  final bool expanded;
  final int visibleBehind;
  final double peek;
  final ValueChanged<Size> onSize;
  final VoidCallback onClose;
  final VoidCallback onRemoved;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  @override
  State<_StackedCard> createState() => _StackedCardState();
}

class _StackedCardState extends State<_StackedCard> with SingleTickerProviderStateMixin {
  /// 0 off to the right, 1 in place.
  late final AnimationController _presence = AnimationController.unbounded(vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.notice.leaving) AppMotion.springTo(context, _presence, 1, AppMotion.standard);
    });
  }

  @override
  void didUpdateWidget(_StackedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notice.leaving && !_leaving) _leave();
  }

  bool _leaving = false;

  Future<void> _leave() async {
    _leaving = true;
    await AppMotion.springTo(context, _presence, 0, AppMotion.snappy).orCancel.catchError((_) {});
    if (mounted) widget.onRemoved();
  }

  @override
  void dispose() {
    _presence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final depth = widget.depth.toDouble();
    final hidden = !widget.expanded && widget.depth > widget.visibleBehind;
    // Collapsed: older cards shrink and peek out below the front one.
    // Spread: every card at full size, stacked upward.
    final offset = widget.expanded ? -widget.lift : math.min(depth, widget.visibleBehind + 1.0) * widget.peek;
    final scale = widget.expanded ? 1.0 : 1 - .05 * math.min(depth, widget.visibleBehind + 1.0);
    final dim = widget.expanded ? 0.0 : .18 * math.min(depth, widget.visibleBehind.toDouble());
    return IgnorePointer(
      ignoring: hidden || widget.notice.leaving,
      child: SpringBuilder(
        value: offset,
        spring: AppMotion.standard,
        builder: (context, offset, child) => SpringBuilder(
          value: scale,
          spring: AppMotion.standard,
          builder: (context, scale, child) => AnimatedBuilder(
            animation: _presence,
            builder: (context, child) {
              final presence = _presence.value.clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(48 * (1 - presence), offset),
                child: Transform.scale(
                  scale: scale * (.96 + .04 * presence),
                  alignment: Alignment.topCenter,
                  child: Opacity(opacity: hidden ? 0 : presence, child: child),
                ),
              );
            },
            child: child,
          ),
          child: child,
        ),
        child: _SizeReporter(
          onSize: widget.onSize,
          child: MouseRegion(
            onEnter: (_) => widget.onEnter(),
            onExit: (_) => widget.onExit(),
            child: _CardContent(notice: widget.notice, dim: dim, onClose: widget.onClose),
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.notice, required this.dim, required this.onClose});

  final _Notice notice;

  /// How much a card behind the front one is darkened, 0 for the front.
  final double dim;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    return Semantics(
      liveRegion: true,
      child: FpSurface(
        role: FpSurfaceRole.overlay,
        borderRadius: BorderRadius.circular(AppMetrics.groupRadius),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 6, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _ToastGlyph(kind: notice.kind),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        notice.count > 1 ? '${notice.message}  ×${notice.count}' : notice.message,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // A quiet icon button: its hover follows the theme on the
                  // glass instead of a fixed dark wash.
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: tokens.textSecondary,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            if (dim > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(color: tokens.canvas.withValues(alpha: dim)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter renderObject) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;

  @override
  void performLayout() {
    super.performLayout();
    onSize(size);
  }
}

// ---------------------------------------------------------------------------
// The glyph: a success check draws itself, an error shakes once, others pop.

class _ToastGlyph extends StatefulWidget {
  const _ToastGlyph({required this.kind});

  final AppToastKind kind;

  @override
  State<_ToastGlyph> createState() => _ToastGlyphState();
}

class _ToastGlyphState extends State<_ToastGlyph> with SingleTickerProviderStateMixin {
  static const _size = 20.0;

  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.status == AnimationStatus.dismissed) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final (icon, color) = _toastGlyph(tokens, widget.kind);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // The glyph starts once the capsule or card has mostly arrived.
        final appear = Curves.easeOutCubic.transform(const Interval(.15, .55).transform(t));
        return switch (widget.kind) {
          AppToastKind.success => CustomPaint(
            size: const Size.square(_size),
            painter: _CheckPainter(color: color, ring: appear, check: Curves.easeOutCubic.transform(const Interval(.35, .85).transform(t))),
          ),
          AppToastKind.error => Transform.translate(
            // One short shake after it appears.
            offset: Offset(math.sin(const Interval(.3, 1).transform(t) * math.pi * 4) * 2.5 * (1 - t), 0),
            child: Opacity(
              opacity: appear,
              child: Icon(icon, size: _size, color: color),
            ),
          ),
          _ => Transform.scale(
            scale: .6 + .4 * appear,
            child: Opacity(
              opacity: appear,
              child: Icon(icon, size: _size, color: color),
            ),
          ),
        };
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.color, required this.ring, required this.check});

  final Color color;

  /// Progress of the circle and of the tick drawing, 0 to 1.
  final double ring;
  final double check;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .1;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final radius = size.width / 2 - stroke / 2;
    final center = size.center(Offset.zero);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 2 * ring, false, paint);
    if (check <= 0) return;
    final tick = Path()
      ..moveTo(size.width * .30, size.height * .52)
      ..lineTo(size.width * .45, size.height * .66)
      ..lineTo(size.width * .71, size.height * .38);
    for (final PathMetric metric in tick.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * check), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => oldDelegate.ring != ring || oldDelegate.check != check || oldDelegate.color != color;
}
