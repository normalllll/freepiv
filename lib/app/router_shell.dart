import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/downloads/presentation/download_floating_panel.dart';
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

  /// Space between the sidebar's bottom edge and the dock button.
  static const _dockBottomOffset = 78.0;

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
          } else if (_fallbackPath(path) case final fallback?) {
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
          secondaryDestinations: [
            for (final route in _secondaryRoutes) FrostNavDestination(icon: _secondaryIcon(route), label: appRouteNavigationLabel(translations, route)),
          ],
          selectedSecondaryIndex: secondaryIndex < 0 ? null : secondaryIndex,
          onSecondarySelected: (index) {
            final route = _secondaryRoutes[index];
            if (path != route.path) context.push(route.path);
          },
          canGoBack: canPop || _fallbackPath(path) != null,
          onBack: goBack,
          showsMobileNavigation: isMobileNavigationPath(path),
          sidebarStyle: const FrostSidebarStyle.capsule(),
          desktopOverlayBuilder: (context, geometry) =>
              DesktopDownloadDock(railWidth: geometry.sidebarRight, buttonCenterX: geometry.iconAxis, bottomOffset: geometry.bottom - 8 + _dockBottomOffset),
          child: child,
        );
      },
    );
  }
}

/// Where Back goes from a page reached without history (a deep link): the
/// work a sub-page belongs to, or the section's top page.
String? _fallbackPath(String path) {
  if (isMobileNavigationPath(path)) return null;
  final segments = Uri(path: path).pathSegments;
  if (segments.length >= 3 && segments.first == 'illust') return '/illust/${segments[1]}';
  if (segments.length >= 3 && segments.first == 'novel') return '/novel/${segments[1]}';
  if (segments.length >= 2 && segments.first == 'fanbox') return AppRoute.fanbox.path;
  if (segments.length >= 2 && segments.first == 'pixivision') return AppRoute.pixivision.path;
  if (segments.length >= 2 && segments.first == 'me') return AppRoute.me.path;
  if (segments.length >= 2 && segments.first == 'search') return AppRoute.search.path;
  return AppRoute.home.path;
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
