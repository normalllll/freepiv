/// Every route of the app, defined once. Pages navigate with [AppLocations],
/// the router reads parameters by the names in [AppRouteParam] and
/// [AppRouteQuery], and code that needs to know which route a location belongs
/// to asks [AppRoute.match]; nothing else spells a route path.
enum AppRoute {
  home('/'),
  newest('/newest'),
  me('/me'),
  discover('/discover'),
  searchIllustResult('/search/illust'),
  searchNovelResult('/search/novel'),
  searchUserResult('/search/user'),
  tagSearch('/search/tag'),
  ranking('/ranking'),
  legacyRankingIllust('/ranking/illust'),
  legacyRankingManga('/ranking/manga'),
  legacyRankingNovel('/ranking/novel'),
  fanbox('/fanbox'),
  fanboxBrowse('/fanbox/browse'),
  fanboxTag('/fanbox/tag'),
  fanboxPost('/fanbox/post/:${AppRouteParam.postId}'),
  fanboxCreator('/fanbox/creator/:${AppRouteParam.creatorId}'),
  fanboxWebLogin('/fanbox/sign-in'),
  pixivision('/pixivision'),
  pixivisionBrowse('/pixivision/browse'),
  pixivisionArticle('/pixivision/article'),
  login('/login'),
  meFollowing('/me/following'),
  meFollowers('/me/followers'),
  meMypixiv('/me/mypixiv'),
  meWatchlist('/me/watchlist'),
  meProfileEdit('/me/profile'),
  meWorkspaceEdit('/me/workspace'),
  about('/about'),
  settings('/settings'),
  downloads('/downloads'),
  originalImageViewer('/image-viewer'),
  illustDetail('/illust/:${AppRouteParam.id}'),
  illustRelated('/illust/:${AppRouteParam.id}/related'),
  illustComments('/illust/:${AppRouteParam.id}/comments'),
  novelDetail('/novel/:${AppRouteParam.id}'),
  novelReader('/novel/:${AppRouteParam.id}/read'),
  novelComments('/novel/:${AppRouteParam.id}/comments'),
  mangaSeries('/series/manga/:${AppRouteParam.id}'),
  novelSeries('/series/novel/:${AppRouteParam.id}'),
  userDetail('/user/:${AppRouteParam.id}'),
  userRelated('/user/:${AppRouteParam.id}/related');

  const AppRoute(this.path);

  /// The go_router path template.
  final String path;

  /// The route whose template matches [location]'s path, or null.
  static AppRoute? match(String location) {
    final segments = Uri.parse(location).pathSegments.where((segment) => segment.isNotEmpty).toList();
    for (final route in values) {
      if (route._matches(segments)) return route;
    }
    return null;
  }

  /// The value of this route's path parameter [name] in [location], or null
  /// when [location] is not this route.
  String? parameterIn(String location, String name) {
    final segments = Uri.parse(location).pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (!_matches(segments)) return null;
    final index = _template.indexOf(':$name');
    return index < 0 ? null : segments[index];
  }

  List<String> get _template => path.split('/').where((segment) => segment.isNotEmpty).toList();

  bool _matches(List<String> segments) {
    final template = _template;
    if (template.length != segments.length) return false;
    for (var index = 0; index < template.length; index++) {
      if (!template[index].startsWith(':') && template[index] != segments[index]) return false;
    }
    return true;
  }

  /// [path] with its parameters filled in, and [query] as the query string.
  String _location({Map<String, Object> parameters = const {}, Map<String, String?> query = const {}}) {
    var filled = path;
    parameters.forEach((name, value) => filled = filled.replaceFirst(':$name', Uri.encodeComponent('$value')));
    final queryParameters = {
      for (final entry in query.entries)
        if (entry.value case final value? when value.isNotEmpty) entry.key: value,
    };
    return Uri(path: filled, queryParameters: queryParameters.isEmpty ? null : queryParameters).toString();
  }
}

/// Path parameter names.
abstract final class AppRouteParam {
  static const id = 'id';
  static const postId = 'postId';
  static const creatorId = 'creatorId';
}

/// Query parameter names.
abstract final class AppRouteQuery {
  static const query = 'q';
  static const url = 'url';
  static const section = 'section';
  static const creator = 'creator';
  static const tab = 'tab';
  static const item = 'item';
  static const plans = 'plans';
  static const type = 'type';
  static const mode = 'mode';

  /// Set to [on] to open the discover page with its search focused.
  static const focus = 'focus';
  static const on = '1';

