import 'dart:async';

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_scroll_view.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

List<WebviewNovelImage> _images(Size size) => [
  for (final id in [1, 2])
    WebviewNovelImage(
      novelImageId: '$id',
      urls: WebviewNovelImageUrls(
        size240Mw: readerImageUrl(300 + id, width: 240, height: (240 * size.height / size.width).round()),
        size480Mw: readerImageUrl(300 + id, width: 480, height: (480 * size.height / size.width).round()),
        size1200X1200: readerImageUrl(300 + id, width: 1200, height: (1200 * size.height / size.width).round()),
        original: readerImageUrl(300 + id, width: size.width.round(), height: size.height.round()),
      ),
    ),
];

/// A picture that arrives when [gate] completes, like one on a slow network.
class _Gated extends ImageProvider<_Gated> {
  const _Gated(this.inner, this.gate);

  final ImageProvider inner;
  final Future<void> gate;

  @override
  Future<_Gated> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Gated key, ImageDecoderCallback decode) => OneFrameImageStreamCompleter(
    gate.then((_) {
      final done = Completer<ImageInfo>();
      final stream = inner.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener((info, _) {
        stream.removeListener(listener);
        done.complete(info);
      });
      stream.addListener(listener);
      return done.future;
    }),
  );

  @override
  bool operator ==(Object other) => other is _Gated && other.inner == inner && identical(other.gate, gate);

  @override
  int get hashCode => Object.hash(inner, gate);
}

/// Pictures arriving while the text is read: the line at the reading line
/// stays where it is on the screen.
void main() {
  flingTests();
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  final body = [
    for (var i = 0; i < 3; i++) '$readerParagraph a$i',
    '[uploadedimage:1]',
    for (var i = 0; i < 12; i++) '$readerParagraph b$i',
    '[uploadedimage:2]',
    for (var i = 0; i < 40; i++) '$readerParagraph c$i',
  ].join('\n\n');

  ScrollPosition position(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  for (final (name, size) in [('landscape', const Size(1600, 400)), ('tall', const Size(400, 1600)), ('wide', const Size(1200, 675))]) {
    // Where the reading line sits against the second picture, as a share of
    // its height, when the picture arrives.
    for (final (where, share) in [('above', -0.5), ('inside', 0.5)]) {
      testWidgets('$name picture arriving with the reading line $where it', (tester) async {
        await mountReader(tester, history, text: readerText(body, images: _images(size)));
        final gate = Completer<void>();
        final original = pixivImageOverride;
        pixivImageOverride = (url) {
          final image = original?.call(url);
          return image == null ? null : _Gated(image, gate.future);
        };
        addTearDown(() => pixivImageOverride = original);

        final layout = readerState(tester).layout!;
        final picture = layout.model.imageBlocks.last;
        layout.metricsOf(picture);
        final extent = layout.extentOf(picture);
        // Scroll so the picture is built and waiting; the share places the reading line.
        position(tester).jumpTo(layout.topOf(picture) - 200);
        await tester.pump();
        await tester.pump();
        position(tester).jumpTo((layout.topOf(picture) + extent * share).clamp(0, position(tester).maxScrollExtent));
        await tester.pump();
        await tester.pump();
        expect(find.byType(AppPixivImage), findsWidgets);

        final offset = layout.offsetAtPixel(position(tester).pixels);
        double screenY() => layout.pixelOfOffset(offset) - position(tester).pixels;
        final before = screenY();
        final unresolved = layout.extentOf(picture);
        gate.complete();
        for (var frame = 0; frame < 10; frame++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 20));
        }
        if (name != 'tall') expect(layout.extentOf(picture), isNot(closeTo(unresolved, 1)), reason: 'the picture reported its real size');
        if (where == 'above') expect(screenY(), closeTo(before, 0.5), reason: 'text above a picture that changed size does not move');
        expect(layout.offsetAtPixel(position(tester).pixels), inInclusiveRange(0, layout.model.totalLength));
      });
    }
  }
}

/// A picture resolving while the finger's fling still carries the text.
void flingTests() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  testWidgets('a picture above the reading line changing size during a fling leaves the text moving on from where it was', (tester) async {
    final body = ['$readerParagraph a', '[uploadedimage:1]', for (var i = 0; i < 60; i++) '$readerParagraph b$i'].join('\n\n');
    await mountReader(tester, history, text: readerText(body));
    final layout = readerState(tester).layout!;
    final picture = layout.model.imageBlocks.single;
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    scroll.jumpTo(layout.topOf(picture) + layout.extentOf(picture) + 300);
    await settlePilot(tester);

    await tester.fling(find.byType(Scrollable).first, const Offset(0, -400), 1200);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 100));
    final offset = layout.offsetAtPixel(scroll.pixels);
    double screenY() => layout.pixelOfOffset(offset) - scroll.pixels;
    final before = screenY();
    final extent = layout.extentOf(picture);
    // A landscape picture is much shorter than the one assumed before it arrived.
    tester.state<ReaderScrollViewState>(find.byType(ReaderScrollView)).imageSized(picture, const Size(1600, 400));
    expect((layout.extentOf(picture) - extent).abs(), greaterThan(200));
    await tester.pump(const Duration(milliseconds: 16));
    // The fling carries the text a few pixels in a frame, not the picture's change of height.
    expect((screenY() - before).abs(), lessThan(60), reason: 'the text kept its place under the finger');
    await settlePilot(tester);
  });
}
