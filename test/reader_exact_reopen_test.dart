import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/core/media/image_size_store.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

/// Reopening a text in scroll mode lands on the pixel it was left on, not on
/// the top of the line holding it.
void main() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  ScrollPosition position(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  Future<void> reopen(WidgetTester tester, Size size, Map<String, dynamic> settings) async {
    await tester.pumpWidget(const SizedBox());
    await readerStorageIdle(tester);
    await mountReader(tester, history, size: size, settings: settings);
  }

  for (final width in [390.0, 750.0]) {
    final size = Size(width, 800);
    for (final depth in [0.3, 0.7]) {
      testWidgets('a depth of $depth inside the line is restored to the pixel, at $width', (tester) async {
        await mountReader(tester, history, size: size);
        final layout = readerState(tester).layout!;
        final controller = readerController(tester);
        final line = layout.offsetAtPixel(2000);
        final pixel = layout.pixelOfPosition(line, depth);
        expect(pixel, greaterThan(layout.pixelOfOffset(line) + 1), reason: 'the reading line is inside its line');
        position(tester).jumpTo(pixel);
        await settlePilot(tester);
        expect(controller.offset, line);
        expect(controller.depth, closeTo(depth, 0.01));
        await controller.saveNow();
        final id = readerState(tester).widget.detail.novel.id;
        final stored = await tester.runAsync(() => loadReadingProgress(id));
        expect(stored!.offset, line);
        expect(stored.depth, closeTo(depth, 0.01), reason: 'the depth is saved with the offset');

        await reopen(tester, size, readerScrollSettings);
        expect(position(tester).pixels, closeTo(pixel, 0.5), reason: 'the same pixel');
        expect(readerController(tester).depth, closeTo(depth, 0.01));
      });
    }
  }

  testWidgets('an offset that no longer starts a line reopens at the top of its line', (tester) async {
    const size = Size(390, 800);
    await mountReader(tester, history, size: size);
    final layout = readerState(tester).layout!;
    final id = readerState(tester).widget.detail.novel.id;
    final line = layout.offsetAtPixel(2000);
    final inside = line + 3;
    expect(layout.offsetAtPixel(layout.pixelOfOffset(inside)), line, reason: 'the offset lies inside a line');
    await tester.runAsync(() => saveReadingProgress(id, offset: inside, totalLength: readerController(tester).model.totalLength, depth: 0.5));

    await reopen(tester, size, readerScrollSettings);
    final top = readerState(tester).layout!.pixelOfOffset(inside);
    expect(position(tester).pixels, closeTo(top, 0.5), reason: 'the line alone');
  });
  testWidgets('a reading line inside a picture reopens inside it', (tester) async {
    const size = Size(390, 800);
    final body = [for (var i = 0; i < 3; i++) '$readerParagraph a$i', '[uploadedimage:1]', for (var i = 0; i < 20; i++) '$readerParagraph b$i'].join('\n\n');
    final text = readerText(body);
    // The picture's size is known to the second opening, as it is on a device.
    final sizes = {imageSizeStoreProvider: imageSizeStoreProvider.overrideWithValue(MemoryImageSizeStore())};
    await mountReader(tester, history, text: text, size: size, overrides: sizes);
    final layout = readerState(tester).layout!;
    final controller = readerController(tester);
    final block = layout.model.imageBlocks.single;
    final offset = layout.model.offsetOf(block);
    final pixel = layout.pixelOfPosition(offset, 0.6);
    expect(pixel, greaterThan(layout.topOf(block) + 10), reason: 'well inside the picture');
    position(tester).jumpTo(pixel);
    await settlePilot(tester);
    expect(controller.depth, closeTo(0.6, 0.02));
    await controller.saveNow();

    await tester.pumpWidget(const SizedBox());
    await readerStorageIdle(tester);
    await mountReader(tester, history, text: text, size: size, overrides: sizes);
    expect(position(tester).pixels, closeTo(pixel, 0.5), reason: 'the same pixel inside the picture');
  });
}
