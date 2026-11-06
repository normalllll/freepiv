import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/features/fanbox/cards.dart';
import 'package:freepiv/features/fanbox/detail.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';

const _user = FanboxUser(id: 'author', name: 'Author');

FanboxPost _post(String excerpt) => FanboxPost(
  id: 'post',
  creatorId: 'author',
  user: _user,
  title: 'A short post',
  excerpt: excerpt,
  publishedDatetime: '2026-09-27T00:00:00Z',
  updatedDatetime: '2026-09-27T00:00:00Z',
  feeRequired: 0,
  isRestricted: false,
  isLiked: false,
  likeCount: 2,
  commentCount: 1,
  tags: const [],
  blocks: const [],
);

Widget _app(Widget child, {double width = 390, double textScale = 1}) => ProviderScope(
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 844), textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('empty post excerpt does not reserve preview lines and author has its own target', (tester) async {
    var creatorTaps = 0;
    var postTaps = 0;
    Widget card(String excerpt) => FanboxPostCard(post: _post(excerpt), onTap: () => postTaps++, onCreator: () => creatorTaps++);

    await tester.pumpWidget(_app(card('')));
    final emptyHeight = tester.getSize(find.byType(FanboxPostCard)).height;
    await tester.tap(find.text('Author'));
    expect(creatorTaps, 1);
    expect(postTaps, 0);

    await tester.pumpWidget(_app(card('A real preview for the post.')));
    expect(tester.getSize(find.byType(FanboxPostCard)).height, greaterThan(emptyHeight));
  });

  testWidgets('article image reserves its source aspect ratio before loading', (tester) async {
    const image = FanboxImage(id: 'image', originalUrl: '', thumbnailUrl: '', width: 400, height: 1200, extension_: 'jpg');
    await tester.pumpWidget(_app(const FanboxBlockView(FanboxBlock.image(image: image))));
    final size = tester.getSize(find.byType(AspectRatio));
    expect(size.width, 390);
    expect(size.height, 1170);
  });
}
