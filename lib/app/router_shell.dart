import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// freepiv's routes on the shared navigation shell: the capsule sidebar, the
/// phone bottom bar, the secondary destinations in More, and the download
/// dock aligned with the sidebar's icon column.
class RouterShell extends StatelessWidget {
  const RouterShell({required this.child, required this.canPopListenable, required this.onBack, required this.onResetRightNavigator, super.key});

  final Widget child;
  final ValueListenable<bool> canPopListenable;
  final VoidCallback onBack;
  final VoidCallback onResetRightNavigator;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final translations = context.t;
    final secondaryIndex = _secondaryRoutes.indexWhere((route) => path == route.path || path.startsWith('${route.path}/'));
    return ValueListenableBuilder<bool>(
      valueListenable: canPopListenable,
      builder: (context, canPop, _) {
        void goBack() {
          if (canPopListenable.value) {
            onBack();
          } else if (fallbackPathFor(path) case final fallback?) {
            context.go(fallback);
          }
        }

        return FrostShell(
          destinations: [
            for (final destination in appRouteDestinations)
              FrostNavDestination(icon: destination.icon, label: appRouteDestinationLabel(translations, destination)),
          ],
          selectedIndex: appDestinationIndexForPath(path),
          atDestinationRoot: !canPop && isMobileNavigationPath(path),
          onDestinationSelected: (index) {
            onResetRightNavigator();
            context.go(appRouteDestinations[index].route.path);
          },
          secondary: FrostShellSecondary(
            destinations: [
              for (final route in _secondaryRoutes) FrostNavDestination(icon: _secondaryIcon(route), label: appRouteNavigationLabel(translations, route)),
            ],
            selectedIndex: secondaryIndex < 0 ? null : secondaryIndex,
            onSelected: (index) {
              final route = _secondaryRoutes[index];
              if (path != route.path) context.push(route.path);
            },
          ),
          canGoBack: canPop || fallbackPathFor(path) != null,
          onBack: goBack,
          showsMobileNavigation: isMobileNavigationPath(path),
          child: child,
        );
      },
    );
  }
}

/// Where Back goes from a page reached without history (a deep link): the
/// work a sub-page belongs to, or the section's top page.
String? fallbackPathFor(String path) {
  if (isMobileNavigationPath(path)) return null;
  final route = AppRoute.match(path);
  final id = route?.parameterIn(path, AppRouteParam.id);
  return switch (route) {
    AppRoute.illustRelated || AppRoute.illustComments when id != null => AppLocations.illust(id),
    AppRoute.novelReader || AppRoute.novelComments when id != null => AppLocations.novel(id),
    AppRoute.fanboxBrowse || AppRoute.fanboxTag || AppRoute.fanboxPost || AppRoute.fanboxCreator => AppRoute.fanbox.path,
    AppRoute.pixivisionBrowse || AppRoute.pixivisionArticle => AppRoute.pixivision.path,
    AppRoute.meFollowing || AppRoute.meFollowers => AppRoute.me.path,
    AppRoute.searchIllustResult || AppRoute.searchNovelResult || AppRoute.searchUserResult || AppRoute.tagSearch => AppRoute.discover.path,
    _ => AppRoute.home.path,
  };
}

const _secondaryRoutes = [AppRoute.fanbox, AppRoute.pixivision, AppRoute.downloads, AppRoute.settings, AppRoute.about];

FrostIconData _secondaryIcon(AppRoute route) => switch (route) {
  AppRoute.fanbox => PivIcons.heart,
  AppRoute.pixivision => PivIcons.newspaper,
  AppRoute.downloads => PivIcons.download,
  AppRoute.settings => PivIcons.settings,
  AppRoute.about => PivIcons.info,
  _ => PivIcons.more,
};
