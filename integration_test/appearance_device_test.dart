import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:integration_test/integration_test.dart';

class _MemoryStore implements AppSettingsStore {
  final Map<String, dynamic> values = {};
  @override
  Map<String, dynamic> load() => {...values};
  @override
  Future<void> write(String key, dynamic value) async => values[key] = value;
}

class _DeviceAppearanceApp extends ConsumerWidget {
  const _DeviceAppearanceApp();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider).settings;
    const locale = Locale('en', 'US');
    return MaterialApp(
      locale: locale,
      theme: FrostTheme.build(
        config: freepivFrostConfig,
        brightness: Brightness.light,
        platform: defaultTargetPlatform,
        locale: locale,
        tone: appearance.effectiveToneFor(Brightness.light),
        accent: appearance.lightAccent,
      ),
      darkTheme: FrostTheme.build(
        config: freepivFrostConfig,
        brightness: Brightness.dark,
        platform: defaultTargetPlatform,
        locale: locale,
        tone: appearance.effectiveToneFor(Brightness.dark),
        accent: appearance.darkAccent,
      ),
      themeMode: appearance.mode,
      home: const SettingsPage(),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real settings page mode, tone and unsafe color on device', (tester) async {
    await AppSettings.initialize(store: _MemoryStore());
    LocaleSettings.setLocale(AppLocale.enUs);
    await tester.pumpWidget(ProviderScope(child: TranslationProvider(child: const _DeviceAppearanceApp())));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    void expectCanvas(Color expected) {
      expect(FrostThemeTokens.of(tester.element(find.byType(SettingsPage))).canvas, expected);
      expect(tester.takeException(), isNull);
    }

    final systemBrightness = MediaQuery.platformBrightnessOf(tester.element(find.byType(SettingsPage)));
    expectCanvas(systemBrightness == Brightness.dark ? const Color(0xFF202124) : const Color(0xFFF6F6F6));
    debugPrint('APPEARANCE_DEVICE_STAGE: initial');

    await tester.tap(find.text(t.settings.theme.light).first);
    await tester.pumpAndSettle();
    expectCanvas(const Color(0xFFF6F6F6));
    await tester.tap(find.text(t.settings.theme.cool).first);
    await tester.pumpAndSettle();
    expectCanvas(const Color(0xFFF4F7FA));
    debugPrint('APPEARANCE_DEVICE_STAGE: light_cool');

    await tester.tap(find.text(t.settings.theme.warm).first);
    await tester.pumpAndSettle();
    expectCanvas(const Color(0xFFF7F7F4));
    await tester.tap(find.text(t.settings.theme.cool).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.settings.theme.dark).first);
    await tester.pumpAndSettle();
    expectCanvas(const Color(0xFF202124));
    await tester.tap(find.text(t.settings.theme.cool).first);
    await tester.pumpAndSettle();
    expectCanvas(const Color(0xFF1B2026));
    await tester.tap(find.text(t.settings.theme.warm).first);
    await tester.pumpAndSettle();
    expectCanvas(const Color(0xFF20201E));
    debugPrint('APPEARANCE_DEVICE_STAGE: dark_warm');

    await tester.tap(find.text(t.settings.theme.light).first);
    await tester.pumpAndSettle();
    expectCanvas(const Color(0xFFF4F7FA));
    final appearance = ProviderScope.containerOf(tester.element(find.byType(SettingsPage))).read(appearanceProvider).settings;
    expect(appearance.lightTone, FrostTone.cool);
    expect(appearance.darkTone, FrostTone.warm);

    await tester.ensureVisible(find.text(t.settings.theme.custom));
    await tester.tap(find.text(t.settings.theme.custom));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '#FFFFFF');
    await tester.pumpAndSettle();
    expect(find.text(t.settings.theme.rejectedLight), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed, isNull);
    final media = MediaQuery.of(tester.element(find.text(t.settings.theme.rejectedLight)));
    final keyboardTop = media.size.height - media.viewInsets.bottom;
    expect(tester.getBottomLeft(find.byType(FilledButton).last).dy, lessThan(keyboardTop));
    expect(tester.getBottomLeft(find.widgetWithText(TextButton, t.common.cancel)).dy, lessThan(keyboardTop));
    debugPrint('APPEARANCE_DEVICE_STAGE: unsafe_rejected');
  });
}
