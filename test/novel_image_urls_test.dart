import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

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
}
