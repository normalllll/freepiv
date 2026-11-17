import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/app_settings.dart' show PreviewImageQuality;
import 'package:freepiv/core/downloads/models/download_origin.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

const _original = 'https://i.pximg.net/img-original/img/2024/01/02/03/04/05/123_p1.png';

WebviewNovelEmbeddedWork _work(String key, {String? original, String? medium}) => WebviewNovelEmbeddedWork(
  key: key,
  illustId: 123,
  page: 1,
  visible: true,
  title: 'Work',
  xRestrict: 0,
  userId: '2',
  userName: 'Author',
  imageOriginal: original,
  imageMedium: medium,
);

WebviewNovel _novel({required String text, required List<WebviewNovelEmbeddedWork> illusts}) => WebviewNovel(
  id: '1',
  title: 'Novel',
  userId: '2',
  coverUrl: '',
  tags: const [],
  caption: '',
  cdate: '',
  rating: const NovelRating(like: 0, bookmark: 0, view: 0),
  text: text,
  illusts: illusts,
  images: const [],
  glossaryItems: const [],
  replaceableItemIds: const [],
  aiType: 0,
  isOriginal: false,
);

void main() {
  _imageUrlTests();
  test('works embedded in the text get their image from the webview, keyed like the marker', () {
    final novel = _novel(
      text: 'Before\n[pixivimage:123-2]\nAfter',
      illusts: [_work('123-2', original: _original, medium: 'https://i.pximg.net/c/128x128/img-master/img/2024/01/02/03/04/05/123_p1_square1200.jpg')],
    );

    final block = parseWebviewNovel(novel).whereType<NovelEmbeddedWork>().single;
    expect(block.work?.imageOriginal, _original);
    expect(novelEmbeddedImageUrls(novel)[block.key], _original);
  });

  test('works without a usable image address are ignored rather than failing the text', () {
    final novel = _novel(
      text: '[pixivimage:9]',
      illusts: [
        _work('9-1'),
        _work('9-2', medium: 'not a url'),
      ],
    );
    expect(novelEmbeddedWorkUrls(novel), isEmpty);
  });

  test('a Pixiv work image downloads as its work page; other images by their address', () {
    expect(DownloadOrigin.ofImageUrl(Uri.parse(_original)), const ArtworkPage(illustId: 123, pageIndex: 1));
    final upload = Uri.parse('https://i.pximg.net/novel-cover-original/img/2024/01/02/03/04/05/ci9_abc.jpg?x=1');
    final origin = DownloadOrigin.ofImageUrl(upload);
    expect(origin, isA<ContentFile>());
    expect(origin.jobId, DownloadOrigin.ofImageUrl(upload.replace(query: '')).jobId, reason: 'the query does not change which image it is');
  });
}

WebviewNovelImage _image({String? s240, String? s480, String? s1200, String? original}) => WebviewNovelImage(
  novelImageId: '1',
  urls: WebviewNovelImageUrls(size240Mw: s240, size480Mw: s480, size1200X1200: s1200, original: original),
);

void _imageUrlTests() {
  const a = 'https://i.pximg.net/a.jpg';
  const b = 'https://i.pximg.net/b.jpg';
  const c = 'https://i.pximg.net/c.jpg';
  const d = 'https://i.pximg.net/d.jpg';

  group('novel image url choice', () {
    test('text: medium is 480mw, then 1200x1200, then original', () {
      const medium = PreviewImageQuality.medium;
      expect(novelTextImageUrl(_image(s1200: a, s480: b, original: c), medium), b);
      expect(novelTextImageUrl(_image(s1200: a, original: c), medium), a);
      expect(novelTextImageUrl(_image(original: c, s240: d), medium), c);
    });
    test('text: large is 1200x1200, then 480mw, then original', () {
      const large = PreviewImageQuality.large;
      expect(novelTextImageUrl(_image(s1200: a, s480: b, original: c), large), a);
      expect(novelTextImageUrl(_image(s480: b, original: c), large), b);
      expect(novelTextImageUrl(_image(original: c, s240: d), large), c);
      expect(novelTextImageUrl(_image(s240: d), large), isNull);
    });
    test('text placeholder is the small picture: 240mw, then 480mw', () {
      expect(novelTextPlaceholderUrl(_image(s240: d, s480: b, s1200: a)), d);
      expect(novelTextPlaceholderUrl(_image(s480: b, s1200: a)), b);
      expect(novelTextPlaceholderUrl(_image(s1200: a)), isNull);
    });
    test('the size key does not follow the quality setting or the variants a picture has', () {
      final full = _image(s240: d, s480: b, s1200: a, original: c);
      expect(novelImageSizeKey(full), a);
      expect(novelImageSizeKey(_image(s480: b, original: c)), b);
      expect(novelImageSizeKey(_image(s240: d)), d);
    });
    test('embedded work: medium, then original', () {
      expect(novelEmbeddedWorkImageUrl(_work('1-1', medium: a, original: b)), a);
      expect(novelEmbeddedWorkImageUrl(_work('1-1', original: b)), b);
    });
    test('viewer: original, then 1200x1200', () {
      expect(novelViewerImageUrl(_image(original: a, s1200: b)), a);
      expect(novelViewerImageUrl(_image(s1200: b, s480: c)), b);
    });
    test('strip: 240mw, then 480mw', () {
      expect(novelStripImageUrl(_image(s240: a, s480: b)), a);
      expect(novelStripImageUrl(_image(s480: b, original: c)), b);
    });
    test('blank and non-http candidates are skipped', () {
      expect(novelTextImageUrl(_image(s1200: '  ', s480: 'not a url', original: a), PreviewImageQuality.large), a);
      expect(novelStripImageUrl(_image(s240: 'ftp://host/x.jpg', s480: b)), b);
      expect(novelEmbeddedWorkImageUrl(_work('1-1', medium: '', original: a)), a);
    });
    test('no usable candidate gives null', () {
      expect(novelTextImageUrl(_image(), PreviewImageQuality.medium), isNull);
      expect(novelViewerImageUrl(_image(s240: a)), isNull);
      expect(novelStripImageUrl(_image(s1200: ' ', original: 'x')), isNull);
      expect(novelEmbeddedWorkImageUrl(_work('1-1')), isNull);
    });
  });
}
