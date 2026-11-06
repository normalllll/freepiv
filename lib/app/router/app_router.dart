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
import 'package:freepiv/app/router/single_top_go_router.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  const AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final rightNavigatorKey = GlobalKey<NavigatorState>();
  static final rightNavigatorCanPop = ValueNotifier<bool>(false);
  static String? _pendingProtectedTarget;

  static final router = SingleTopGoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.home.path,
    refreshListenable: pixivAccountNotifier,
    config: RoutingConfig(
      redirect: _redirect,
      routes: [
        GoRoute(path: AppRoute.login.path, name: AppRoute.login.name, pageBuilder: route_pages.loginPage),
        ShellRoute(
          navigatorKey: rightNavigatorKey,
          builder: (context, state, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _refreshRightNavigatorCanPop());
            return RouterShell(
              canPopListenable: rightNavigatorCanPop,
              onBack: _popRightNavigator,
              onResetRightNavigator: _popRightNavigatorToRoot,
              child: child,
            );
          },
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) {
                return navigationShell;
              },
              // Only primary navigation destinations retain independent stacks.
              // Secondary pages are pushed above them so all back controls agree.
              branches: [
                StatefulShellBranch(
                  routes: [GoRoute(path: AppRoute.home.path, name: AppRoute.home.name, pageBuilder: route_pages.homePage)],
                ),
                StatefulShellBranch(
                  routes: [GoRoute(path: AppRoute.newest.path, name: AppRoute.newest.name, pageBuilder: route_pages.newestPage)],
                ),
                StatefulShellBranch(
                  routes: [GoRoute(path: AppRoute.me.path, name: AppRoute.me.name, pageBuilder: route_pages.mePage)],
                ),
              ],
            ),
            GoRoute(path: AppRoute.discover.path, name: AppRoute.discover.name, pageBuilder: route_pages.discoverPage),
            GoRoute(path: AppRoute.downloads.path, name: AppRoute.downloads.name, pageBuilder: route_pages.downloadsPage),
            GoRoute(
              path: AppRoute.pixivision.path,
              name: AppRoute.pixivision.name,
              builder: (context, state) => PixivisionPage(url: state.uri.queryParameters[AppRouteQuery.url]),
            ),
            GoRoute(
              path: AppRoute.fanbox.path,
              name: AppRoute.fanbox.name,
              builder: (context, state) => FanboxPage(
                location: (
                  section: FanboxSection.values.where((e) => e.name == state.uri.queryParameters[AppRouteQuery.section]).firstOrNull ?? FanboxSection.home,
                  creatorId: state.uri.queryParameters[AppRouteQuery.creator] ?? '',
                  query: state.uri.queryParameters[AppRouteQuery.query] ?? '',
                ),
              ),
            ),
            GoRoute(path: AppRoute.searchIllustResult.path, name: AppRoute.searchIllustResult.name, pageBuilder: route_pages.searchIllustResultPage),
            GoRoute(path: AppRoute.searchNovelResult.path, name: AppRoute.searchNovelResult.name, pageBuilder: route_pages.searchNovelResultPage),
            GoRoute(path: AppRoute.searchUserResult.path, name: AppRoute.searchUserResult.name, pageBuilder: route_pages.searchUserResultPage),
            GoRoute(path: AppRoute.tagSearch.path, name: AppRoute.tagSearch.name, pageBuilder: route_pages.tagSearchPage),
            GoRoute(path: AppRoute.ranking.path, name: AppRoute.ranking.name, pageBuilder: route_pages.rankingPage),
            // The three ranking pages became one; their old paths still open it.
            for (final legacy in [AppRoute.legacyRankingIllust, AppRoute.legacyRankingManga, AppRoute.legacyRankingNovel])
              GoRoute(path: legacy.path, name: legacy.name, redirect: route_pages.legacyRankingRedirect),
            GoRoute(path: AppRoute.meFollowing.path, name: AppRoute.meFollowing.name, pageBuilder: route_pages.meFollowingPage),
            GoRoute(path: AppRoute.meFollowers.path, name: AppRoute.meFollowers.name, pageBuilder: route_pages.meFollowersPage),
            GoRoute(path: AppRoute.about.path, name: AppRoute.about.name, pageBuilder: route_pages.aboutPage),
            GoRoute(path: AppRoute.settings.path, name: AppRoute.settings.name, pageBuilder: route_pages.settingsPage),
            GoRoute(path: AppRoute.originalImageViewer.path, name: AppRoute.originalImageViewer.name, pageBuilder: route_pages.originalImageViewerPage),
            GoRoute(path: AppRoute.illustDetail.path, name: AppRoute.illustDetail.name, pageBuilder: route_pages.illustDetailPage),
            GoRoute(path: AppRoute.illustRelated.path, name: AppRoute.illustRelated.name, pageBuilder: route_pages.illustRelatedPage),
            GoRoute(path: AppRoute.illustComments.path, name: AppRoute.illustComments.name, pageBuilder: route_pages.illustCommentsPage),
            GoRoute(path: AppRoute.novelDetail.path, name: AppRoute.novelDetail.name, pageBuilder: route_pages.novelDetailPage),
            GoRoute(path: AppRoute.novelReader.path, name: AppRoute.novelReader.name, pageBuilder: route_pages.novelReaderPage),
            GoRoute(path: AppRoute.novelComments.path, name: AppRoute.novelComments.name, pageBuilder: route_pages.novelCommentsPage),
            GoRoute(path: AppRoute.userDetail.path, name: AppRoute.userDetail.name, pageBuilder: route_pages.userDetailPage),
            GoRoute(
              path: AppRoute.pixivisionBrowse.path,
              name: AppRoute.pixivisionBrowse.name,
              builder: (context, state) => PixivisionPage(url: state.uri.queryParameters[AppRouteQuery.url]),
            ),
            GoRoute(
              path: AppRoute.pixivisionArticle.path,
              name: AppRoute.pixivisionArticle.name,
              builder: (context, state) => PixivisionArticlePage(
                url: validPixivisionUrl(state.uri.queryParameters[AppRouteQuery.url]) ?? 'https://www.pixivision.net/en/',
                summary: state.extra is ArticleSummary ? state.extra as ArticleSummary : null,
              ),
            ),
            GoRoute(
              path: AppRoute.fanboxBrowse.path,
              name: AppRoute.fanboxBrowse.name,
              builder: (context, state) => FanboxPage(
                location: (
                  section:
                      FanboxSection.values.where((item) => item.name == state.uri.queryParameters[AppRouteQuery.section]).firstOrNull ?? FanboxSection.home,
                  creatorId: '',
                  query: state.uri.queryParameters[AppRouteQuery.query] ?? '',
                ),
              ),
            ),
            fanboxTagRoute(),
            GoRoute(
              path: AppRoute.fanboxPost.path,
              name: AppRoute.fanboxPost.name,
              builder: (context, state) => FanboxPostDetailPage(
                postId: state.pathParameters[AppRouteParam.postId]!,
                summary: state.extra is FanboxPost ? state.extra as FanboxPost : null,
              ),
            ),
            GoRoute(
              path: AppRoute.fanboxCreator.path,
              name: AppRoute.fanboxCreator.name,
              builder: (context, state) => FanboxCreatorDetailPage(
                creatorId: state.pathParameters[AppRouteParam.creatorId]!,
                showPlans: state.uri.queryParameters[AppRouteQuery.plans] == 'true',
                summary: state.extra is FanboxCreator ? state.extra as FanboxCreator : null,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final loggedIn = pixivAccountNotifier.value != null;
    final goingLogin = state.matchedLocation == AppRoute.login.path;

    if (!loggedIn) {
      if (goingLogin) return null;
      _pendingProtectedTarget = state.uri.toString();
      return AppRoute.login.path;
    }

    if (goingLogin) {
      final target = _pendingProtectedTarget;
      _pendingProtectedTarget = null;
      return target != null && target.startsWith('/') && !target.startsWith('//') && target != AppRoute.login.path ? target : AppRoute.home.path;
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

  /// How many pages the right navigator holds above the destination's root.
  static int get rightNavigatorDepth {
    for (final match in router.routerDelegate.currentConfiguration.matches) {
      if (match is ShellRouteMatch && match.navigatorKey == rightNavigatorKey) {
        return match.matches.length - 1;
      }
    }
    return 0;
  }

  static void _refreshRightNavigatorCanPop() {
    final canPop = rightNavigatorDepth > 0;
    if (rightNavigatorCanPop.value != canPop) {
      rightNavigatorCanPop.value = canPop;
    }
  }
}
