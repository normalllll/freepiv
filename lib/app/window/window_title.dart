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
  final segments = uri.pathSegments;
  if (segments.length >= 2 && (segments.first == 'illust' || segments.first == 'novel')) {
    final isNovel = segments.first == 'novel';
    final sourcePath = '/${segments.first}/${segments[1]}';
    final work = registry.page(sourcePath);
    final type = isNovel
        ? translations.nativeWindow.novel
        : work?.kind == 'manga'
        ? translations.nativeWindow.manga
        : translations.nativeWindow.illust;
    final fallback = translations.nativeWindow.workFallback(type: type, id: segments[1]);
    if (segments.length >= 3 && segments[2] == 'related') {
      return translations.nativeWindow.relatedTitle(title: work?.title.isNotEmpty == true ? work!.title : fallback);
    }
    if (segments.length == 2 || segments[2] == 'read' || segments[2] == 'comments') {
      return work?.title.isNotEmpty == true ? translations.nativeWindow.workTitle(type: type, id: segments[1], title: work!.title) : fallback;
    }
  }
  if (segments.length == 2 && segments.first == 'user') {
    final name = registry.page('/user/${segments[1]}')?.title ?? '';
    return name.isNotEmpty ? name : translations.nativeWindow.userFallback(id: segments[1]);
  }
  // The viewer contributes its already formatted "title · page/total".
  if (path == AppRoute.originalImageViewer.path) {
    final viewer = registry.page(path)?.title ?? '';
    if (viewer.isNotEmpty) return viewer;
  }
  if (path == AppRoute.meFollowing.path) return translations.me.following;
  if (path == AppRoute.meFollowers.path) return translations.me.followers;
  for (final route in AppRoute.values) {
    if (route.path == path) {
      final label = appRouteLabel(translations, route);
      if (label.isNotEmpty) return label;
    }
  }
  if (path.startsWith('/fanbox/')) return translations.fanbox.title;
  if (path.startsWith('/pixivision/')) return translations.pixivision.title;
  return translations.app.title;
}

/// Artwork that tints the ambient backdrop for the visible work page.
String? resolveWindowArtwork(Uri uri, FrostWindowTitleRegistry registry) {
  final segments = uri.pathSegments;
  if (segments.length < 2) return null;
  return switch (segments.first) {
    'illust' ||
    'novel' when segments.length == 2 || segments[2] == 'comments' || segments[2] == 'related' => registry.page('/${segments.first}/${segments[1]}')?.imageUrl,
    'user' when segments.length == 2 => registry.page('/user/${segments[1]}')?.imageUrl,
    _ => null,
  };
}
