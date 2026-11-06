import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/about/presentation/about_page.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/work_comments_page.dart';
import 'package:freepiv/features/downloads/presentation/downloads_page.dart';
import 'package:freepiv/features/home/presentation/home_page.dart';
import 'package:freepiv/features/illust/presentation/illust_detail_page.dart';
import 'package:freepiv/features/illust/presentation/illust_related_page.dart';
import 'package:freepiv/features/login/presentation/login_page.dart';
import 'package:freepiv/features/me/presentation/me_page.dart';
import 'package:freepiv/features/newest/presentation/page/newest_page.dart';
import 'package:freepiv/features/novel/presentation/detail/novel_detail_page.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reader_page.dart';
import 'package:freepiv/features/ranking/presentation/ranking_work_pages.dart';
import 'package:freepiv/features/search/presentation/search_illust_result_page.dart';
import 'package:freepiv/features/search/presentation/search_novel_result_page.dart';
import 'package:freepiv/features/discover/page.dart';
import 'package:freepiv/features/search/presentation/search_user_result_page.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/artwork_hero.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:go_router/go_router.dart';

Page<void> loginPage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: LoginPage());
}

Page<void> homePage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: HomePage());
}

Page<void> newestPage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: NewestPage());
}

/// The ranking route (`?type=&mode=`): the ranking of one kind, starting on [mode] when it
/// names one of that kind's modes.
Page<void> rankingPage(BuildContext context, GoRouterState state) {
  final query = state.uri.queryParameters;
  final kind = AppRankingKind.values.where((kind) => kind.name == query[AppRouteQuery.type]).firstOrNull ?? AppRankingKind.illust;
  return FrostDetailPage(
    key: state.pageKey,
    child: _RankingRoute(kind: kind, mode: query[AppRouteQuery.mode]),
  );
}

/// The location an old per-kind ranking path now lives at, with its mode.
String? legacyRankingRedirect(BuildContext context, GoRouterState state) {
  final mode = state.uri.queryParameters[AppRouteQuery.mode];
  return switch (AppRoute.match(state.uri.path)) {
    AppRoute.legacyRankingIllust => AppLocations.ranking(kind: AppRankingKind.illust, mode: mode),
    AppRoute.legacyRankingManga => AppLocations.ranking(kind: AppRankingKind.manga, mode: mode),
    AppRoute.legacyRankingNovel => AppLocations.ranking(kind: AppRankingKind.novel, mode: mode),
    _ => null,
  };
}

/// One ranking page, on the route's mode when it names one of its kind's
/// modes. The mode belongs to this page: nothing shared changes on the way in.
class _RankingRoute extends StatelessWidget {
  const _RankingRoute({required this.kind, required this.mode});

  final AppRankingKind kind;
  final String? mode;

  static T? _named<T extends Enum>(List<T> values, String? name) => values.where((value) => value.name == name).firstOrNull;

  @override
  Widget build(BuildContext context) => switch (kind) {
    AppRankingKind.illust => RankingIllustPage(initialMode: _named(IllustRankingMode.values, mode)),
    AppRankingKind.manga => RankingMangaPage(initialMode: _named(MangaRankingMode.values, mode)),
    AppRankingKind.novel => RankingNovelPage(initialMode: _named(NovelRankingMode.values, mode)),
  };
}

/// The discover page, pushed above the destination it was opened from.
Page<void> discoverPage(BuildContext context, GoRouterState state) {
  return FrostDetailPage(key: state.pageKey, child: const DiscoverPage());
}

/// The tag search route (`?q=&type=`): works carrying exactly the tag.
Page<void> tagSearchPage(BuildContext context, GoRouterState state) {
  final query = state.uri.queryParameters;
  final tag = query[AppRouteQuery.query] ?? '';
  final novel = query[AppRouteQuery.type] == AppSearchKind.novel.name;
  const exactTag = SearchFilterState(target: SearchTarget.exactMatchForTags, novelTarget: SearchNovelTarget.exactMatchForTags);
  return FrostDetailPage(
    key: state.pageKey,
    child: novel
        ? SearchNovelResultPage(
            keyword: tag,
            initialFilters: const SearchFiltersState(novel: exactTag),
          )
        : SearchIllustResultPage(
            keyword: tag,
            initialFilters: const SearchFiltersState(illust: exactTag),
          ),
  );
}

Page<void> searchIllustResultPage(BuildContext context, GoRouterState state) {
  return NoTransitionPage(
    child: SearchIllustResultPage(
      keyword: state.uri.queryParameters[AppRouteQuery.query] ?? '',
      initialFilters: state.extra is SearchFiltersState ? state.extra as SearchFiltersState : null,
    ),
  );
}

Page<void> searchNovelResultPage(BuildContext context, GoRouterState state) {
  return NoTransitionPage(
    child: SearchNovelResultPage(
      keyword: state.uri.queryParameters[AppRouteQuery.query] ?? '',
      initialFilters: state.extra is SearchFiltersState ? state.extra as SearchFiltersState : null,
    ),
  );
}

Page<void> searchUserResultPage(BuildContext context, GoRouterState state) {
  return NoTransitionPage(
    child: SearchUserResultPage(
      keyword: state.uri.queryParameters[AppRouteQuery.query] ?? '',
      initialFilters: state.extra is SearchFiltersState ? state.extra as SearchFiltersState : null,
    ),
  );
}

Page<void> mePage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: MePage());
}

