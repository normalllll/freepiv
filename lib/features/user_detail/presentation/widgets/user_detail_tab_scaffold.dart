import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_collapsible_header.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

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
  final DataRefreshAction? onRefresh;
  final DataRefreshViewBuilder builder;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = includeTopPadding ? mediaQuery.padding.top : 0.0;
    final pinnedHeaderExtent = topPadding + UserCollapsibleHeaderSliver.collapsedHeightFor(mediaQuery.size.width) + UserDetailTabBarSliver.height;

    return DataNestedRefreshView(
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
                sliver: _UserDetailPinnedHeaderGroup(
                  maxScrollObstructionExtent: pinnedHeaderExtent,
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      UserCollapsibleHeaderSliver(
                        detail: detail,
                        overlapsContent: innerBoxIsScrolled,
                        includeTopPadding: includeTopPadding,
                        showBackButton: showBackButton,
                      ),
                      UserDetailTabBarSliver(tabs: tabs, controller: tabController),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: Padding(
            padding: EdgeInsets.only(top: pinnedHeaderExtent),
            child: refresh.body(
              builder: (context, locators) {
                return builder(context, refresh.physics, locators);
              },
            ),
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
    return SliverMainAxisGroup(slivers: [?refreshSliverHeader]);
  }
}

class _UserDetailPinnedHeaderGroup extends SingleChildRenderObjectWidget {
  const _UserDetailPinnedHeaderGroup({required this.maxScrollObstructionExtent, required Widget sliver}) : super(child: sliver);

  final double maxScrollObstructionExtent;

  @override
  _RenderUserDetailPinnedHeaderGroup createRenderObject(BuildContext context) {
    return _RenderUserDetailPinnedHeaderGroup(maxScrollObstructionExtent);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderUserDetailPinnedHeaderGroup renderObject) {
    renderObject.maxScrollObstructionExtent = maxScrollObstructionExtent;
  }
}

class _RenderUserDetailPinnedHeaderGroup extends RenderProxySliver {
  _RenderUserDetailPinnedHeaderGroup(this._maxScrollObstructionExtent);

  double get maxScrollObstructionExtent => _maxScrollObstructionExtent;
  double _maxScrollObstructionExtent;

  set maxScrollObstructionExtent(double value) {
    if (value == _maxScrollObstructionExtent) {
      return;
    }

    _maxScrollObstructionExtent = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    super.performLayout();
    geometry = geometry?.copyWith(maxScrollObstructionExtent: maxScrollObstructionExtent);
  }
}

class UserDetailTabBarSliver extends StatelessWidget {
  const UserDetailTabBarSliver({required this.tabs, required this.controller, super.key});

  final List<UserDetailTabItem> tabs;
  final TabController controller;

  static const height = 52.0;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _UserTabBarDelegate(tabs: tabs, controller: controller),
    );
  }
}

class _UserTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _UserTabBarDelegate({required this.tabs, required this.controller});

  final List<UserDetailTabItem> tabs;
  final TabController controller;

  @override
  double get minExtent => UserDetailTabBarSliver.height;

  @override
  double get maxExtent => UserDetailTabBarSliver.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: overlapsContent ? 1 : 0,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.42))),
        ),
        child: SizedBox(
          height: UserDetailTabBarSliver.height,
          child: TabBar(
            controller: controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              for (final tab in tabs)
                Tab(
                  height: UserDetailTabBarSliver.height,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(tab.icon, size: 18), const SizedBox(width: 6), Text(tab.label, maxLines: 1)]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_UserTabBarDelegate oldDelegate) {
    return oldDelegate.tabs != tabs || oldDelegate.controller != controller;
  }
}
