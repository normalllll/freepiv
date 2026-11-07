import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/route_activity.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reader_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/custom/reader/reader_text.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

const _paragraph =
    'The boats came back late that evening, and the town waited on the pier as it always did, '
    'lanterns swinging in the wind, until the last sail turned the point and the harbour lights came on one by one.';

/// Three chapters of a dozen paragraphs each.
String _chapters({String title = 'Departure'}) => [
  for (final (index, name) in [title, 'Harbour', 'Return'].indexed)
    ['[chapter:$name]', for (var line = 0; line < 12; line++) '$_paragraph ${index + 1}.${line + 1}'].join('\n\n'),
].join('\n\n');

WebviewNovel _text(String body) {
  final sample = sampleNovelText(70000);
  return WebviewNovel(
    id: sample.id,
    title: sample.title,
    userId: sample.userId,
    coverUrl: sample.coverUrl,
    tags: sample.tags,
    caption: sample.caption,
    cdate: sample.cdate,
    rating: sample.rating,
    text: body,
    illusts: const [],
    images: const [],
    glossaryItems: const [],
    replaceableItemIds: const [],
    aiType: 0,
    isOriginal: true,
  );
}

Future<void> _mount(
  WidgetTester tester, {
  String? body,
  Map<String, dynamic> settings = const {'readerFontSize': 18.0, 'readerLineHeight': 1.6, 'readerAutoScrollSpeed': 60.0},
  Size size = desktopSize,
  double textScale = 1,
  String title = 'A novel',
}) {
  final novel = sampleNovels(count: 1, title: title).single;
  return mountPilotPage(
    tester,
    NovelReaderContent(
      detail: NovelDetailData(novel: novel, webviewNovel: _text(body ?? _chapters())),
    ),
    size: size,
    textScale: textScale,
    settings: settings,
    observers: [appRootRouteActivity],
  );
}

NovelReaderContentState _reader(WidgetTester tester) => tester.state<NovelReaderContentState>(find.byType(NovelReaderContent));

String _chapterTitle(WidgetTester tester) => tester.widget<FrostTitleMenu>(find.byKey(const ValueKey('reader-chapters'))).title;

