import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_scroll_view.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

/// A touch that stops a fling does not turn the page; a tap at rest does.
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

  group('a touch during a fling', () {
    for (final (name, share) in [('right third', 0.85), ('left third', 0.15)]) {
      testWidgets('in the $name only stops it', (tester) async {
        await mount(tester);
        position(tester).jumpTo(3000);
        await settlePilot(tester);
        await tester.fling(find.byType(Scrollable).first, const Offset(0, -500), 3000);
        await pumpFrames(tester, 10);
        expect(scrollView(tester).isCoasting, isTrue, reason: 'the fling is coasting');
        final stoppedAt = position(tester).pixels;
        final size = tester.view.physicalSize;

        await tester.tapAt(Offset(size.width * share, size.height / 2));
        await settlePilot(tester);

        expect((position(tester).pixels - stoppedAt).abs(), lessThan(120), reason: 'the view stays where the touch stopped it, not a screen on');
        expect(scrollView(tester).isCoasting, isFalse);
      });
    }

    testWidgets('a tap at rest turns forward and back', (tester) async {
      await mount(tester);
      position(tester).jumpTo(3000);
      await settlePilot(tester);
      final size = tester.view.physicalSize;
      final screen = position(tester).viewportDimension - readerState(tester).layout!.typesetting.bodyLinePx;
      final start = position(tester).pixels;

      await tester.tapAt(Offset(size.width * 0.85, size.height / 2));
      await settlePilot(tester);
      expect(position(tester).pixels, closeTo(start + screen, 2));

      await tester.tapAt(Offset(size.width * 0.15, size.height / 2));
      await settlePilot(tester);
      expect(position(tester).pixels, closeTo(start, 2));
    });

    testWidgets('two quick taps at rest turn twice, the second during the turn of the first', (tester) async {
      await mount(tester);
      position(tester).jumpTo(3000);
      await settlePilot(tester);
      final size = tester.view.physicalSize;
      final screen = position(tester).viewportDimension - readerState(tester).layout!.typesetting.bodyLinePx;
      final start = position(tester).pixels;

      await tester.tapAt(Offset(size.width * 0.85, size.height / 2));
      await pumpFrames(tester, 4);
      expect(scrollView(tester).isCoasting, isFalse, reason: 'the reader\'s own turn is not a fling');
      await tester.tapAt(Offset(size.width * 0.85, size.height / 2));
      await settlePilot(tester);

      expect(position(tester).pixels, greaterThan(start + 1.5 * screen), reason: 'twice');
      expect(position(tester).pixels, lessThan(start + 2 * screen + 2));
    });
  });
}
