import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';

/// A download entry (the sidebar dock or the phone's floating button) that
/// can receive a flight: where its count badge is on screen, even before the
/// button has appeared for the first task, and a bounce for the landing.
abstract interface class DownloadFlightTarget {
  /// The badge's global rect, or null while this entry is not shown.
  Rect? get badgeRect;

  void land();
}

/// “Added to downloads”: a small copy of the work jumps from where the user
/// tapped to the download badge, which bounces as it lands
/// (docs/MOTION_SPEC.md). Purely visual; the download runs regardless.
abstract final class DownloadFlight {
  static final List<DownloadFlightTarget> _targets = [];

  static void attach(DownloadFlightTarget target) => _targets.add(target);

  static void detach(DownloadFlightTarget target) => _targets.remove(target);

  static DownloadFlightTarget? get _target => _targets.reversed.where((target) => target.badgeRect != null).firstOrNull;

  /// The global rect of the widget at [context], as a flight origin.
  static Rect? originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Sends a flight from [origin] (a global rect: the tapped button, or a
  /// small box around a pointer position) showing [imageUrl] when there is
  /// one. With reduced motion only the landing bounce plays.
  static void launch({required Rect? origin, String? imageUrl}) {
    final target = _target;
    final overlay = AppRouter.rootNavigatorKey.currentState?.overlay;
    if (target == null) return;
    if (origin == null || overlay == null || MediaQuery.disableAnimationsOf(overlay.context)) {
      target.land();
      return;
    }
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _Flight(
        origin: origin,
        target: target,
        imageUrl: imageUrl,
        onDone: () {
          target.land();
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _Flight extends StatefulWidget {
  const _Flight({required this.origin, required this.target, required this.imageUrl, required this.onDone});

  final Rect origin;
  final DownloadFlightTarget target;
  final String? imageUrl;
  final VoidCallback onDone;

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 620);
  static const _endSize = 18.0;

  late final AnimationController _controller = AnimationController(vsync: this, duration: _duration)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  /// Where the token lands, followed each frame: the badge may only appear
  /// as the first task registers.
  Rect _destination = Rect.zero;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The overlay sits below the Windows title bar; convert the global rects
    // into its own space.
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    Offset local(Offset global) => overlayBox == null || !overlayBox.hasSize ? global : overlayBox.globalToLocal(global);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        _destination = widget.target.badgeRect ?? _destination;
        final from = local(widget.origin.center);
        final to = local(_destination.center);
        final t = _controller.value;
        // A jump: along a curve that rises above both ends, faster through
        // the middle, like something tossed onto the badge.
        final eased = Curves.easeInOutCubic.transform(t);
        final lift = 64 + .18 * (to - from).distance;
        final control = Offset((from.dx + to.dx) / 2, math.min(from.dy, to.dy) - lift);
        final position = _quadratic(from, control, to, eased);
        final startSize = math.min(56.0, widget.origin.shortestSide.clamp(28.0, 56.0));
        final size = startSize + (_endSize - startSize) * Curves.easeInCubic.transform(t);
        final opacity = math.min((t / .12).clamp(0.0, 1.0), ((1 - t) / .1).clamp(0.0, 1.0));
        return Stack(
          children: [
            Positioned(
              left: position.dx - size / 2,
              top: position.dy - size / 2,
              width: size,
              height: size,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: _Token(imageUrl: widget.imageUrl),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Offset _quadratic(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }
}

class _Token extends StatelessWidget {
  const _Token({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final imageUrl = this.imageUrl;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.actionFill,
        border: Border.all(color: tokens.surfaceRaised, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: tokens.isDark ? .36 : .18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl == null
            ? Center(
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.download_rounded, color: tokens.onAction),
                  ),
                ),
              )
            : PixivImage(url: imageUrl),
      ),
    );
  }
}

/// The landing bounce of a download entry: a velocity kick on a critically
/// damped spring, the same gesture as the bookmark heart. Mix into the
/// entry's state and wrap its button with [landingScale].
mixin DownloadLandingBounce<T extends StatefulWidget> on State<T>, TickerProvider {
  late final AnimationController _landing = AnimationController.unbounded(vsync: this);

  /// Peak of about 1.16 roughly 40 ms after landing, at rest within a
  /// quarter second.
  static const _kick = 11.0;

  void bounce() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _landing.animateWith(SpringSimulation(AppMotion.snappy, _landing.value, 0, _landing.velocity + _kick));
  }

  Widget landingScale({required Widget child}) => AnimatedBuilder(
    animation: _landing,
    builder: (context, child) => Transform.scale(scale: 1 + _landing.value, child: child),
    child: child,
  );

  @override
  void dispose() {
    _landing.dispose();
    super.dispose();
  }
}
