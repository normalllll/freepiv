import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

class AppRouteDestination {
  const AppRouteDestination({required this.route, required this.icon, this.owns = const {}});

  final AppRoute route;
  final FrostIconData icon;

  /// Routes below the destination that keep it highlighted.
  final Set<AppRoute> owns;
}

/// The primary destinations; discover is a page pushed from search, not one
/// of them.
const appRouteDestinations = <AppRouteDestination>[
  AppRouteDestination(route: AppRoute.home, icon: PivIcons.home),
  AppRouteDestination(route: AppRoute.newest, icon: PivIcons.activity),
  AppRouteDestination(
    route: AppRoute.me,
    icon: PivIcons.user,
    owns: {
      AppRoute.meFollowing,
      AppRoute.meFollowers,
      AppRoute.meMypixiv,
      AppRoute.meWatchlist,
      AppRoute.meHistory,
      AppRoute.meProfileEdit,
      AppRoute.meWorkspaceEdit,
    },
  ),
];

/// The destinations without a page stack of their own, in order. The sidebar
/// lists them after the primary destinations; the bottom bar leaves them out.
const appSecondaryRoutes = [AppRoute.fanbox, AppRoute.settings];

/// The secondary destination a location belongs to.
int? appSecondaryIndexForPath(String path) => switch (AppRoute.match(path)) {
  AppRoute.fanbox || AppRoute.fanboxBrowse || AppRoute.fanboxTag || AppRoute.fanboxPost || AppRoute.fanboxCreator || AppRoute.fanboxWebLogin => 0,
  AppRoute.settings => 1,
  _ => null,
};

/// The route a shell navigation index stands for: a primary destination, or
/// past them a secondary one, as the sidebar lists them.
AppRoute appShellRouteAt(int index) {
  final primary = appRouteDestinations.length;
  return index < primary ? appRouteDestinations[index].route : appSecondaryRoutes[index - primary];
}

/// Whether [path] is a destination's root page.
bool isMobileNavigationPath(String path) {
  final route = AppRoute.match(path);
  return appRouteDestinations.any((item) => item.route == route);
}

int? appDestinationIndexForPath(String path) {
  final route = AppRoute.match(path);
  if (route == null) return null;
  for (var index = 0; index < appRouteDestinations.length; index += 1) {
    final destination = appRouteDestinations[index];
    if (destination.route == route || destination.owns.contains(route)) return index;
  }
  return null;
}

String appRouteDestinationLabel(Translations translations, AppRouteDestination destination) => appRouteLabel(translations, destination.route);

/// Navigation surfaces use short names; page and window titles keep the full
/// name from [appRouteLabel].
String appRouteNavigationLabel(Translations translations, AppRoute route) {
  return switch (route) {
    AppRoute.downloads => translations.navigation.downloads,
    AppRoute.about => translations.navigation.about,
    _ => appRouteLabel(translations, route),
  };
}

String appRouteLabel(Translations translations, AppRoute route) {
  return switch (route) {
    AppRoute.home => translations.navigation.home,
    AppRoute.discover => translations.common.discover,
    AppRoute.searchIllustResult || AppRoute.searchNovelResult || AppRoute.searchUserResult || AppRoute.tagSearch => translations.navigation.search,
    AppRoute.newest => translations.navigation.activity,
    AppRoute.fanbox ||
    AppRoute.fanboxBrowse ||
    AppRoute.fanboxTag ||
    AppRoute.fanboxPost ||
    AppRoute.fanboxCreator ||
    AppRoute.fanboxWebLogin => translations.fanbox.title,
    AppRoute.pixivision || AppRoute.pixivisionBrowse || AppRoute.pixivisionArticle => translations.pixivision.title,
    AppRoute.ranking || AppRoute.legacyRankingIllust || AppRoute.legacyRankingManga || AppRoute.legacyRankingNovel => translations.navigation.ranking,
    AppRoute.me => translations.navigation.me,
    AppRoute.about => translations.about.title,
    AppRoute.settings => translations.navigation.settings,
    AppRoute.downloads => translations.settings.downloads.tasksTitle,
    AppRoute.login => translations.login.title,
    AppRoute.accountsAdd => translations.accounts.addTitle,
    AppRoute.meFollowing => translations.me.following,
    AppRoute.meFollowers => translations.me.followers,
    AppRoute.meMypixiv => translations.me.mypixiv,
    AppRoute.meWatchlist => translations.me.watchlist,
    AppRoute.meHistory => translations.me.history,
    AppRoute.meProfileEdit => translations.me.editProfile,
    AppRoute.meWorkspaceEdit => translations.me.workspace,
    AppRoute.userRelated => translations.user.related.title,
    AppRoute.mangaSeries || AppRoute.novelSeries => translations.series.title,
    AppRoute.originalImageViewer ||
    AppRoute.illustDetail ||
    AppRoute.illustRelated ||
    AppRoute.illustComments ||
    AppRoute.novelDetail ||
    AppRoute.novelReader ||
    AppRoute.novelComments ||
    AppRoute.userDetail => '',
  };
}
