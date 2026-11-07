import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/features/pixivision/article_images.dart';
import 'package:freepiv/features/pixivision/article_page.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';

const home = 'https://www.pixivision.net/en/';

ArticleBlock block({
  BlockKind kind = BlockKind.paragraph,
  String text = '',
  String html = '',
  List<ArticleImage> images = const [],
  List<ArticleLink> links = const [],
}) => ArticleBlock(kind: kind, html: html, text: text, images: images, links: links, works: const [], embeds: const []);

Article article({String? thumbnail, String? description, List<ArticleBlock> blocks = const []}) => Article(
  id: 1,
  url: '${home}a/1',
  language: Language.english,
  title: 'Article title',
  description: description,
  thumbnail: thumbnail,
  publishDate: '2026-09-20',
  tags: const [],
  translations: const [],
  blocks: blocks,
  related: const [],
  monthlyRanking: const [],
  recommended: const [],
);

class FixtureBrowse extends PixivisionBrowse {
  @override
  Future<PixivisionListing> build(String url) async => PixivisionListing(
    ArticlePage(
      url: home,
      title: 'Latest articles',
      articles: const [ArticleSummary(id: 1, title: 'Color and light', url: '${home}a/1', tags: [])],
      monthlyRanking: const [],
      recommended: const [],
      categories: const [ArticleLink(title: 'Illustration', url: '${home}c/1')],
    ),
  );
}

class FixtureTransport extends RustMediaTransport {
  FixtureTransport(this.source) : super(null);
  final Stream<rust.MediaChunk> Function() source;
  int requests = 0;

  @override
  Stream<rust.MediaChunk> stream(String url, Map<String, String> headers) {
    requests++;
    expect(headers['Referer'], 'https://www.pixivision.net/');
    return source();
  }
}

Future<TagDirectory> fixtureTags() async => const TagDirectory(
  url: '${home}t/',
  groups: [
    TagGroup(
      name: 'Topics',
      nodes: [
        TagNode(
          name: 'Color',
          tag: PixivisionTag(id: 1, name: 'Color', url: '${home}t/1'),
          children: [],
        ),
      ],
    ),
  ],
);

void mockMediaCache(WidgetTester tester) {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'getTemporaryDirectory') return Directory('build/pixivision-test-cache').absolute.path;
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
}

void main() {
  test('header only hides content represented by matching body blocks', () {
    final repeated = article(
      thumbnail: 'https://example.test/cover.jpg?size=small',
      description: 'Opening  sentence',
      blocks: [
        block(
          kind: BlockKind.image,
          images: const [ArticleImage(url: 'https://example.test/cover.jpg?size=large', alt: '', width: 800, height: 1200)],
        ),
        block(text: 'Opening sentence'),
      ],
    );
    expect(pixivisionHeaderThumbnail(repeated), isNull);
    expect(pixivisionHeaderDescription(repeated), isNull);
    expect(pixivisionKnownImageRatios(repeated)['https://example.test/cover.jpg?size=large'], closeTo(2 / 3, .001));

    final distinct = article(
      thumbnail: 'https://example.test/cover.jpg',
      description: 'Opening sentence',
      blocks: [
        block(text: 'A different paragraph'),
        block(
          kind: BlockKind.image,
          images: const [ArticleImage(url: 'https://example.test/other.jpg', alt: '')],
        ),
      ],
    );
    expect(pixivisionHeaderThumbnail(distinct), 'https://example.test/cover.jpg');
    expect(pixivisionHeaderDescription(distinct), 'Opening sentence');
    expect(pixivisionKnownImageRatios(distinct), isEmpty);
  });

  test('link-only article cards remain in the body', () {
    expect(
      pixivisionBlockHasContent(
        block(
          kind: BlockKind.articleCard,
          links: const [ArticleLink(title: 'Related article', url: '${home}a/2')],
        ),
      ),
      isTrue,
    );
  });

  testWidgets('image ratio probe settles on failed and slow sources', (tester) async {
    mockMediaCache(tester);
    final nonce = DateTime.now().microsecondsSinceEpoch;
    final failed = FixtureTransport(() => Stream<rust.MediaChunk>.error(StateError('image unavailable')));
    expect(await tester.runAsync(() => probePixivisionImageRatio(failed, 'https://example.test/failed-article-image-$nonce.png')), isNull);
    expect(failed.requests, 3); // The media provider's existing retry policy is retained.

    final slow = FixtureTransport(
      () => Stream<rust.MediaChunk>.periodic(const Duration(seconds: 10), (_) => rust.MediaChunk(bytes: Uint8List(0), received: 0)),
    );
    expect(
      await tester.runAsync(
        () => probePixivisionImageRatio(slow, 'https://example.test/slow-article-image-$nonce.png', timeout: const Duration(milliseconds: 100)),
      ),
      isNull,
    );
    expect(slow.requests, 1);
  });

  testWidgets('image ratio probe reads a long image', (tester) async {
    mockMediaCache(tester);
    final bytes = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(const ui.Rect.fromLTWH(0, 0, 2, 3), ui.Paint());
      final image = await recorder.endRecording().toImage(2, 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    final png = bytes!;
    final transport = FixtureTransport(() => Stream.value(rust.MediaChunk(bytes: png, received: png.length, total: png.length)));
    final nonce = DateTime.now().microsecondsSinceEpoch;
    expect(await tester.runAsync(() => probePixivisionImageRatio(transport, 'https://example.test/long-article-image-$nonce.png')), closeTo(2 / 3, .001));
    expect(transport.requests, 1);
  });
}
