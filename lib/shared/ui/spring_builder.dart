import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:freepiv/app/theme/app_metrics.dart';

/// A no-bounce spring's path as a [Curve] over [duration], for implicit
/// animations that only take a curve (sizes, cross-fades). It keeps the
/// spring's shape (a quick start easing into rest) but not its velocity
/// hand-off; use [SpringBuilder] or [AppMotion.springTo] where a motion can
/// be redirected mid-flight.
class SpringCurve extends Curve {
  SpringCurve(this.spring, this.duration) : _end = SpringSimulation(spring, 0, 1, 0).x(duration.inMicroseconds / 1e6);

  final SpringDescription spring;
  final Duration duration;
  final double _end;

  @override
  double transformInternal(double t) => SpringSimulation(spring, 0, 1, 0).x(t * duration.inMicroseconds / 1e6) / _end;
}

/// Animates a number toward [value] on a spring and rebuilds with it.
///
/// Unlike an implicit animation, a new target taken mid-flight continues from
/// the current value *and velocity*, so quick reversals never jump back or
/// stall. With reduced motion the value is applied at once.
class SpringBuilder extends StatefulWidget {
  const SpringBuilder({required this.value, required this.spring, required this.builder, this.child, super.key});

  final double value;
  final SpringDescription spring;
  final ValueWidgetBuilder<double> builder;
  final Widget? child;

  @override
  State<SpringBuilder> createState() => _SpringBuilderState();
}

class _SpringBuilderState extends State<SpringBuilder> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(vsync: this, value: widget.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = widget.value;
  }

  @override
  void didUpdateWidget(SpringBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) AppMotion.springTo(context, _controller, widget.value, widget.spring);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) => widget.builder(context, _controller.value, child), child: widget.child);
  }
}

/// Shows [child] by growing it out of [alignment] (from [hiddenScale]) and
/// fading it in on the standard spring; hiding runs on the quicker snappy
/// spring. For panels that open from the button that summons them.
class SpringReveal extends StatelessWidget {
  const SpringReveal({required this.shown, required this.alignment, required this.child, this.hiddenScale = .9, super.key});

  final bool shown;
  final AlignmentGeometry alignment;
  final double hiddenScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SpringBuilder(
      value: shown ? 1 : 0,
      spring: shown ? AppMotion.standard : AppMotion.snappy,
      child: child,
      builder: (context, progress, child) => Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.scale(scale: hiddenScale + (1 - hiddenScale) * progress, alignment: alignment.resolve(Directionality.of(context)), child: child),
      ),
    );
  }
}
