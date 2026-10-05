import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    final mediaQuery = MediaQuery.of(context);
    final topPadding = includeTopPadding ? mediaQuery.padding.top : 0.0;
    final pinnedHeaderExtent = topPadding + UserCollapsibleHeaderSliver.collapsedHeightFor(mediaQuery.size.width, context) + UserDetailTabBarSliver.height;

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
                sliver: _UserDetailPinnedHeaderGroup(
                  maxScrollObstructionExtent: pinnedHeaderExtent,
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      // A fixed-height pinned delegate cannot express how far
                      // the outer header has collapsed. Use the group's actual
                      // outer offset, with the same snapped extents as the top.
                      double snap(double value) => (value * mediaQuery.devicePixelRatio).roundToDouble() / mediaQuery.devicePixelRatio;
                      final collapseExtent =
                          snap(UserCollapsibleHeaderSliver.expandedHeightFor(context, mediaQuery.size.width, detail)) -
                          snap(UserCollapsibleHeaderSliver.collapsedHeightFor(mediaQuery.size.width, context));
                      final coverage = (constraints.scrollOffset / collapseExtent).clamp(0.0, 1.0);
                      return SliverMainAxisGroup(
                        slivers: [
                          UserCollapsibleHeaderSliver(
                            detail: detail,
                            // The coordinator exhausts outer collapse before inner
                            // lists scroll. The measured outer progress therefore
                            // also covers inner scrolling and refresh-to-top, with
                            // no delayed boolean override at the joined edge.
                            overlapsContent: false,
                            includeTopPadding: includeTopPadding,
                            showBackButton: showBackButton,
                          ),
                          UserDetailTabBarSliver(tabs: tabs, controller: tabController, glassCoverage: coverage),
                        ],
                      );
                    },
                  ),
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
  const UserDetailTabBarSliver({required this.tabs, required this.controller, required this.glassCoverage, super.key});

  final List<UserDetailTabItem> tabs;
  final TabController controller;
  final double glassCoverage;

  static const height = 52.0;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _UserTabBarDelegate(tabs: tabs, controller: controller, glassCoverage: glassCoverage),
    );
  }
}

class _UserTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _UserTabBarDelegate({required this.tabs, required this.controller, required this.glassCoverage});

  final List<UserDetailTabItem> tabs;
  final TabController controller;
  final double glassCoverage;

  @override
  double get minExtent => UserDetailTabBarSliver.height;

  @override
  double get maxExtent => UserDetailTabBarSliver.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Continues the collapsed header's glass once works pass beneath.
    return SizedBox.expand(
      child: FrostPinnedChromeGlass(
        opacity: glassCoverage,
        animate: false,
        corners: FrostPinnedChromeCorners.bottom,
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
                        height: UserDetailTabBarSliver.height,
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

  @override
  bool shouldRebuild(_UserTabBarDelegate oldDelegate) {
    return oldDelegate.tabs != tabs || oldDelegate.controller != controller || oldDelegate.glassCoverage != glassCoverage;
  }
}
