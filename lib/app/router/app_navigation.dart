import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

class AppRouteDestination {
  const AppRouteDestination({required this.route, required this.icon});

  final AppRoute route;
  final FrostIconData icon;
}

const appRouteDestinations = <AppRouteDestination>[
  AppRouteDestination(route: AppRoute.home, icon: PivIcons.home),
  AppRouteDestination(route: AppRoute.newest, icon: PivIcons.activity),
  AppRouteDestination(route: AppRoute.search, icon: PivIcons.compass),
  AppRouteDestination(route: AppRoute.me, icon: PivIcons.user),
];

bool isMobileNavigationPath(String path) => appRouteDestinations.any((item) => item.route.path == path);

int? appDestinationIndexForPath(String path) {
  for (var index = 0; index < appRouteDestinations.length; index += 1) {
    if (_routeOwnsPath(appRouteDestinations[index].route, path)) {
      return index;
    }
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
    // Primary destinations share one name between navigation and titles.
    AppRoute.search => translations.common.discover,
    AppRoute.searchIllustResult || AppRoute.searchNovelResult || AppRoute.searchUserResult => translations.navigation.search,
    AppRoute.newest => translations.navigation.activity,
    AppRoute.fanbox => translations.fanbox.title,
    AppRoute.pixivision => translations.pixivision.title,
    // The ranking page header holds only the mode picker; the kind lives in
    // the window and top-bar title.
    AppRoute.rankingIllust => '${translations.navigation.ranking} · ${translations.user.tabs.illustrations}',
    AppRoute.rankingManga => '${translations.navigation.ranking} · ${translations.user.tabs.manga}',
    AppRoute.rankingNovel => '${translations.navigation.ranking} · ${translations.user.tabs.novels}',
    AppRoute.me => translations.navigation.me,
    AppRoute.about => translations.about.title,
    AppRoute.settings => translations.navigation.settings,
    AppRoute.downloads => translations.settings.downloads.tasksTitle,
    AppRoute.login => translations.login.title,
    AppRoute.meFollowing || AppRoute.meFollowers => '',
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

bool _routeOwnsPath(AppRoute route, String path) {
  return switch (route) {
    AppRoute.home => path == route.path,
    AppRoute.search => path == route.path || path.startsWith('/search/'),
    AppRoute.newest => path == route.path || path.startsWith('${route.path}/'),
    AppRoute.me => path == route.path || path.startsWith('/me/'),
    _ => false,
  };
}