Page<void> meFollowingPage(BuildContext context, GoRouterState state) {
  return FrostDetailPage(
    key: state.pageKey,
    child: const MeUserListPage(kind: MeUserListKind.following),
  );
}

Page<void> meFollowersPage(BuildContext context, GoRouterState state) {
  return FrostDetailPage(
    key: state.pageKey,
    child: const MeUserListPage(kind: MeUserListKind.followers),
  );
}

Page<void> settingsPage(BuildContext context, GoRouterState state) {
  return FrostDetailPage(key: state.pageKey, child: const SettingsPage());
}

Page<void> aboutPage(BuildContext context, GoRouterState state) {
  return FrostDetailPage(key: state.pageKey, child: const AboutPage());
}

Page<void> downloadsPage(BuildContext context, GoRouterState state) {
  return FrostDetailPage(
    key: state.pageKey,
    child: DownloadsPage(focusItem: state.uri.queryParameters[AppRouteQuery.item]),
  );
}

Page<void> originalImageViewerPage(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  if (extra is! OriginalImageViewerArgs || extra.pages.isEmpty) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return FrostDetailPage(
    key: state.pageKey,
    child: OriginalImageViewerPage(args: extra),
  );
}

Page<void> illustDetailPage(BuildContext context, GoRouterState state) {
  // A card opening the work passes its own hero tag with it, so exactly that
  // card's image flies into the stage (see ArtworkHeroTag).
  final (Illust? illust, ArtworkHeroTag? heroTag) = switch (state.extra) {
    (illust: final Illust illust, heroTag: final ArtworkHeroTag heroTag) => (illust, heroTag),
    final Illust illust => (illust, null),
    _ => (null, null),
  };
  final illustId = int.tryParse(state.pathParameters[AppRouteParam.id] ?? '');

  if (illustId == null && illust == null) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return FrostDetailPage(
    key: state.pageKey,
    child: ArtworkHeroScope(
      tag: heroTag,
      child: IllustDetailPage(illustId: illustId, illust: illust),
    ),
  );
}

Page<void> illustCommentsPage(BuildContext context, GoRouterState state) {
  final illustId = int.tryParse(state.pathParameters[AppRouteParam.id] ?? '');
  if (illustId == null) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return FrostDetailPage(
    key: state.pageKey,
    child: WorkCommentsPage(workType: CommentWorkType.illust, workId: illustId, totalComments: _commentCountFromExtra(state.extra)),
  );
}

Page<void> illustRelatedPage(BuildContext context, GoRouterState state) {
  final illustId = int.tryParse(state.pathParameters[AppRouteParam.id] ?? '');
  if (illustId == null) return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  return FrostDetailPage(
    key: state.pageKey,
    child: IllustRelatedPage(illustId: illustId, sourceIllust: state.extra is Illust ? state.extra as Illust : null),
  );
}

Page<void> novelDetailPage(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  final novel = extra is Novel ? extra : null;
  final novelId = int.tryParse(state.pathParameters[AppRouteParam.id] ?? '');

  if (novelId == null && novel == null) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return FrostDetailPage(
    key: state.pageKey,
    child: NovelDetailPage(novelId: novel == null ? novelId : null, novel: novel),
  );
}

Page<void> novelReaderPage(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  final novel = extra is Novel ? extra : null;
  final novelId = int.tryParse(state.pathParameters[AppRouteParam.id] ?? '');

  if (novelId == null && novel == null) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return FrostDetailPage(
    key: state.pageKey,
    child: NovelReaderPage(novelId: novel == null ? novelId : null, novel: novel),
  );
}

Page<void> novelCommentsPage(BuildContext context, GoRouterState state) {
  final novelId = int.tryParse(state.pathParameters[AppRouteParam.id] ?? '');
  if (novelId == null) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return FrostDetailPage(
    key: state.pageKey,
    child: WorkCommentsPage(workType: CommentWorkType.novel, workId: novelId, totalComments: _commentCountFromExtra(state.extra)),
  );
}

Page<void> userDetailPage(BuildContext context, GoRouterState state) {
  final extra = state.extra;

  if (extra is UserDetailResult) {
    return FrostDetailPage(
      key: state.pageKey,
      child: UserDetailPage(
        userDetail: extra,
        initialTab: state.uri.queryParameters[AppRouteQuery.tab] == AppRouteQuery.bookmarksTab ? UserContentTabKind.bookmarks : UserContentTabKind.illust,
      ),
    );
  }

  final userId = extra is int ? extra : int.tryParse(state.pathParameters[AppRouteParam.id] ?? '');
  if (userId == null) {
    return _missingRoutePage(key: state.pageKey, message: t.user.error.missingUser);
  }

  return FrostDetailPage(
    key: state.pageKey,
    child: UserDetailPage(
      userId: userId,
      initialTab: state.uri.queryParameters[AppRouteQuery.tab] == AppRouteQuery.bookmarksTab ? UserContentTabKind.bookmarks : UserContentTabKind.illust,
    ),
  );
}

int? _commentCountFromExtra(Object? extra) {
  return extra is int ? extra : null;
}

Page<void> _missingRoutePage({required LocalKey key, required String message}) {
  return FrostDetailPage(
    key: key,
    child: FrostAutoScaffold(
      builder: (BuildContext context, FrostSizeLayout layout, Orientation orientation, bool useHorizontalLayout) {
        return Scaffold(
          appBar: useHorizontalLayout ? null : AppBar(title: Text(context.t.common.notFound)),
          body: Center(child: Text(message)),
        );
      },
    ),
  );
}
