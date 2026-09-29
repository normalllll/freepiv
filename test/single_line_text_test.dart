import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';

/// Every ranking mode label, in the order the pickers list them.
List<String> _rankingModeLabels() {
  final modes = t.ranking.modes;
  return [
    modes.day,
    modes.dayR18,
    modes.dayMale,
    modes.dayMaleR18,
    modes.dayFemale,
    modes.dayFemaleR18,
    modes.dayAi,
    modes.dayR18Ai,
    modes.week,
    modes.weekR18,
    modes.weekR18G,
    modes.weekOriginal,
    modes.weekRookie,
    modes.month,
  ];
}

/// Asserts the acceptance rule for text in supported test environments: one
/// line, nothing wrapped, clipped or shortened with an ellipsis.
void expectSingleLineTexts(WidgetTester tester, Finder scope, {required String reason}) {
  final paragraphs = tester.renderObjectList<RenderParagraph>(find.descendant(of: scope, matching: find.byType(RichText)));
  expect(paragraphs, isNotEmpty, reason: reason);
  for (final paragraph in paragraphs) {
    final text = paragraph.text.toPlainText();
    expect(paragraph.didExceedMaxLines, isFalse, reason: '$reason: "$text" is cut off');
    final lines = paragraph.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.length)).map((box) => box.top).toSet();
    expect(lines.length, lessThanOrEqualTo(1), reason: '$reason: "$text" wraps');
  }
}

/// Loads the fonts the app ships, so widths are real rather than the square
/// glyphs of the default test font.
Future<void> _loadAppFonts() async {
  for (final (family, asset) in [('Noto Sans SC', 'assets/fonts/NotoSansSC-Subset.ttf'), ('Noto Sans JP', 'assets/fonts/NotoSansJP-Subset.ttf')]) {
    await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
  }
}

void main() {
  setUpAll(_loadAppFonts);

  testWidgets('ranking mode picker stays on one line in every language at supported phone widths', (tester) async {
    addTearDown(() => LocaleSettings.setLocale(AppLocale.enUs));
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final locale in AppLocale.values) {
      LocaleSettings.setLocale(locale);
      final labels = _rankingModeLabels();
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        for (final scale in [1.0, 1.3]) {
          tester.view.physicalSize = Size(width, 800);
          final heights = <double>{};
          for (final (index, label) in labels.indexed) {
            final key = GlobalKey();
            await tester.pumpWidget(
              TranslationProvider(
                child: MaterialApp(
                  theme: AppTheme.light(platform: TargetPlatform.android, locale: locale.flutterLocale),
                  home: MediaQuery(
                    data: MediaQueryData(size: Size(width, 800), textScaler: TextScaler.linear(scale)),
                    child: Scaffold(
                      // The ranking header row: the page inset minus the
                      // picker's own padding on each side.
                      body: Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppMetrics.browseInset(width) - 12, vertical: 8),
                        child: Row(
                          key: key,
                          children: [
                            AppValueMenuButton<int>(
                              value: index,
                              items: [for (final (value, item) in labels.indexed) AppSelectItem(value: value, label: item)],
                              onSelected: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            final reason = '$locale $width ${scale}x "$label"';
            expect(tester.takeException(), isNull, reason: reason);
            expectSingleLineTexts(tester, find.byType(AppValueMenuButton<int>), reason: reason);
            heights.add(tester.getSize(find.byKey(key)).height);
          }
          // Whatever the chosen mode, the header row keeps one height.
          expect(heights, hasLength(1), reason: '$locale $width ${scale}x');
        }
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
