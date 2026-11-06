import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

class FanboxScaffold extends StatelessWidget {
  const FanboxScaffold({required this.title, required this.body, this.actions, super.key});

  final String title;
  final Widget body;
  final List<FrostToolbarItem>? actions;

  @override
  Widget build(BuildContext context) => FrostAutoScaffold(
    builder: (context, layout, orientation, desktop) => Scaffold(
      body: FrostCollapsingHeader(
        header: desktop
            ? null
            : FrostPageHeader(title: Text(title), actions: actions ?? const [], onBack: () => context.canPop() ? context.pop() : context.go('/me')),
        child: SafeArea(bottom: false, child: body),
      ),
    ),
  );
}

class FanboxContent extends StatelessWidget {
  const FanboxContent({required this.child, super.key});
  final Widget child;

  // Header rows pad their children by 12 themselves.
  @override
  Widget build(BuildContext context) => FrostContentColumn(child: child);
}

EdgeInsets fanboxScrollPadding(double width) => FrostMetrics.columnPadding(width).copyWith(top: 12, bottom: 12);

EdgeInsets fanboxReadingPadding(double width) => FrostMetrics.columnPadding(width, maxWidth: FrostMetrics.readingMaxWidth).copyWith(top: 24, bottom: 24);
