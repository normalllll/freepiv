import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/features/pixivision/article_blocks.dart';
import 'package:freepiv/features/pixivision/article_images.dart';
import 'package:freepiv/features/pixivision/detail.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/features/pixivision/page.dart';
import 'package:freepiv/features/pixivision/widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';
import 'package:freepiv/shared/widgets/search_input.dart';
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
  testWidgets('work and author links align long emoji names and retain pointer and keyboard activation', (tester) async {
    const title = '作品 Artwork ✨🌸 とても長い名前 混合文字';
    const author = '作者 Artist 🎨🌈 とても長い名前 Long creator name';
    const work = FeaturedWork(id: 7, kind: FeaturedWorkKind.illustration, title: title, url: 'https://www.pixiv.net/artworks/7', userId: 8, userName: author);
    const featured = ArticleBlock(kind: BlockKind.pixivWork, html: '', text: '', images: [], links: [], works: [work], embeds: []);
    final targets = <String>[];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() async => tester.runAsync(() => LocaleSettings.setLocale(AppLocale.enUs)));
    for (final locale in AppLocale.values) {
      await tester.runAsync(() => LocaleSettings.setLocale(locale));
      for (final dark in [false, true]) {
        for (final width in [390.0, 1280.0]) {
          tester.view.physicalSize = Size(width, 700);
          await tester.pumpWidget(
            ProviderScope(
              child: TranslationProvider(
                child: MaterialApp(
                  theme: dark
                      ? AppTheme.dark(platform: TargetPlatform.windows, locale: locale.flutterLocale)
                      : AppTheme.light(platform: TargetPlatform.windows, locale: locale.flutterLocale),
                  home: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PixivisionBlock(block: featured, imageRatios: const {}, onLink: targets.add),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          for (final label in [title, author]) {
            final text = tester.widget<Text>(find.text(label));
            expect(text.style?.decoration, isNot(TextDecoration.underline));
            expect(text.style?.fontFamilyFallback, isNotEmpty, reason: 'content font fallback keeps emoji rendering');
            final link = find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first;
            expect(tester.getSize(link).height, greaterThanOrEqualTo(44));
          }
          expect(find.byIcon(Icons.chevron_right), findsNWidgets(2), reason: 'links remain discoverable on touch');
          final avatar = tester.getRect(find.byIcon(Icons.person_outline));
          final name = tester.getRect(find.text(author));
          expect(avatar.center.dy, closeTo(name.center.dy, .1), reason: 'mixed font metrics keep the identity row centered');
          await tester.tap(find.text(author));
          expect(targets.last, 'https://www.pixiv.net/users/8');
          Focus.of(tester.element(find.text(title))).requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          expect(targets.last, work.url);
          expect(tester.takeException(), isNull, reason: '${locale.languageCode} / $dark / $width');
        }
      }
    }
  });

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

  testWidgets('article links use readable text color and retain link gestures', (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark
              ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
              : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: Scaffold(
            body: PixivisionBlock(
              block: block(text: 'Read source', html: '<p>Read <a href="https://example.test/">source</a></p>'),
              imageRatios: const {},
              onLink: (_) {},
            ),
          ),
        ),
      );
      final text = tester.widget<SelectableText>(find.byType(SelectableText));
      final link = text.textSpan!.children!.whereType<TextSpan>().firstWhere((span) => span.text == 'source');
      expect(link.style!.color, Theme.of(tester.element(find.byType(SelectableText))).colorScheme.onSurface);
      expect(link.style!.decoration, TextDecoration.underline);
      expect(link.recognizer, isNotNull);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('compact browse shows content with one row of modes and expandable search', (tester) async {
    LocaleSettings.setLocale(AppLocale.enUs);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pixivisionBrowseProvider(home).overrideWith(FixtureBrowse.new), pixivisionTagsProvider('en').overrideWith((ref) => fixtureTags())],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
            home: const AppLayoutScope(child: PixivisionPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsOneWidget);
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);
    expect(find.byType(SearchInput), findsNothing);
    expect(find.text('Color and light'), findsOneWidget);
    final tabs = find.byType(TabBar);
    await tester.ensureVisible(find.text('Monthly ranking').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly ranking').first);
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(tabs).controller!.index, PixivisionSection.ranking.index);
    await tester.ensureVisible(find.text('Recommended').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recommended').first);
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(tabs).controller!.index, PixivisionSection.recommended.index);
    await tester.ensureVisible(find.text('Tags').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tags').first);
    await tester.pumpAndSettle();
    expect(find.text('Topics'), findsOneWidget);
    await tester.tap(find.byTooltip('Search articles'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchInput), findsOneWidget);
    await tester.tap(find.byTooltip('Search articles'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchInput), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('browse heading, controls and list share one content axis on wide windows', (tester) async {
    LocaleSettings.setLocale(AppLocale.enUs);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [800.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [pixivisionBrowseProvider(home).overrideWith(FixtureBrowse.new)],
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
              home: const AppLayoutScope(child: PixivisionPage()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final heading = tester.getRect(find.text('pixivision').first);
      final card = tester.getRect(find.byType(PixivisionCard).first);
      expect(card.left, closeTo(heading.left, 1), reason: 'content axis at $width');
      expect(find.byType(SearchInput), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('compact browse accommodates large text and category choices', (tester) async {
    LocaleSettings.setLocale(AppLocale.enUs);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final (size, scale, dark) in [(const Size(360, 844), 2.0, false), (const Size(430, 932), 1.0, true)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [pixivisionBrowseProvider(home).overrideWith(FixtureBrowse.new)],
          child: TranslationProvider(
            child: MaterialApp(
              theme: dark
                  ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
                  : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
              home: MediaQuery(
                data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
                child: const AppLayoutScope(child: PixivisionPage()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size / $scale');
      await tester.tap(find.descendant(of: find.byType(AppMenuAnchor), matching: find.byType(TextButton)));
      await tester.pumpAndSettle();
      expect(find.text('Illustration'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size / $scale category menu');
      await tester.tapAt(const Offset(8, 400));
      await tester.pumpAndSettle();
    }
  });
}
