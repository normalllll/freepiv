import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart' show ArticleSummary;
import 'package:freepiv/features/pixivision/navigation.dart';
import 'package:freepiv/features/pixivision/page.dart';
import 'package:freepiv/features/pixivision/detail.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/features/fanbox/page.dart';
import 'package:freepiv/features/fanbox/detail.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
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
                routes: [
                  GoRoute(
                    path: AppRoute.pixivision.path,
                    name: AppRoute.pixivision.name,
                    builder: (context, state) => PixivisionPage(url: state.uri.queryParameters['url']),
                  ),
                ],
              ),
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
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoute.fanbox.path,
                    name: AppRoute.fanbox.name,
                    builder: (context, state) => FanboxPage(
                      location: (
                        section: FanboxSection.values.where((e) => e.name == state.uri.queryParameters['section']).firstOrNull ?? FanboxSection.home,
                        creatorId: state.uri.queryParameters['creator'] ?? '',
                        query: state.uri.queryParameters['q'] ?? '',
                      ),
                    ),
                  ),
                ],
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
          GoRoute(
            path: '/pixivision/browse',
            builder: (context, state) => PixivisionPage(url: state.uri.queryParameters['url']),
          ),
          GoRoute(
            path: '/pixivision/article',
            builder: (context, state) => PixivisionArticlePage(
              url: validPixivisionUrl(state.uri.queryParameters['url']) ?? 'https://www.pixivision.net/en/',
              summary: state.extra is ArticleSummary ? state.extra as ArticleSummary : null,
            ),
          ),
          GoRoute(
            path: '/fanbox/browse',
            builder: (context, state) => FanboxPage(
              location: (
                section: FanboxSection.values.where((item) => item.name == state.uri.queryParameters['section']).firstOrNull ?? FanboxSection.home,
                creatorId: '',
                query: state.uri.queryParameters['q'] ?? '',
              ),
            ),
          ),
          fanboxTagRoute(),
          GoRoute(
            path: '/fanbox/post/:postId',
            builder: (context, state) =>
                FanboxPostDetailPage(postId: state.pathParameters['postId']!, summary: state.extra is FanboxPost ? state.extra as FanboxPost : null),
          ),
          GoRoute(
            path: '/fanbox/creator/:creatorId',
            builder: (context, state) => FanboxCreatorDetailPage(
              creatorId: state.pathParameters['creatorId']!,
              showPlans: state.uri.queryParameters['plans'] == 'true',
              summary: state.extra is FanboxCreator ? state.extra as FanboxCreator : null,
            ),
          ),
        ],
      ),
    ],
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    if (state.uri.path == AppRoute.settings.path || state.uri.path == AppRoute.downloads.path) return null;
    if (state.uri.path == '/pixivision' || state.uri.path.startsWith('/pixivision/')) return null;
    if (state.uri.path == '/fanbox' || state.uri.path.startsWith('/fanbox/')) return null;
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
