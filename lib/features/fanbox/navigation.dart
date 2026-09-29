import 'package:freepiv/shared/widgets/app_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';
import 'package:freepiv/shared/widgets/floating_filter_sliver.dart';
import 'logic.dart';

double fanboxNavigationHeight(BuildContext context) {
  final labelSize = Theme.of(context).textTheme.labelLarge?.fontSize ?? 14;
  final textGrowth = (MediaQuery.textScalerOf(context).scale(labelSize) / labelSize - 1).clamp(0.0, double.infinity);
  return compactFilterHeight(context) + AppMetrics.compactGap * textGrowth;
}

// Kept for existing layout checks; FANBOX now uses one navigation row at every width.
({bool stacked, double height}) fanboxNavigationLayout(BuildContext context, double viewportWidth) => (stacked: false, height: fanboxNavigationHeight(context));

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

class FanboxSectionNavigation extends StatefulWidget {
  const FanboxSectionNavigation({required this.section, required this.onSelected, super.key});
  final FanboxSection section;
  final ValueChanged<FanboxSection> onSelected;

  @override
  State<FanboxSectionNavigation> createState() => _FanboxSectionNavigationState();
}

class _FanboxSectionNavigationState extends State<FanboxSectionNavigation> with SingleTickerProviderStateMixin {
  late final _controller = TabController(length: _FanboxGroup.values.length, initialIndex: _group.index, vsync: this);

  _FanboxGroup get _group => _FanboxGroup.values.where((group) => group.sections.contains(widget.section)).firstOrNull ?? _FanboxGroup.discover;

  @override
  void didUpdateWidget(covariant FanboxSectionNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.index != _group.index) _controller.animateTo(_group.index, duration: Duration.zero);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: AppTabBar(
              controller: _controller,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              labelPadding: EdgeInsets.symmetric(horizontal: AppMetrics.tabLabelPadding(MediaQuery.sizeOf(context).width)),
              tabs: [
                // Group names differ from their sections, so the tab and the
                // collection value beside it never repeat the same label.
                Tab(text: context.t.fanbox.feedGroup),
                Tab(text: context.t.common.discover),
                Tab(text: context.t.navigation.me),
              ],
              onTap: (index) => widget.onSelected(_FanboxGroup.values[index].sections.first),
            ),
          ),
          const SizedBox(width: 8),
          // It keeps its full label at the row's end while the scrollable group
          // tabs take the rest; only at accessibility text sizes does the half
          // row limit make the label wrap instead of pushing the row over.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
            child: AppValueMenuButton<FanboxSection>(
              value: widget.section,
              items: [
                for (final section in {...group.sections, widget.section}) AppSelectItem(value: section, label: fanboxSectionLabel(context, section)),
              ],
              onSelected: widget.onSelected,
            ),
          ),
        ],
      ),
    );
  }
}
