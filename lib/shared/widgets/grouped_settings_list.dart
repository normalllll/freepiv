import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/ui/fp_grouped_rows.dart';

class GroupedSettingsList extends StatelessWidget {
  const GroupedSettingsList({required this.groups, this.horizontalPadding, super.key});

  final List<List<Widget>> groups;

  /// Defaults to the shared content column; a split settings pane passes the
  /// part of the column its list occupies.
  final EdgeInsets? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.sizeOf(context).width >= 600 ? AppMetrics.sectionGap : AppMetrics.pageInset;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = horizontalPadding ?? AppMetrics.columnPadding(constraints.maxWidth, maxWidth: AppMetrics.settingsMaxWidth);
        return ListView.separated(
          primary: false,
          padding: EdgeInsets.fromLTRB(
            horizontal.left,
            topPadding + MediaQuery.paddingOf(context).top,
            horizontal.right,
            28 + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppMetrics.itemGap),
          itemBuilder: (context, groupIndex) {
            final items = groups[groupIndex];
            return FpGroupedRows(children: items);
          },
        );
      },
    );
  }
}
