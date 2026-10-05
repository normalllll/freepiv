import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';

/// Lets a mouse drag tab strips and swipe tab pages the way touch does.
/// Wrap the tab bar and the tab view themselves rather than a whole header,
/// so a mouse drag in a text field still selects text.
class MouseDragScroll extends StatelessWidget {
  const MouseDragScroll({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(dragDevices: frostRefreshScrollBehavior.dragDevices),
    child: child,
  );
}
