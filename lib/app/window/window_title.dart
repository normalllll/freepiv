import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// Reports GoRouter's visible location to the window title registry.
/// GoRouter keeps the base URI for push routes; the visible route is in the
/// last imperative match, including when pushes are nested.
class WindowTitleRouterBridge {
  WindowTitleRouterBridge(this._registry, this._router) {
    _router.routerDelegate.addListener(_routeChanged);
    _routeChanged();
  }

  final FrostWindowTitleRegistry _registry;
  final GoRouter _router;

  void _routeChanged() {
    var matches = _router.routerDelegate.currentConfiguration;
    while (matches.lastOrNull is ImperativeRouteMatch) {
      matches = (matches.last as ImperativeRouteMatch).matches;
    }
    _registry.updateLocation(matches.uri);
  }

  void dispose() => _router.routerDelegate.removeListener(_routeChanged);
}

String resolveWindowTitle(Uri uri, Translations translations, FrostWindowTitleRegistry registry) {
  final path = uri.path;
  final route = AppRoute.match(path);
  final id = route?.parameterIn(path, AppRouteParam.id);
  switch (route) {
    case AppRoute.illustDetail || AppRoute.illustRelated || AppRoute.illustComments || AppRoute.novelDetail || AppRoute.novelReader || AppRoute.novelComments
        when id != null:
      final novel = route == AppRoute.novelDetail || route == AppRoute.novelReader || route == AppRoute.novelComments;
      final work = registry.page(novel ? AppLocations.novel(id) : AppLocations.illust(id));
      final type = novel
          ? translations.nativeWindow.novel
          : work?.kind == 'manga'
          ? translations.nativeWindow.manga
          : translations.nativeWindow.illust;
      final fallback = translations.nativeWindow.workFallback(type: type, id: id);
      if (route == AppRoute.illustRelated) {
        return translations.nativeWindow.relatedTitle(title: work?.title.isNotEmpty == true ? work!.title : fallback);
      }
      return work?.title.isNotEmpty == true ? translations.nativeWindow.workTitle(type: type, id: id, title: work!.title) : fallback;
    case AppRoute.userDetail when id != null:
      final name = registry.page(AppLocations.user(id))?.title ?? '';
      return name.isNotEmpty ? name : translations.nativeWindow.userFallback(id: id);
    // The viewer contributes its already formatted "title · page/total".
    case AppRoute.originalImageViewer:
      final viewer = registry.page(path)?.title ?? '';
      if (viewer.isNotEmpty) return viewer;
    default:
  }
  if (route == null) return translations.app.title;
  final label = appRouteLabel(translations, route);
  return label.isNotEmpty ? label : translations.app.title;
}

/// Artwork that tints the ambient backdrop for the visible work page.
String? resolveWindowArtwork(Uri uri, FrostWindowTitleRegistry registry) {
  final path = uri.path;
  final route = AppRoute.match(path);
  final id = route?.parameterIn(path, AppRouteParam.id);
  if (id == null) return null;
  return switch (route) {
    AppRoute.illustDetail || AppRoute.illustComments || AppRoute.illustRelated => registry.page(AppLocations.illust(id))?.imageUrl,
    AppRoute.novelDetail || AppRoute.novelComments => registry.page(AppLocations.novel(id))?.imageUrl,
    AppRoute.userDetail => registry.page(AppLocations.user(id))?.imageUrl,
    _ => null,
  };
}
