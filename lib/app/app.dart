import 'package:flutter/widgets.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart' show pixivImageProviderFor;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/app/theme/transparency_logic.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/core/platform/platform_info.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

import 'window/window_title.dart';

class FreepivApp extends StatelessWidget {
  const FreepivApp({required this.windowController, this.overrides = const [], super.key});

  /// Created and placed at startup; the app only hosts it.
  final FrostWindowController windowController;

  /// Provider overrides, for the sample-data entrypoint.
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    FrostToast.systemConfirmsClipboardCopies = systemConfirmsClipboardCopies;
    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(child: _FreepivMaterialApp(windowController: windowController)),
    );
  }
}

class _FreepivMaterialApp extends ConsumerStatefulWidget {
  const _FreepivMaterialApp({required this.windowController});

  final FrostWindowController windowController;

  @override
  ConsumerState<_FreepivMaterialApp> createState() => _FreepivMaterialAppState();
}

/// The native window title; windows/runner/main.cpp finds a running
/// instance by this exact title.
const _windowTitle = 'freepiv';

class _FreepivMaterialAppState extends ConsumerState<_FreepivMaterialApp> {
  final FrostWindowTitleRegistry _windowTitles = FrostWindowTitleRegistry();
  late final WindowTitleRouterBridge _routerBridge;

  @override
  void initState() {
    super.initState();
    _routerBridge = WindowTitleRouterBridge(_windowTitles, AppRouter.router);
  }

  @override
  void dispose() {
    _routerBridge.dispose();
    _windowTitles.dispose();
    super.dispose();
  }

  /// The visible work's artwork: the same provider its card or page already
  /// shows the picture with, so the backdrop reuses that decoded image instead
  /// of fetching it again.
  ImageProvider? _backdropImage(String? url) => url == null ? null : pixivImageProviderFor(ref.read(rustMediaTransportProvider), url);

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider).settings;
    final selectedLocale = ref.watch(appLocaleProvider);

    return FrostScope(
      config: freepivFrostConfig,
      reduceTransparency: ref.watch(reduceTransparencyProvider),
      child: FrostApp.router(
        config: freepivFrostConfig,
        title: context.t.app.title,
        appearance: appearance,
        locale: selectedLocale?.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return FrostWindowTitleScope(
            registry: _windowTitles,
            child: AnimatedBuilder(
              animation: _windowTitles,
              // The title bar, navigation and pages are transparent over one
              // window-wide ambient backdrop, so the window reads as one surface.
              // The window's own title stays the app name: the runner finds
              // the running instance by it, and pages carry their titles.
              builder: (context, _) => FrostWindowHost(
                controller: widget.windowController,
                title: _windowTitle,
                child: FrostAmbientBackdropHost(
                  image: _backdropImage(resolveWindowArtwork(_windowTitles.location, _windowTitles)),
                  child: FrostFontWarmUp(samples: _fontSamples, child: child ?? const SizedBox.shrink()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

List<FrostFontWarmUpSample> _fontSamples(BuildContext context) {
  final t = context.t;
  return [
    const FrostFontWarmUpSample(locale: Locale('en', 'US'), text: 'freepiv Search Settings Proxy Address Port 0123456789'),
    const FrostFontWarmUpSample(locale: Locale('en', 'US'), text: '★ ☆ ♥ ✓ × … — () [] {} / : @ #'),
    FrostFontWarmUpSample(
      locale: Localizations.localeOf(context),
      text: [t.navigation.home, t.navigation.search, t.navigation.settings, t.navigation.activity, t.navigation.me].join(' '),
    ),
  ];
}