  /// The [tab] value that opens an author's public bookmarks.
  static const bookmarksTab = 'bookmarks';
}

/// What a search result page lists.
enum AppSearchKind { illust, novel, user }

/// What a ranking lists.
enum AppRankingKind { illust, manga, novel }

/// What a series collects.
enum AppSeriesKind { manga, novel }

/// Locations to navigate to, built from [AppRoute].
abstract final class AppLocations {
  static String illust(Object id) => AppRoute.illustDetail._location(parameters: {AppRouteParam.id: id});

  static String illustRelated(Object id) => AppRoute.illustRelated._location(parameters: {AppRouteParam.id: id});

  static String illustComments(Object id) => AppRoute.illustComments._location(parameters: {AppRouteParam.id: id});

  static String novel(Object id) => AppRoute.novelDetail._location(parameters: {AppRouteParam.id: id});

  static String novelReader(Object id) => AppRoute.novelReader._location(parameters: {AppRouteParam.id: id});

  static String novelComments(Object id) => AppRoute.novelComments._location(parameters: {AppRouteParam.id: id});

  static String series(AppSeriesKind kind, Object id) => switch (kind) {
    AppSeriesKind.manga => AppRoute.mangaSeries._location(parameters: {AppRouteParam.id: id}),
    AppSeriesKind.novel => AppRoute.novelSeries._location(parameters: {AppRouteParam.id: id}),
  };

  /// An author's page, on their public bookmarks when [bookmarks] is set.
  static String user(Object id, {bool bookmarks = false}) =>
      AppRoute.userDetail._location(parameters: {AppRouteParam.id: id}, query: {AppRouteQuery.tab: bookmarks ? AppRouteQuery.bookmarksTab : null});

  /// The authors related to the author [id].
  static String userRelated(Object id) => AppRoute.userRelated._location(parameters: {AppRouteParam.id: id});

  /// The result page of [kind] for [query].
  static String search(AppSearchKind kind, String query) => searchRoute(kind)._location(query: {AppRouteQuery.query: query});

  static AppRoute searchRoute(AppSearchKind kind) => switch (kind) {
    AppSearchKind.illust => AppRoute.searchIllustResult,
    AppSearchKind.novel => AppRoute.searchNovelResult,
    AppSearchKind.user => AppRoute.searchUserResult,
  };

  /// Works carrying exactly the tag [tag]; [kind] is illust or novel.
  static String tagSearch(String tag, {AppSearchKind kind = AppSearchKind.illust}) =>
      AppRoute.tagSearch._location(query: {AppRouteQuery.query: tag, AppRouteQuery.type: kind.name});

  /// The ranking of [kind], on [mode] (a ranking mode's name) when given.
  static String ranking({AppRankingKind kind = AppRankingKind.illust, String? mode}) =>
      AppRoute.ranking._location(query: {AppRouteQuery.type: kind.name, AppRouteQuery.mode: mode});

  /// The discover page; [focusSearch] opens it with its search focused, the
  /// way the bottom-bar layout searches.
  /// [section] (a DiscoverSection name) opens it scrolled to that section.
  static String discover({bool focusSearch = false, String? section}) =>
      AppRoute.discover._location(query: {AppRouteQuery.focus: focusSearch ? AppRouteQuery.on : null, AppRouteQuery.section: section});

  static String downloads({String? item}) => AppRoute.downloads._location(query: {AppRouteQuery.item: item});

  static String fanboxPost(String postId) => AppRoute.fanboxPost._location(parameters: {AppRouteParam.postId: postId});

  static String fanboxCreator(String creatorId, {bool plans = false}) =>
      AppRoute.fanboxCreator._location(parameters: {AppRouteParam.creatorId: creatorId}, query: {AppRouteQuery.plans: plans ? 'true' : null});

  /// A FANBOX collection: [section] is a `FanboxSection` name.
  static String fanboxBrowse({String? section, String? query}) =>
      AppRoute.fanboxBrowse._location(query: {AppRouteQuery.section: section, AppRouteQuery.query: query});

  static String fanboxTag(String tag, {String creatorId = '', required String section}) =>
      AppRoute.fanboxTag._location(query: {AppRouteQuery.section: section, AppRouteQuery.query: tag, AppRouteQuery.creator: creatorId});

  static String pixivisionBrowse({String? url}) => AppRoute.pixivisionBrowse._location(query: {AppRouteQuery.url: url});

  static String pixivisionArticle(String url) => AppRoute.pixivisionArticle._location(query: {AppRouteQuery.url: url});
}
