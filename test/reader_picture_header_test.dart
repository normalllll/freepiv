import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/core/media/rust_media_source.dart' show appPictureStore;
import 'package:freepiv/features/novel/presentation/reader/views/reader_paged_view.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';

import 'support/memory_history.dart';
import 'support/reader_harness.dart';

/// A transport whose downloads start with the first bytes of a real file and
/// then wait: every address opened is recorded.
class _HeldTransport extends RustMediaTransport {
  _HeldTransport(this.head) : super(null);

  final Uint8List head;
  final opened = <String>[];
  final _open = <StreamController<rust.MediaChunk>>[];

  @override
  Stream<rust.MediaChunk> stream(String url, Map<String, String> headers) {
    opened.add(url);
    final controller = StreamController<rust.MediaChunk>();
    _open.add(controller);
    return controller.stream;
  }

  /// The first chunk of every download so far.
  void sendHeads() {
    for (final controller in _open) {
      controller.add(rust.MediaChunk(bytes: head, received: head.length, total: 80000));
    }
  }

  var _failed = 0;

  /// Fails the downloads still waiting, which the image cache retries a few
  /// times; the test ends with none left.
  void failPending() {
    for (final controller in _open.skip(_failed).toList()) {
      controller.addError(StateError('the test is over'));
      _failed++;
    }
  }
}

var _seed = 0;

WebviewNovelImage _picture(int id) => WebviewNovelImage(
  novelImageId: '1',
  urls: WebviewNovelImageUrls(
    size240Mw: 'https://i.pximg.net/fixtures/$id/240.jpg',
    size480Mw: 'https://i.pximg.net/fixtures/$id/480.jpg',
    size1200X1200: 'https://i.pximg.net/fixtures/$id/1200.jpg',
    original: 'https://i.pximg.net/fixtures/$id/original.jpg',
  ),
);

