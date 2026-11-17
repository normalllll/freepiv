import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/route_activity.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/dev/sample_novel_text.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/presentation/novel_download_source.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reader_page.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_controller.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_paged_view.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_scroll_view.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';
import 'package:freepiv/ui/custom/reader/reader_progress_track.dart';
import 'package:freepiv/ui/custom/reader/reader_text.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';

const _paragraph =
    'The boats came back late that evening, and the town waited on the pier as it always did, '
    'lanterns swinging in the wind, until the last sail turned the point and the harbour lights came on one by one.';

/// Three chapters of a dozen paragraphs each.
String _chapters({String title = 'Departure'}) => [
  for (final (index, name) in [title, 'Harbour', 'Return'].indexed)
    ['[chapter:$name]', for (var line = 0; line < 12; line++) '$_paragraph ${index + 1}.${line + 1}'].join('\n\n'),
].join('\n\n');

/// The last chapter is shorter than a screen.
final _withCoda = '${_chapters()}\n\n[chapter:Coda]\n\n$_paragraph';

const _works = [
  WebviewNovelEmbeddedWork(key: '12345', illustId: 12345, page: 1, visible: true, title: 'A work', xRestrict: 0, userId: '1', userName: 'Someone'),
];

const _scrollSettings = <String, dynamic>{'readerFontSize': 18.0, 'readerLineSpacing': 'regular', 'readerAutoScrollStep': 'fast'};
const _pagedSettings = <String, dynamic>{..._scrollSettings, 'readerPageMode': 'paged', 'readerPageAnimation': 'slide'};

WebviewNovel _text(String body, {List<WebviewNovelEmbeddedWork> works = const []}) {
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
    illusts: works,
    images: sample.images,
    glossaryItems: const [],
    replaceableItemIds: const [],
    aiType: 0,
    isOriginal: true,
  );
}

/// The browsing history, kept between the mounts of one test: where the
/// reader stopped is stored in it.
late HistoryRepository _history;

Future<void> _mount(
  WidgetTester tester, {
  String? body,
  Map<String, dynamic> settings = _scrollSettings,
  Size size = desktopSize,
  double textScale = 1,
  String title = 'A novel',
  List<WebviewNovelEmbeddedWork> works = const [],
}) async {
  // The place of the last reading is written and read on real time.
  await _storageIdle(tester);
  final novel = sampleNovels(count: 1, title: title).single;
  await mountPilotPage(
    tester,
    DownloadSourceScope(
      source: novelDownloadSource(novel),
      child: NovelReaderContent(
        detail: NovelDetailData(
          novel: novel,
          webviewNovel: _text(body ?? _chapters(), works: works),
        ),
      ),
    ),
    size: size,
    textScale: textScale,
    settings: {...sampleSettings, ...settings},
    observers: [appRootRouteActivity],
    history: _history,
  );
  await _storageIdle(tester);
  await settlePilot(tester);
}

Future<void> _storageIdle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
}

NovelReaderContentState _reader(WidgetTester tester) => tester.state<NovelReaderContentState>(find.byType(NovelReaderContent));

ReaderController _controller(WidgetTester tester) => _reader(tester).controller!;

/// The title between the chapter buttons of the bottom panel.
String _chapterTitle(WidgetTester tester) => tester.widget<FrostText>(find.byKey(const ValueKey('reader-chapter-title'))).data!;

/// Shows the bars the way a tap in the middle does.
Future<void> _showBars(WidgetTester tester) async {
  _reader(tester).chrome.show();
  await settlePilot(tester);
}

ScrollPosition _position(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

ReaderPagedViewState _paged(WidgetTester tester) => tester.state<ReaderPagedViewState>(find.byType(ReaderPagedView));

/// The model offset at the start of the visual line holding [offset].
int _lineStart(ReaderLayout layout, int offset) {
  final lines = layout.metricsOf(layout.model.blockAt(offset)).lines;
  return lines.lastWhere((line) => line.startOffset <= offset, orElse: () => lines.first).startOffset;
}

/// The model offset of the line at the reading line of the scroll view.
int _readingLine(WidgetTester tester) => _reader(tester).layout!.offsetAtPixel(_position(tester).pixels);

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await settlePilot(tester, frames: 6);
}