ScrollPosition _position(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

void main() {
  testWidgets('the text takes the size and spacing from the saved settings', (tester) async {
    await _mount(tester, settings: const {'readerFontSize': 24.0, 'readerLineHeight': 2.0});
    final styles = tester.widgetList<ReaderParagraph>(find.byType(ReaderParagraph)).map((paragraph) => paragraph.typesetting.body);
    expect(styles, isNotEmpty);
    expect(styles.map((style) => (style.fontSize, style.height)), everyElement((24.0, 2.0)));
    final text = tester.widget<Text>(find.descendant(of: find.byType(ReaderParagraph).first, matching: find.byType(Text)));
    expect(text.style!.fontSize, 24);
    expect(text.style!.fontFamily, FrostTypography.of(tester.element(find.byType(ReaderParagraph).first)).style(FrostTextRole.body).fontFamily);
  });

  testWidgets('chapters: the menu, the bar buttons and the arrow keys move between them', (tester) async {
    await _mount(tester);
    expect(_chapterTitle(tester), t.novel.reader.chapterPosition(current: 1, total: 3));

    await tester.tap(find.bySemanticsLabel(t.novel.reader.nextChapter));
    await settlePilot(tester);
    expect(_reader(tester).currentChapter.index, 1);
    expect(_chapterTitle(tester), t.novel.reader.chapterPosition(current: 2, total: 3));
    final heading = tester.getTopLeft(find.text('Harbour'));
    expect(heading.dy, lessThan(desktopSize.height / 3), reason: 'the chapter starts at the top');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await settlePilot(tester);
    expect(_reader(tester).currentChapter.index, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await settlePilot(tester);
    expect(_reader(tester).currentChapter.index, 1);

    await tester.tap(find.byKey(const ValueKey('reader-chapters')));
    await settlePilot(tester);
    await tester.tap(find.text('Departure').last);
    await settlePilot(tester);
    expect(_reader(tester).currentChapter.index, 0);
  });

  testWidgets('the progress bar shows how far the reader is and moves there', (tester) async {
    await _mount(tester);
    FrostSlider slider() => tester.widget<FrostSlider>(find.byKey(const ValueKey('reader-progress')));
    expect(slider().value, 0);
    slider().onChanged!(.5);
    await settlePilot(tester);
    expect(_reader(tester).progress, closeTo(.5, .03));
    expect(slider().value, closeTo(.5, .03), reason: 'the bar follows');
    expect(slider().valueLabel!(.5), t.novel.reader.progressValue(percent: 50));
    expect(_reader(tester).currentChapter.index, 1, reason: 'half way is in the middle chapter');
  });

  testWidgets('auto scroll runs on through the chapters and pauses under a window-wide dialog', (tester) async {
    await _mount(tester);
    await tester.tap(find.byKey(const ValueKey('reader-auto-scroll')));
    await tester.pump();
    expect(_reader(tester).autoScrolling, isTrue);
    final start = _position(tester).pixels;
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final moved = _position(tester).pixels;
    expect(moved, greaterThan(start + 30), reason: '60 px/s for a second');

    final context = tester.element(find.byType(NovelReaderContent));
    showFrostDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => FrostDialog(title: 'Over the window', content: const SizedBox()),
    );
    await settlePilot(tester);
    expect(appRootRouteActivity.popupOnTop, isTrue);
    expect(_reader(tester).autoScrolling, isFalse);
    final paused = _position(tester).pixels;
    await tester.pump(const Duration(seconds: 1));
    expect(_position(tester).pixels, paused);
  });

  testWidgets('scrolling by hand stops auto scroll and hides the bars; a tap brings them back', (tester) async {
    await _mount(tester);
    await tester.tap(find.byKey(const ValueKey('reader-auto-scroll')));
    await settlePilot(tester, frames: 4);
    expect(_reader(tester).autoScrolling, isTrue);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await settlePilot(tester);
    expect(_reader(tester).autoScrolling, isFalse);
    bool barsShown() => _reader(tester).chromeVisible;
    expect(barsShown(), isFalse);
    await tester.tapAt(tester.getCenter(find.byType(CustomScrollView)));
    await settlePilot(tester);
    expect(barsShown(), isTrue);
  });

  testWidgets('a new text size keeps the paragraph being read at the top', (tester) async {
    await _mount(tester);
    await tester.tap(find.bySemanticsLabel(t.novel.reader.nextChapter));
    await settlePilot(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await settlePilot(tester);
    final before = _reader(tester).currentBlock;
    final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderContent)));
    container.read(readerSettingsProvider.notifier).setFontSize(26);
    await settlePilot(tester);
    expect(tester.widget<ReaderParagraph>(find.byType(ReaderParagraph).first).typesetting.body.fontSize, 26);
    expect(_reader(tester).currentBlock, before);
  });

  testWidgets('the reader sliders keep their labels above them', (tester) async {
    await _mount(tester);
    await tester.tap(find.byKey(const ValueKey('reader-settings')));
    await settlePilot(tester, frames: 10);
    final label = find.text(t.novel.reader.fontSize);
    final slider = find.byKey(const ValueKey('reader-font-size'));
    expect(tester.getSize(label).width, greaterThan(10));
    expect(tester.getBottomLeft(label).dy, lessThanOrEqualTo(tester.getTopLeft(slider).dy + 1));
    expectNoLayoutErrors(tester);
  });

  testWidgets('reopening the novel comes back to the same place', (tester) async {
    await _mount(tester);
    _reader(tester).goToChapter(2);
    await settlePilot(tester);
    final block = _reader(tester).currentBlock;
    await tester.pumpWidget(const SizedBox());
    await _mount(tester);
    expect(_reader(tester).currentBlock, block);
    expect(_reader(tester).currentChapter.index, 2);
  });

  testWidgets('reopening the novel takes the saved text size and spacing, not those it was last read with', (tester) async {
    await _mount(tester, settings: const {'readerFontSize': 18.0, 'readerLineHeight': 1.6});
    _reader(tester).goToChapter(1);
    await settlePilot(tester);
    await tester.pumpWidget(const SizedBox());
    // Changed elsewhere (another novel, the settings page) in the meantime.
    await _mount(tester, settings: const {'readerFontSize': 24.0, 'readerLineHeight': 2.0});
    final styles = tester.widgetList<ReaderParagraph>(find.byType(ReaderParagraph)).map((paragraph) => paragraph.typesetting.body);
    expect(styles, isNotEmpty);
    expect(styles.map((style) => (style.fontSize, style.height)), everyElement((24.0, 2.0)));
    expect(_reader(tester).currentChapter.index, 1, reason: 'the place is still restored');
  });

  testWidgets('the chapter keys do nothing on an empty text', (tester) async {
    await _mount(tester, body: '');
    for (final key in [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyD]) {
      await tester.sendKeyEvent(key);
      await settlePilot(tester, frames: 2);
    }
    expect(tester.takeException(), isNull);
    expect(find.text(t.novel.reader.emptyBody), findsOneWidget);
  });

  testWidgets('tapping an embedded work opens it and leaves the bars; tapping the text toggles them', (tester) async {
    await _mount(tester, body: ['$_paragraph 1', '[pixivimage:12345]', '$_paragraph 2'].join('\n\n'));
    final shown = _reader(tester).chromeVisible;
    await tester.tap(find.text(t.novel.reader.openEmbeddedWork));
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.illust(12345));
    final covered = tester.state<NovelReaderContentState>(find.byType(NovelReaderContent, skipOffstage: false));
    expect(covered.chromeVisible, shown, reason: 'the button acts on the work alone');

    await _mount(tester, body: ['$_paragraph 1', '[pixivimage:12345]', '$_paragraph 2'].join('\n\n'));
    await tester.tap(find.textContaining('$_paragraph 2'));
    await settlePilot(tester);
    expect(_reader(tester).chromeVisible, !shown, reason: 'the text toggles them');
  });

  testWidgets('Escape leaves the reader for the novel', (tester) async {
    await _mount(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.novel(70000));
  });

  testWidgets('an empty text says so', (tester) async {
    await _mount(tester, body: '');
    expect(find.text(t.novel.reader.emptyBody), findsOneWidget);
  });

  testWidgets('a long title and the bars fit a phone at double text size', (tester) async {
    await _mount(
      tester,
      size: phoneSize,
      textScale: 2,
      title: longText,
      body: _chapters(title: longText),
    );
    expectNoLayoutErrors(tester);
  });

  test('the reader strings exist in all four languages', () => expectLocalesComplete(['novel']));
}
