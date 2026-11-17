import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/features/novel/domain/reading_time.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_bottom_panel.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_status_line.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_top_bar.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_scroll_view.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/custom/reader/reader_progress_track.dart';
import 'package:freepiv/ui/custom/reader/reader_status_text.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

void main() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  Future<void> mount(WidgetTester tester, {String? body, Map<String, dynamic> settings = readerScrollSettings, Size size = desktopSize, String? language}) =>
      mountReader(
        tester,
        history,
        text: readerText(body ?? readerChapters(), language: language),
        settings: settings,
        size: size,
      );

  /// Lets a slide start and end: an animation starts on the frame after its change.
  Future<void> animate(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder scrim() => find.byKey(const ValueKey('reader-scrim'));

  group('reading time', () {
    test('rates by language: Chinese 400, Japanese 500, anything else 900, none as Chinese', () {
      expect(readingCharactersPerMinute('zh-cn'), 400);
      expect(readingCharactersPerMinute('zh'), 400);
      expect(readingCharactersPerMinute(null), 400);
      expect(readingCharactersPerMinute(''), 400);
      expect(readingCharactersPerMinute('ja'), 500);
      expect(readingCharactersPerMinute('JA-JP'), 500);
      expect(readingCharactersPerMinute('en'), 900);
      expect(readingCharactersPerMinute('ko'), 900);
    });

    test('minutes round up and are zero only for nothing left', () {
      expect(readingMinutes(0), 0);
      expect(readingMinutes(-5), 0);
      expect(readingMinutes(1), 1);
      expect(readingMinutes(400), 1);
      expect(readingMinutes(401), 2);
      expect(readingMinutes(1000, language: 'ja'), 2);
      expect(readingMinutes(1000, language: 'en'), 2);
      expect(readingMinutes(901, language: 'en'), 2);
    });
  });

  group('visibility', () {
    testWidgets('hidden on open; a tap in the middle shows both bars and the scrim; a tap on the scrim hides them', (tester) async {
      await mount(tester);
      expect(find.byType(ReaderTopBar), findsNothing);
      expect(find.byType(ReaderBottomPanel), findsNothing);
      final state = readerState(tester);
      expect(state.chromeVisible, isFalse);

      await tester.tapAt(tester.getCenter(find.byType(ReaderScrollView)));
      await settlePilot(tester);
      expect(state.chromeVisible, isTrue);
      expect(find.byType(ReaderTopBar), findsOneWidget);
      expect(find.byType(ReaderBottomPanel), findsOneWidget);
      final tokens = FrostThemeTokens.of(tester.element(scrim()));
      expect(tester.widget<ColoredBox>(find.descendant(of: scrim(), matching: find.byType(ColoredBox))).color, tokens.onMediaScrim);

      await tester.tapAt(const Offset(500, 300));
      await settlePilot(tester);
      expect(state.chromeVisible, isFalse);
      expect(find.byType(ReaderTopBar), findsNothing, reason: 'a hidden bar is not kept built');
    });

    testWidgets('a key, a page turn and a scroll by hand hide the bars', (tester) async {
      await mount(tester);
      final state = readerState(tester);
      await showReaderBars(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await settlePilot(tester);
      expect(state.chromeVisible, isFalse, reason: 'a turn by key hides');

      await showReaderBars(tester);
      await tester.drag(scrim(), const Offset(0, -200));
      await settlePilot(tester);
      expect(state.chromeVisible, isFalse, reason: 'a drag over the scrim hides');

      await showReaderBars(tester);
      final wheel = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(wheel.hover(const Offset(500, 300)));
      await tester.sendEventToBinding(wheel.scroll(const Offset(0, 120)));
      await settlePilot(tester);
      expect(state.chromeVisible, isFalse, reason: 'the wheel over the scrim hides');
    });

    testWidgets('the pointer near an edge shows that bar alone, without the scrim, and it goes 2 s after the pointer leaves it', (tester) async {
      await mount(tester);
      final state = readerState(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(500, 300));
      addTearDown(mouse.removePointer);
      await tester.pump();

      await mouse.moveTo(const Offset(500, 20));
      await animate(tester);
      expect(state.chrome.topVisible, isTrue);
      expect(state.chrome.bottomVisible, isFalse);
      expect(state.chromeVisible, isFalse, reason: 'no scrim for a peek');
      expect(find.byType(ReaderTopBar), findsOneWidget);
      expect(find.byType(ReaderBottomPanel), findsNothing);

      // On the bar the pointer keeps it.
      await mouse.moveTo(tester.getCenter(find.byType(ReaderTopBar)));
      await tester.pump(const Duration(seconds: 3));
      expect(state.chrome.topVisible, isTrue);

      await mouse.moveTo(const Offset(500, 300));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(state.chrome.topVisible, isTrue, reason: 'still within the 2 s');
      await tester.pump(const Duration(milliseconds: 800));
      expect(state.chrome.topVisible, isFalse);
      await animate(tester);
      expect(find.byType(ReaderTopBar), findsNothing);

      await mouse.moveTo(const Offset(500, 700));
      await animate(tester);
      expect(state.chrome.bottomVisible, isTrue);
      expect(state.chrome.topVisible, isFalse);
      expect(find.byType(ReaderBottomPanel), findsOneWidget);
      await mouse.moveTo(const Offset(500, 300));
      await tester.pump(const Duration(seconds: 3));
      expect(state.chrome.bottomVisible, isFalse);
    });

    testWidgets('a drag that starts on a bar the pointer showed keeps it while it wanders off; the 2 s start at release', (tester) async {
      await mount(tester);
      final state = readerState(tester);
      final controller = readerController(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(500, 300));
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(Offset(500, desktopSize.height - 10));
      await animate(tester);
      expect(state.chrome.bottomVisible, isTrue);

      final track = find.byType(ReaderProgressTrack);
      final rect = tester.getRect(track);
      final trackState = tester.state<ReaderProgressTrackState>(track);
      double fractionAt(double x) => ((x - rect.left - ReaderProgressTrack.inset) / (rect.width - 2 * ReaderProgressTrack.inset)).clamp(0.0, 1.0);
      await mouse.moveTo(rect.center);
      await tester.pump();
      await mouse.down(rect.center);
      await tester.pump();
      var at = rect.center + const Offset(-120, -200);
      for (var step = 0; step < 30; step++) {
        if (step > 0) at += Offset(step.isEven ? 60 : -50, 0);
        await mouse.moveTo(at);
        await tester.pump(const Duration(milliseconds: 100));
        expect(track, findsOneWidget, reason: 'the bar stays at ${(step + 1) * 100} ms');
        expect(trackState.dragging, closeTo(fractionAt(at.dx), .01), reason: 'the thumb follows at ${(step + 1) * 100} ms');
      }
      final released = trackState.dragging!;
      await mouse.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.progress, closeTo(released, .01), reason: 'the release goes there');

      await tester.pump(const Duration(milliseconds: 1400));
      expect(state.chrome.bottomVisible, isTrue, reason: 'the 2 s count from the release');
      await tester.pump(const Duration(milliseconds: 800));
      expect(state.chrome.bottomVisible, isFalse);
    });

    testWidgets('a key hides a bar that the pointer showed', (tester) async {
      await mount(tester);
      final state = readerState(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(500, 300));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(const Offset(500, 700));
      await animate(tester);
      expect(state.chrome.bottomVisible, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await animate(tester);
      expect(state.chrome.bottomVisible, isFalse);
    });
  });

  group('bottom panel', () {
    testWidgets('chapter ticks and illustration dots lie at their share of the text, and the chapter buttons stop at the ends', (tester) async {
      final body = [
        readerChapters(titles: ['One', 'Two']),
        '[uploadedimage:1]',
        readerParagraph,
        '[chapter:Three]',
        readerParagraph,
      ].join('\n\n');
      await mount(tester, body: body);
      await showReaderBars(tester);
      final track = tester.widget<ReaderProgressTrack>(find.byKey(const ValueKey('reader-progress')));
      final model = readerController(tester).model;
      final total = model.totalLength;
      expect(track.chapterMarks, [for (final chapter in model.chapters) chapter.startOffset / total]);
      expect(track.chapterMarks.first, 0);
      expect(track.chapterMarks.length, 3);
      expect(track.imageMarks, [for (final block in model.imageBlocks) model.offsetOf(block) / total]);
      expect(track.imageMarks.length, 1);
      expect(track.imageMarks.single, inExclusiveRange(track.chapterMarks[1], track.chapterMarks[2]));

      FrostButton button(String label) => tester.widget<FrostButton>(find.widgetWithText(FrostButton, label));
      expect(button(t.novel.reader.previousChapter).onPressed, isNull, reason: 'none before the first');
      expect(button(t.novel.reader.nextChapter).onPressed, isNotNull);
      readerController(tester).goToChapter(2);
      await settlePilot(tester);
      expect(button(t.novel.reader.nextChapter).onPressed, isNull, reason: 'none after the last');
    });

    testWidgets('dragging the thumb shows the chapter and percent under it and releasing goes there', (tester) async {
      await mount(tester);
      await showReaderBars(tester);
      final controller = readerController(tester);
      final rect = tester.getRect(find.byType(ReaderProgressTrack));
      double xOf(double fraction) => rect.left + ReaderProgressTrack.inset + fraction * (rect.width - 2 * ReaderProgressTrack.inset);

      final gesture = await tester.startGesture(Offset(xOf(0), rect.center.dy));
      await gesture.moveTo(Offset(xOf(.25), rect.center.dy));
      await tester.pump();
      await gesture.moveTo(Offset(xOf(.5), rect.center.dy));
      await tester.pump();
      final state = tester.state<ReaderProgressTrackState>(find.byType(ReaderProgressTrack));
      expect(state.dragging, closeTo(.5, .02));
      final model = controller.model;
      final shown = state.dragging!;
      final label = t.novel.reader.progressBubble(chapter: model.chapterAt((shown * model.totalLength).round()).title!, percent: (shown * 100).round());
      expect(find.text(label), findsOneWidget);
      expect(controller.offset, 0, reason: 'nothing moves until the thumb is released');

      await gesture.up();
      await settlePilot(tester);
      expect(find.text(label), findsNothing, reason: 'the bubble goes with the drag');
      expect(controller.progress, closeTo(shown, .01));
    });

    testWidgets('a tap on the track and the arrow keys move by a percent', (tester) async {
      await mount(tester);
      await showReaderBars(tester);
      final controller = readerController(tester);
      final rect = tester.getRect(find.byType(ReaderProgressTrack));
      await tester.tapAt(Offset(rect.left + ReaderProgressTrack.inset + .4 * (rect.width - 2 * ReaderProgressTrack.inset), rect.center.dy));
      await settlePilot(tester);
      expect(controller.progress, closeTo(.4, .01));
    });
  });

  group('status lines', () {
    testWidgets('scroll: the chapter above the text, the share read and the minutes left in the chapter below', (tester) async {
      await mount(tester);
      final controller = readerController(tester);
      expect(find.descendant(of: find.byType(ReaderHeaderLine), matching: find.text('Departure')), findsOneWidget);
      final left = controller.chapter.endOffset - controller.offset;
      final minutes = readingMinutes(left);
      expect(find.text(t.novel.reader.progressStatus(percent: 0, minutes: minutes)), findsOneWidget);

      controller.goToChapter(1);
      await settlePilot(tester);
      expect(find.descendant(of: find.byType(ReaderHeaderLine), matching: find.text('Harbour')), findsOneWidget);
      final percent = (controller.progress * 100).round();
      final minutes2 = readingMinutes(controller.chapter.endOffset - controller.offset);
      expect(find.text(t.novel.reader.progressStatus(percent: percent, minutes: minutes2)), findsOneWidget);
    });

    testWidgets('the minutes follow the language of the novel', (tester) async {
      await mount(tester, language: 'en');
      final controller = readerController(tester);
      final minutes = readingMinutes(controller.chapter.endOffset - controller.offset, language: 'en');
      expect(minutes, lessThan(readingMinutes(controller.chapter.endOffset - controller.offset)));
      expect(find.text(t.novel.reader.progressStatus(percent: 0, minutes: minutes)), findsOneWidget);
    });

    testWidgets('paged: the page of the chapter and the share read', (tester) async {
      await mount(tester, settings: readerPagedSettings);
      final controller = readerController(tester);
      final paginator = readerState(tester).paginator!;
      final page = paginator.pageAt(controller.offset);
      final pages = paginator.pagesOfChapter(page.chapter).length;
      expect(find.text(t.novel.reader.pageStatus(page: page.index + 1, pages: pages, percent: 0)), findsOneWidget);
      controller.nextScreen();
      await settlePilot(tester);
      final next = paginator.pageAt(controller.offset);
      expect(next.index, greaterThan(0));
      expect(find.textContaining('${next.index + 1} / $pages'), findsOneWidget);
    });

    testWidgets('a single untitled chapter has no header; the footer stays', (tester) async {
      await mount(tester, body: readerParagraph);
      expect(find.byType(ReaderStatusText), findsOneWidget);
      expect(find.descendant(of: find.byType(ReaderHeaderLine), matching: find.byType(ReaderStatusText)), findsNothing);
    });

    testWidgets('an untitled chapter is called by its number', (tester) async {
      await mount(tester, body: '$readerParagraph\n\n[newpage]\n\n$readerParagraph');
      expect(find.descendant(of: find.byType(ReaderHeaderLine), matching: find.text(t.novel.reader.chapterNumber(number: 1))), findsOneWidget);
    });
  });

  testWidgets('the bars do not rebuild while the text scrolls under them', (tester) async {
    await mount(tester);
    await showReaderBars(tester);
    final controller = readerController(tester);
    final track = find.byKey(const ValueKey('reader-progress'));
    final before = tester.widget<ReaderProgressTrack>(track).progress();

    var bars = 0;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      final widget = element.widget;
      if (widget is ReaderTopBar || widget is ReaderBottomPanel) bars++;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    for (final offset in [900, 1800, 2400]) {
      controller.goToOffset(offset);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(bars, 0, reason: 'only the parts that show the chapter and the progress follow');
    expect(tester.widget<ReaderProgressTrack>(track).progress(), greaterThan(before));
  });
}
