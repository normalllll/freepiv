import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/features/novel/logic/novel_structure.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';

const _palette = ReaderPalette(
  background: Color(0xFFFFFFFF),
  text: Color(0xFF1F1F1F),
  secondary: Color(0x991F1F1F),
  link: Color(0xFF0B5CAD),
  ruby: Color(0xBF1F1F1F),
  selection: Color(0x4D0B5CAD),
);

const _typesetting = ReaderTypesetting(
  textSize: 10,
  lineHeight: 2,
  body: TextStyle(fontSize: 10, height: 2),
  chapterTitle: TextStyle(fontSize: 13, height: 1.4),
  indent: false,
  palette: _palette,
);

WebviewNovelImage _picture() => const WebviewNovelImage(
  novelImageId: '1',
  urls: WebviewNovelImageUrls(
    size240Mw: 'https://i.pximg.net/240.jpg',
    size480Mw: 'https://i.pximg.net/480.jpg',
    size1200X1200: 'https://i.pximg.net/1200.jpg',
    original: 'https://i.pximg.net/original.jpg',
  ),
);

void main() {
  test('a size the text layout records is found under the key the strip and the panel use', () async {
    final store = MemoryImageSizeStore();
    final image = _picture();
    final block = NovelUploadedImage('1', image);
    final layout = ReaderLayout(
      model: ReaderModel([block]),
      typesetting: _typesetting,
      width: 116,
      flow: ReaderFlow.scroll,
      sizes: store,
      viewportHeight: 600,
      pageJumpLabel: (page) => '$page',
    );
    addTearDown(layout.dispose);
    layout.updateImageSize(0, const Size(400, 600), anchorBlock: 0);
    await Future<void>.delayed(Duration.zero);

    final key = novelImageSizeKey(image)!;
    expect(store.sizeOf(key), const Size(400, 600));
    expect(store.sizeOf(novelStripImageUrl(image)!), isNull, reason: 'the 240mw address no longer holds it');
    expect(key, isNot(novelStripImageUrl(image)));
  });

  test('a size recorded by the strip or the panel under the key is the layout\'s size', () async {
    final store = MemoryImageSizeStore();
    final image = _picture();
    await store.record(novelImageSizeKey(image)!, const Size(1200, 675));
    final layout = ReaderLayout(
      model: ReaderModel([NovelUploadedImage('1', image)]),
      typesetting: _typesetting,
      width: 116,
      flow: ReaderFlow.scroll,
      sizes: store,
      viewportHeight: 2000,
      pageJumpLabel: (page) => '$page',
    );
    addTearDown(layout.dispose);
    expect(layout.imageWidthOf(0), 60);
    expect(layout.extentOf(0), greaterThan(0));
    // 60 wide at 16:9 is 33.75 tall, plus the gap below.
    expect(layout.extentOf(0) - layout.typesetting.paragraphGap, closeTo(33.75, 0.01));
  });

  test('the structure gives each uploaded picture the same size key', () {
    final image = _picture();
    final picture = NovelPicture.uploaded(thumbnailUrl: novelStripImageUrl(image)!, viewerUrl: novelViewerImageUrl(image), sizeKey: novelImageSizeKey(image)!);
    expect(picture.sizeKey, novelImageSizeKey(image));
    expect(const NovelPicture.work(thumbnailUrl: 'https://i.pximg.net/w.jpg', illustId: 1).sizeKey, isNull);
  });
}
