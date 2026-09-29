import 'package:freepiv/shared/widgets/app_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_labels.dart';
import 'package:freepiv/i18n/strings.g.dart';

/// Single toolbar row: audience tabs, with the feed filter summary at the end.
class NewestToolbar extends StatelessWidget {
  const NewestToolbar({required this.tabController, required this.onAudienceChanged, required this.filter, super.key});

  final TabController tabController;
  final ValueChanged<NewestAudience> onAudienceChanged;
  final Widget filter;

  static const height = kTextTabBarHeight;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inset = AppMetrics.browseInset(constraints.maxWidth);
          return Padding(
            padding: EdgeInsetsDirectional.only(start: AppMetrics.pageTabInset(constraints.maxWidth), end: inset - 8),
            child: SizedBox(
              height: height,
              child: Row(
                children: [
                  Expanded(
                    child: AppTabBar(
                      controller: tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      labelPadding: EdgeInsets.symmetric(horizontal: AppMetrics.tabLabelPadding(MediaQuery.sizeOf(context).width)),
                      onTap: (index) => onAudienceChanged(newestAudienceForIndex(index)),
                      tabs: [
                        Tab(text: translations.newest.audience.following),
                        Tab(text: translations.newest.audience.mypixiv),
                        Tab(text: translations.newest.audience.everyone),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth * .45),
                    child: filter,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
