import 'package:flutter/widgets.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart' show pixivImageProviderFor;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:freepiv/app/account_scope.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/app/theme/system_transparency.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/core/platform/platform_info.dart';
import 'package:freepiv/core/services/app_settings.dart';
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
    return AccountScope(
      overrides: overrides,
      builder: (context, accountId) => TranslationProvider(
        // TranslationProvider keeps its element across scopes; this key starts
        // everything below it over for the account.
        child: KeyedSubtree(
          key: ValueKey(accountId),
          child: _FreepivMaterialApp(windowController: windowController, scopeId: accountId),
        ),
      ),
    );
  }
}

class _FreepivMaterialApp extends ConsumerStatefulWidget {
  const _FreepivMaterialApp({required this.windowController, required this.scopeId});

  final FrostWindowController windowController;

  /// The account the scope is for; keys what the app builds, see [AccountScope].
  final String? scopeId;

  @override
  ConsumerState<_FreepivMaterialApp> createState() => _FreepivMaterialAppState();
}

/// The native window title; windows/runner/main.cpp finds a running
/// instance by this exact title.
const _windowTitle = 'freepiv';

class _FreepivMaterialAppState extends ConsumerState<_FreepivMaterialApp> {
  final FrostWindowTitleRegistry _windowTitles = FrostWindowTitleRegistry();
  late final WindowTitleRouterBridge _routerBridge;

  /// The router of the scope this was mounted in; a later one belongs to the next scope.
  final _router = AppRouter.router;

  @override
  void initState() {
    super.initState();
    _routerBridge = WindowTitleRouterBridge(_windowTitles, _router);
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
    final background = ref.watch(backgroundSettingsProvider);

    return FrostScope(
      config: freepivFrostConfig,
      reduceTransparency: background.material == BackgroundMaterial.off,
      child: FrostApp.router(
        config: freepivFrostConfig,
        title: context.t.app.title,
        appearance: appearance,
        locale: selectedLocale?.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        routerConfig: _router,
        builder: (context, child) {
          return FrostWindowTitleScope(
            registry: _windowTitles,
            child: AnimatedBuilder(
              animation: _windowTitles,
              // The title bar, navigation and pages are transparent over one
              // window-wide ambient backdrop, so the window reads as one surface.
              // The window's own title stays the app name: the runner finds
              // the running instance by it, and pages carry their titles.
              builder: (context, _) => ValueListenableBuilder<FrostWindowState>(
                valueListenable: widget.windowController,
                builder: (context, window, _) {
                  // The system's preference and what it can paint override the
                  // saved choice here, which stays as the user made it.
                  final systemDisabled = window.reduceTransparency || MediaQuery.highContrastOf(context);
                  final effective = switch ((systemDisabled, background.material, window.backdropAvailable)) {
                    (true, _, _) => BackgroundMaterial.off,
                    (false, BackgroundMaterial.mica, false) => BackgroundMaterial.ambient,
                    (false, final material, _) => material,
                  };
                  return SystemTransparencyPreference(
                    disabled: systemDisabled,
                    child: FrostWindowHost(
                      controller: widget.windowController,
                      title: _windowTitle,
                      backdrop: effective == BackgroundMaterial.mica ? FrostWindowBackdrop.mica : FrostWindowBackdrop.none,
                      child: FrostAmbientBackdropHost(
                        image: effective == BackgroundMaterial.ambient ? _backdropImage(resolveWindowArtwork(_windowTitles.location, _windowTitles)) : null,
                        intensity: effective == BackgroundMaterial.off ? 0 : background.intensity / 100,
                        child: FrostFontWarmUp(samples: _fontSamples, child: child ?? const SizedBox.shrink()),
                      ),
                    ),
                  );
                },
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
