import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_scroll_view.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

/// What the layout owes the position while a fling coasts changes neither
/// its direction nor its speed.
void main() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  const frame = Duration(milliseconds: 16);

  String body({int before = 2, int after = 80}) =>
      [for (var i = 0; i < before; i++) '$readerParagraph a$i', '[uploadedimage:1]', for (var i = 0; i < after; i++) '$readerParagraph b$i'].join('\n\n');

  Future<void> mount(WidgetTester tester, {String? text}) => mountReader(
    tester,
    history,
    text: readerText(
      text ?? body(),
      images: [WebviewNovelImage(novelImageId: '1', urls: const WebviewNovelImageUrls())],
    ),
  );

  ScrollPosition position(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;
  ReaderScrollViewState scrollView(WidgetTester tester) => tester.state<ReaderScrollViewState>(find.byType(ReaderScrollView));

  Future<void> pumpFrames(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(frame);
    }
  }

  group('corrections during a fling', () {
    /// The screen position of the text at the reading line when [offset] was
    /// first sampled, frame after frame.
    Future<List<double>> watch(WidgetTester tester, int offset, int frames, {void Function(int frame)? each}) async {
      final layout = readerState(tester).layout!;
      final ys = <double>[];
      for (var i = 0; i < frames; i++) {
        each?.call(i);
        await tester.pump(frame);
        ys.add(layout.pixelOfOffset(offset) - position(tester).pixels);
      }
      return ys;
    }

    /// The change from one frame to the next, from the first frame the text
    /// moves (a fling's first tick has no time elapsed).
    List<double> steps(List<double> ys) {
      final all = [for (var i = 1; i < ys.length; i++) ys[i] - ys[i - 1]];
      final first = all.indexWhere((move) => move.abs() > 0.5);
      return first < 0 ? const [] : all.sublist(first);
    }

    for (final waited in [0, 1, 2]) {
      testWidgets('a picture above the reading line changing size, $waited frames into a fling back, keeps its direction and speed', (tester) async {
        await mount(tester);
        final layout = readerState(tester).layout!;
        final picture = layout.model.imageBlocks.single;
        position(tester).jumpTo(layout.topOf(picture + 30));
        await settlePilot(tester);
        final finder = find.byType(Scrollable).first;

        await tester.fling(finder, const Offset(0, -500), 3000);
        await pumpFrames(tester, 4);
        await tester.fling(finder, const Offset(0, 500), 3000);
        await pumpFrames(tester, waited);
        final offset = layout.offsetAtPixel(position(tester).pixels);
        final before = layout.pixelOfOffset(offset) - position(tester).pixels;

        final ys = <double>[before];
        ys.addAll(await watch(tester, offset, 2));
        final extent = layout.extentOf(picture);
        scrollView(tester).imageSized(picture, const Size(1600, 400));
        expect(layout.extentOf(picture), isNot(closeTo(extent, 1)));
        ys.addAll(await watch(tester, offset, 8));

        final moves = steps(ys);
        expect(moves.length, greaterThan(6), reason: 'the fling moves the text');
        for (final (i, move) in moves.indexed) {
          expect(move, greaterThan(0), reason: 'frame $i keeps the direction');
        }
        // No frame goes at half the speed of the one before it, and none jumps.
        for (var i = 1; i < moves.length; i++) {
          expect(moves[i], greaterThan(moves[i - 1] * 0.7), reason: 'frame $i: the speed is not halved');
          expect(moves[i], lessThan(moves[i - 1] * 1.3 + 2), reason: 'frame $i: nothing jumps');
        }
      });
    }

    testWidgets('a correction at rest keeps the reading line', (tester) async {
      await mount(tester);
      final layout = readerState(tester).layout!;
      final picture = layout.model.imageBlocks.single;
      position(tester).jumpTo(layout.topOf(picture + 10));
      await settlePilot(tester);
      final offset = layout.offsetAtPixel(position(tester).pixels);
      final before = layout.pixelOfOffset(offset) - position(tester).pixels;
      final pixels = position(tester).pixels;

      scrollView(tester).imageSized(picture, const Size(1600, 400));
      await tester.pump();

      expect(position(tester).pixels, isNot(closeTo(pixels, 1)), reason: 'the position followed the picture');
      expect(layout.pixelOfOffset(offset) - position(tester).pixels, closeTo(before, 0.5));
      expect(layout.offsetAtPixel(position(tester).pixels), offset);
    });

    testWidgets('background measuring above a fling changes no direction and makes no jump', (tester) async {
      ReaderScrollViewState.debugMeasurePass = (layout, anchor) {
        var done = false;
        for (var i = 0; i < 6 && !done; i++) {
          done = layout.measureSome(anchor, Duration.zero);
        }
        return done;
      };
      addTearDown(() => ReaderScrollViewState.debugMeasurePass = null);
      await mount(tester, text: body(before: 2, after: 300));
      final layout = readerState(tester).layout!;
      // Far down, with the text above still estimated.
      position(tester).jumpTo(layout.topOf(layout.blockCount - 60));
      await tester.pump();
      final finder = find.byType(Scrollable).first;
      await tester.fling(finder, const Offset(0, 500), 3000);
      final offset = layout.offsetAtPixel(position(tester).pixels);
      final ys = <double>[layout.pixelOfOffset(offset) - position(tester).pixels];
      ys.addAll(await watch(tester, offset, 40));

      final moves = steps(ys);
      for (final (i, move) in moves.indexed) {
        expect(move, greaterThanOrEqualTo(-0.5), reason: 'frame $i: the text keeps moving the way the fling goes');
      }
      for (var i = 1; i < moves.length; i++) {
        expect((moves[i] - moves[i - 1]).abs(), lessThan(25), reason: 'frame $i: no jump of what was measured');
      }
    });
  });
}
