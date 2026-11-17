import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_appearance_panel.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_paged_view.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/custom/reader/reader_paragraph.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

void main() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  Future<void> mount(WidgetTester tester, {Map<String, dynamic> settings = readerScrollSettings, Size size = desktopSize}) =>
      mountReader(tester, history, settings: settings, size: size);

  Future<void> openPanel(WidgetTester tester) async {
    await showReaderBars(tester);
    await tester.tap(find.byKey(const ValueKey('reader-settings')));
    await settlePilot(tester, frames: 10);
  }

  ReaderSettings settings(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(ReaderAppearancePanel))).read(readerSettingsProvider);

  testWidgets('offers every setting; the animation and the scroll speed belong to their page mode', (tester) async {
    await mount(tester);
    await openPanel(tester);
    for (final key in [
      'reader-font-size',
      'reader-theme',
      'reader-font',
      'reader-line-spacing',
      'reader-margins',
      'reader-page-mode',
      'reader-tap-zones',
      'reader-indent',
      'reader-scroll-speed',
      'reader-shortcuts',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    expect(find.byKey(const ValueKey('reader-page-animation')), findsNothing, reason: 'scrolling does not turn pages');
    expect(find.byKey(const ValueKey('reader-volume-keys')), findsOneWidget, reason: 'the test platform is Android, which has volume keys');
    expect(tester.widgetList(find.byType(FrostColorSwatch)).length, ReaderTheme.values.length, reason: 'a swatch for each theme, in its colours');
    final r = t.novel.reader;
    for (final label in [r.fontSize, r.theme, r.font, r.lineHeight, r.margins, r.pageMode, r.tapZones, r.indent, r.autoScrollSpeed, r.shortcuts]) {
      expect(find.text(label), findsWidgets, reason: 'a visible label: $label');
    }
    expect(
      tester.widget<FrostText>(find.byKey(const ValueKey('reader-font-size-value'))).data,
      '${settings(tester).textSize.round()}',
      reason: 'the size is shown',
    );
    for (final name in [r.themeApp, r.themeWhite, r.themePaper, r.themeGreen, r.themeNight, r.themeBlack]) {
      expect(find.bySemanticsLabel(name), findsWidgets, reason: 'a swatch named $name');
    }
    expectNoLayoutErrors(tester);

    await tester.tap(find.text(t.novel.reader.pageModePaged));
    await settlePilot(tester);
    expect(settings(tester).pageMode, ReaderPageMode.paged);
    expect(find.byType(ReaderPagedView), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-page-animation')), findsOneWidget);
    expect(find.text(r.pageAnimation), findsWidgets, reason: 'the animation row has its label');
    expect(find.byKey(const ValueKey('reader-scroll-speed')), findsNothing, reason: 'there is no auto scroll in pages');
  });

  testWidgets('every change applies at once and the text keeps its place', (tester) async {
    await mount(tester);
    final controller = readerController(tester);
    controller.goToChapter(1);
    await settlePilot(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await settlePilot(tester);
    final offset = controller.offset;
    await openPanel(tester);

    Future<void> expectKept(String what) async {
      await settlePilot(tester);
      expect(controller.offset, offset, reason: what);
      expect(tester.takeException(), isNull, reason: what);
    }

    TextStyle body() => tester.widget<ReaderParagraph>(find.byType(ReaderParagraph).first).typesetting.body;

    final before = body().fontSize!;
    ProviderScope.containerOf(tester.element(find.byType(ReaderAppearancePanel))).read(readerSettingsProvider.notifier).setTextSize(before + 4);
    await expectKept('text size');
    expect(body().fontSize, before + 4);

    await tester.tap(find.text(t.novel.reader.lineSpacingRelaxed));
    await expectKept('line spacing');
    expect(body().height, ReaderLineSpacing.relaxed.lineHeight);

    await tester.tap(find.text(t.novel.reader.marginsWide));
    await expectKept('margins');
    expect(settings(tester).margins, ReaderMargins.wide);

    await tester.tap(find.text(t.novel.reader.fontSerif));
    await expectKept('font');
    expect(settings(tester).font, ReaderFont.serif);

    await tester.tap(find.bySemanticsLabel(t.novel.reader.themeNight));
    await expectKept('theme');
    expect(settings(tester).theme, ReaderTheme.night);
    expect(body().color, isNot(const Color(0xFFFFFFFF)));

    await tester.tap(find.byKey(const ValueKey('reader-indent')));
    await expectKept('indent');
    expect(settings(tester).indent, isFalse);

    await tester.tap(find.text(t.novel.reader.tapZonesForward));
    await expectKept('tap zones');
    expect(settings(tester).tapZones, ReaderTapZones.forward);
  });

  testWidgets('the auto scroll speed is one of five named steps, kept as the step', (tester) async {
    await mount(tester);
    await openPanel(tester);
    final slider = find.byKey(const ValueKey('reader-scroll-speed'));
    expect(tester.widget<FrostSlider>(slider).divisions, 4);
    final names = [t.novel.reader.speedVerySlow, t.novel.reader.speedSlow, t.novel.reader.speedNormal, t.novel.reader.speedFast, t.novel.reader.speedVeryFast];
    expect(settings(tester).autoScrollSpeed, ReaderAutoScrollSpeed.fast, reason: 'the saved step');
    for (final (index, step) in ReaderAutoScrollSpeed.values.indexed) {
      expect(tester.widget<FrostSlider>(slider).valueLabel!(index.toDouble()), names[index]);
      tester.widget<FrostSlider>(slider).onChanged!(index.toDouble());
      await settlePilot(tester, frames: 2);
      expect(settings(tester).autoScrollSpeed, step);
      expect(AppSettings.readerAutoScrollSpeed, step);
    }
  });

  testWidgets('the shortcuts row and the more menu open the list of keys', (tester) async {
    await mount(tester);
    await openPanel(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('reader-shortcuts')));
    await tester.tap(find.byKey(const ValueKey('reader-shortcuts')));
    await settlePilot(tester);
    expect(find.byType(ReaderShortcutsList), findsOneWidget);
    expect(find.text('Space · → · PgDn'), findsOneWidget);
    expect(find.descendant(of: find.byType(ReaderShortcutsList), matching: find.text(t.novel.reader.shortcutContents)), findsOneWidget);
    expectNoLayoutErrors(tester);
  });

  testWidgets('the more menu lists the shortcuts too', (tester) async {
    await mount(tester);
    await showReaderBars(tester);
    await tester.tap(find.byKey(const ValueKey('reader-more')));
    await settlePilot(tester);
    for (final label in [t.novel.reader.openDetail, t.novel.reader.comments, t.novel.reader.copyLink, t.novel.reader.shortcuts]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tester.tap(find.text(t.novel.reader.shortcuts));
    await settlePilot(tester);
    expect(find.byType(ReaderShortcutsList), findsOneWidget);
  });

  group('the shortcuts hint', () {
    testWidgets('shows once on a desktop and is remembered', (tester) async {
      await mount(tester, settings: {...readerScrollSettings, 'readerShortcutsHintSeen': false});
      await settlePilot(tester, frames: 4);
      expect(find.text(t.novel.reader.shortcutsHint), findsOneWidget);
      expect(AppSettings.readerShortcutsHintSeen, isTrue);

      await tester.pumpWidget(const SizedBox());
      await mount(tester, settings: {...readerScrollSettings, 'readerShortcutsHintSeen': true});
      await settlePilot(tester, frames: 4);
      expect(find.text(t.novel.reader.shortcutsHint), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    testWidgets('never shows on a phone', (tester) async {
      await mount(tester, settings: {...readerScrollSettings, 'readerShortcutsHintSeen': false}, size: phoneSize);
      await settlePilot(tester, frames: 4);
      expect(find.text(t.novel.reader.shortcutsHint), findsNothing);
      expect(AppSettings.readerShortcutsHintSeen, isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  test('the reader strings exist in all four languages', () => expectLocalesComplete(['novel']));
}
