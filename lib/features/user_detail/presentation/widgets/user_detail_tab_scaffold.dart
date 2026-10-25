import 'package:flutter/material.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_collapsible_header.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

class UserDetailTabItem {
  const UserDetailTabItem({required this.kind, required this.label, required this.icon});

  final Object kind;
  final String label;
  final IconData icon;
}

abstract interface class UserDetailTabRefreshController {
  Future<bool> refreshTab();
}

class UserDetailTabScaffold extends StatelessWidget {
  const UserDetailTabScaffold({
    required this.detail,
    required this.tabs,
    required this.tabController,
    required this.builder,
    required this.storageKey,
    required this.includeTopPadding,
    required this.showBackButton,
    this.onRefresh,
    super.key,
  });

  final UserDetailResult detail;
  final List<UserDetailTabItem> tabs;
  final TabController tabController;
  final String storageKey;
  final bool includeTopPadding;
  final bool showBackButton;
  final FrostRefreshAction? onRefresh;
  final FrostRefreshViewBuilder builder;

  @override
  Widget build(BuildContext context) {
    return FrostNestedRefreshView(
      onRefresh: onRefresh,
      builder: (context, refresh) {
        return NestedScrollView(
          key: PageStorageKey<String>('user-detail-${detail.user.id}-$storageKey-nested-scroll'),
          controller: refresh.scrollController,
          floatHeaderSlivers: false,
          physics: refresh.physics,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                // The coordinator exhausts outer collapse before inner lists
                // scroll, so the header's own collapse progress also covers
                // inner scrolling and refresh-to-top.
                sliver: UserCollapsibleHeaderSliver(
                  detail: detail,
                  includeTopPadding: includeTopPadding,
                  showBackButton: showBackButton,
                  bottom: UserDetailTabBar(tabs: tabs, controller: tabController),
                  bottomHeight: UserDetailTabBar.height,
                ),
              ),
            ];
          },
          // Tab bodies inject the header overlap themselves (see
          // UserDetailNestedSliverHeader), so works scroll beneath the glass
          // header instead of being clipped at its edge.
          body: refresh.body(
            builder: (context, locators) {
              return builder(context, refresh.physics, locators);
            },
          ),
        );
      },
    );
  }
}

class UserDetailNestedSliverHeader extends StatelessWidget {
  const UserDetailNestedSliverHeader({required this.refreshSliverHeader, super.key});

  final Widget? refreshSliverHeader;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
        ?refreshSliverHeader,
      ],
    );
  }
}

/// The tab row pinned under the user header, drawn on the header's glass.
class UserDetailTabBar extends StatelessWidget {
  const UserDetailTabBar({required this.tabs, required this.controller, super.key});

  final List<UserDetailTabItem> tabs;
  final TabController controller;

  static const height = 52.0;

  @override
  Widget build(BuildContext context) {
    // A floating glass panel is inset and rounded; keep tab highlights on it.
    final insets = FrostPinnedChromeGlass.insetsOf(context);
    final floats = insets != EdgeInsetsDirectional.zero;
    return Padding(
      padding: insets,
      child: ClipRRect(
        borderRadius: floats ? const BorderRadius.vertical(bottom: Radius.circular(FrostMetrics.groupRadius + 4)) : BorderRadius.zero,
        clipBehavior: floats ? Clip.antiAlias : Clip.none,
        child: Material(
          type: MaterialType.transparency,
          child: LayoutBuilder(
            builder: (context, constraints) => Padding(
              padding: EdgeInsets.symmetric(horizontal: FrostMetrics.pageTabInset(constraints.maxWidth)),
              child: MouseDragScroll(
                child: FrostTabBar(
                  controller: controller,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.symmetric(horizontal: FrostMetrics.tabLabelPadding(MediaQuery.sizeOf(context).width)),
                  tabs: [
                    for (final tab in tabs)
                      Tab(
                        height: height,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Icon(tab.icon, size: 18), const SizedBox(width: 6), Text(tab.label, maxLines: 1)],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
