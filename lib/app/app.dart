import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/app/theme/app_input_feedback.dart';
import 'window/native_window.dart';
import 'window/window_title.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/app/widgets/font_warm_up.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/features/downloads/presentation/mobile_download_floating_window.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/ui/fp_ambient_backdrop.dart';
import 'package:freepiv/app/toast/app_toast.dart';

class FreepivApp extends StatelessWidget {
  const FreepivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: TranslationProvider(child: const AppInputFeedback(child: _FreepivMaterialApp())),
    );
  }
}

class _FreepivMaterialApp extends ConsumerStatefulWidget {
  const _FreepivMaterialApp();

  @override
  ConsumerState<_FreepivMaterialApp> createState() => _FreepivMaterialAppState();
}

class _FreepivMaterialAppState extends ConsumerState<_FreepivMaterialApp> {
  final WindowTitleRegistry _windowTitles = WindowTitleRegistry();

  @override
  void initState() {
    super.initState();
    _windowTitles.attachRouter(AppRouter.router);
  }

  @override
  void dispose() {
    _windowTitles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider).settings;
    final selectedLocale = ref.watch(appLocaleProvider);
    final effectiveLocale = selectedLocale?.flutterLocale ?? View.of(context).platformDispatcher.locale;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: context.t.app.title,
      themeAnimationDuration: MediaQuery.maybeOf(context)?.disableAnimations == true ? Duration.zero : const Duration(milliseconds: 180),
      themeAnimationCurve: Curves.easeInOutCubic,
      theme: AppTheme.light(
        platform: defaultTargetPlatform,
        locale: effectiveLocale,
        tone: appearance.effectiveToneFor(Brightness.light),
        accent: appearance.lightAccent,
      ),
      darkTheme: AppTheme.dark(
        platform: defaultTargetPlatform,
        locale: effectiveLocale,
        tone: appearance.effectiveToneFor(Brightness.dark),
        accent: appearance.darkAccent,
      ),
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
          value: appSystemOverlayStyle(FreepivThemeTokens.of(context)),
          child: WindowTitleScope(
            registry: _windowTitles,
            child: AnimatedBuilder(
              animation: _windowTitles,
              // The title bar, navigation and pages are transparent over one
              // window-wide ambient backdrop, so the window reads as one surface.
              builder: (context, _) => AmbientBackdropHost(
                artworkUrl: resolveWindowArtwork(_windowTitles.uri, _windowTitles),
                child: NativeWindowFrame(
                  title: resolveWindowTitle(_windowTitles.uri, context.t, _windowTitles),
                  brandTitle: context.t.app.title,
                  leading: Image.asset('assets/icon-512.png', cacheWidth: 96, cacheHeight: 96),
                  background: Colors.transparent,
                  foreground: colors.onSurfaceVariant,
                  border: Colors.transparent,
                  child: AppLayoutScope(
                    // Notices sit over the pages but below the Windows title
                    // bar, inside the theme and locale.
                    child: AppToastHost(
                      child: FontWarmUp(child: MobileDownloadFloatingWindow(child: child ?? const SizedBox.shrink())),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
