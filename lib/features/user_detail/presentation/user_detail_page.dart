import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_bookmarks_tab.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_skeleton.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_tab_scaffold.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_following_tab.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_illust_grid_tab.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_novel_list_tab.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_profile_info_tab.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/app/router/app_route.dart';

class UserDetailPage extends ConsumerWidget {
  const UserDetailPage({this.userId, this.userDetail, this.initialTab = UserContentTabKind.illust, super.key}) : assert(userId != null || userDetail != null);

  final UserContentTabKind initialTab;
  final int? userId;
  final UserDetailResult? userDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = UserDetailArgs(userId: userId, userDetail: userDetail);
    final detailValue = ref.watch(userDetailProvider(args));
    final visible = detailValue.asData?.value ?? userDetail;
    final id = userId ?? userDetail!.user.id;

    // The window shows the author's name, and the ambient backdrop takes its
    // colours from the banner or avatar that the page already loads.
    return FrostWindowTitleContribution(
      path: AppLocations.user(id),
      page: visible == null
          ? null
          : FrostPageTitle(
              id: id,
              title: visible.user.name,
              kind: 'user',
              imageUrl: visible.profile.backgroundImageUrl ?? visible.user.profileImageUrls.medium,
            ),
      child: _buildPage(detailValue, ref),
    );
  }

  Widget _buildPage(AsyncValue<UserDetailResult> detailValue, WidgetRef ref) {
    final args = UserDetailArgs(userId: userId, userDetail: userDetail);
    return FrostAutoScaffold(
      builder: (BuildContext context, FrostSizeLayout layout, Orientation orientation, bool useHorizontalLayout) {
        return detailValue.when(
          data: (detail) => UserDetailContent(
            key: ValueKey<String>('user-detail-content-${detail.user.id}'),
            detail: detail,
            initialTab: initialTab,
            useHorizontalLayout: useHorizontalLayout,
          ),
          loading: () {
            final initialDetail = userDetail;
            if (initialDetail != null) {
              return UserDetailContent(
                key: ValueKey<String>('user-detail-content-${initialDetail.user.id}'),
                detail: initialDetail,
                initialTab: initialTab,
                useHorizontalLayout: useHorizontalLayout,
              );
            }

            return UserDetailLoadingSkeleton(useHorizontalLayout: useHorizontalLayout);
          },
          error: (error, stackTrace) {
            return AppPageError.fromError(error: error, onRetry: () => ref.read(userDetailProvider(args).notifier).reload());
          },
        );
      },
    );
  }
}

class UserDetailContent extends StatefulWidget {
  const UserDetailContent({required this.detail, required this.useHorizontalLayout, this.initialTab = UserContentTabKind.illust, super.key});

  final UserContentTabKind initialTab;
  final UserDetailResult detail;
  final bool useHorizontalLayout;

  @override
  State<UserDetailContent> createState() => _UserDetailContentState();
}

class _UserDetailContentState extends State<UserDetailContent> with SingleTickerProviderStateMixin {
  List<UserDetailTabItem> get _tabs => _tabsFor(widget.detail, t);
  late final TabController _tabController;
  late final Map<Object, GlobalKey> _tabKeys;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _tabKeys = {for (final tab in _tabs) tab.kind: GlobalKey(debugLabel: 'user-detail-tab-${tab.kind}')};

