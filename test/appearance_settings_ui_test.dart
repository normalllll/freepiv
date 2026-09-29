import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/appearance_settings.dart';
import 'package:freepiv/features/settings/presentation/appearance_settings_section.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/i18n/strings.g.dart';

class _MemoryStore implements AppSettingsStore {
  _MemoryStore([Map<String, dynamic>? initial]) : values = {...?initial};
  final Map<String, dynamic> values;

  @override
  Map<String, dynamic> load() => {...values};

  @override
  Future<void> write(String key, dynamic value) async => values[key] = value;
}

class _AppearanceHarness extends ConsumerWidget {
  const _AppearanceHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appearanceProvider).settings.mode;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AppearanceSettingsSection(
          modeSelector: ThemeModeSelector(value: mode, onChanged: (next) => ref.read(appearanceProvider.notifier).setMode(next)),
        ),
      ),
    );
  }
}

Future<void> _pumpAppearance(WidgetTester tester, {required double width, required double scale}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          locale: LocaleSettings.currentLocale.flutterLocale,
          theme: AppTheme.light(platform: TargetPlatform.windows, locale: LocaleSettings.currentLocale.flutterLocale),
          home: MediaQuery(
            data: MediaQueryData.fromView(tester.view).copyWith(textScaler: TextScaler.linear(scale)),
            child: const Scaffold(body: _AppearanceHarness()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSettingsPage(WidgetTester tester, {required double width, required double height, required double scale}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          locale: LocaleSettings.currentLocale.flutterLocale,
          theme: AppTheme.light(platform: TargetPlatform.windows, locale: LocaleSettings.currentLocale.flutterLocale),
          builder: (context, child) => MediaQuery(
            data: MediaQueryData.fromView(tester.view).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const SettingsPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    LocaleSettings.setLocaleSync(AppLocale.enUs);
  });

  testWidgets('appearance labels and controls fit narrow and wide layouts in every locale', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final locale in AppLocale.values) {
      await tester.runAsync(() => LocaleSettings.setLocale(locale));
      for (final width in [320.0, 360.0, 390.0, 800.0]) {
        for (final scale in [1.0, 2.0]) {
          await AppSettings.initialize(store: _MemoryStore());
          await _pumpAppearance(tester, width: width, scale: scale);
          expect(find.text(t.settings.theme.title), findsOneWidget, reason: '$locale, $width, $scale');
          expect(find.text(t.settings.theme.displayMode), findsOneWidget, reason: '$locale, $width, $scale');
          expect(find.text(t.settings.theme.tone), findsOneWidget, reason: '$locale, $width, $scale');
          expect(find.text(t.settings.theme.custom), findsOneWidget, reason: '$locale, $width, $scale');
          final exception = tester.takeException();
          expect(exception, isNull, reason: '$locale, $width, $scale');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
  });

  testWidgets('custom editor keeps fields and actions usable at narrow widths and large text', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final locale in AppLocale.values) {
      await tester.runAsync(() => LocaleSettings.setLocale(locale));
      for (final width in [320.0, 360.0, 390.0, 800.0]) {
        for (final scale in [1.0, 2.0]) {
          await AppSettings.initialize(store: _MemoryStore());
          await _pumpAppearance(tester, width: width, scale: scale);
          await tester.ensureVisible(find.text(t.settings.theme.custom));
          await tester.tap(find.text(t.settings.theme.custom));
          await tester.pumpAndSettle();
          expect(find.text(t.settings.theme.editLightAccent), findsOneWidget, reason: '$locale, $width, $scale');
          expect(find.byType(TextField), findsOneWidget, reason: '$locale, $width, $scale');
          expect(find.text(t.common.cancel), findsOneWidget, reason: '$locale, $width, $scale');
          expect(tester.takeException(), isNull, reason: '$locale, $width, $scale');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
  });

  testWidgets('system hint takes room only while following the system, and settles smoothly', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    LocaleSettings.setLocaleSync(AppLocale.enUs);
    await AppSettings.initialize(store: _MemoryStore());
    await _pumpAppearance(tester, width: 390, scale: 1);
    final systemHeight = tester.getSize(find.byType(AppearanceSettingsSection)).height;
    await tester.tap(find.text(t.settings.theme.light).first);
    await tester.pumpAndSettle();
    final manualHeight = tester.getSize(find.byType(AppearanceSettingsSection)).height;
    expect(find.text(t.settings.theme.systemNeutralHint), findsNothing);
    expect(manualHeight, lessThan(systemHeight), reason: 'two hint lines are gone, not reserved');
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile editor actions stay above the keyboard at two times text', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    LocaleSettings.setLocaleSync(AppLocale.enUs);
    await AppSettings.initialize(store: _MemoryStore());
    await _pumpAppearance(tester, width: 320, scale: 2);
    await tester.ensureVisible(find.text(t.settings.theme.custom));
    await tester.tap(find.text(t.settings.theme.custom));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '#FFFFFF');
    tester.view.viewInsets = const FakeViewPadding(bottom: 350);
    await tester.pumpAndSettle();
    final keyboardTop = tester.view.physicalSize.height - tester.view.viewInsets.bottom;
    final cancelButton = find.ancestor(of: find.text(t.common.cancel), matching: find.byType(TextButton)).last;
    expect(tester.getBottomLeft(cancelButton).dy, lessThan(keyboardTop));
    expect(tester.getBottomLeft(find.byType(FilledButton).last).dy, lessThan(keyboardTop));
    expect(find.text(t.settings.theme.rejectedLight), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor rejects unsafe HEX and applies exact color with target tone preview', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    LocaleSettings.setLocaleSync(AppLocale.enUs);
    const chosen = Color(0xFF4C8DFF);
    final settings = AppearanceSettings(mode: ThemeMode.light, lightTone: AppearanceTone.cool);
    await AppSettings.initialize(store: _MemoryStore({'appearance': settings.toRecord()}));
    await _pumpAppearance(tester, width: 800, scale: 1);
    await tester.tap(find.text(t.settings.theme.custom));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '#FFFFFF');
    await tester.pump();
    expect(find.text(t.settings.theme.rejectedLight), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed, isNull);
    final container = ProviderScope.containerOf(tester.element(find.byType(_AppearanceHarness)));
    expect(container.read(appearanceProvider).settings.lightAccent, FreepivThemeTokens.brandPink);

    await tester.enterText(find.byType(TextField).last, '#4c8dff');
    await tester.pump();
    final icon = tester.widget<Icon>(find.byIcon(Icons.favorite).last);
    final palette = FreepivThemeTokens.palette(Brightness.light, AppearanceTone.cool, chosen);
    expect(icon.color, palette.keyGraphicOn(palette.canvas));
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider).settings.lightAccent, chosen);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('actual SettingsPage appearance and dialog fit desktop windows in every locale', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final locale in AppLocale.values) {
      await tester.runAsync(() => LocaleSettings.setLocale(locale));
      for (final width in [800.0, 1024.0, 1440.0]) {
        for (final height in [600.0, 900.0]) {
          for (final scale in [1.0, 2.0]) {
            await AppSettings.initialize(store: _MemoryStore());
            await _pumpSettingsPage(tester, width: width, height: height, scale: scale);
            expect(find.byType(SettingsPage), findsOneWidget, reason: '$locale, $width×$height, $scale');
            expect(find.byType(AppearanceSettingsSection), findsOneWidget, reason: '$locale, $width×$height, $scale');
            expect(tester.takeException(), isNull, reason: '$locale, $width×$height, $scale appearance');
            await tester.dragUntilVisible(find.text(t.settings.theme.custom), find.byType(ListView).last, const Offset(0, -250));
            await tester.pumpAndSettle();
            await tester.tap(find.text(t.settings.theme.custom));
            await tester.pumpAndSettle();
            expect(find.byType(Dialog), findsOneWidget, reason: '$locale, $width×$height, $scale');
            expect(find.text(t.settings.theme.editLightAccent), findsOneWidget, reason: '$locale, $width×$height, $scale');
            expect(tester.takeException(), isNull, reason: '$locale, $width×$height, $scale editor');
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }
      }
    }
  });

  testWidgets('desktop SettingsPage editor handles hover, Tab, Escape, cancel, and apply', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    LocaleSettings.setLocaleSync(AppLocale.enUs);
    await AppSettings.initialize(store: _MemoryStore());
    await _pumpSettingsPage(tester, width: 1024, height: 600, scale: 1);
    final custom = find.text(t.settings.theme.custom);
    await tester.dragUntilVisible(custom, find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(custom));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(custom);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final dialogFocus = FocusManager.instance.primaryFocus;
    expect(dialogFocus, isNotNull);
    expect(dialogFocus!.context!.findAncestorWidgetOfExactType<Dialog>(), isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(custom);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(custom);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '#4C8DFF');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(SettingsPage)));
    expect(container.read(appearanceProvider).settings.lightAccent, const Color(0xFF4C8DFF));
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
