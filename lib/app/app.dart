import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/app/theme/transparency_logic.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/core/platform/platform_info.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/features/downloads/presentation/mobile_download_floating_window.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'window/native_window.dart';
import 'window/window_title.dart';

class FreepivApp extends StatelessWidget {
  const FreepivApp({super.key});

  @override
  Widget build(BuildContext context) {
    FrostToast.systemConfirmsClipboardCopies = systemConfirmsClipboardCopies;
    return ProviderScope(
      child: TranslationProvider(child: const FrostInputFeedback(child: _FreepivMaterialApp())),
    );
  }
}

class _FreepivMaterialApp extends ConsumerStatefulWidget {
  const _FreepivMaterialApp();

  @override
  ConsumerState<_FreepivMaterialApp> createState() => _FreepivMaterialAppState();
}

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

  /// The visible work's thumbnail, decoded at the backdrop's sample width.
  ImageProvider? _backdropImage(String? url) {
    if (url == null) return null;
    final transport = ref.read(rustMediaTransportProvider);
    return RustExtendedNetworkImageProvider(
      request: MediaRequest(url: url, headers: const {'Referer': 'https://www.pixiv.net/'}),
      decodeWidth: FrostAmbientBackdropHost.sampleWidth,
      mediaStream: transport.stream,
      mediaStreamCacheIdentity: transport.imageCacheIdentity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider).settings;
    final selectedLocale = ref.watch(appLocaleProvider);
    final effectiveLocale = selectedLocale?.flutterLocale ?? View.of(context).platformDispatcher.locale;
    ThemeData theme(Brightness brightness) => FrostTheme.build(
      config: freepivFrostConfig,
      brightness: brightness,
      platform: defaultTargetPlatform,
      locale: effectiveLocale,
      tone: appearance.effectiveToneFor(brightness),
      accent: appearance.accentFor(brightness),
    );

    return FrostScope(
      config: freepivFrostConfig,
      reduceTransparency: ref.watch(reduceTransparencyProvider),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: context.t.app.title,
        themeAnimationDuration: MediaQuery.maybeOf(context)?.disableAnimations == true ? Duration.zero : const Duration(milliseconds: 180),
        themeAnimationCurve: Curves.easeInOutCubic,
        theme: theme(Brightness.light),
        darkTheme: theme(Brightness.dark),
        themeMode: appearance.mode,
        locale: selectedLocale?.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        routerConfig: AppRouter.router,
        builder: (context, child) {
          final colors = Theme.of(context).colorScheme;
          // Pages without an AppBar still need readable status bar icons over
          // the transparent backdrop.
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: frostSystemOverlayStyle(FrostThemeTokens.of(context)),
            // Skeletons follow the app's theme mode; left alone they resolve
            // their shimmer from the platform brightness.
            child: SkeletonizerConfig(
              data: SkeletonizerConfigData(brightness: Theme.of(context).brightness),
              child: FrostWindowTitleScope(
                registry: _windowTitles,
                child: AnimatedBuilder(
                  animation: _windowTitles,
                  // The title bar, navigation and pages are transparent over one
                  // window-wide ambient backdrop, so the window reads as one surface.
                  builder: (context, _) => FrostAmbientBackdropHost(
                    image: _backdropImage(resolveWindowArtwork(_windowTitles.location, _windowTitles)),
                    child: NativeWindowFrame(
                      title: resolveWindowTitle(_windowTitles.location, context.t, _windowTitles),
                      brandTitle: context.t.app.title,
                      leading: Image.asset('assets/icon-512.png', cacheWidth: 96, cacheHeight: 96),
                      background: Colors.transparent,
                      foreground: colors.onSurfaceVariant,
                      border: Colors.transparent,
                      child: FrostLayoutScope(
                        // Notices sit over the pages but below the Windows title
                        // bar, inside the theme and locale.
                        child: FrostToastHost(
                          child: FrostFontWarmUp(
                            samples: _fontSamples,
                            child: MobileDownloadFloatingWindow(child: child ?? const SizedBox.shrink()),
                          ),
                        ),
                      ),
                    ),
                  ),
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
