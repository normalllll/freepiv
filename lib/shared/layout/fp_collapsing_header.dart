import 'package:flutter/material.dart';

/// A phone page header, such as [FpPageHeader], that collapses while the
/// content below scrolls on and returns when it scrolls back or reaches its
/// top. The status bar inset stays; only the toolbar collapses.
///
/// Without a [header] (desktop layouts, whose window caption carries the
/// title) the [child] is returned as it is.
class FpCollapsingHeader extends StatefulWidget {
  const FpCollapsingHeader({required this.child, this.header, super.key});

  final Widget? header;
  final Widget child;

  @override
  State<FpCollapsingHeader> createState() => _FpCollapsingHeaderState();
}

class _FpCollapsingHeaderState extends State<FpCollapsingHeader> with SingleTickerProviderStateMixin {
  /// How far one direction must scroll before the header follows it, so a
  /// jitter or a slow drag does not make it flicker.
  static const _travel = 16.0;

  late final AnimationController _shown = AnimationController(vsync: this, value: 1, duration: const Duration(milliseconds: 200));
  double _travelled = 0;

  @override
  void dispose() {
    _shown.dispose();
    super.dispose();
  }

  void _setShown(bool shown) {
    final target = shown ? 1.0 : 0.0;
    if (_shown.isAnimating ? _shown.status == (shown ? AnimationStatus.forward : AnimationStatus.reverse) : _shown.value == target) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _shown.value = target;
    } else {
      _shown.animateTo(target, curve: Curves.easeOutCubic);
    }
  }

  bool _handleScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical || notification is! ScrollUpdateNotification) return false;
    final delta = notification.scrollDelta ?? 0;
    if (metrics.extentBefore <= 0) {
      _travelled = 0;
      _setShown(true);
      return false;
    }
    // A change of direction starts the count again.
    _travelled = (_travelled.sign == delta.sign ? _travelled : 0) + delta;
    if (_travelled <= -_travel) {
      _setShown(true);
    } else if (_travelled >= _travel && metrics.extentAfter > kToolbarHeight) {
      // With no room left below, hiding would grow the viewport past the end
      // and flip the direction back.
      _setShown(false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final header = widget.header;
    if (header == null) return widget.child;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Column(
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top),
        AnimatedBuilder(
          animation: _shown,
          // The height moves in whole device pixels: a fractional edge between
          // the header and the pinned bars below it shows as a jagged seam.
          builder: (context, child) => SizedBox(
            height: (kToolbarHeight * _shown.value * pixelRatio).round() / pixelRatio,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: kToolbarHeight,
                maxHeight: kToolbarHeight,
                child: Opacity(opacity: _shown.value, child: child),
              ),
            ),
          ),
          child: RepaintBoundary(
            child: MediaQuery.removePadding(context: context, removeTop: true, child: header),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: NotificationListener<ScrollNotification>(onNotification: _handleScroll, child: widget.child),
          ),
        ),
      ],
    );
  }
}
