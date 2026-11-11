import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_route_pages.dart' as route_pages;
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AppLocations', () {
    test('build each location from its route template', () {
      expect(AppLocations.illust(12), '/illust/12');
      expect(AppLocations.illustRelated(12), '/illust/12/related');
      expect(AppLocations.illustComments('12'), '/illust/12/comments');
      expect(AppLocations.novel(7), '/novel/7');
      expect(AppLocations.novelReader(7), '/novel/7/read');
      expect(AppLocations.novelComments(7), '/novel/7/comments');
      expect(AppLocations.user(3), '/user/3');
      expect(AppLocations.user(3, bookmarks: true), '/user/3?tab=bookmarks');
      expect(AppLocations.search(AppSearchKind.illust, 'miku'), '/search/illust?q=miku');
      expect(AppLocations.search(AppSearchKind.novel, 'a b'), '/search/novel?q=a+b');
      expect(AppLocations.search(AppSearchKind.user, 'x'), '/search/user?q=x');
      expect(AppLocations.tagSearch('初音ミク'), Uri(path: '/search/tag', queryParameters: {'q': '初音ミク', 'type': 'illust'}).toString());
      expect(AppLocations.tagSearch('r', kind: AppSearchKind.novel), '/search/tag?q=r&type=novel');
      expect(AppLocations.ranking(), '/ranking?type=illust');
      expect(AppLocations.ranking(kind: AppRankingKind.manga, mode: 'week'), '/ranking?type=manga&mode=week');
      expect(AppLocations.downloads(), '/downloads');
      expect(AppLocations.downloads(item: 'artwork:1'), '/downloads?item=artwork%3A1');
      expect(AppLocations.fanboxPost('9'), '/fanbox/post/9');
      expect(AppLocations.fanboxCreator('a/b'), '/fanbox/creator/a%2Fb');
      expect(AppLocations.fanboxCreator('c', plans: true), '/fanbox/creator/c?plans=true');
      expect(AppLocations.fanboxTag('t', section: 'tag'), '/fanbox/tag?section=tag&q=t');
      expect(AppLocations.fanboxTag('t', section: 'tag', creatorId: 'c'), '/fanbox/tag?section=tag&q=t&creator=c');
      expect(AppLocations.fanboxBrowse(section: 'home'), '/fanbox/browse?section=home');
      expect(AppLocations.pixivisionBrowse(), '/pixivision/browse');
      expect(AppLocations.pixivisionArticle('https://www.pixivision.net/en/a/1'), startsWith('/pixivision/article?url=https'));
    });

    test('match every built location back to its route and parameters', () {
      final cases = {
        AppRoute.home.path: AppRoute.home,
        AppRoute.discover.path: AppRoute.discover,
        AppLocations.illust(1): AppRoute.illustDetail,
        AppLocations.illustRelated(1): AppRoute.illustRelated,
        AppLocations.illustComments(1): AppRoute.illustComments,
        AppLocations.novel(1): AppRoute.novelDetail,
        AppLocations.novelReader(1): AppRoute.novelReader,
        AppLocations.novelComments(1): AppRoute.novelComments,
        AppLocations.user(1, bookmarks: true): AppRoute.userDetail,
        AppLocations.search(AppSearchKind.user, 'q'): AppRoute.searchUserResult,
        AppLocations.tagSearch('q'): AppRoute.tagSearch,
        AppLocations.ranking(): AppRoute.ranking,
        AppLocations.fanboxPost('p'): AppRoute.fanboxPost,
        AppLocations.fanboxCreator('c'): AppRoute.fanboxCreator,
        AppLocations.pixivisionBrowse(): AppRoute.pixivisionBrowse,
        AppRoute.meFollowing.path: AppRoute.meFollowing,
        AppRoute.meMypixiv.path: AppRoute.meMypixiv,
        AppRoute.meHistory.path: AppRoute.meHistory,
        AppLocations.userRelated(1): AppRoute.userRelated,
        '/ranking/novel': AppRoute.legacyRankingNovel,
      };
      cases.forEach((location, route) => expect(AppRoute.match(location), route, reason: location));
      expect(AppRoute.match('/nowhere'), isNull);
      expect(AppRoute.match('/search'), isNull, reason: 'the old discover path is gone');
      expect(AppRoute.illustComments.parameterIn(AppLocations.illustComments(42), AppRouteParam.id), '42');
      expect(AppRoute.fanboxPost.parameterIn(AppLocations.fanboxPost('x1'), AppRouteParam.postId), 'x1');
      expect(AppRoute.illustDetail.parameterIn(AppLocations.novel(42), AppRouteParam.id), isNull);
    });

    test('every route is a distinct template', () {
      expect(AppRoute.values.map((route) => route.path).toSet(), hasLength(AppRoute.values.length));
    });
  });

  group('navigation', () {
    test('three destinations: home, newest and me, which owns its lists', () {
      expect(appRouteDestinations.map((destination) => destination.route), [AppRoute.home, AppRoute.newest, AppRoute.me]);
      expect(appDestinationIndexForPath(AppRoute.me.path), 2);
      expect(appDestinationIndexForPath(AppRoute.meFollowers.path), 2);
      expect(appDestinationIndexForPath(AppRoute.meMypixiv.path), 2);
      expect(appDestinationIndexForPath(AppRoute.meHistory.path), 2);
      expect(appDestinationIndexForPath(AppRoute.discover.path), isNull);
      expect(appDestinationIndexForPath(AppLocations.illust(1)), isNull);
      expect(isMobileNavigationPath(AppRoute.newest.path), isTrue);
      expect(isMobileNavigationPath(AppRoute.discover.path), isFalse);
    });

    test('a deep-linked page goes back to the page it belongs to', () {
      expect(fallbackPathFor(AppLocations.illustComments(5)), AppLocations.illust(5));
      expect(fallbackPathFor(AppLocations.novelReader(5)), AppLocations.novel(5));
      expect(fallbackPathFor(AppLocations.fanboxPost('p')), AppRoute.fanbox.path);
      expect(fallbackPathFor(AppLocations.pixivisionArticle('u')), AppRoute.pixivision.path);
      expect(fallbackPathFor(AppRoute.meFollowing.path), AppRoute.me.path);
      expect(fallbackPathFor(AppRoute.meMypixiv.path), AppRoute.me.path);
      expect(fallbackPathFor(AppRoute.meHistory.path), AppRoute.me.path);
      expect(fallbackPathFor(AppLocations.userRelated(7)), AppLocations.user(7));
      expect(fallbackPathFor(AppLocations.search(AppSearchKind.illust, 'q')), AppRoute.discover.path);
      expect(fallbackPathFor(AppLocations.user(1)), AppRoute.home.path);
      expect(fallbackPathFor(AppRoute.home.path), isNull);
    });
  });

  group('router', () {
    test('discover, ranking and tag search are routes of the app router', () {
      final configuration = AppRouter.router.configuration;
      for (final location in [AppRoute.discover.path, AppLocations.ranking(kind: AppRankingKind.novel), AppLocations.tagSearch('t')]) {
        final matches = configuration.findMatch(Uri.parse(location));
        expect(matches.isError, isFalse, reason: location);
        expect(matches.last.route, isA<GoRoute>().having((route) => route.path, 'path', Uri.parse(location).path), reason: location);
      }
      expect(configuration.findMatch(Uri.parse('/search')).isError, isTrue, reason: 'no redirect from the old discover path');
    });

    testWidgets('the old per-kind ranking paths redirect to the merged ranking', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: AppRoute.ranking.path,
            builder: (_, state) => Text(state.uri.toString(), textDirection: TextDirection.ltr),
          ),
          for (final legacy in [AppRoute.legacyRankingIllust, AppRoute.legacyRankingManga, AppRoute.legacyRankingNovel])
            GoRoute(path: legacy.path, redirect: route_pages.legacyRankingRedirect),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(WidgetsApp.router(routerConfig: router, color: const Color(0xFF000000)));
      for (final (legacy, kind) in [
        ('/ranking/illust', AppRankingKind.illust),
        ('/ranking/manga', AppRankingKind.manga),
        ('/ranking/novel', AppRankingKind.novel),
      ]) {
        router.go(legacy);
        await tester.pumpAndSettle();
        expect(router.state.uri.toString(), AppLocations.ranking(kind: kind));
        router.go('$legacy?mode=week');
        await tester.pumpAndSettle();
        expect(
          router.state.uri.toString(),
          AppLocations.ranking(kind: kind, mode: 'week'),
          reason: 'the mode survives the redirect',
        );
      }
    });
  });
}
