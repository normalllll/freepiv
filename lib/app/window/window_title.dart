import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:go_router/go_router.dart';

@immutable
class WorkWindowTitle {
  const WorkWindowTitle({required this.id, required this.title, required this.kind, this.artworkUrl});

  /// What the window shows; only compared, to skip repeated updates.
  final Object id;
  final String title;
  final String kind;

  /// Small artwork image that tints the window's ambient backdrop.
  final String? artworkUrl;
}

/// Page data is contributed by the mounted detail page, so the window chrome
/// never starts another detail request just to render a title.
class WindowTitleRegistry extends ChangeNotifier {
  final Map<String, Map<Object, WorkWindowTitle>> _works = {};
  GoRouter? _router;
  bool _routeQueued = false;
  bool _noticeQueued = false;
  bool _disposed = false;
  Uri _uri = Uri(path: '/');

  Uri get uri => _uri;

  void attachRouter(GoRouter router) {
    if (identical(_router, router)) return;
    _router?.routerDelegate.removeListener(_routeChanged);
    _router = router;
    router.routerDelegate.addListener(_routeChanged);
    _routeChanged();
  }

  void _routeChanged() {
    if (_routeQueued) return;
    _routeQueued = true;
    // GoRouter may notify while the nested Router is building. Publish only
    // once that frame has completed so the outer title bar can rebuild safely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeQueued = false;
      final router = _router;
      if (router == null) return;
      var matches = router.routerDelegate.currentConfiguration;
      // GoRouter keeps the base URI for push routes. The visible route is in
      // the last imperative match, including when pushes are nested.
      while (matches.lastOrNull is ImperativeRouteMatch) {
        matches = (matches.last as ImperativeRouteMatch).matches;
      }
      final next = matches.uri;
      if (_uri == next) return;
      _uri = next;
      notifyListeners();
    });
  }

  WorkWindowTitle? work(String path) {
    final owners = _works[path];
    return owners == null || owners.isEmpty ? null : owners.values.last;
  }

  void setWork(String path, Object owner, WorkWindowTitle? work) {
    if (work == null) {
      remove(path, owner);
      return;
    }
    final owners = _works.putIfAbsent(path, () => {});
    final old = owners[owner];
    if (old?.id == work.id && old?.title == work.title && old?.kind == work.kind && old?.artworkUrl == work.artworkUrl) return;
    owners[owner] = work;
    notifyListeners();
  }

  void remove(String path, Object owner) {
    final owners = _works[path];
    if (owners == null || owners.remove(owner) == null) return;
    if (owners.isEmpty) _works.remove(path);
    // Page disposal happens while Flutter finalizes a frame and the widget
    // tree is locked. Its title can only be published after that frame.
    if (_noticeQueued) return;
    _noticeQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _noticeQueued = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _router?.routerDelegate.removeListener(_routeChanged);
    _router = null;
    super.dispose();
  }
}

class WindowTitleScope extends InheritedWidget {
  const WindowTitleScope({required this.registry, required super.child, super.key});

  final WindowTitleRegistry registry;

  static WindowTitleRegistry? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<WindowTitleScope>()?.registry;

  @override
  bool updateShouldNotify(WindowTitleScope oldWidget) => !identical(registry, oldWidget.registry);
}

class WindowTitleContribution extends StatefulWidget {
  const WindowTitleContribution({required this.path, required this.work, required this.child, super.key});

  final String path;
  final WorkWindowTitle? work;
  final Widget child;

  @override
  State<WindowTitleContribution> createState() => _WindowTitleContributionState();
}

class _WindowTitleContributionState extends State<WindowTitleContribution> {
  final Object _owner = Object();
  WindowTitleRegistry? _registry;
  String? _registeredPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registry = WindowTitleScope.maybeOf(context);
    _scheduleUpdate();
  }

  @override
  void didUpdateWidget(WindowTitleContribution oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleUpdate();
  }

  void _scheduleUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_registeredPath != null && _registeredPath != widget.path) _registry?.remove(_registeredPath!, _owner);
      _registeredPath = widget.path;
      _registry?.setWork(widget.path, _owner, widget.work);
    });
  }

  @override
  void dispose() {
    if (_registeredPath case final path?) _registry?.remove(path, _owner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

String resolveWindowTitle(Uri uri, Translations translations, WindowTitleRegistry registry) {
  final path = uri.path;
  final segments = uri.pathSegments;
  if (segments.length >= 2 && (segments.first == 'illust' || segments.first == 'novel')) {
    final isNovel = segments.first == 'novel';
    final sourcePath = '/${segments.first}/${segments[1]}';
    final work = registry.work(sourcePath);
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
    final name = registry.work('/user/${segments[1]}')?.title ?? '';
    return name.isNotEmpty ? name : translations.nativeWindow.userFallback(id: segments[1]);
  }
  // The viewer contributes its already formatted "title · page/total".
  if (path == AppRoute.originalImageViewer.path) {
    final viewer = registry.work(path)?.title ?? '';
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
String? resolveWindowArtwork(Uri uri, WindowTitleRegistry registry) {
  final segments = uri.pathSegments;
  if (segments.length < 2) return null;
  return switch (segments.first) {
    'illust' || 'novel' when segments.length == 2 || segments[2] == 'comments' || segments[2] == 'related' =>
      registry.work('/${segments.first}/${segments[1]}')?.artworkUrl,
    'user' when segments.length == 2 => registry.work('/user/${segments[1]}')?.artworkUrl,
    _ => null,
  };
}
