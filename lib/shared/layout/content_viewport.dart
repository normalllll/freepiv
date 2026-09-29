import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';

/// Measures content in the space remaining after window navigation.
class ContentViewport extends StatelessWidget {
  const ContentViewport({required this.child, this.navigationReserve, super.key});
  final Widget child;
  final double? navigationReserve;

  @override
  Widget build(BuildContext context) {
    final reserve = navigationReserve ?? ContentColumnBudget.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => ContentColumnBudget(
        reservedWidth: reserve,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(size: Size(constraints.maxWidth, constraints.maxHeight)),
          child: child,
        ),
      ),
    );
  }
}

/// Keeps responsive column counts stable while the user opens the sidebar.
/// The count still follows the window, text scale, and each grid's own inset.
class ContentColumnBudget extends InheritedWidget {
  const ContentColumnBudget({required this.reservedWidth, required super.child, super.key});

  final double reservedWidth;

  static double of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ContentColumnBudget>()?.reservedWidth ?? 0;

  static double columnWidth(BuildContext context, double availableWidth) => math.max(0, availableWidth - of(context));

  @override
  bool updateShouldNotify(ContentColumnBudget oldWidget) => reservedWidth != oldWidget.reservedWidth;
}

/// A page's content column: centred, at most [maxWidth] wide, and inset by
/// [AppMetrics.columnPadding] so every page shares the same edges.
class ContentColumn extends StatelessWidget {
  const ContentColumn({required this.child, this.maxWidth = AppMetrics.contentMaxWidth, this.bleed = 0, super.key});

  final Widget child;
  final double maxWidth;

  /// How far the box reaches past the column on each side, for rows whose
  /// children carry that much inset themselves (padded buttons and tabs), so
  /// their visible content still lands on the column edge.
  final double bleed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final column = AppMetrics.columnPadding(constraints.maxWidth, maxWidth: maxWidth);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: math.max(0, column.left - bleed)),
          child: child,
        );
      },
    );
  }
}

/// [ContentColumn] for a sliver inside a scroll view; the scroll view itself
/// stays full width so its scrollbar remains at the window edge.
class SliverContentColumn extends StatelessWidget {
  const SliverContentColumn({required this.sliver, this.maxWidth = AppMetrics.contentMaxWidth, super.key});

  final Widget sliver;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverPadding(
        padding: AppMetrics.columnPadding(constraints.crossAxisExtent, maxWidth: maxWidth),
        sliver: sliver,
      ),
    );
  }
}