    final initialIndex = _tabs.indexWhere((tab) => tab.kind == widget.initialTab);
    _currentIndex = initialIndex < 0 ? 0 : initialIndex;
    _tabController = TabController(initialIndex: _currentIndex, length: _tabs.length, vsync: this, animationDuration: const Duration(milliseconds: 200));
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void didUpdateWidget(covariant UserDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab == widget.initialTab) return;
    final index = _tabs.indexWhere((tab) => tab.kind == widget.initialTab);
    if (index >= 0) _tabController.animateTo(index, duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200));
  }

  void _handleTabChanged() {
    final nextIndex = _tabController.index;
    if (nextIndex == _currentIndex || nextIndex < 0 || nextIndex >= _tabs.length) {
      return;
    }

    setState(() {
      _currentIndex = nextIndex;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FrostContentViewport(
        child: UserDetailTabScaffold(
          detail: widget.detail,
          tabs: _tabs,
          tabController: _tabController,
          storageKey: 'content',
          includeTopPadding: true,
          showBackButton: !widget.useHorizontalLayout && !(FrostShellNavigationScope.maybeOf(context)?.ownsBackControl ?? false),
          onRefresh: _tabs[_currentIndex].kind == UserContentTabKind.profile ? null : _refreshCurrentTab,
          builder: (context, physics, locators) {
            // Swipeable like the other tabbed pages; a tab stays alive once
            // opened, keeping its list, scroll position and requests.
            //
            // Only the selected tab's list joins the nested scroll. The
            // coordinator drives every attached inner list together, so a kept
            // tab resting at its top would expand the header over the selected
            // list while that list is still mid-way.
            final nestedController = PrimaryScrollController.maybeOf(context);
            return TabBarView(
              controller: _tabController,
              children: [
                for (final (index, tab) in _tabs.indexed)
                  _KeptAlive(
                    key: PageStorageKey<String>('user-detail-active-tab-${widget.detail.user.id}-${tab.kind}'),
                    child: index == _currentIndex && nestedController != null
                        ? PrimaryScrollController(
                            controller: nestedController,
                            automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
                            child: _tabBodyFor(widget.detail, tab.kind, physics, UserDetailNestedSliverHeader(refreshSliverHeader: locators.sliverHeader)),
                          )
                        : PrimaryScrollController.none(
                            child: _tabBodyFor(widget.detail, tab.kind, physics, UserDetailNestedSliverHeader(refreshSliverHeader: locators.sliverHeader)),
                          ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tabBodyFor(UserDetailResult detail, Object kind, ScrollPhysics? physics, Widget? sliverHeader) {
    final key = _tabKeys[kind];

    return switch (kind) {
      UserContentTabKind.illust => UserIllustGridTabBody(key: key, detail: detail, illustType: IllustType.illust, physics: physics, sliverHeader: sliverHeader),
      UserContentTabKind.manga => UserIllustGridTabBody(key: key, detail: detail, illustType: IllustType.manga, physics: physics, sliverHeader: sliverHeader),
      UserContentTabKind.novel => UserNovelListTabBody(key: key, detail: detail, physics: physics, sliverHeader: sliverHeader),
      UserContentTabKind.bookmarks => UserBookmarksTabBody(key: key, detail: detail, physics: physics, sliverHeader: sliverHeader),
      UserContentTabKind.following => UserFollowingTabBody(key: key, detail: detail, physics: physics, sliverHeader: sliverHeader),
      UserContentTabKind.profile => UserProfileInfoBody(key: key, detail: detail, physics: physics, sliverHeader: sliverHeader),
      _ => const Placeholder(),
    };
  }

  Future<bool> _refreshCurrentTab() {
    return _currentTabRefreshController()?.refreshTab() ?? Future.value(true);
  }

  UserDetailTabRefreshController? _currentTabRefreshController() {
    final index = _tabController.index;
    if (index < 0 || index >= _tabs.length) {
      return null;
    }

    return _tabKeys[_tabs[index].kind]?.currentState as UserDetailTabRefreshController?;
  }
}

List<UserDetailTabItem> _tabsFor(UserDetailResult detail, Translations translations) {
  return [
    UserDetailTabItem(kind: UserContentTabKind.illust, icon: Icons.image_outlined, label: translations.user.tabs.illustrations),
    UserDetailTabItem(kind: UserContentTabKind.manga, icon: Icons.auto_stories_outlined, label: translations.user.tabs.manga),
    UserDetailTabItem(kind: UserContentTabKind.novel, icon: Icons.menu_book_outlined, label: translations.user.tabs.novels),
    UserDetailTabItem(kind: UserContentTabKind.bookmarks, icon: Icons.bookmarks_outlined, label: translations.user.tabs.bookmarks),
    UserDetailTabItem(kind: UserContentTabKind.following, icon: Icons.people_outline, label: translations.user.tabs.following),
    UserDetailTabItem(kind: UserContentTabKind.profile, icon: Icons.info_outline, label: translations.user.tabs.profile),
  ];
}

class _KeptAlive extends StatefulWidget {
  const _KeptAlive({required this.child, super.key});

  final Widget child;

  @override
  State<_KeptAlive> createState() => _KeptAliveState();
}

class _KeptAliveState extends State<_KeptAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
