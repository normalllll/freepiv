import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_controller.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_paged_view.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

class _Sink {
  final calls = <(int, int)>[];

  Future<void> call(int offset, int totalLength, double depth) async => calls.add((offset, totalLength));
}

class _Viewport implements ReaderViewport {
  final shown = <int>[];

  @override
  void showOffset(int offset, {double depth = 0}) => shown.add(offset);

  @override
  bool turn(int direction) => true;
}

/// A reader that reached the end of the text reopens with the end card in view.
void main() {
  final model = ReaderModel(parseNovelText('[chapter:One]\nalpha beta gamma\n[chapter:Two]\ndelta epsilon\n[chapter:Three]\nzeta eta theta iota'));
  final total = model.totalLength;

  ReaderController make(_Sink sink, {int initial = 3, bool atEnd = false}) =>
      ReaderController(model: model, initialOffset: initial, mode: ReaderPageMode.scroll, save: sink.call, initialAtEnd: atEnd);

  group('controller', () {
    test('while at the end it saves the end of the text', () async {
      final sink = _Sink();
      final controller = make(sink);
      controller.reportPosition(total - 4, atEnd: true);
      await controller.saveNow();
      expect(sink.calls, [(total, total)]);
      controller.dispose();
    });

    test('moving on at the end saves the end once, and leaving it saves the real offset', () async {
      final sink = _Sink();
      final controller = make(sink);
      controller.reportPosition(total - 4, atEnd: true);
      await controller.saveNow();
      controller.reportPosition(total - 2, atEnd: true);
      await controller.saveNow();
      expect(sink.calls, [(total, total)], reason: 'the end is already saved');

      controller.reportPosition(total - 2, atEnd: false);
      await controller.saveNow();
      expect(sink.calls.last, (total - 2, total), reason: 'the offset, though it did not move');
      controller.dispose();
    });

    test('goToEnd saves the end of the text, and a command away saves where it went', () async {
      final sink = _Sink();
      final controller = make(sink);
      controller.goToEnd();
      await controller.saveNow();
      expect(sink.calls, [(total, total)]);
      controller.goToOffset(5);
      await controller.saveNow();
      expect(sink.calls.last, (5, total));
      controller.dispose();
    });

    test('a controller built at the end is at the end with progress 1', () async {
      final sink = _Sink();
      final viewport = _Viewport();
      final controller = make(sink, initial: total, atEnd: true)..attach(viewport);
      expect(controller.atEnd, isTrue);
      expect(controller.progress, 1.0);
      expect(controller.offset, total);
      expect(viewport.shown, [total]);
      await controller.saveNow();
      expect(sink.calls, isEmpty, reason: 'what was saved is what it shows');
      controller.dispose();
    });

    test('the end is the end of the text as it is now, whatever length the saved text had', () {
      final controller = make(_Sink(), initial: total - 10, atEnd: true);
      expect(controller.offset, total);
      expect(controller.atEnd, isTrue);
      controller.dispose();
    });
  });

  group('views', () {
    late HistoryRepository history;
    setUp(() => history = useMemoryHistory());

    final body = '${readerChapters()}\n\n[chapter:Coda]\n\n$readerParagraph';
    Finder card() => find.byKey(const ValueKey('reader-end-card'));

    /// Whether the card is on the screen (a card built ahead lies below it).
    bool cardShown(WidgetTester tester) => card().evaluate().isNotEmpty && tester.getRect(card()).top < tester.view.physicalSize.height;
    ScrollPosition position(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

    Future<int> novelId(WidgetTester tester) async => readerState(tester).widget.detail.novel.id;

    Future<void> mount(WidgetTester tester, {Map<String, dynamic> settings = readerScrollSettings}) =>
        mountReader(tester, history, text: readerText(body), settings: settings);

    Future<void> reopen(WidgetTester tester, {Map<String, dynamic> settings = readerScrollSettings}) async {
      await tester.pumpWidget(const SizedBox());
      await readerStorageIdle(tester);
      await mount(tester, settings: settings);
    }

    Future<void> storedAs(WidgetTester tester, int id, int offset, int length) async {
      await tester.runAsync(() => saveReadingProgress(id, offset: offset, totalLength: length));
    }

    for (final (name, settings) in [('scroll', readerScrollSettings), ('paged', readerPagedSettings)]) {
      group(name, () {
        testWidgets('opening with the saved offset at the end of the text shows the end card', (tester) async {
          await mount(tester, settings: settings);
          final id = await novelId(tester);
          final length = readerController(tester).model.totalLength;
          await storedAs(tester, id, length, length);
          await reopen(tester, settings: settings);
          expect(card(), findsOneWidget);
          expect(readerController(tester).atEnd, isTrue);
          expect(readerController(tester).progress, 1.0);
          if (name == 'paged') {
            final view = tester.state<ReaderPagedViewState>(find.byType(ReaderPagedView));
            expect(view.showsEnd, !view.endCardOnLastPage, reason: 'the page holding the card');
          } else {
            expect(position(tester).pixels, closeTo(position(tester).maxScrollExtent, .5));
          }
        });

        testWidgets('goToEnd shows the end card', (tester) async {
          await mount(tester, settings: settings);
          expect(cardShown(tester), isFalse);
          readerController(tester).goToEnd();
          await settlePilot(tester);
          expect(card(), findsOneWidget);
          if (name == 'scroll') expect(position(tester).pixels, closeTo(position(tester).maxScrollExtent, .5));
        });

        testWidgets('going back from the end and reopening lands on the real offset', (tester) async {
          await mount(tester, settings: settings);
          final id = await novelId(tester);
          final controller = readerController(tester);
          controller.goToEnd();
          await settlePilot(tester);
          await controller.saveNow();
          final atEnd = await tester.runAsync(() => loadReadingProgress(id));
          expect(atEnd?.offset, atEnd?.totalLength, reason: 'the end is saved');

          if (name == 'scroll') {
            position(tester).jumpTo(position(tester).maxScrollExtent - 3 * position(tester).viewportDimension);
          } else {
            expect(controller.previousScreen(), isTrue);
            expect(controller.previousScreen(), isTrue);
          }
          await settlePilot(tester);
          expect(controller.atEnd, isFalse);
          final offset = controller.offset;
          expect(offset, lessThan(controller.model.totalLength));
          await controller.saveNow();
          final left = await tester.runAsync(() => loadReadingProgress(id));
          expect(left?.offset, offset, reason: 'leaving the end saves the real offset');

          await reopen(tester, settings: settings);
          expect(cardShown(tester), isFalse);
          expect(readerController(tester).atEnd, isFalse);
          expect(readerController(tester).offset, offset);
        });
      });
    }

    testWidgets('scroll: the view stays at the bottom while pictures and measuring change the extents', (tester) async {
      await mount(tester);
      final id = await novelId(tester);
      final length = readerController(tester).model.totalLength;
      await storedAs(tester, id, length, length);
      await reopen(tester);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(position(tester).pixels, closeTo(position(tester).maxScrollExtent, .5), reason: 'frame $i');
      }
    });
  });
}
