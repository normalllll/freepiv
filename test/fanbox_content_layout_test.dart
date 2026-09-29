import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/features/fanbox/cards.dart';
import 'package:freepiv/features/fanbox/detail.dart';
import 'package:freepiv/features/fanbox/navigation.dart';
import 'package:freepiv/features/fanbox/logic.dart';
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

  testWidgets('collection navigation stays on one line at narrow widths and large text', (tester) async {
    for (final width in [360.0, 390.0, 430.0]) {
      await tester.pumpWidget(
        _app(
          const FanboxSectionNavigation(section: FanboxSection.home, onSelected: _ignoreSection),
          width: width,
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      final tab = tester.getRect(find.byType(TabBar));
      // The collection value is a compact button at the row's end.
      final selector = tester.getRect(find.descendant(of: find.byType(FanboxSectionNavigation), matching: find.byType(TextButton)));
      expect((tab.center.dy - selector.center.dy).abs(), lessThan(2));
      expect(selector.right, lessThanOrEqualTo(width));
      expect(selector.left, greaterThan(tab.left));
    }
  });
}

void _ignoreSection(FanboxSection _) {}
