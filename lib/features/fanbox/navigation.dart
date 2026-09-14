import 'package:flutter/material.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';
import 'logic.dart';

String fanboxSectionLabel(BuildContext context, FanboxSection section) {
  final t = context.t.fanbox;
  return switch (section) {
    FanboxSection.home => t.home,
    FanboxSection.supporting => t.supporting,
    FanboxSection.following => t.following,
    FanboxSection.recommended => t.recommended,
    FanboxSection.pixiv => t.pixiv,
    FanboxSection.plans => t.plans,
    FanboxSection.searchCreators => t.searchCreators,
    FanboxSection.searchTags || FanboxSection.tag => t.searchTags,
    FanboxSection.creatorPosts => t.posts,
    FanboxSection.creatorPlans => t.creatorPlans,
    FanboxSection.notices => t.notices,
    FanboxSection.messages => t.messages,
    FanboxSection.bookmarks => t.bookmarks,
  };
}

enum _FanboxGroup {
  feed([FanboxSection.home, FanboxSection.supporting]),
  discover([FanboxSection.recommended, FanboxSection.pixiv, FanboxSection.plans, FanboxSection.searchCreators, FanboxSection.searchTags]),
  personal([FanboxSection.following, FanboxSection.bookmarks, FanboxSection.notices, FanboxSection.messages]);

  const _FanboxGroup(this.sections);
  final List<FanboxSection> sections;
}

class FanboxSectionNavigation extends StatelessWidget {
  const FanboxSectionNavigation({required this.section, required this.onSelected, super.key});
  final FanboxSection section;
  final ValueChanged<FanboxSection> onSelected;
  @override
  Widget build(BuildContext context) {
    final group = _FanboxGroup.values.where((group) => group.sections.contains(section)).firstOrNull ?? _FanboxGroup.discover;
    final controls = <Widget>[
      SegmentedButton<_FanboxGroup>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: _FanboxGroup.feed, label: Text(context.t.fanbox.home)),
          ButtonSegment(value: _FanboxGroup.discover, label: Text(context.t.common.discover)),
          ButtonSegment(value: _FanboxGroup.personal, label: Text(context.t.navigation.me)),
        ],
        selected: {group},
        onSelectionChanged: (selection) => onSelected(selection.single.sections.first),
      ),
      AppSelect<FanboxSection>(
        value: section,
        items: [
          for (final item in {...group.sections, section}) AppSelectItem(value: item, label: fanboxSectionLabel(context, item)),
        ],
        onChanged: onSelected,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: controls[0]),
          ),
          const SizedBox(width: 12),
          SizedBox(width: (constraints.maxWidth * .4).clamp(0, 200), child: controls[1]),
        ],
      ),
    );
  }
}
