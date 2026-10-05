import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/i18n/strings.g.dart';

void main() {
  testWidgets('theme selector keeps selection and keyboard input usable across themes and widths', (tester) async {
    final previousHighlight = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = previousHighlight);

    for (final dark in [false, true]) {
      for (final width in [320.0, 800.0]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, 600);
          tester.view.devicePixelRatio = 1;
          var selected = ThemeMode.system;
          final theme = dark
              ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
              : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en'));
          final tokens = theme.extension<FrostThemeTokens>()!;

          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData.fromView(tester.view).copyWith(textScaler: TextScaler.linear(scale)),
                  child: StatefulBuilder(
                    builder: (context, setState) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: ThemeModeSelector(value: selected, onChanged: (mode) => setState(() => selected = mode)),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final track = tester.widget<DecoratedBox>(find.byKey(const ValueKey('theme-mode-track')));
          expect((track.decoration as BoxDecoration).color, tokens.surfaceInset);
          expect((track.decoration as BoxDecoration).border, isNull);
          final initialSelection = tester.widget<AnimatedContainer>(
            find.descendant(of: find.byKey(const ValueKey('theme-mode-system')), matching: find.byType(AnimatedContainer)).first,
          );
          expect((initialSelection.decoration as BoxDecoration).color, tokens.surfaceRaised);
          expect((initialSelection.decoration as BoxDecoration).border, isNull);
          expect(find.text(t.settings.theme.system), findsOneWidget);
          expect(find.text(t.settings.theme.light), findsOneWidget);
          expect(find.text(t.settings.theme.dark), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text(t.settings.theme.light));
          await tester.pumpAndSettle();
          expect(selected, ThemeMode.light);
          final changedSelection = tester.widget<AnimatedContainer>(
            find.descendant(of: find.byKey(const ValueKey('theme-mode-light')), matching: find.byType(AnimatedContainer)).first,
          );
          expect((changedSelection.decoration as BoxDecoration).color, tokens.surfaceRaised);

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
