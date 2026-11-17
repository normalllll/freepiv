import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_paged_view.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/custom/reader/reader_paragraph.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

/// Records the series writes; any other request fails.
class _Api implements PixivApi {
  final writes = <String>[];

  @override
  Future<String> postWatchlistAdd({required int seriesId, required bool isNovel}) async {
    writes.add('watch $seriesId novel=$isNovel');
    return '';
  }

  @override
  Future<String> postWatchlistDelete({required int seriesId, required bool isNovel}) async {
    writes.add('unwatch $seriesId novel=$isNovel');
    return '';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #setAccount) return null;
    throw StateError('unexpected request: ${invocation.memberName}');
  }
}

NovelNavigationItem _item({required String id, required String title, bool viewable = true, String? message, String? order}) => NovelNavigationItem(
  id: id,
  title: title,
  coverUrl: readerImageUrl(7, width: 300, height: 420),
  contentOrder: order,
  viewable: viewable,
  viewableMessage: message,
);

void main() {
  late HistoryRepository history;
  late _Api api;
  setUp(() {
    history = useMemoryHistory();
    pixivApi = api = _Api();
  });

  final body = '${readerChapters()}\n\n[chapter:Coda]\n\n$readerParagraph';

  Future<void> mount(WidgetTester tester, {WebviewNovel? text, Map<String, dynamic> settings = readerScrollSettings, Size size = desktopSize}) =>
      mountReader(tester, history, text: text ?? readerText(body), settings: settings, size: size);

  ScrollPosition position(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  /// Scrolls to the very end of what scrolls: the end card in view.
  Future<void> scrollToEnd(WidgetTester tester) async {
    readerController(tester).goToEnd();
    await settlePilot(tester);
    position(tester).jumpTo(position(tester).maxScrollExtent);
    await settlePilot(tester);
  }

  Finder card() => find.byKey(const ValueKey('reader-end-card'));

  WebviewNovel series({NovelNavigationItem? next, NovelNavigationItem? previous, bool watched = false, String? text}) => readerText(
    text ?? body,
    seriesId: '500',
    seriesTitle: 'The shore stories',
    seriesIsWatched: watched,
    seriesNavigation: NovelNavigationInfo(nextNovel: next, prevNovel: previous),
  );

  group('scroll', () {
    testWidgets('not in a series: the end, the bookmark and the comments, nothing more', (tester) async {
      await mount(tester);
      await scrollToEnd(tester);
      expect(card(), findsOneWidget);
      expect(find.text(t.novel.reader.theEnd), findsOneWidget);
      expect(find.byKey(const ValueKey('reader-end-bookmark')), findsOneWidget);
      expect(find.byKey(const ValueKey('reader-end-comments')), findsOneWidget);
      expect(find.byKey(const ValueKey('reader-end-next')), findsNothing);
      expect(find.text(t.series.watch), findsNothing);
      expect(find.byKey(const ValueKey('reader-end-previous')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('reader-end-comments')));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.novelComments(70000));
    });

    testWidgets('progress reaches 100 % at the end of the text, before the card; the card adds nothing', (tester) async {
      await mount(tester);
      final controller = readerController(tester);
      controller.goToEnd();
      await settlePilot(tester);
      final textEnd = readerState(tester).layout!.totalExtent - position(tester).viewportDimension;
      expect(position(tester).pixels, closeTo(position(tester).maxScrollExtent, .5), reason: 'the End key shows the card');
      expect(position(tester).maxScrollExtent, greaterThan(textEnd + 100), reason: 'the card lies after the text');
      expect(controller.atEnd, isTrue);
      expect(controller.progress, 1);
      expect(find.byType(ReaderParagraph), findsWidgets);

      position(tester).jumpTo(position(tester).maxScrollExtent);
      await settlePilot(tester);
      expect(controller.progress, 1, reason: 'further on is still the end');
      expect(card(), findsOneWidget);
    });

    testWidgets('a text shorter than a screen shows the card under it, and auto scroll stops at the text', (tester) async {
      await mount(tester, text: readerText(readerParagraph));
      expect(readerController(tester).atEnd, isTrue);
      expect(readerController(tester).progress, 1);
      expect(card(), findsOneWidget);
    });

    testWidgets('a next novel that can be read: its place in the series and title; a tap replaces the reader with its reader', (tester) async {
      await mount(
        tester,
        text: series(
          next: _item(id: '70001', title: 'The tide table', order: '2'),
          previous: _item(id: '69999', title: 'The first light'),
        ),
      );
      await scrollToEnd(tester);
      expect(find.text('The tide table'), findsOneWidget);
      expect(find.text('${t.novel.reader.seriesNext} · #2'), findsOneWidget);
      expect(find.text(t.series.link(title: 'The shore stories')), findsOneWidget);
      expect(find.text(t.novel.reader.seriesPrevious(title: 'The first light')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('reader-end-next')));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.novelReader(70001));
    });

    testWidgets('a next novel that cannot be read says why and cannot be opened', (tester) async {
      await mount(
        tester,
        text: series(
          next: _item(id: '70001', title: 'The tide table', viewable: false, message: 'Not published yet.'),
        ),
      );
      await scrollToEnd(tester);
      expect(find.text('Not published yet.'), findsOneWidget);
      openedLocations.clear();
      await tester.tap(find.byKey(const ValueKey('reader-end-next')), warnIfMissed: false);
      await settlePilot(tester);
      expect(openedLocations, isEmpty);

      await mount(
        tester,
        text: series(
          next: _item(id: '70001', title: 'The tide table', viewable: false),
        ),
      );
      await scrollToEnd(tester);
      expect(find.text(t.novel.reader.seriesNextUnavailable), findsOneWidget);
    });

    testWidgets('the series can be watched from the card, and the card starts as the novel says', (tester) async {
      await mount(
        tester,
        text: series(
          next: _item(id: '70001', title: 'The tide table'),
        ),
      );
      await scrollToEnd(tester);
      expect(find.text(t.series.watch), findsOneWidget);
      await tester.tap(find.text(t.series.watch));
      await settlePilot(tester);
      expect(api.writes, ['watch 500 novel=true']);
      expect(find.text(t.series.watching), findsOneWidget);

      await mount(tester, text: series(watched: true));
      await scrollToEnd(tester);
      expect(find.text(t.series.watching), findsOneWidget, reason: 'already watched');
      await tester.tap(find.text(t.series.watching));
      await settlePilot(tester);
      expect(api.writes.last, 'unwatch 500 novel=true');
    });

    testWidgets('the last episode has no next card but keeps the watch button and the previous link', (tester) async {
      await mount(
        tester,
        text: series(
          previous: _item(id: '69999', title: 'The first light'),
        ),
      );
      await scrollToEnd(tester);
      expect(find.byKey(const ValueKey('reader-end-next')), findsNothing);
      expect(find.text(t.series.watch), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('reader-end-previous')));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.novelReader(69999));
    });

    testWidgets('the card fits a phone', (tester) async {
      await mount(
        tester,
        text: series(
          next: _item(id: '70001', title: 'A next episode with a very long title that wraps over several lines of the card'),
          previous: _item(id: '69999', title: 'The first light'),
        ),
        size: phoneSize,
      );
      await scrollToEnd(tester);
      expect(card(), findsOneWidget);
      expectNoLayoutErrors(tester);
    });
  });

  group('paged', () {
    ReaderPagedViewState view(WidgetTester tester) => tester.state<ReaderPagedViewState>(find.byType(ReaderPagedView));

    testWidgets('the card is a last page: reaching the last text page is the end, the card holds no text', (tester) async {
      await mount(
        tester,
        text: series(
          next: _item(id: '70001', title: 'The tide table'),
        ),
        settings: readerPagedSettings,
      );
      final controller = readerController(tester);
      controller.goToEnd();
      await settlePilot(tester);
      expect(view(tester).showsEnd, isTrue, reason: 'the End key shows the end card');
      expect(controller.previousScreen(), isTrue);
      await settlePilot(tester);
      expect(view(tester).showsEnd, isFalse, reason: 'the last page of the text');
      expect(controller.atEnd, isTrue);
      expect(controller.progress, 1);
      final lastOffset = controller.offset;

      expect(controller.nextScreen(), isTrue);
      await settlePilot(tester);
      expect(view(tester).showsEnd, isTrue);
      expect(card(), findsOneWidget);
      expect(find.text('The tide table'), findsOneWidget);
      expect(controller.progress, 1);
      expect(controller.offset, lastOffset, reason: 'the position stays on the last page');
      expect(controller.nextScreen(), isFalse, reason: 'nothing after the card');

      expect(controller.previousScreen(), isTrue);
      await settlePilot(tester);
      expect(view(tester).showsEnd, isFalse);
      expect(card(), findsNothing);
      expect(view(tester).visiblePages, isNotEmpty);
    });

    testWidgets('on a phone the card scrolls inside its page and the next novel opens', (tester) async {
      await mount(
        tester,
        text: series(
          next: _item(id: '70001', title: 'The tide table'),
          previous: _item(id: '69999', title: 'The first light'),
        ),
        settings: readerPagedSettings,
        size: phoneSize,
      );
      readerController(tester).goToEnd();
      await settlePilot(tester);
      readerController(tester).nextScreen();
      await settlePilot(tester);
      expect(view(tester).showsEnd, isTrue);
      expectNoLayoutErrors(tester);
      await tester.tap(find.byKey(const ValueKey('reader-end-next')));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.novelReader(70001));
    });
  });
}
