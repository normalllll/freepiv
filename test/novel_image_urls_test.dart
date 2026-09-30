import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/downloads/models/download_origin.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/domain/novel_text_parser.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

const _original = 'https://i.pximg.net/img-original/img/2024/01/02/03/04/05/123_p1.png';

WebviewNovel _novel({required String text, required List<String> illusts}) => WebviewNovel(
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
  test('works embedded in the text get their image from the webview JSON, keyed like the marker', () {
    // The bridge hands the webview's `illusts` object over as one JSON string.
    final novel = _novel(
      text: 'Before\n[pixivimage:123-2]\nAfter',
      illusts: [
        jsonEncode({
          '123-2': {
            'illust': {
              'images': {'small': 'https://i.pximg.net/c/128x128/img-master/img/2024/01/02/03/04/05/123_p1_square1200.jpg', 'original': _original},
            },
          },
        }),
      ],
    );

    final blocks = parseNovelText(novel.text, imageUrls: novelEmbeddedImageUrls(novel));
    expect(blocks.whereType<NovelTextImage>().single.url, _original);
  });

  test('malformed or unrelated entries are ignored rather than failing the text', () {
    final novel = _novel(
      text: '[pixivimage:9]',
      illusts: [
        'not json',
        jsonEncode(['a', 'b']),
        'https://example.com/a.png',
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
