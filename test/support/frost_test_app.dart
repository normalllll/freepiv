import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// Hosts [home] the way the app is hosted: [FrostApp] over a single route, so
/// a test gets the app's theme, toasts and layout scope without building a
/// Material app itself. [brightness] picks the theme; the platform comes from
/// the test's [TargetPlatformVariant] or the host.
Widget frostTestApp({
  required Widget home,
  Brightness brightness = Brightness.light,
  GlobalKey<NavigatorState>? navigatorKey,
  List<NavigatorObserver> observers = const [],
  TransitionBuilder? builder,
}) => frostTestRouterApp(
  GoRouter(
    navigatorKey: navigatorKey,
    observers: observers,
    routes: [GoRoute(path: '/', builder: (_, _) => home)],
  ),
  brightness: brightness,
  builder: builder,
);

/// [FrostApp] over the given [router], in the theme of [brightness].
Widget frostTestRouterApp(RouterConfig<Object> router, {Brightness brightness = Brightness.light, TransitionBuilder? builder}) => FrostApp.router(
  config: freepivFrostConfig,
  title: 'test',
  appearance: FrostAppearance.initial(freepivFrostConfig.palettes).copyWith(mode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light),
  routerConfig: router,
  builder: builder,
);