void main() {
  late HistoryRepository history;
  // One directory for the file: the picture cache remembers where it is.
  final temporary = Directory.systemTemp.createTempSync('reader_pictures');
  setUpAll(() async {
    // The picture cache keeps its files in the temporary directory. It finds
    // the folder once, outside any test's fake clock, and keeps the answer.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => temporary.path,
    );
    await appPictureStore.read('warm-up');
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), null);
    temporary.deleteSync(recursive: true);
  });
  setUp(() {
    history = useMemoryHistory();
    imageCache.clear();
    imageCache.clearLiveImages();
  });

  /// Lets the real-time work of loading (files, streams) run between frames.
  Future<void> loading(WidgetTester tester, bool Function() until) async {
    for (var i = 0; i < 100 && !until(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
  }

  // 240x173: a landscape picture, not the portrait the layout assumes.
  final head = File('test/fixtures/image_headers/pximg_152069551_240mw_head.jpg').readAsBytesSync();

  String body({required int before, int after = 40}) =>
      [for (var i = 0; i < before; i++) '$readerParagraph a$i', '[uploadedimage:1]', for (var i = 0; i < after; i++) '$readerParagraph b$i'].join('\n\n');

  Future<_HeldTransport> mount(WidgetTester tester, String text, {Map<String, dynamic> settings = readerScrollSettings}) async {
    final transport = _HeldTransport(head);
    await mountReader(
      tester,
      history,
      settings: settings,
      text: readerText(text, images: [_picture(++_seed)]),
      overrides: {rustMediaTransportProvider: rustMediaTransportProvider.overrideWithValue(transport)},
    );
    return transport;
  }

  Future<void> finish(WidgetTester tester, _HeldTransport transport) async {
    await tester.pumpWidget(const SizedBox());
    for (var round = 0; round < 6; round++) {
      transport.failPending();
      await tester.pump(const Duration(seconds: 3));
    }
    // The failed downloads of pictures nothing shows any more are reported.
    while (tester.takeException() != null) {}
  }

  ScrollPosition position(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  testWidgets('the frame takes the header ratio before the picture completes, and the text at the reading line stays', (tester) async {
    final restore = pixivImageOverride;
    final transport = await mount(tester, body(before: 12));
    pixivImageOverride = null;
    addTearDown(() => pixivImageOverride = restore);
    addTearDown(() => finish(tester, transport));
    final layout = readerState(tester).layout!;
    final picture = layout.model.imageBlocks.single;
    layout.metricsOf(picture);
    final assumed = layout.extentOf(picture);

    // The picture comes into view; its download opens.
    position(tester).jumpTo(layout.topOf(picture) - 300);
    await tester.pump();
    await tester.pump();
    await loading(tester, () => transport.opened.isNotEmpty);
    expect(transport.opened, isNotEmpty, reason: 'the picture started loading');
    expect(layout.extentOf(picture), assumed, reason: 'nothing known yet');

    final offset = layout.offsetAtPixel(position(tester).pixels);
    double screenY() => layout.pixelOfOffset(offset) - position(tester).pixels;
    final before = screenY();
    transport.sendHeads();
    await loading(tester, () => layout.extentOf(picture) != assumed);
    await tester.pump();

    final expected = layout.columnWidth * 173 / 240;
    expect(layout.extentOf(picture) - layout.typesetting.paragraphGap, closeTo(expected, 1), reason: 'the header ratio, though the image has not arrived');
    expect(layout.extentOf(picture), isNot(closeTo(assumed, 1)));
    expect(layout.offsetAtPixel(position(tester).pixels), offset);
    expect(screenY(), closeTo(before, 0.5), reason: 'the text at the reading line did not move');
    expect(find.byType(AppPixivImage), findsWidgets);
  });

  testWidgets('a picture one screen below the viewport has started loading, one far below has not', (tester) async {
    final restore = pixivImageOverride;
    final transport = await mount(tester, body(before: 60, after: 60));
    pixivImageOverride = null;
    addTearDown(() => pixivImageOverride = restore);
    addTearDown(() => finish(tester, transport));
    final layout = readerState(tester).layout!;
    final picture = layout.model.imageBlocks.single;
    final viewport = position(tester).viewportDimension;

    position(tester).jumpTo(layout.topOf(picture) - viewport * 3);
    await tester.pump();
    await tester.pump();
    expect(transport.opened, isEmpty, reason: 'three screens away');

    // Text before the picture is measured as it is reached, which moves the
    // picture: aim again until it lies about a screen and a third below.
    for (var aim = 0; aim < 4; aim++) {
      position(tester).jumpTo(layout.topOf(picture) - viewport * 1.3);
      await tester.pump();
      await tester.pump();
    }
    final distance = layout.topOf(picture) - (position(tester).pixels + viewport);
    expect(distance, inInclusiveRange(0.1 * viewport, 0.5 * viewport), reason: 'below the viewport, within one and a half screens');
    await loading(tester, () => transport.opened.isNotEmpty);
    expect(transport.opened, isNotEmpty, reason: 'its source was opened before it is scrolled into view');
    // It is not on screen yet.
    expect(layout.topOf(picture), greaterThan(position(tester).pixels + viewport));
  });

  testWidgets('paged: a size arriving for a picture keeps the current offset on the shown page', (tester) async {
    final transport = await mount(tester, body(before: 5, after: 30), settings: readerPagedSettings);
    addTearDown(() => finish(tester, transport));
    final controller = readerController(tester);
    final view = tester.state<ReaderPagedViewState>(find.byType(ReaderPagedView));
    final offset = controller.offset;
    final shown = view.visiblePages.map((page) => page.startOffset).toList();
    expect(offset, greaterThanOrEqualTo(shown.first));
    final layout = readerState(tester).layout!;
    final picture = layout.model.imageBlocks.single;
    final extent = layout.extentOf(picture);

    // The picture's frame learns a size very different from the assumed one.
    final images = tester.widgetList<AppPixivImage>(find.byType(AppPixivImage, skipOffstage: false)).where((image) => image.onImageSize != null).toList();
    expect(images, isNotEmpty, reason: 'the picture is built, shown or for the page next to it');
    images.first.onImageSize!(const Size(1600, 400));
    await tester.pump();
    await tester.pump();

    expect(layout.extentOf(picture), isNot(closeTo(extent, 1)), reason: 'the layout took the size');
    expect(controller.offset, offset, reason: 'the reading offset did not move');
    final page = view.visiblePages.first;
    expect(page.startOffset <= offset && offset < page.endOffset, isTrue, reason: 'the page shown holds the reading offset');
    expect(ProviderScope.containerOf(tester.element(find.byType(ReaderPagedView))), isNotNull);
  });
}
