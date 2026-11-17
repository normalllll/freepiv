import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_scroll_view.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

import 'support/memory_history.dart';
import 'support/reader_harness.dart';

/// Which way a picture's change of size pushes the text: down from the
/// picture's top edge, with the scroll offset corrected only for a picture
/// wholly above the top of the view.
void main() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  const landscape = Size(1600, 400);
  const portrait = Size(400, 1600);

  String body({required int before}) =>
      [for (var i = 0; i < before; i++) '$readerParagraph a$i', '[uploadedimage:1]', for (var i = 0; i < 40; i++) '$readerParagraph b$i'].join('\n\n');

  ScrollPosition position(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  Future<void> sized(WidgetTester tester, int block, Size size) async {
    tester.state<ReaderScrollViewState>(find.byType(ReaderScrollView)).imageSized(block, size);
    await tester.pump();
    await tester.pump();
  }

  Future<void> mount(WidgetTester tester, int before) => mountReader(
    tester,
    history,
    text: readerText(
      body(before: before),
      images: [WebviewNovelImage(novelImageId: '1', urls: const WebviewNovelImageUrls())],
    ),
  );

  testWidgets('a picture wholly above the top of the view corrects the offset, and the visible text stays', (tester) async {
    await mount(tester, 3);
    final layout = readerState(tester).layout!;
    final picture = layout.model.imageBlocks.single;
    // Three paragraphs below the picture: the picture is well above the top.
    position(tester).jumpTo(layout.topOf(picture + 4));
    await tester.pump();
    await tester.pump();
    final pixels = position(tester).pixels;
    expect(pixels, greaterThan(layout.topOf(picture) + layout.extentOf(picture)), reason: 'wholly above');
    final reading = layout.offsetAtPixel(pixels);
    double screenY() => layout.pixelOfOffset(reading) - position(tester).pixels;
    final before = screenY();
    final extent = layout.extentOf(picture);

    await sized(tester, picture, landscape);

    expect(layout.extentOf(picture), isNot(closeTo(extent, 1)));
    expect(position(tester).pixels, closeTo(pixels + layout.extentOf(picture) - extent, 0.5), reason: 'the offset follows the picture');
    expect(layout.offsetAtPixel(position(tester).pixels), reading);
    expect(screenY(), closeTo(before, 0.5));
  });

  testWidgets('a picture straddling the top edge grows downward: the offset stays and the text below moves', (tester) async {
    await mount(tester, 3);
    final layout = readerState(tester).layout!;
    final picture = layout.model.imageBlocks.single;
    await sized(tester, picture, landscape);
    position(tester).jumpTo(layout.topOf(picture) + layout.extentOf(picture) / 2);
    await tester.pump();
    await tester.pump();
    final pixels = position(tester).pixels;
    final below = layout.topOf(picture + 1);
    final extent = layout.extentOf(picture);

    await sized(tester, picture, portrait);

    final grown = layout.extentOf(picture) - extent;
    expect(grown, greaterThan(100), reason: 'the picture grew');
    expect(position(tester).pixels, closeTo(pixels, 0.5), reason: 'the offset is unchanged');
    expect(layout.topOf(picture + 1) - below, closeTo(grown, 0.5), reason: 'the text below moved down by the growth');
  });

  testWidgets('a picture below the top edge on screen grows downward with the offset unchanged', (tester) async {
    await mount(tester, 3);
    final layout = readerState(tester).layout!;
    final picture = layout.model.imageBlocks.single;
    await sized(tester, picture, landscape);
    position(tester).jumpTo(layout.topOf(picture) - 100);
    await tester.pump();
    await tester.pump();
    final pixels = position(tester).pixels;
    final below = layout.topOf(picture + 1);
    final extent = layout.extentOf(picture);

    await sized(tester, picture, portrait);

    expect(position(tester).pixels, closeTo(pixels, 0.5));
    expect(layout.topOf(picture + 1) - below, closeTo(layout.extentOf(picture) - extent, 0.5));
    expect(layout.extentOf(picture), greaterThan(extent + 100));
  });

  testWidgets('at offset 0 with a picture first, a size arriving leaves the offset 0 and moves the text below down', (tester) async {
    await mountReader(
      tester,
      history,
      text: readerText(
        body(before: 0),
        images: [WebviewNovelImage(novelImageId: '1', urls: const WebviewNovelImageUrls())],
      ),
    );
    final layout = readerState(tester).layout!;
    final picture = layout.model.imageBlocks.single;
    expect(picture, 0);
    expect(position(tester).pixels, 0);
    // The header of a short, wide picture came first; then a taller one is learned.
    await sized(tester, picture, landscape);
    final below = layout.topOf(1);

    await sized(tester, picture, portrait);

    expect(position(tester).pixels, 0, reason: 'the offset stays 0');
    expect(readerController(tester).offset, 0);
    expect(layout.topOf(1), greaterThan(below + 100), reason: 'the text below moved down');
  });

  testWidgets('a size of the shape already known leaves the frame as it is', (tester) async {
    await mount(tester, 3);
    final layout = readerState(tester).layout!;
    final picture = layout.model.imageBlocks.single;
    await sized(tester, picture, const Size(240, 173));
    final extent = layout.extentOf(picture);
    final below = layout.topOf(picture + 1);

    // The decoded size of a larger variant: 0.2 % apart in ratio.
    await sized(tester, picture, const Size(1200, 865));
    expect(layout.extentOf(picture), extent);
    expect(layout.topOf(picture + 1), below);

    // A different shape does change it.
    await sized(tester, picture, const Size(240, 240));
    expect(layout.extentOf(picture), isNot(closeTo(extent, 1)));
  });
}
