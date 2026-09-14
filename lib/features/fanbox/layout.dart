import 'package:freepiv/shared/widgets/refresh_indicator.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';

class FanboxScaffold extends StatelessWidget {
  const FanboxScaffold({required this.title, required this.body, super.key});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) => AutoScaffold(
    builder: (context, layout, orientation, desktop) => Scaffold(
      appBar: desktop
          ? null
          : AppBar(
              title: Text(title),
              leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/search')),
            ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: dataRefreshScrollBehavior.dragDevices),
        child: SafeArea(bottom: false, child: body),
      ),
    ),
  );
}

class FanboxContent extends StatelessWidget {
  const FanboxContent({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: child),
  );
}

EdgeInsets fanboxScrollPadding(double width, {double inset = 12}) =>
    EdgeInsets.symmetric(horizontal: math.max(inset, (width - 900) / 2 + inset), vertical: inset);
