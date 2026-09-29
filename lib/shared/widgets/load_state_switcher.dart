import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';

/// Cross-fades between load phases (skeleton → content, empty or error) so a
/// finished request never swaps the page in a single frame.
///
/// The first build shows its child without animation, so content that is
/// already cached appears immediately when a page is revisited. The outgoing
/// child is detached from the inherited [PrimaryScrollController] while it
/// fades, so the two scroll views never share a controller; detaching keeps
/// its scroll position, so it does not jump while leaving.
///
/// With [animateSize] the switcher also eases height changes, for phases that
/// sit inside a larger scroll view (sections, previews) rather than filling
/// the page.
class LoadStateSwitcher extends StatelessWidget {
  const LoadStateSwitcher({required this.child, this.phase, this.animateSize = false, super.key});

  /// Identifies the shown state. When null, a change of the child's type or key
  /// marks a new state, which suits `AsyncValue.when` branches that already
  /// build different widgets.
  final Object? phase;
  final Widget child;
  final bool animateSize;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.duration(context, AppMotion.reveal);
    final switcher = AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [
          for (final child in previous) _Phase(key: ObjectKey(child.key), leaving: true, child: child),
          if (current case final child?) _Phase(key: ObjectKey(child.key), leaving: false, child: child),
        ],
      ),
      child: phase == null ? child : KeyedSubtree(key: ValueKey(phase), child: child),
    );
    if (!animateSize) return switcher;
    return AnimatedSize(duration: duration, curve: Curves.easeInOutCubic, alignment: Alignment.topCenter, child: switcher);
  }
}

class _Phase extends StatelessWidget {
  const _Phase({required this.leaving, required this.child, super.key});

  final bool leaving;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Both branches are the same widget type, so toggling [leaving] updates
    // the subtree in place instead of rebuilding it.
    final inherited = context.dependOnInheritedWidgetOfExactType<PrimaryScrollController>();
    final scope = switch (inherited) {
      PrimaryScrollController(:final controller?) when !leaving => PrimaryScrollController(
        controller: controller,
        automaticallyInheritForPlatforms: inherited.automaticallyInheritForPlatforms,
        scrollDirection: inherited.scrollDirection,
        child: child,
      ),
      _ => PrimaryScrollController.none(child: child),
    };
    return IgnorePointer(
      ignoring: leaving,
      child: ExcludeSemantics(excluding: leaving, child: scope),
    );
  }
}
