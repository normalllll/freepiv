import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/features/downloads/presentation/download_entry.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The destinations kept off the phone's bottom bar, in order.
const appSecondaryRoutes = [AppRoute.fanbox, AppRoute.settings];

/// The secondary destination a location belongs to.
int? appSecondaryIndexForPath(String path) => switch (AppRoute.match(path)) {
  AppRoute.fanbox || AppRoute.fanboxBrowse || AppRoute.fanboxTag || AppRoute.fanboxPost || AppRoute.fanboxCreator || AppRoute.fanboxWebLogin => 0,
  AppRoute.settings => 1,
  _ => null,
};

/// freepiv's routes on the shared navigation shell: the three destinations,
/// the secondary group, Back, and the keys that act on the visible page.
class RouterShell extends ConsumerWidget {
  const RouterShell({
    required this.location,
    required this.selectedIndex,
    required this.routeDepth,
    this.atSecondaryRoot = false,
    required this.onBack,
    required this.onBackToFirst,
    required this.onDestinationSelected,
    required this.onSecondarySelected,
    required this.child,
    super.key,
  });

  /// The location on top of the content navigator.
  final Uri location;

  /// The destination to highlight; pages any destination opens keep the one
  /// they were opened from.
  final int? selectedIndex;

  /// Pages above the destination's root page.
  final int routeDepth;

  /// The page on top is a secondary destination chosen in the sidebar: a
  /// destination root like the primary ones, with no Back.
  final bool atSecondaryRoot;
  final VoidCallback onBack;
  final VoidCallback onBackToFirst;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<AppRoute> onSecondarySelected;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final path = location.path;
    final atDestinationRoot = (routeDepth == 0 && isMobileNavigationPath(path)) || atSecondaryRoot;
    // The login page is where signed-out navigation ends up; there is no page
    // to go back to from it.
    final canGoBack = !atDestinationRoot && AppRoute.match(path) != AppRoute.login;
    final downloads = ref.watch(downloadActivityProvider);
    final shell = ValueListenableBuilder<bool>(
      valueListenable: DownloadFlight.revealRequested,
      builder: (context, revealed, _) => FrostShell(
        destinations: [
          for (final destination in appRouteDestinations)
            FrostNavDestination(icon: destination.icon, label: appRouteDestinationLabel(translations, destination)),
        ],
        selectedIndex: selectedIndex,
        atDestinationRoot: atDestinationRoot,
        onDestinationSelected: onDestinationSelected,
        secondary: FrostShellSecondary(
          destinations: [
            for (final route in appSecondaryRoutes) FrostNavDestination(icon: _secondaryIcon(route), label: appRouteNavigationLabel(translations, route)),
          ],
          selectedIndex: appSecondaryIndexForPath(path),
          onSelected: (index) => onSecondarySelected(appSecondaryRoutes[index]),
        ),
        canGoBack: canGoBack,
        onBack: onBack,
        showsMobileNavigation: true,
        initiallyExpanded: ref.read(sidebarExpandedProvider),
        onExpandedChanged: ref.read(sidebarExpandedProvider.notifier).setExpanded,
        brand: FrostShellBrand(
          expanded: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BrandIcon(),
              const SizedBox(width: FrostGap.related),
              Flexible(
                child: FrostText(translations.app.title, role: FrostTextRole.callout, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          icon: const _BrandIcon(),
          label: translations.app.title,
        ),
        // Frost shows it in the title row when the sidebar layout has room; the
        // pages that offer a search carry the same session in their header
        // otherwise.
        titleBarSearch: const AppTitleBarSearch(),
        titleBarSearchPlacement: FrostCaptionSearchPlacement.end,
        routeDepth: routeDepth,
        backToFirst: FrostShellBackToFirst(label: translations.navigation.backToFirst, icon: PivIcons.home, onPressed: onBackToFirst),
        taskEntry: appDownloadTaskEntry(downloads, revealed: revealed),
        child: AppSearchPlacementProbe(child: child),
      ),
    );
    // An Escape nothing inside the shell took goes back one page; at a
    // destination's root it does nothing. It has its own intent: the Scaffolds
    // around the pages map DismissIntent to their drawers and would swallow it.
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _PageBackIntent(),
        SingleActivator(LogicalKeyboardKey.f5): _PageRefreshIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, control: true): _FocusSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, meta: true): _FocusSearchIntent(),
      },
      child: Actions(
        actions: {
          _PageBackIntent: _PageBackAction(enabled: canGoBack, onBack: onBack),
          _PageRefreshIntent: CallbackAction<_PageRefreshIntent>(onInvoke: (_) => AppRefreshScope.refreshVisible()),
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(onInvoke: (_) => openAppSearch(ref, GoRouter.of(context))),
        },
        // The title bar search sits outside the page navigators: when it lets
        // go of focus, focus falls back to the nearest scope. This one keeps
        // it inside the shortcuts, so Ctrl K works again after a search.
        child: FocusScope(child: shell),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) => Image.asset('assets/icon-512.png', width: 24, height: 24, cacheWidth: 96, cacheHeight: 96, excludeFromSemantics: true);
}

class _PageBackIntent extends Intent {
  const _PageBackIntent();
}

class _PageRefreshIntent extends Intent {
  const _PageRefreshIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _PageBackAction extends Action<_PageBackIntent> {
  _PageBackAction({required this.enabled, required this.onBack});

  final bool enabled;
  final VoidCallback onBack;

  @override
  bool isEnabled(_PageBackIntent intent) => enabled;

  @override
  Object? invoke(_PageBackIntent intent) {
    onBack();
    return null;
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
    AppRoute.fanboxBrowse || AppRoute.fanboxTag || AppRoute.fanboxPost || AppRoute.fanboxCreator || AppRoute.fanboxWebLogin => AppRoute.fanbox.path,
    AppRoute.pixivisionBrowse || AppRoute.pixivisionArticle => AppRoute.pixivision.path,
    AppRoute.meFollowing || AppRoute.meFollowers => AppRoute.me.path,
    AppRoute.searchIllustResult || AppRoute.searchNovelResult || AppRoute.searchUserResult || AppRoute.tagSearch => AppRoute.discover.path,
    _ => AppRoute.home.path,
  };
}

FrostIconData _secondaryIcon(AppRoute route) => switch (route) {
  AppRoute.fanbox => PivIcons.heart,
  AppRoute.settings => PivIcons.settings,
  _ => PivIcons.more,
};
