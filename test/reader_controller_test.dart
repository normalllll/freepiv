import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_controller.dart';

class FakeViewport implements ReaderViewport {
  final shown = <int>[];
  final turns = <int>[];
  bool turnResult = true;

  @override
  void showOffset(int offset) => shown.add(offset);

  @override
  bool turn(int direction) {
    turns.add(direction);
    return turnResult;
  }
}

class SinkCalls {
  final calls = <(int, int)>[];
  Object? error;

  Future<void> call(int offset, int totalLength) async {
    calls.add((offset, totalLength));
    if (error != null) throw error!;
  }
}

ReaderModel modelOf(String text) => ReaderModel(parseNovelText(text));

const chaptered = '[chapter:One]\nalpha beta gamma\n[chapter:Two]\ndelta epsilon\n[chapter:Three]\nzeta eta theta iota';
const sectioned = 'first section text\n[newpage]\nsecond section text\n[newpage]\nthird section text';

ReaderController make(
  ReaderModel model, {
  int initial = 0,
  ReaderPageMode mode = ReaderPageMode.scroll,
  required SinkCalls sink,
  Duration interval = const Duration(seconds: 1),
}) => ReaderController(model: model, initialOffset: initial, mode: mode, save: sink.call, saveInterval: interval);

void main() {
  final chapterModel = modelOf(chaptered);
  final sectionModel = modelOf(sectioned);
  final total = chapterModel.totalLength;

  test('test model has three chapters and three sections', () {
    expect(chapterModel.chapters.length, 3);
    expect(sectionModel.pageCount, 3);
    expect(total, greaterThan(10));
  });

  group('initial state', () {
    test('keeps an offset inside the text', () {
      final c = make(chapterModel, initial: 7, sink: SinkCalls());
      expect(c.offset, 7);
      expect(c.model, same(chapterModel));
    });

    test('clamps a negative initial offset to 0', () {
      expect(make(chapterModel, initial: -5, sink: SinkCalls()).offset, 0);
    });

    test('clamps an initial offset past the end to the total length', () {
      expect(make(chapterModel, initial: total + 100, sink: SinkCalls()).offset, total);
    });

    test('reports the mode it was given', () {
      expect(make(chapterModel, mode: ReaderPageMode.paged, sink: SinkCalls()).mode, ReaderPageMode.paged);
    });

    test('chapter follows the offset', () {
      final c = make(chapterModel, initial: chapterModel.chapters[1].startOffset + 1, sink: SinkCalls());
      expect(c.chapter.index, 1);
    });

    test('is not at the end initially', () {
      expect(make(chapterModel, sink: SinkCalls()).atEnd, isFalse);
    });
  });

  group('viewport attachment', () {
    test('attach shows the current offset immediately', () {
      final c = make(chapterModel, initial: 12, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      expect(v.shown, [12]);
    });

    test('detach of the attached viewport stops commands reaching it', () {
      final c = make(chapterModel, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      c.detach(v);
      v.shown.clear();
      c.goToOffset(5);
      expect(v.shown, isEmpty);
      expect(c.nextScreen(), isFalse);
      expect(v.turns, isEmpty);
    });

    test('detach of a viewport that is not attached is ignored', () {
      final c = make(chapterModel, sink: SinkCalls());
      final current = FakeViewport();
      final other = FakeViewport();
      c.attach(current);
      c.detach(other);
      current.shown.clear();
      c.goToOffset(5);
      expect(current.shown, [5]);
    });

    test('a newly attached viewport replaces the previous one', () {
      final c = make(chapterModel, initial: 3, sink: SinkCalls());
      final first = FakeViewport();
      final second = FakeViewport();
      c.attach(first);
      c.attach(second);
      expect(second.shown, [3]);
      c.detach(first);
      c.goToOffset(8);
      expect(second.shown, [3, 8]);
      expect(first.shown, [3]);
    });
  });

  group('reportPosition', () {
    test('updates offset and never calls the viewport', () {
      final c = make(chapterModel, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      v.shown.clear();
      c.reportPosition(9);
      c.reportPosition(15, atEnd: true);
      expect(c.offset, 15);
      expect(v.shown, isEmpty);
      expect(v.turns, isEmpty);
    });

    test('records atEnd as last reported', () {
      final c = make(chapterModel, sink: SinkCalls());
      c.reportPosition(10, atEnd: true);
      expect(c.atEnd, isTrue);
      c.reportPosition(10);
      expect(c.atEnd, isFalse);
    });

    test('clamps the reported offset to the text', () {
      final c = make(chapterModel, sink: SinkCalls());
      c.reportPosition(total + 50);
      expect(c.offset, total);
      c.reportPosition(-3);
      expect(c.offset, 0);
    });
  });

  group('go to', () {
    test('goToOffset sets, clamps and shows the offset', () {
      final c = make(chapterModel, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      v.shown.clear();
      c.goToOffset(11);
      expect(c.offset, 11);
      c.goToOffset(-4);
      expect(c.offset, 0);
      c.goToOffset(total + 9);
      expect(c.offset, total);
      expect(v.shown, [11, 0, total]);
    });

    test('goToFraction maps a fraction of the total length, rounded', () {
      final c = make(chapterModel, sink: SinkCalls());
      c.goToFraction(0.5);
      expect(c.offset, (0.5 * total).round());
      c.goToFraction(0.37);
      expect(c.offset, (0.37 * total).round());
    });

    test('goToFraction clamps the fraction to 0..1', () {
      final c = make(chapterModel, initial: 5, sink: SinkCalls());
      c.goToFraction(1.7);
      expect(c.offset, total);
      c.goToFraction(-0.4);
      expect(c.offset, 0);
    });

    test('goToFraction shows the offset in the viewport', () {
      final c = make(chapterModel, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      v.shown.clear();
      c.goToFraction(1);
      expect(v.shown, [total]);
    });

    test('goToChapter goes to the chapter start', () {
      final c = make(chapterModel, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      v.shown.clear();
      c.goToChapter(1);
      expect(c.offset, chapterModel.chapters[1].startOffset);
      expect(v.shown, [chapterModel.chapters[1].startOffset]);
    });

    test('goToChapter clamps the index', () {
      final c = make(chapterModel, initial: 5, sink: SinkCalls());
      c.goToChapter(99);
      expect(c.offset, chapterModel.chapters.last.startOffset);
      c.goToChapter(-3);
      expect(c.offset, chapterModel.chapters.first.startOffset);
    });

    test('goToPixivPage goes to the section offset', () {
      final c = make(sectionModel, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      v.shown.clear();
      c.goToPixivPage(2);
      expect(c.offset, sectionModel.offsetOfPage(2));
      expect(c.offset, greaterThan(0));
      c.goToPixivPage(3);
      expect(c.offset, sectionModel.offsetOfPage(3));
      expect(v.shown, [sectionModel.offsetOfPage(2), sectionModel.offsetOfPage(3)]);
    });

    test('goToPixivPage clamps like the model', () {
      final c = make(sectionModel, initial: 4, sink: SinkCalls());
      c.goToPixivPage(50);
      expect(c.offset, sectionModel.offsetOfPage(sectionModel.pageCount));
      c.goToPixivPage(0);
      expect(c.offset, 0);
    });

    test('goToStart and goToEnd', () {
      final c = make(chapterModel, initial: 10, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      v.shown.clear();
      c.goToEnd();
      expect(c.offset, total);
      c.goToStart();
      expect(c.offset, 0);
      expect(v.shown, [total, 0]);
    });
  });

  group('chapters', () {
    test('nextChapter moves to the next chapter start and returns true', () {
      final c = make(chapterModel, initial: 2, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      v.shown.clear();
      expect(c.nextChapter(), isTrue);
      expect(c.offset, chapterModel.chapters[1].startOffset);
      expect(v.shown, [chapterModel.chapters[1].startOffset]);
      expect(c.nextChapter(), isTrue);
      expect(c.offset, chapterModel.chapters[2].startOffset);
    });

    test('nextChapter on the last chapter returns false and does not move', () {
      final last = chapterModel.chapters.last;
      final c = make(chapterModel, initial: last.startOffset + 3, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      v.shown.clear();
      expect(c.nextChapter(), isFalse);
      expect(c.offset, last.startOffset + 3);
      expect(v.shown, isEmpty);
    });

    test('previousChapter goes to the previous chapter start', () {
      final second = chapterModel.chapters[1];
      final c = make(chapterModel, initial: second.startOffset + 4, sink: SinkCalls());
      expect(c.previousChapter(), isTrue);
      expect(c.offset, chapterModel.chapters[0].startOffset);
    });

    test('previousChapter on the first chapter goes to 0 and returns true when not at 0', () {
      final c = make(chapterModel, initial: 6, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      v.shown.clear();
      expect(c.chapter.index, 0);
      expect(c.previousChapter(), isTrue);
      expect(c.offset, 0);
      expect(v.shown, [0]);
    });

    test('previousChapter at offset 0 returns false', () {
      final c = make(chapterModel, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      v.shown.clear();
      expect(c.previousChapter(), isFalse);
      expect(c.offset, 0);
      expect(v.shown, isEmpty);
    });
  });

  group('screens', () {
    test('nextScreen and previousScreen forward the direction and return the result', () {
      final c = make(chapterModel, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      expect(c.nextScreen(), isTrue);
      expect(c.previousScreen(), isTrue);
      expect(v.turns, [1, -1]);
      v.turnResult = false;
      expect(c.nextScreen(), isFalse);
      expect(c.previousScreen(), isFalse);
      expect(v.turns, [1, -1, 1, -1]);
    });

    test('without a viewport both return false', () {
      final c = make(chapterModel, sink: SinkCalls());
      expect(c.nextScreen(), isFalse);
      expect(c.previousScreen(), isFalse);
    });

    test('turning does not itself change the offset', () {
      final c = make(chapterModel, initial: 5, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      c.nextScreen();
      expect(c.offset, 5);
    });
  });

  group('mode', () {
    test('changing mode keeps the offset, notifies and re-shows the offset', () {
      final c = make(chapterModel, initial: 14, sink: SinkCalls());
      final v = FakeViewport();
      c.attach(v);
      v.shown.clear();
      var notified = 0;
      c.addListener(() => notified++);
      c.mode = ReaderPageMode.paged;
      expect(c.mode, ReaderPageMode.paged);
      expect(c.offset, 14);
      expect(notified, 1);
      expect(v.shown, [14]);
    });

    test('setting the same mode does not notify', () {
      final c = make(chapterModel, sink: SinkCalls());
      var notified = 0;
      c.addListener(() => notified++);
      c.mode = ReaderPageMode.scroll;
      expect(notified, 0);
    });

    test('changing mode without a viewport is fine', () {
      final c = make(chapterModel, sink: SinkCalls());
      c.mode = ReaderPageMode.paged;
      expect(c.mode, ReaderPageMode.paged);
    });
  });

  group('progress', () {
    test('is offset over total length', () {
      final c = make(chapterModel, initial: 10, sink: SinkCalls());
      expect(c.progress, closeTo(10 / total, 1e-9));
      expect(make(chapterModel, sink: SinkCalls()).progress, 0);
    });

    test('is 1.0 when the view reported the end, even before the last character', () {
      final c = make(chapterModel, sink: SinkCalls());
      c.reportPosition(total - 3, atEnd: true);
      expect(c.progress, 1.0);
    });

    test('leaves 1.0 once the view reports a non-end position', () {
      final c = make(chapterModel, sink: SinkCalls());
      c.reportPosition(total - 3, atEnd: true);
      c.reportPosition(total - 3);
      expect(c.progress, closeTo((total - 3) / total, 1e-9));
    });

    test('is 0 for empty text', () {
      final empty = modelOf('');
      expect(empty.totalLength, 0);
      final c = make(empty, sink: SinkCalls());
      expect(c.offset, 0);
      expect(c.progress, 0);
    });
  });

  group('notifications', () {
    test('notify only when offset, atEnd or mode really change', () {
      final c = make(chapterModel, initial: 5, sink: SinkCalls());
      var notified = 0;
      c.addListener(() => notified++);

      c.reportPosition(5);
      expect(notified, 0);
      c.reportPosition(6);
      expect(notified, 1);
      c.reportPosition(6);
      expect(notified, 1);
      c.reportPosition(6, atEnd: true);
      expect(notified, 2);
      c.reportPosition(6, atEnd: true);
      expect(notified, 2);
      c.goToOffset(6);
      expect(notified, 2);
      c.goToOffset(9);
      expect(notified, 3);
      c.goToOffset(total + 20);
      expect(notified, 4);
      c.goToOffset(total + 40);
      expect(notified, 4);
    });

    test('clamped commands that land on the same offset do not notify', () {
      final c = make(chapterModel, sink: SinkCalls());
      var notified = 0;
      c.addListener(() => notified++);
      c.goToOffset(-10);
      c.goToStart();
      expect(notified, 0);
    });
  });

  group('saving', () {
    testWidgets('a change saves once after the interval with the offset and total length', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, sink: sink);
        c.reportPosition(10);
        await tester.pump(const Duration(milliseconds: 999));
        expect(sink.calls, isEmpty);
        await tester.pump(const Duration(milliseconds: 1));
        expect(sink.calls, [(10, total)]);
    });

    testWidgets('changes within the interval save only the latest offset', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, sink: sink);
        c.reportPosition(10);
        await tester.pump(const Duration(milliseconds: 400));
        c.reportPosition(20);
        c.goToOffset(25);
        await tester.pump(const Duration(milliseconds: 600));
        expect(sink.calls, [(25, total)]);
        await tester.pump(const Duration(seconds: 5));
        expect(sink.calls.length, 1);
    });

    testWidgets('a change after a save starts a new interval', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, sink: sink);
        c.reportPosition(10);
        await tester.pump(const Duration(seconds: 1));
        c.reportPosition(30);
        await tester.pump(const Duration(milliseconds: 500));
        expect(sink.calls.length, 1);
        await tester.pump(const Duration(milliseconds: 500));
        expect(sink.calls, [(10, total), (30, total)]);
    });

    testWidgets('a custom interval is honoured', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, sink: sink, interval: const Duration(seconds: 3));
        c.reportPosition(10);
        await tester.pump(const Duration(seconds: 2));
        expect(sink.calls, isEmpty);
        await tester.pump(const Duration(seconds: 1));
        expect(sink.calls, [(10, total)]);
    });

    testWidgets('commands schedule a save too', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, sink: sink);
        c.goToChapter(2);
        await tester.pump(const Duration(seconds: 1));
        expect(sink.calls, [(chapterModel.chapters[2].startOffset, total)]);
    });

    testWidgets('nothing is saved when the offset is back at the initial offset', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, initial: 7, sink: sink);
        c.reportPosition(15);
        c.reportPosition(7);
        await tester.pump(const Duration(seconds: 3));
        expect(sink.calls, isEmpty);
    });

    testWidgets('nothing is saved when the offset equals the last saved offset', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, sink: sink);
        c.reportPosition(10);
        await tester.pump(const Duration(seconds: 1));
        c.reportPosition(18);
        c.reportPosition(10);
        await tester.pump(const Duration(seconds: 3));
        expect(sink.calls, [(10, total)]);
    });

    testWidgets('a clamped initial offset counts as the initial offset', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, initial: total + 40, sink: sink);
        c.goToOffset(total + 1);
        c.saveNow();
        await tester.pump(const Duration(seconds: 3));
        expect(sink.calls, isEmpty);
    });

    testWidgets('saveNow writes immediately and cancels the pending timer', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, sink: sink);
        c.reportPosition(12);
        c.saveNow();
        await tester.pump();
        expect(sink.calls, [(12, total)]);
        await tester.pump(const Duration(seconds: 5));
        expect(sink.calls.length, 1);
    });

    testWidgets('saveNow twice writes once', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, sink: sink);
        c.reportPosition(12);
        c.saveNow();
        c.saveNow();
        await tester.pump();
        expect(sink.calls.length, 1);
    });

    testWidgets('saveNow without a change writes nothing', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, initial: 4, sink: sink);
        c.saveNow();
        await tester.pump();
        expect(sink.calls, isEmpty);
    });

    testWidgets('dispose saves a changed offset', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, sink: sink);
        c.reportPosition(16);
        c.dispose();
        await tester.pump();
        expect(sink.calls, [(16, total)]);
        await tester.pump(const Duration(seconds: 5));
        expect(sink.calls.length, 1);
    });

    testWidgets('dispose without a change writes nothing', (tester) async {
        final sink = SinkCalls();
        final c = make(chapterModel, sink: sink);
        c.dispose();
        await tester.pump();
        expect(sink.calls, isEmpty);
    });

    testWidgets('sink errors are swallowed by saveNow', (tester) async {
        final sink = SinkCalls()..error = StateError('disk full');
        final c = make(chapterModel, sink: sink);
        c.reportPosition(10);
        Object? thrown;
        c.saveNow().catchError((Object e) => thrown = e);
        await tester.pump();
        expect(sink.calls, [(10, total)]);
        expect(thrown, isNull);
    });

    testWidgets('sink errors are swallowed by the timed save and by dispose', (tester) async {
        final sink = SinkCalls()..error = StateError('disk full');
        final c = make(chapterModel, sink: sink);
        c.reportPosition(10);
        await tester.pump(const Duration(seconds: 1));
        c.reportPosition(20);
        c.dispose();
        await tester.pump();
        expect(sink.calls.isNotEmpty, isTrue);
    });
  });
}
