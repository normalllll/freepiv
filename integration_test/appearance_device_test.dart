import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

class _MemoryStore implements AppSettingsStore {
  final Map<String, dynamic> values = {};
  @override
  Map<String, dynamic> load() => {...values};
  @override
  Future<void> write(String key, dynamic value) async => values[key] = value;
}

class _DeviceAppearanceApp extends ConsumerStatefulWidget {
  const _DeviceAppearanceApp();

  @override
  ConsumerState<_DeviceAppearanceApp> createState() => _DeviceAppearanceAppState();
}

/// The settings page in the app's own host, following the appearance it edits.
class _DeviceAppearanceAppState extends ConsumerState<_DeviceAppearanceApp> {
  final _router = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const SettingsPage())]);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FrostApp.router(
    config: freepivFrostConfig,
    title: 'freepiv',
    locale: const Locale('en', 'US'),
    appearance: ref.watch(appearanceProvider).settings,
    routerConfig: _router,
  );
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
    await tester.enterText(find.byType(FrostTextField).last, '#FFFFFF');
    await tester.pumpAndSettle();
    expect(find.text(t.settings.theme.rejectedLight), findsOneWidget);
    final apply = find.widgetWithText(FrostButton, t.common.apply);
    expect(tester.widget<FrostButton>(apply).onPressed, isNull);
    final media = MediaQuery.of(tester.element(find.text(t.settings.theme.rejectedLight)));
    final keyboardTop = media.size.height - media.viewInsets.bottom;
    expect(tester.getBottomLeft(apply).dy, lessThan(keyboardTop));
    expect(tester.getBottomLeft(find.widgetWithText(FrostButton, t.common.cancel)).dy, lessThan(keyboardTop));
    debugPrint('APPEARANCE_DEVICE_STAGE: unsafe_rejected');
  });
}
