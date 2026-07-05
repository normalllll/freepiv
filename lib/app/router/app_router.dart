import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_route_pages.dart' as route_pages;
import 'package:freepiv/app/router/navigator_stack_observer.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  const AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final rightNavigatorKey = GlobalKey<NavigatorState>();
  static final rightNavigatorCanPop = ValueNotifier<bool>(false);
  static final _rightNavigatorObserver = NavigatorStackObserver(_refreshRightNavigatorCanPop);

  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.home.path,
    refreshListenable: pixivAccountNotifier,
    redirect: _redirect,
    routes: [
      GoRoute(path: AppRoute.login.path, name: AppRoute.login.name, pageBuilder: route_pages.loginPage),
      ShellRoute(
        navigatorKey: rightNavigatorKey,
        observers: [_rightNavigatorObserver],
        builder: (context, state, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _refreshRightNavigatorCanPop());
          return RouterShell(canPopListenable: rightNavigatorCanPop, onBack: _popRightNavigator, onResetRightNavigator: _popRightNavigatorToRoot, child: child);
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return navigationShell;
            },
            branches: [
              StatefulShellBranch(
                routes: [GoRoute(path: AppRoute.home.path, name: AppRoute.home.name, pageBuilder: route_pages.homePage)],
              ),
              StatefulShellBranch(
                routes: [GoRoute(path: AppRoute.newest.path, name: AppRoute.newest.name, pageBuilder: route_pages.newestPage)],
              ),
              StatefulShellBranch(
                routes: [GoRoute(path: AppRoute.search.path, name: AppRoute.search.name, pageBuilder: route_pages.searchPage)],
              ),
              StatefulShellBranch(
                routes: [GoRoute(path: AppRoute.downloads.path, name: AppRoute.downloads.name, pageBuilder: route_pages.downloadsPage)],
              ),
              StatefulShellBranch(
                routes: [GoRoute(path: AppRoute.me.path, name: AppRoute.me.name, pageBuilder: route_pages.mePage)],
              ),
            ],
          ),
          GoRoute(path: AppRoute.searchIllustResult.path, name: AppRoute.searchIllustResult.name, pageBuilder: route_pages.searchIllustResultPage),
          GoRoute(path: AppRoute.searchNovelResult.path, name: AppRoute.searchNovelResult.name, pageBuilder: route_pages.searchNovelResultPage),
          GoRoute(path: AppRoute.searchUserResult.path, name: AppRoute.searchUserResult.name, pageBuilder: route_pages.searchUserResultPage),
          GoRoute(path: AppRoute.rankingIllust.path, name: AppRoute.rankingIllust.name, pageBuilder: route_pages.rankingIllustPage),
          GoRoute(path: AppRoute.rankingManga.path, name: AppRoute.rankingManga.name, pageBuilder: route_pages.rankingMangaPage),
          GoRoute(path: AppRoute.rankingNovel.path, name: AppRoute.rankingNovel.name, pageBuilder: route_pages.rankingNovelPage),
          GoRoute(path: AppRoute.meFollowing.path, name: AppRoute.meFollowing.name, pageBuilder: route_pages.meFollowingPage),
          GoRoute(path: AppRoute.meFollowers.path, name: AppRoute.meFollowers.name, pageBuilder: route_pages.meFollowersPage),
          GoRoute(path: AppRoute.about.path, name: AppRoute.about.name, pageBuilder: route_pages.aboutPage),
          GoRoute(path: AppRoute.settings.path, name: AppRoute.settings.name, pageBuilder: route_pages.settingsPage),
          GoRoute(path: AppRoute.originalImageViewer.path, name: AppRoute.originalImageViewer.name, pageBuilder: route_pages.originalImageViewerPage),
          GoRoute(path: AppRoute.illustDetail.path, name: AppRoute.illustDetail.name, pageBuilder: route_pages.illustDetailPage),
          GoRoute(path: AppRoute.illustComments.path, name: AppRoute.illustComments.name, pageBuilder: route_pages.illustCommentsPage),
          GoRoute(path: AppRoute.novelDetail.path, name: AppRoute.novelDetail.name, pageBuilder: route_pages.novelDetailPage),
          GoRoute(path: AppRoute.novelReader.path, name: AppRoute.novelReader.name, pageBuilder: route_pages.novelReaderPage),
          GoRoute(path: AppRoute.novelComments.path, name: AppRoute.novelComments.name, pageBuilder: route_pages.novelCommentsPage),
          GoRoute(path: AppRoute.userDetail.path, name: AppRoute.userDetail.name, pageBuilder: route_pages.userDetailPage),
        ],
      ),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final loggedIn = pixivAccountNotifier.value != null;
    final goingLogin = state.matchedLocation == AppRoute.login.path;

    if (!loggedIn) {
      return goingLogin ? null : AppRoute.login.path;
    }

    if (goingLogin) {
      return AppRoute.home.path;
    }

    return null;
  }

  static void _popRightNavigator() {
    rightNavigatorKey.currentState?.maybePop();
  }

  static void _popRightNavigatorToRoot() {
    rightNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    _refreshRightNavigatorCanPop();
  }

  static void _refreshRightNavigatorCanPop() {
    final canPop = _rightNavigatorObserver.canPopPageRoute;
    if (rightNavigatorCanPop.value != canPop) {
      rightNavigatorCanPop.value = canPop;
    }
  }
}
