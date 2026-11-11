import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart' show ArticleSummary;
import 'package:freepiv/features/pixivision/navigation.dart';
import 'package:freepiv/features/pixivision/page.dart';
import 'package:freepiv/features/pixivision/article_page.dart';
import 'package:flutter/widgets.dart';
import 'package:freepiv/features/fanbox/browse_page.dart';
import 'package:freepiv/features/fanbox/creator_page.dart';
import 'package:freepiv/features/fanbox/post_page.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/fanbox/login_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/route_activity.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/app/router/app_route_pages.dart' as route_pages;
import 'package:freepiv/app/router/single_top_go_router.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  const AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final rightNavigatorKey = GlobalKey<NavigatorState>();
  static String? _pendingProtectedTarget;

  static final SingleTopGoRouter router = SingleTopGoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.home.path,
    refreshListenable: pixivAccountNotifier,
    observers: [appRootRouteActivity],
    config: RoutingConfig(
      redirect: _redirect,
      routes: [
        ShellRoute(
          navigatorKey: rightNavigatorKey,
          builder: (context, state, child) {
            final location = currentUri;
            return RouterShell(
              location: location,
              selectedIndex: destinationIndexFor(location.path),
              routeDepth: rightNavigatorDepth,
              atSecondaryRoot: atSwitchedSecondary,
              onBack: popRightNavigator,
              onBackToFirst: popRightNavigatorToRoot,
              onDestinationSelected: (index) => router.go(appRouteDestinations[index].route.path),
              onSecondarySelected: switchToSecondary,
              child: child,
            );
          },
          routes: [
            StatefulShellRoute.indexedStack(
              // The destinations' root pages are retained page infrastructure:
              // the shell keeps them below every pushed page.
              pageBuilder: (context, state, navigationShell) => NoTransitionPage<void>(
                key: state.pageKey,
                child: FrostShellDestination(child: navigationShell),
              ),
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
            // Inside the shell, so the download entry stays reachable while signed out.
            GoRoute(path: AppRoute.login.path, name: AppRoute.login.name, pageBuilder: route_pages.loginPage),
            GoRoute(path: AppRoute.downloads.path, name: AppRoute.downloads.name, pageBuilder: route_pages.downloadsPage),
            GoRoute(
              path: AppRoute.pixivision.path,
              name: AppRoute.pixivision.name,
              pageBuilder: (context, state) => FrostDetailPage(
                key: state.pageKey,
                child: PixivisionPage(url: state.uri.queryParameters[AppRouteQuery.url]),
              ),
            ),
            GoRoute(
              path: AppRoute.fanbox.path,
              name: AppRoute.fanbox.name,
              pageBuilder: (context, state) => FrostDetailPage.secondaryDestination(
                key: state.pageKey,
                child: FanboxBrowsePage(
                  location: (
                    section: FanboxSection.values.where((e) => e.name == state.uri.queryParameters[AppRouteQuery.section]).firstOrNull ?? FanboxSection.home,
                    creatorId: state.uri.queryParameters[AppRouteQuery.creator] ?? '',
                    query: state.uri.queryParameters[AppRouteQuery.query] ?? '',
                  ),
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
            GoRoute(path: AppRoute.meMypixiv.path, name: AppRoute.meMypixiv.name, pageBuilder: route_pages.meMypixivPage),
            GoRoute(path: AppRoute.meWatchlist.path, name: AppRoute.meWatchlist.name, pageBuilder: route_pages.meWatchlistPage),
            GoRoute(path: AppRoute.meProfileEdit.path, name: AppRoute.meProfileEdit.name, pageBuilder: route_pages.meProfileEditPage),
            GoRoute(path: AppRoute.meWorkspaceEdit.path, name: AppRoute.meWorkspaceEdit.name, pageBuilder: route_pages.meWorkspaceEditPage),
            GoRoute(path: AppRoute.mangaSeries.path, name: AppRoute.mangaSeries.name, pageBuilder: route_pages.mangaSeriesPage),
            GoRoute(path: AppRoute.novelSeries.path, name: AppRoute.novelSeries.name, pageBuilder: route_pages.novelSeriesPage),
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
              pageBuilder: (context, state) => FrostDetailPage(
                key: state.pageKey,
                child: PixivisionPage(url: state.uri.queryParameters[AppRouteQuery.url]),
              ),
            ),
            GoRoute(
              path: AppRoute.pixivisionArticle.path,
              name: AppRoute.pixivisionArticle.name,
              pageBuilder: (context, state) => FrostDetailPage(
                key: state.pageKey,
                child: PixivisionArticlePage(
                  url: validPixivisionUrl(state.uri.queryParameters[AppRouteQuery.url]) ?? 'https://www.pixivision.net/en/',
                  summary: state.extra is ArticleSummary ? state.extra as ArticleSummary : null,
                ),
              ),
            ),
            GoRoute(
              path: AppRoute.fanboxBrowse.path,
              name: AppRoute.fanboxBrowse.name,
              builder: (context, state) => FanboxBrowsePage(
                location: (
                  section:
                      FanboxSection.values.where((item) => item.name == state.uri.queryParameters[AppRouteQuery.section]).firstOrNull ?? FanboxSection.home,
                  creatorId: '',
                  query: state.uri.queryParameters[AppRouteQuery.query] ?? '',
                ),
              ),
            ),
            GoRoute(
              path: AppRoute.fanboxTag.path,
              name: AppRoute.fanboxTag.name,
              pageBuilder: (context, state) => FrostDetailPage(
                key: state.pageKey,
                child: FanboxBrowsePage(
                  location: (
                    section: FanboxSection.tag,
                    creatorId: state.uri.queryParameters[AppRouteQuery.creator] ?? '',
                    query: state.uri.queryParameters[AppRouteQuery.query] ?? '',
                  ),
                ),
              ),
            ),
            GoRoute(
              path: AppRoute.fanboxPost.path,
              name: AppRoute.fanboxPost.name,
              pageBuilder: (context, state) => FrostDetailPage(
                key: state.pageKey,
                child: FanboxPostDetailPage(
                  postId: state.pathParameters[AppRouteParam.postId]!,
                  summary: state.extra is FanboxPost ? state.extra as FanboxPost : null,
                ),
              ),
            ),
            GoRoute(
              path: AppRoute.fanboxCreator.path,
              name: AppRoute.fanboxCreator.name,
              pageBuilder: (context, state) => FrostDetailPage(
                key: state.pageKey,
                child: FanboxCreatorDetailPage(
                  creatorId: state.pathParameters[AppRouteParam.creatorId]!,
                  showPlans: state.uri.queryParameters[AppRouteQuery.plans] == 'true',
                  summary: state.extra is FanboxCreator ? state.extra as FanboxCreator : null,
                ),
              ),
            ),
            // FANBOX's own sign-in page where the platform has a web view.
            GoRoute(
              path: AppRoute.fanboxWebLogin.path,
              name: AppRoute.fanboxWebLogin.name,
              pageBuilder: (context, state) => FrostDetailPage<bool>(key: state.pageKey, child: const FanboxWebLoginPage()),
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

  /// The location on top: GoRouter keeps the base location for pushed pages,
  /// so the last imperative match is the visible one.
  static Uri get currentUri {
    final configuration = router.routerDelegate.currentConfiguration;
    if (configuration.isEmpty) return router.routeInformationProvider.value.uri;
    return switch (configuration.last) {
      ImperativeRouteMatch(:final matches) => matches.uri,
      _ => configuration.uri,
    };
  }

  /// The destination that opened the pages above a destination's root page.
  static int? _opener;

  /// The destination to highlight for [path]: its own, or for pages any
  /// destination can open (a work, a search), the one they were opened from.
  /// A secondary page (FANBOX, settings) keeps the destination
  /// that opened it for the bottom bar; the sidebar, which lists the secondary
  /// destinations too, highlights the secondary one instead (see RouterShell).
  static int? destinationIndexFor(String path) {
    if (appSecondaryIndexForPath(path) != null) return _opener ?? 0;
    final byPath = appDestinationIndexForPath(path);
    if (byPath == null) return _opener ?? 0;
    _opener = byPath;
    return byPath;
  }

  /// Back one page; a page reached without history goes to the page it
  /// belongs to.
  static void popRightNavigator() {
    final navigator = rightNavigatorKey.currentState;
    if (rightNavigatorDepth > 0 && navigator != null) {
      navigator.maybePop();
    } else if (fallbackPathFor(currentUri.path) case final fallback?) {
      router.go(fallback);
    }
  }

  /// The secondary destination chosen in the sidebar, while it is the page
  /// right above the destination's root.
  static String? _switchedSecondary;

  /// Set from the choice until the page is on the stack.
  static bool _switchPending = false;
  static bool _watchingSwitch = false;

  /// The sidebar's secondary destinations are destinations too: choosing one
  /// replaces the pages above the current destination's root with it, as
  /// choosing a primary destination does, so Back does not return to the page
  /// it was chosen from and repeated choices do not stack pages. Pages that
  /// open these from elsewhere (Me's rows) push them as usual.
  static void switchToSecondary(AppRoute route) {
    if (AppRoute.match(currentUri.path) == route) return;
    if (!_watchingSwitch) {
      _watchingSwitch = true;
      router.routerDelegate.addListener(_trackSwitchedSecondary);
    }
    _switchedSecondary = route.path;
    _switchPending = true;
    if (rightNavigatorDepth > 0) router.go(router.routerDelegate.currentConfiguration.uri.toString());
    router.push(route.path);
  }

  static void _trackSwitchedSecondary() {
    final switched = _switchedSecondary;
    if (switched == null) return;
    final first = _pushedPath(1);
    if (first == switched) {
      _switchPending = false;
    } else if (!_switchPending) {
      _switchedSecondary = null;
    }
  }

  /// Whether the page on top is a secondary destination chosen in the
  /// sidebar: a destination root, with nothing for Back to return to.
  static bool get atSwitchedSecondary => _switchedSecondary != null && rightNavigatorDepth == 1 && _pushedPath(1) == _switchedSecondary;

  /// The path of the right navigator's page at [index] (0 is the
  /// destination's root).
  static String? _pushedPath(int index) {
    for (final match in router.routerDelegate.currentConfiguration.matches) {
      if (match is ShellRouteMatch && match.navigatorKey == rightNavigatorKey) {
        if (index >= match.matches.length) return null;
        return switch (match.matches[index]) {
          ImperativeRouteMatch(:final matches) => matches.uri.path,
          final other => other.matchedLocation,
        };
      }
    }
    return null;
  }

  /// Back to the destination's root in one step: every page above it leaves
  /// the configuration at once, and the Navigator animates only the top one
  /// out. Popping them in turn would run each page's exit together.
  static void popRightNavigatorToRoot() {
    var configuration = router.routerDelegate.currentConfiguration;
    final right = configuration.matches.whereType<ShellRouteMatch>().where((match) => match.navigatorKey == rightNavigatorKey).firstOrNull;
    if (right == null || right.matches.length <= 1) return;
    for (final match in right.matches.skip(1).toList().reversed) {
      configuration = configuration.remove(match);
      if (match is ImperativeRouteMatch) match.complete();
    }
    router.restore(configuration);
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
}
