import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/app/widgets/font_warm_up.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/features/downloads/presentation/mobile_download_floating_window.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:toastification/toastification.dart';

class FreepivApp extends StatelessWidget {
  const FreepivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: TranslationProvider(child: const ToastificationWrapper(child: _FreepivMaterialApp())),
    );
  }
}

class _FreepivMaterialApp extends ConsumerWidget {
  const _FreepivMaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final selectedLocale = ref.watch(appLocaleProvider);
    final effectiveLocale = selectedLocale?.flutterLocale ?? View.of(context).platformDispatcher.locale;

    return MaterialApp.router(
      title: context.t.app.title,
      theme: AppTheme.light(platform: defaultTargetPlatform, locale: effectiveLocale),
      darkTheme: AppTheme.dark(platform: defaultTargetPlatform, locale: effectiveLocale),
      themeMode: themeMode,
      locale: selectedLocale?.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return FontWarmUp(child: MobileDownloadFloatingWindow(child: child ?? const SizedBox.shrink()));
      },
    );
  }
}
