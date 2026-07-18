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
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/shared/widgets/lazy_indexed_stack.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

class UserDetailPage extends ConsumerWidget {
  const UserDetailPage({this.userId, this.userDetail, super.key}) : assert(userId != null || userDetail != null);

  final int? userId;
  final UserDetailResult? userDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = UserDetailArgs(userId: userId, userDetail: userDetail);
    final detailValue = ref.watch(userDetailProvider(args));

    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        return detailValue.when(
          data: (detail) =>
              UserDetailContent(key: ValueKey<String>('user-detail-content-${detail.user.id}'), detail: detail, shouldUseDesktopShell: shouldUseDesktopShell),
          loading: () {
            final initialDetail = userDetail;
            if (initialDetail != null) {
              return UserDetailContent(
                key: ValueKey<String>('user-detail-content-${initialDetail.user.id}'),
                detail: initialDetail,
                shouldUseDesktopShell: shouldUseDesktopShell,
              );
            }

            return UserDetailLoadingSkeleton(shouldUseDesktopShell: shouldUseDesktopShell);
          },
          error: (error, stackTrace) {
            return ErrorPage.fromError(error: error, onRetry: () => ref.read(userDetailProvider(args).notifier).reload());
          },
        );
      },
    );
  }
}

class UserDetailContent extends StatefulWidget {
  const UserDetailContent({required this.detail, required this.shouldUseDesktopShell, super.key});

  final UserDetailResult detail;
  final bool shouldUseDesktopShell;

  @override
  State<UserDetailContent> createState() => _UserDetailContentState();
}

class _UserDetailContentState extends State<UserDetailContent> with SingleTickerProviderStateMixin {
  late final List<UserDetailTabItem> _tabs;
  late final TabController _tabController;
  late final Map<Object, GlobalKey> _tabKeys;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _tabs = _tabsFor(widget.detail, t);
    _tabKeys = {for (final tab in _tabs) tab.kind: GlobalKey(debugLabel: 'user-detail-tab-${tab.kind}')};

    _tabController = TabController(length: _tabs.length, vsync: this, animationDuration: Duration.zero);
    _tabController.addListener(_handleTabChanged);
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
      body: UserDetailTabScaffold(
        detail: widget.detail,
        tabs: _tabs,
        tabController: _tabController,
        storageKey: 'content',
        includeTopPadding: true,
        showBackButton: !widget.shouldUseDesktopShell,
        onRefresh: _refreshCurrentTab,
        builder: (context, physics, locators) {
          return LazyIndexedStack(
            index: _currentIndex,
            sizing: StackFit.expand,
            children: [
              for (final tab in _tabs)
                KeyedSubtree(
                  key: PageStorageKey<String>('user-detail-active-tab-${widget.detail.user.id}-${tab.kind}'),
                  child: _tabBodyFor(widget.detail, tab.kind, physics, UserDetailNestedSliverHeader(refreshSliverHeader: locators.sliverHeader)),
                ),
            ],
          );
        },
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
  final profile = detail.profile;

  return [
    if (profile.totalIllusts > 0) UserDetailTabItem(kind: UserContentTabKind.illust, icon: Icons.image_outlined, label: translations.user.tabs.illustrations),
    if (profile.totalManga > 0) UserDetailTabItem(kind: UserContentTabKind.manga, icon: Icons.auto_stories_outlined, label: translations.user.tabs.manga),
    if (profile.totalNovels > 0) UserDetailTabItem(kind: UserContentTabKind.novel, icon: Icons.menu_book_outlined, label: translations.user.tabs.novels),
    if (profile.totalIllustBookmarksPublic > 0)
      UserDetailTabItem(kind: UserContentTabKind.bookmarks, icon: Icons.bookmarks_outlined, label: translations.user.tabs.bookmarks),
    UserDetailTabItem(kind: UserContentTabKind.following, icon: Icons.people_outline, label: translations.user.tabs.following),
    UserDetailTabItem(kind: UserContentTabKind.profile, icon: Icons.info_outline, label: translations.user.tabs.profile),
  ];
}
