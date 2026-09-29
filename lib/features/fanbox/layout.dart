import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/layout/fp_collapsing_header.dart';
import 'package:freepiv/shared/widgets/refresh_indicator.dart';

import 'package:flutter/material.dart';
import 'package:freepiv/shared/layout/content_viewport.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/layout/fp_page_header.dart';

class FanboxScaffold extends StatelessWidget {
  const FanboxScaffold({required this.title, required this.body, this.actions, super.key});

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => AutoScaffold(
    builder: (context, layout, orientation, desktop) => Scaffold(
      body: FpCollapsingHeader(
        header: desktop ? null : FpPageHeader(title: Text(title), actions: actions, onBack: () => context.canPop() ? context.pop() : context.go('/me')),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: dataRefreshScrollBehavior.dragDevices),
          child: SafeArea(bottom: false, child: body),
        ),
      ),
    ),
  );
}

class FanboxContent extends StatelessWidget {
  const FanboxContent({required this.child, super.key});
  final Widget child;

  // Header rows pad their children by 12 themselves.
  @override
  Widget build(BuildContext context) => ContentColumn(bleed: 12, child: child);
}

EdgeInsets fanboxScrollPadding(double width) => AppMetrics.columnPadding(width).copyWith(top: 12, bottom: 12);

EdgeInsets fanboxReadingPadding(double width) => AppMetrics.columnPadding(width, maxWidth: AppMetrics.readingMaxWidth).copyWith(top: 24, bottom: 24);
