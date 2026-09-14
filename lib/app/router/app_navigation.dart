import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/i18n/strings.g.dart';

class AppRouteDestination {
  const AppRouteDestination({required this.route, required this.icon, required this.selectedIcon});

  final AppRoute route;
  final IconData icon;
  final IconData selectedIcon;
}

const appRouteDestinations = <AppRouteDestination>[
  AppRouteDestination(route: AppRoute.home, icon: Icons.auto_awesome_mosaic_outlined, selectedIcon: Icons.auto_awesome_mosaic),
  AppRouteDestination(route: AppRoute.newest, icon: Icons.fiber_new_outlined, selectedIcon: Icons.fiber_new),
  AppRouteDestination(route: AppRoute.search, icon: Icons.explore_outlined, selectedIcon: Icons.explore),
  AppRouteDestination(route: AppRoute.me, icon: Icons.account_circle_outlined, selectedIcon: Icons.account_circle),
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

String appRouteDestinationLabel(Translations translations, AppRouteDestination destination) {
  return switch (destination.route) {
    AppRoute.search => translations.common.discover,
    AppRoute.newest => translations.navigation.activity,
    _ => appRouteLabel(translations, destination.route),
  };
}

String appRouteLabel(Translations translations, AppRoute route) {
  return switch (route) {
    AppRoute.home => translations.navigation.home,
    AppRoute.search || AppRoute.searchIllustResult || AppRoute.searchNovelResult || AppRoute.searchUserResult => translations.navigation.search,
    AppRoute.newest => translations.navigation.newest,
    AppRoute.fanbox => translations.fanbox.title,
    AppRoute.pixivision => translations.pixivision.title,
    AppRoute.rankingIllust || AppRoute.rankingManga || AppRoute.rankingNovel => translations.navigation.ranking,
    AppRoute.me => translations.navigation.me,
    AppRoute.about => translations.about.title,
    AppRoute.settings => translations.navigation.settings,
    AppRoute.downloads => translations.settings.downloads.tasksTitle,
    AppRoute.login => translations.login.title,
    AppRoute.meFollowing || AppRoute.meFollowers => '',
    AppRoute.originalImageViewer ||
    AppRoute.illustDetail ||
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
    AppRoute.search => path == route.path || path.startsWith('/search/') || path == '/pixivision' || path.startsWith('/pixivision/'),
    AppRoute.newest => path == route.path || path.startsWith('${route.path}/'),
    AppRoute.me => path == route.path || path.startsWith('/me/') || path == '/fanbox' || path.startsWith('/fanbox/'),
    _ => false,
  };
}
