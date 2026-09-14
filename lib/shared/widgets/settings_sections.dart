import 'package:flutter/material.dart';
import 'form_controls.dart';
import 'grouped_settings_list.dart';

class SettingsSections extends StatefulWidget {
  const SettingsSections({required this.labels, required this.groups, super.key}) : assert(labels.length == groups.length);
  final List<String> labels;
  final List<List<Widget>> groups;
  @override
  State<SettingsSections> createState() => _SettingsSectionsState();
}

class _SettingsSectionsState extends State<SettingsSections> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 600) return GroupedSettingsList(groups: widget.groups);
      return SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AppSelect<int>(
                value: _selected,
                items: [for (var index = 0; index < widget.labels.length; index++) AppSelectItem(value: index, label: widget.labels[index])],
                onChanged: (index) => setState(() => _selected = index),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: GroupedSettingsList(key: PageStorageKey('settings-$_selected'), groups: [widget.groups[_selected]]),
              ),
            ),
          ],
        ),
      );
    },
  );
}
