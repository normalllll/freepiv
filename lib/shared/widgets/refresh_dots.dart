import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:freepiv/i18n/strings.g.dart';

class RefreshDots extends StatefulWidget {
  const RefreshDots({super.key});
  @override
  State<RefreshDots> createState() => _RefreshDotsState();
}

class _RefreshDotsState extends State<RefreshDots> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _animation.stop();
    } else if (!_animation.isAnimating) {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.t.refresh.refreshing,
    child: SizedBox(
      width: 24,
      height: 20,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var index = 0; index < 3; index++)
              Transform.translate(
                offset: Offset(0, _reduceMotion ? 0 : -4 * math.max(0, math.sin((_animation.value - index * .16) * math.pi * 2))),
                child: SizedBox.square(
                  dimension: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Keeps the scroll viewport and existing content in place during refresh.
class DotsRefreshIndicator extends StatefulWidget {
  const DotsRefreshIndicator({required this.child, required this.onRefresh, super.key});
  final Widget child;
  final RefreshCallback onRefresh;
  @override
  State<DotsRefreshIndicator> createState() => _DotsRefreshIndicatorState();
}

class _DotsRefreshIndicatorState extends State<DotsRefreshIndicator> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      RefreshIndicator.noSpinner(
        onRefresh: widget.onRefresh,
        onStatusChange: (status) {
          final visible = status != null && status != RefreshIndicatorStatus.done && status != RefreshIndicatorStatus.canceled;
          if (mounted && visible != _visible) setState(() => _visible = visible);
        },
        child: widget.child,
      ),
      Positioned(
        top: 8,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 140),
            child: Center(
              child: TickerMode(enabled: _visible, child: const RefreshDots()),
            ),
          ),
        ),
      ),
    ],
  );
}
