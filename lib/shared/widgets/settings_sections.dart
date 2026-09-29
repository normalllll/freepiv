import 'package:flutter/material.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'grouped_settings_list.dart';

class SettingsSections extends StatefulWidget {
  const SettingsSections({required this.labels, required this.groups, super.key}) : assert(labels.length == groups.length);
  final List<String> labels;
  final List<List<Widget>> groups;
  @override
  State<SettingsSections> createState() => _SettingsSectionsState();
}

class _SettingsSectionsState extends State<SettingsSections> {
  static const _sectionListWidth = 200.0;

  int _selected = 0;
  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!AutoScaffold.usesHorizontalLayoutOf(context) || constraints.maxWidth < 720) {
          return GroupedSettingsList(groups: widget.groups);
        }
        // The section list and the groups share the pages' content column:
        // the list starts at the column's left edge and the groups end at its
        // right edge, while the groups' scroll view still reaches the window
        // edge for its scrollbar.
        final column = AppMetrics.columnPadding(constraints.maxWidth, maxWidth: AppMetrics.settingsMaxWidth);
        return SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: column.left + _sectionListWidth,
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(column.left, AppMetrics.sectionGap, 0, AppMetrics.sectionGap),
                  itemCount: widget.labels.length,
                  itemBuilder: (context, index) => ListTile(
                    selected: _selected == index,
                    selectedTileColor: tokens.selectionFill,
                    selectedColor: tokens.selectionInk,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
                    title: Text(widget.labels[index]),
                    onTap: () => setState(() => _selected = index),
                  ),
                ),
              ),
              const SizedBox(width: AppMetrics.sectionGap),
              Expanded(
                child: GroupedSettingsList(
                  key: PageStorageKey('settings-$_selected'),
                  groups: [widget.groups[_selected]],
                  horizontalPadding: EdgeInsets.only(right: column.right),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