void main() {
  setUp(() => _history = useMemoryHistory());

  testWidgets('the text takes the size and spacing from the saved settings', (tester) async {
    await _mount(tester, settings: const {'readerFontSize': 24.0, 'readerLineSpacing': 'relaxed'});
    final styles = tester.widgetList<ReaderParagraph>(find.byType(ReaderParagraph)).map((paragraph) => paragraph.typesetting.body);
    expect(styles, isNotEmpty);
    expect(styles.map((style) => (style.fontSize, style.height)), everyElement((24.0, ReaderLineSpacing.relaxed.lineHeight)));
    final text = tester.widget<Text>(find.descendant(of: find.byType(ReaderParagraph).first, matching: find.byType(Text)));
    expect(text.style!.fontSize, 24);
    expect(text.style!.fontFamily, FrostTypography.of(tester.element(find.byType(ReaderParagraph).first)).style(FrostTextRole.body).fontFamily);
  });

  testWidgets('the bars lie over the text, which starts below a status line', (tester) async {
    await _mount(tester);
    expect(_reader(tester).chromeVisible, isFalse, reason: 'the reader opens with the bars hidden');
    final text = tester.getRect(find.byType(ReaderScrollView));
    expect(text.top, lessThan(60), reason: 'only the status line is above the text');
    expect(text.bottom, greaterThan(desktopSize.height - 60));
    expect(find.text('Departure'), findsWidgets, reason: 'the chapter is named in the status line');
    await _showBars(tester);
    expect(tester.getRect(find.byType(ReaderScrollView)), text, reason: 'the bars lie over the text and do not move it');
  });

  testWidgets('the top bar names the novel with its series and author; a phone keeps both lines', (tester) async {
    for (final size in [desktopSize, phoneSize]) {
      await _mount(tester, size: size);
      await _showBars(tester);
      final novel = _reader(tester).widget.detail.novel;
      expect(find.text('A novel'), findsOneWidget);
      expect(find.text('${novel.series.title} · ${novel.user.name}'), findsOneWidget);
      expect(find.byKey(const ValueKey('reader-chapters')), findsNothing, reason: 'the contents live in the sidebar');
      expectNoLayoutErrors(tester);
    }
  });

  testWidgets('large text on a phone keeps the top bar in one row, the bookmark beside the title', (tester) async {
    await _mount(tester, size: phoneSize, textScale: 2, body: '${_chapters()}\n\n[newpage]\n\n$_paragraph');
    await _showBars(tester);
    expect(find.byKey(const ValueKey('reader-marker')), findsOneWidget);
    expectNoLayoutErrors(tester);
  });

  testWidgets('chapters: the bar buttons and the bracket keys move between them', (tester) async {
    await _mount(tester);
    await _showBars(tester);
    expect(_chapterTitle(tester), 'Departure');

    await tester.tap(find.bySemanticsLabel(t.novel.reader.nextChapter));
    await settlePilot(tester);
    expect(_reader(tester).currentChapter.index, 1);
    expect(_reader(tester).chromeVisible, isTrue, reason: 'a button of the bar leaves the bars where they are');
    expect(_chapterTitle(tester), 'Harbour');
    final heading = tester.getTopLeft(find.descendant(of: find.byType(ReaderScrollView), matching: find.text('Harbour')).first);
    expect(heading.dy, lessThan(desktopSize.height / 3), reason: 'the chapter starts at the top');

    await _key(tester, LogicalKeyboardKey.bracketRight);
    expect(_reader(tester).currentChapter.index, 2);
    expect(_reader(tester).chromeVisible, isFalse, reason: 'a key hides the bars');
    await _key(tester, LogicalKeyboardKey.bracketLeft);
    expect(_reader(tester).currentChapter.index, 1);

    await _showBars(tester);
    await tester.tap(find.bySemanticsLabel(t.novel.reader.previousChapter));
    await settlePilot(tester);
    expect(_reader(tester).currentChapter.index, 0);
    expect(tester.widget<FrostButton>(find.widgetWithText(FrostButton, t.novel.reader.previousChapter)).onPressed, isNull, reason: 'none before the first');
  });

  testWidgets('the progress track shows how far the reader is and moves there', (tester) async {
    await _mount(tester);
    await _showBars(tester);
    ReaderProgressTrack track() => tester.widget<ReaderProgressTrack>(find.byKey(const ValueKey('reader-progress')));
    expect(track().progress(), 0);
    track().onChanged!(.5);
    await settlePilot(tester);
    expect(_reader(tester).progress, closeTo(.5, .01));
    expect(track().progress(), closeTo(.5, .01), reason: 'the track follows');
    expect(track().valueLabel(.5), t.novel.reader.progressValue(percent: 50));
    expect(_reader(tester).currentChapter.index, 1, reason: 'half way is in the middle chapter');
  });

  group('keyboard', () {
    testWidgets('scroll mode: screens, lines, chapters, start and end', (tester) async {
      await _mount(tester);
      final controller = _controller(tester);
      final line = _reader(tester).layout!.typesetting.bodyLinePx;

      for (final key in [LogicalKeyboardKey.space, LogicalKeyboardKey.pageDown, LogicalKeyboardKey.arrowRight]) {
        final before = _position(tester).pixels;
        await _key(tester, key);
        expect(_position(tester).pixels, greaterThan(before + 200), reason: '${key.keyLabel} goes a screen on');
      }
      for (final key in [LogicalKeyboardKey.pageUp, LogicalKeyboardKey.arrowLeft]) {
        final before = _position(tester).pixels;
        await _key(tester, key);
        expect(_position(tester).pixels, lessThan(before - 200), reason: '${key.keyLabel} goes a screen back');
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      final beforeShift = _position(tester).pixels;
      await _key(tester, LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(_position(tester).pixels, lessThan(beforeShift - 200), reason: 'Shift+Space goes a screen back');

      var before = _position(tester).pixels;
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_position(tester).pixels, closeTo(before + 3 * line, .5), reason: 'Down scrolls three lines');
      before = _position(tester).pixels;
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_position(tester).pixels, closeTo(before - 3 * line, .5));

      await _key(tester, LogicalKeyboardKey.bracketRight);
      expect(controller.chapter.index, 1);
      await _key(tester, LogicalKeyboardKey.bracketLeft);
      expect(controller.chapter.index, 0);
      await _key(tester, LogicalKeyboardKey.end);
      expect(controller.atEnd, isTrue);
      // The end card follows the text, so the end of the text is not the end of the scrolling.
      final textEnd = _reader(tester).layout!.totalExtent - _position(tester).viewportDimension;
      expect(_position(tester).pixels, closeTo(_position(tester).maxScrollExtent, .5), reason: 'the End key shows the end card');
      expect(_position(tester).maxScrollExtent, greaterThan(textEnd), reason: 'the end card lies after the text');
      await _key(tester, LogicalKeyboardKey.home);
      expect(controller.offset, 0);
      expect(_position(tester).pixels, 0);
      await _key(tester, LogicalKeyboardKey.keyT);
      expect(controller.offset, 0, reason: 'the contents do not move the text');
    });

    testWidgets('paged mode: every turning key turns a spread; chapters, start and end', (tester) async {
      await _mount(tester, settings: _pagedSettings);
      final controller = _controller(tester);
      int firstPage() => _paged(tester).visiblePages.first.index;
      expect(firstPage(), 0);

      for (final key in [LogicalKeyboardKey.space, LogicalKeyboardKey.pageDown, LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.arrowDown]) {
        final before = _paged(tester).visiblePages.first;
        await _key(tester, key);
        final after = _paged(tester).visiblePages.first;
        expect(after.startOffset, greaterThan(before.startOffset), reason: '${key.keyLabel} turns forward');
        expect(controller.offset, after.startOffset, reason: 'the reported offset is the page start');
      }
      for (final key in [LogicalKeyboardKey.pageUp, LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowUp]) {
        final before = _paged(tester).visiblePages.first;
        await _key(tester, key);
        expect(_paged(tester).visiblePages.first.startOffset, lessThan(before.startOffset), reason: '${key.keyLabel} turns back');
      }
      await _key(tester, LogicalKeyboardKey.bracketRight);
      expect(controller.chapter.index, 1);
      expect(firstPage(), 0);
      await _key(tester, LogicalKeyboardKey.end);
      expect(controller.atEnd, isTrue);
      expect(find.byKey(const ValueKey('reader-end-card')), findsOneWidget, reason: 'the End key shows the end card');
      expect(_paged(tester).showsEnd, !_paged(tester).endCardOnLastPage, reason: 'on a page of its own unless it fits under the text');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_paged(tester).visiblePages.first.startOffset, 0);
    });

    testWidgets('keys are left alone while a popup is over the reader', (tester) async {
      await _mount(tester);
      showFrostDialog<void>(
        context: tester.element(find.byType(NovelReaderContent)),
        useRootNavigator: true,
        builder: (_) => FrostDialog(title: 'Over the window', content: const SizedBox()),
      );
      await settlePilot(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await settlePilot(tester);
      expect(_position(tester).pixels, 0);
    });

    testWidgets('the chapter keys do nothing on an empty text', (tester) async {
      await _mount(tester, body: '');
      for (final key in [LogicalKeyboardKey.bracketLeft, LogicalKeyboardKey.bracketRight, LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.space]) {
        await _key(tester, key);
      }
      expect(tester.takeException(), isNull);
      expect(find.text(t.novel.reader.emptyBody), findsOneWidget);
    });
  });

  group('tap zones', () {
    Offset middle(WidgetTester tester, double fraction) {
      final rect = tester.getRect(find.byType(ReaderScrollView));
      return Offset(rect.left + rect.width * fraction, rect.center.dy);
    }

    testWidgets('sides: left third back, right third forward, middle toggles the bars', (tester) async {
      await _mount(tester);
      await tester.tapAt(middle(tester, 5 / 6));
      await settlePilot(tester);
      final forward = _position(tester).pixels;
      expect(forward, greaterThan(200));
      expect(_reader(tester).chromeVisible, isFalse);
      await tester.tapAt(middle(tester, 1 / 6));
      await settlePilot(tester);
      expect(_position(tester).pixels, lessThan(forward - 200));
      await tester.tapAt(middle(tester, .5));
      await settlePilot(tester);
      expect(_reader(tester).chromeVisible, isTrue);
    });

    testWidgets('forward: the centre toggles the bars, every other tap goes forward', (tester) async {
      await _mount(tester, settings: {..._scrollSettings, 'readerTapZones': 'forward'});
      await tester.tapAt(middle(tester, 1 / 6));
      await settlePilot(tester);
      final first = _position(tester).pixels;
      expect(first, greaterThan(200), reason: 'the left side goes forward too');
      final rect = tester.getRect(find.byType(ReaderScrollView));
      await tester.tapAt(Offset(rect.center.dx, rect.top + rect.height * 5 / 6 - 80));
      await settlePilot(tester);
      expect(_position(tester).pixels, greaterThan(first + 200));
      await tester.tapAt(rect.center);
      await settlePilot(tester);
      expect(_reader(tester).chromeVisible, isTrue);
    });

    testWidgets('paged: the sides turn pages', (tester) async {
      await _mount(tester, settings: _pagedSettings);
      final rect = tester.getRect(find.byType(ReaderPagedView));
      await tester.tapAt(Offset(rect.right - 40, rect.center.dy));
      await settlePilot(tester);
      expect(_paged(tester).visiblePages.first.index, 2);
      await tester.tapAt(Offset(rect.left + 40, rect.center.dy));
      await settlePilot(tester);
      expect(_paged(tester).visiblePages.first.index, 0);
    });

    testWidgets('a page jump acts on its own, not on the zone it lies in', (tester) async {
      // Below the top bar, which lies over the first lines.
      await _mount(
        tester,
        body: [_paragraph, _paragraph, '[jump:2] $_paragraph', for (var i = 0; i < 4; i++) _paragraph, '[newpage]', _paragraph].join('\n\n'),
      );
      final shown = _reader(tester).chromeVisible;
      final paragraph = find.byType(ReaderParagraph).at(2);
      final text = tester.widget<ReaderParagraph>(paragraph).text;
      final jump = text.taps.single;
      final rendered = tester.renderObject<RenderParagraph>(find.descendant(of: paragraph, matching: find.byType(RichText)));
      final box = rendered.getBoxesForSelection(TextSelection(baseOffset: jump.start, extentOffset: jump.end)).first.toRect();
      await tester.tapAt(rendered.localToGlobal(box.center));
      await settlePilot(tester);
      expect(_controller(tester).offset, _controller(tester).model.offsetOfPage(2));
      expect(_reader(tester).chromeVisible, shown);
    });

    testWidgets('tapping an embedded work opens it and leaves the bars; tapping the text toggles them', (tester) async {
      await _mount(tester, body: ['$_paragraph 1', '[pixivimage:12345]', '$_paragraph 2'].join('\n\n'), works: _works);
      final shown = _reader(tester).chromeVisible;
      await tester.tap(find.byKey(const ValueKey('reader-work-card')));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.illust(12345));
      final covered = tester.state<NovelReaderContentState>(find.byType(NovelReaderContent, skipOffstage: false));
      expect(covered.chromeVisible, shown, reason: 'the button acts on the work alone');

      await _mount(tester, body: ['$_paragraph 1', '[pixivimage:12345]', '$_paragraph 2'].join('\n\n'), works: _works);
      await tester.tapAt(tester.getCenter(find.byType(ReaderScrollView)));
      await settlePilot(tester);
      expect(_reader(tester).chromeVisible, !shown, reason: 'the text toggles them');
    });
  });

  group('auto scroll', () {
    testWidgets('runs on through the chapters and pauses under a window-wide dialog', (tester) async {
      await _mount(tester);
      await _showBars(tester);
      await tester.tap(find.byKey(const ValueKey('reader-auto-scroll')));
      await tester.pump();
      expect(_reader(tester).autoScrolling, isTrue);
      expect(_reader(tester).chromeVisible, isFalse, reason: 'starting hides the bars');
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

    testWidgets('scrolling by hand stops it and hides the bars; a tap brings them back', (tester) async {
      await _mount(tester);
      await _showBars(tester);
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

    testWidgets('is not offered in paged mode', (tester) async {
      await _mount(tester, settings: _pagedSettings);
      expect(find.byKey(const ValueKey('reader-auto-scroll')), findsNothing);
    });
  });

  testWidgets('a new text size keeps the character at the reading line', (tester) async {
    await _mount(tester);
    await _showBars(tester);
    await tester.tap(find.bySemanticsLabel(t.novel.reader.nextChapter));
    await settlePilot(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await settlePilot(tester);
    final before = _controller(tester).offset;
    expect(_readingLine(tester), before);
    final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderContent)));
    container.read(readerSettingsProvider.notifier).setTextSize(26);
    await settlePilot(tester);
    expect(tester.widget<ReaderParagraph>(find.byType(ReaderParagraph).first).typesetting.body.fontSize, 26);
    expect(_controller(tester).offset, before);
    expect(_readingLine(tester), _lineStart(_reader(tester).layout!, before), reason: 'the line holding it is at the reading line');
  });

  testWidgets('switching to pages and back keeps the place', (tester) async {
    await _mount(tester);
    _reader(tester).goToChapter(1);
    await settlePilot(tester);
    final offset = _controller(tester).offset;
    final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderContent)));
    container.read(readerSettingsProvider.notifier).setPageMode(ReaderPageMode.paged);
    await settlePilot(tester);
    expect(_paged(tester).visiblePages.first.startOffset, offset);
    container.read(readerSettingsProvider.notifier).setPageMode(ReaderPageMode.scroll);
    await settlePilot(tester);
    expect(_readingLine(tester), offset);
  });

  group('the place is kept', () {
    testWidgets('reopening comes back to the same offset in scroll mode', (tester) async {
      await _mount(tester);
      _controller(tester).goToOffset(1234);
      await settlePilot(tester);
      await tester.pumpWidget(const SizedBox());
      await _mount(tester);
      expect(_controller(tester).offset, 1234);
      expect(_readingLine(tester), _lineStart(_reader(tester).layout!, 1234));
    });

    testWidgets('reopening comes back to the same page in paged mode', (tester) async {
      await _mount(tester, settings: _pagedSettings);
      _reader(tester).goToChapter(2);
      await settlePilot(tester);
      _controller(tester).nextScreen();
      await settlePilot(tester);
      final start = _paged(tester).visiblePages.first.startOffset;
      expect(_controller(tester).offset, start);
      await tester.pumpWidget(const SizedBox());
      await _mount(tester, settings: _pagedSettings);
      expect(_controller(tester).offset, start);
      expect(_paged(tester).visiblePages.first.startOffset, start);
    });

    testWidgets('reopening takes the saved text size and spacing, not those it was last read with', (tester) async {
      await _mount(tester, settings: const {'readerFontSize': 18.0, 'readerLineSpacing': 'compact'});
      _reader(tester).goToChapter(1);
      await settlePilot(tester);
      await tester.pumpWidget(const SizedBox());
      // Changed elsewhere (another novel, the settings page) in the meantime.
      await _mount(tester, settings: const {'readerFontSize': 24.0, 'readerLineSpacing': 'relaxed'});
      final styles = tester.widgetList<ReaderParagraph>(find.byType(ReaderParagraph)).map((paragraph) => paragraph.typesetting.body);
      expect(styles, isNotEmpty);
      expect(styles.map((style) => (style.fontSize, style.height)), everyElement((24.0, ReaderLineSpacing.relaxed.lineHeight)));
      expect(_reader(tester).currentChapter.index, 1, reason: 'the place is still restored');
    });

    testWidgets('it is saved at once when the app goes to the background and when the reader closes', (tester) async {
      await _mount(tester);
      final novelId = _reader(tester).widget.detail.novel.id;
      final controller = _controller(tester);
      controller.goToChapter(2);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
      await _storageIdle(tester);
      final background = await tester.runAsync(() => loadReadingProgress(novelId));
      expect(background?.offset, controller.model.chapters[2].startOffset);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      controller.goToChapter(1);
      await tester.pumpWidget(const SizedBox());
      await _storageIdle(tester);
      final closed = await tester.runAsync(() => loadReadingProgress(novelId));
      expect(closed?.offset, controller.model.chapters[1].startOffset);
    });
  });

  group('scroll view', () {
    // Background measuring runs a fixed number of blocks per frame here, not
    // by wall time, so every interleaving is the same on every machine.
    for (final perPass in [1, 3, 40, null]) {
      testWidgets('a jump anywhere in a long text lands in one call, measuring ${perPass ?? 'everything'} per frame', (tester) async {
        ReaderScrollViewState.debugMeasurePass = (layout, anchor) {
          if (perPass == null) return layout.measureSome(anchor, const Duration(days: 1));
          var done = false;
          // A zero budget measures exactly one block.
          for (var i = 0; i < perPass && !done; i++) {
            done = layout.measureSome(anchor, Duration.zero);
          }
          return done;
        };
        addTearDown(() => ReaderScrollViewState.debugMeasurePass = null);
        await _mount(tester, body: sampleLongNovelText());
        final controller = _controller(tester);
        expect(controller.model.totalLength, greaterThan(250000));
        const target = 187654;
        controller.goToOffset(target);
        await tester.pump();
        final layout = _reader(tester).layout!;
        expect(_readingLine(tester), _lineStart(layout, target));
        expect(controller.offset, target);
        await settlePilot(tester, frames: 6);
        expect(_readingLine(tester), _lineStart(layout, target), reason: 'measuring around it keeps the reading line');
      });
    }

    testWidgets('an image growing above the reading line leaves the reading line where it was', (tester) async {
      await _mount(tester, body: [_paragraph, '[uploadedimage:1]', for (var i = 0; i < 30; i++) '$_paragraph $i'].join('\n\n'));
      final layout = _reader(tester).layout!;
      final image = layout.model.blocks.indexWhere((block) => block is NovelUploadedImage);
      _controller(tester).goToOffset(layout.model.offsetOf(image + 8) + 20);
      await settlePilot(tester);
      final before = _readingLine(tester);
      final pixels = _position(tester).pixels;
      final extent = layout.extentOf(image);
      tester.state<ReaderScrollViewState>(find.byType(ReaderScrollView)).imageSized(image, const Size(1600, 400));
      await tester.pump();
      expect(layout.extentOf(image), isNot(extent));
      expect(_position(tester).pixels, isNot(closeTo(pixels, 1)), reason: 'the scroll position follows the image');
      expect(_readingLine(tester), before);
    });

    testWidgets('an image changing size during a turn still leaves the turn one screen less a line on', (tester) async {
      await _mount(tester, body: [_paragraph, '[uploadedimage:1]', for (var i = 0; i < 40; i++) '$_paragraph $i'].join('\n\n'));
      final layout = _reader(tester).layout!;
      final image = layout.model.blocks.indexWhere((block) => block is NovelUploadedImage);
      _controller(tester).goToOffset(layout.model.offsetOf(image + 4));
      await settlePilot(tester);
      final start = _position(tester).pixels;
      final screen = _position(tester).viewportDimension - layout.typesetting.bodyLinePx;
      final extent = layout.extentOf(image);
      expect(_controller(tester).nextScreen(), isTrue);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 60));
      tester.state<ReaderScrollViewState>(find.byType(ReaderScrollView)).imageSized(image, const Size(1600, 400));
      final shift = layout.extentOf(image) - extent;
      expect(shift, isNot(0));
      await settlePilot(tester);
      // In model terms: the start's text moved by the shift, and the turn went a screen on from it.
      expect(_position(tester).pixels, closeTo(start + shift + screen, .5));
    });

    testWidgets('scroll: going to the last chapter shows the end at 100 %', (tester) async {
      await _mount(tester, body: _withCoda);
      _reader(tester).goToChapter(3);
      await settlePilot(tester);
      expect(_controller(tester).atEnd, isTrue);
      expect(_reader(tester).progress, 1.0);
      _reader(tester).goToChapter(0);
      await settlePilot(tester);
      expect(_controller(tester).atEnd, isFalse);
      for (var turn = 0; turn < 40 && _controller(tester).nextScreen(); turn++) {
        await settlePilot(tester, frames: 4);
      }
      expect(_controller(tester).atEnd, isTrue, reason: 'turning forward reports the end');
    });
  });

  group('paged view', () {
    testWidgets('turning forward runs through a chapter boundary to the next chapter start', (tester) async {
      await _mount(tester, settings: _pagedSettings);
      final controller = _controller(tester);
      final second = controller.model.chapters[1].startOffset;
      for (var turn = 0; turn < 20 && controller.chapter.index == 0; turn++) {
        expect(controller.nextScreen(), isTrue);
        await settlePilot(tester, frames: 4);
        expect(controller.offset, _paged(tester).visiblePages.first.startOffset);
      }
      expect(controller.chapter.index, 1);
      expect(controller.offset, second);
      expect(_paged(tester).visiblePages.first.index, 0);
    });

    testWidgets('a wide window shows two pages side by side', (tester) async {
      await _mount(tester, settings: _pagedSettings, size: const Size(1147, 717));
      final pages = _paged(tester).visiblePages;
      expect(pages.length, 2);
      expect(pages[1].startOffset, pages[0].endOffset);
      final paragraphs = tester.widgetList<ReaderParagraph>(find.byType(ReaderParagraph)).toList();
      final lefts = {for (var i = 0; i < paragraphs.length; i++) tester.getTopLeft(find.byType(ReaderParagraph).at(i)).dx.round()};
      expect(lefts.length, greaterThanOrEqualTo(2), reason: 'text in two columns');
      expectNoLayoutErrors(tester);
    });

    testWidgets('a phone shows one page and a drag turns it', (tester) async {
      await _mount(tester, settings: _pagedSettings, size: phoneSize);
      expect(_paged(tester).visiblePages.length, 1);
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ReaderPagedView)), kind: PointerDeviceKind.touch);
      for (var step = 0; step < 10; step++) {
        await gesture.moveBy(const Offset(-25, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await settlePilot(tester);
      expect(_paged(tester).visiblePages.single.index, 1);
      expect(_controller(tester).offset, _paged(tester).visiblePages.single.startOffset);
    });

    for (final animation in ReaderPageAnimation.values) {
      testWidgets('the ${animation.name} turn ends on the next page', (tester) async {
        await _mount(tester, settings: {..._pagedSettings, 'readerPageAnimation': animation.name}, size: phoneSize);
        _controller(tester).nextScreen();
        await tester.pump(const Duration(milliseconds: 100));
        expectNoLayoutErrors(tester);
        await settlePilot(tester);
        expect(_paged(tester).visiblePages.single.index, 1);
      });
    }

    for (final dragging in [false, true]) {
      testWidgets('a new text size ${dragging ? 'during a drag' : 'during a turn'} lands on the page holding the place', (tester) async {
        await _mount(tester, settings: _pagedSettings, size: phoneSize);
        _reader(tester).goToChapter(1);
        await settlePilot(tester);
        TestGesture? gesture;
        if (dragging) {
          gesture = await tester.startGesture(tester.getCenter(find.byType(ReaderPagedView)), kind: PointerDeviceKind.touch);
          for (var step = 0; step < 4; step++) {
            await gesture.moveBy(const Offset(-30, 0));
            await tester.pump(const Duration(milliseconds: 16));
          }
        } else {
          _controller(tester).nextScreen();
          await tester.pump(const Duration(milliseconds: 60));
        }
        final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderContent)));
        container.read(readerSettingsProvider.notifier).setTextSize(24);
        await tester.pump();
        await gesture?.moveBy(const Offset(-30, 0));
        await gesture?.up();
        await settlePilot(tester);
        expect(tester.takeException(), isNull);
        final page = _paged(tester).visiblePages.single;
        final offset = _controller(tester).offset;
        expect(page.startOffset <= offset && offset < page.endOffset, isTrue, reason: '$offset on ${page.startOffset}..${page.endOffset}');
      });
    }

    testWidgets('paged: going to the last chapter shows the end at 100 %', (tester) async {
      await _mount(tester, body: _withCoda, settings: _pagedSettings);
      _reader(tester).goToChapter(3);
      await settlePilot(tester);
      expect(_controller(tester).atEnd, isTrue);
      expect(_reader(tester).progress, 1.0);
      _reader(tester).goToChapter(2);
      await settlePilot(tester);
      expect(_controller(tester).atEnd, isFalse);
      for (var turn = 0; turn < 40 && _controller(tester).nextScreen(); turn++) {
        await settlePilot(tester, frames: 4);
      }
      expect(_controller(tester).atEnd, isTrue, reason: 'turning forward reports the end');
    });
  });

  group('selection and Escape', () {
    testWidgets('selecting with the mouse pauses auto scroll; Escape clears it, then hides the bars, then leaves', (tester) async {
      await _mount(tester);
      await _showBars(tester);
      await tester.tap(find.byKey(const ValueKey('reader-auto-scroll')));
      await settlePilot(tester, frames: 4);
      expect(_reader(tester).autoScrolling, isTrue);

      final paragraph = find.textContaining('1.2').first;
      final from = tester.getTopLeft(paragraph) + const Offset(2, 8);
      final gesture = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
      await tester.pump();
      await gesture.moveTo(from + const Offset(220, 0));
      await tester.pump();
      await gesture.up();
      await settlePilot(tester, frames: 3);
      expect(_reader(tester).autoScrolling, isFalse, reason: 'a selection pauses auto scroll');
      final paused = _position(tester).pixels;
      await tester.pump(const Duration(seconds: 1));
      expect(_position(tester).pixels, paused);

      await _key(tester, LogicalKeyboardKey.escape);
      expect(openedLocations, isEmpty, reason: 'the first Escape only clears the selection');
      await _showBars(tester);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(openedLocations, isEmpty);
      expect(_reader(tester).chromeVisible, isFalse, reason: 'the second hides the bars');
      await _key(tester, LogicalKeyboardKey.escape);
      expect(openedLocations.last, AppLocations.novel(70000));
    });

    testWidgets('touch selection has handles and a copy menu, and pauses auto scroll', (tester) async {
      await _mount(tester, size: phoneSize);
      await _showBars(tester);
      await tester.tap(find.byKey(const ValueKey('reader-auto-scroll')));
      await settlePilot(tester, frames: 4);
      expect(_reader(tester).autoScrolling, isTrue);
      await tester.longPress(find.textContaining('1.2').first);
      await settlePilot(tester, frames: 4);
      expect(_reader(tester).autoScrolling, isFalse);
      expect(find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter.runtimeType.toString() == '_SelectionHandlePainter'), findsNWidgets(2));
      expect(find.widgetWithText(FrostButton, 'Copy'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
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
    await _showBars(tester);
    expectNoLayoutErrors(tester);
  });

  test('the reader strings exist in all four languages', () => expectLocalesComplete(['novel']));
}
