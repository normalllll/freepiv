import 'dart:async';

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/dev/sample_images.dart';
import 'package:freepiv/features/pixivision/article_card.dart';
import 'package:freepiv/features/pixivision/article_page.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

const _url = 'https://www.pixivision.net/en/a/9000';

Future<void> _mount(
  WidgetTester tester, {
  Future<PixivisionDocument> Function(String url)? load,
  ArticleSummary? summary,
  Size size = desktopSize,
  double textScale = 1,
}) => mountPilotPage(
  tester,
  PixivisionArticlePage(url: _url, summary: summary),
  size: size,
  textScale: textScale,
  overrides: {
    if (load != null) pixivisionArticleProvider: pixivisionArticleProvider.overrideWith((ref, url) => load(url)),
  },
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('the head, the body blocks and the tags, previous and next, and the related articles', (tester) async {
    await _mount(tester);
    final article = samplePixivisionArticle(_url);
    expect(find.text(article.title), findsOneWidget);
    expect(find.text('Illustration'), findsOneWidget);
    expect(find.text('2026-11-01'), findsOneWidget);
    expect(find.text(article.description!), findsOneWidget, reason: 'the opening shows once, in the head');
    expect(find.byType(FrostRichText), findsOneWidget);
    expect(find.text('The works'), findsOneWidget);
    expect(find.text('Morning at the pier 1'), findsOneWidget);
    await _scrollTo(tester, find.byType(FrostTable<List<String>>));
    final table = tester.widget<FrostTable<List<String>>>(find.byType(FrostTable<List<String>>));
    expect(table.shrinkWrap, isTrue, reason: 'the table runs with the text');
    expect([for (final column in table.columns) column.label], ['Work', 'Artist']);
    expect(find.descendant(of: find.byType(FrostTable<List<String>>), matching: find.text('Morning at the pier')), findsOneWidget);
    expect(find.descendant(of: find.byType(FrostTable<List<String>>), matching: find.text('Sample artist')), findsOneWidget);
    await _scrollTo(tester, find.text(t.pixivision.unsupported));
    await _scrollTo(tester, find.text('#Landscape'));
    await _scrollTo(tester, find.text(t.pixivision.next));
    await _scrollTo(tester, find.text('Related articles'));
    expect(find.byType(AppPixivisionCard), findsWidgets);
    expectNoLayoutErrors(tester);
  });

  testWidgets('a pixiv link opens in the app; an anchor scrolls to its block', (tester) async {
    await _mount(tester);
    final text = tester.widget<FrostRichText>(find.byType(FrostRichText));
    expect(text.text, contains('[first work on pixiv](https://www.pixiv.net/artworks/90001)'));
    expect(text.text, contains('[the works](https://www.pixivision.net/en/a/9000#works)'), reason: 'relative to the article');

    text.onLink!(Uri.parse('https://www.pixiv.net/artworks/90001'));
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.illust('90001'));

    await _mount(tester, size: phoneSize);
    final heading = find.text('The works');
    final before = tester.getTopLeft(heading).dy;
    tester.widget<FrostRichText>(find.byType(FrostRichText)).onLink!(Uri.parse('$_url#works'));
    await settlePilot(tester);
    expect(tester.getTopLeft(heading).dy, lessThan(before), reason: 'the page scrolled to the heading');
    expect(openedLocations, isEmpty);
  });

  testWidgets('a featured work opens it; its author opens their page', (tester) async {
    await _mount(tester);
    await _scrollTo(tester, find.text('Morning at the pier 1'));
    await tester.tap(find.text('Morning at the pier 1'));
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.illust('90000'));
    await _mount(tester);
    final author = find.widgetWithText(FrostListRow, 'Sample artist');
    await _scrollTo(tester, author.first);
    await Scrollable.ensureVisible(tester.element(author.first), alignment: .5);
    await settlePilot(tester);
    await tester.tap(author.first);
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.user('2000'));
  });

  testWidgets('loading shows the opening card\'s title over placeholders; a failure retries the page', (tester) async {
    final never = Completer<PixivisionDocument>();
    await _mount(tester, load: (_) => never.future, summary: sampleArticles(count: 1).single);
    expect(find.text(sampleArticles(count: 1).single.title), findsOneWidget);
    expect(find.byType(FrostRichText), findsNothing);

    var attempts = 0;
    await _mount(
      tester,
      load: (url) async {
        if (attempts++ == 0) throw StateError('offline');
        return samplePixivisionDocument(url);
      },
    );
    expect(find.byType(FrostErrorContent), findsOneWidget);
    await tester.tap(find.text(t.common.retry));
    await settlePilot(tester);
    expect(find.byType(FrostRichText), findsOneWidget);
  });

  testWidgets('a long title and blocks fit a phone at double text size', (tester) async {
    await _mount(
      tester,
      size: phoneSize,
      textScale: 2,
      load: (url) async {
        final sample = samplePixivisionArticle(url);
        return PixivisionDocument(
          article: Article(
            id: sample.id,
            url: sample.url,
            language: sample.language,
            title: longText,
            description: longText,
            thumbnail: sample.thumbnail,
            publishDate: sample.publishDate,
            category: const ArticleLink(title: longText, url: 'https://www.pixivision.net/en/c/long'),
            tags: const [PixivisionTag(id: 2, name: longText, url: 'https://www.pixivision.net/en/t/2')],
            translations: sample.translations,
            blocks: sample.blocks,
            related: sample.related,
            monthlyRanking: const [],
            recommended: const [],
          ),
          imageRatios: samplePixivisionDocument(url).imageRatios,
        );
      },
    );
    expectNoLayoutErrors(tester, where: 'head');
    await _scrollTo(tester, find.text('#$longText'));
    expectNoLayoutErrors(tester, where: 'body');
  });

  group('the loading page is the loaded page', () {
    const wide = Size(1200, 800);
    final bannerFrame = find.byWidgetPredicate((widget) => widget is AspectRatio && widget.aspectRatio == pixivisionBannerRatio);
    // The list's cover is square; the article's own banner is wide.
    final summary = ArticleSummary(
      id: 9000,
      title: samplePixivisionArticle(_url).title,
      url: _url,
      thumbnail: sampleImageUrl(150, width: 600, height: 600),
      publishDate: '2026-11-01',
      category: const ArticleLink(title: 'Illustration', url: 'https://www.pixivision.net/en/c/illustration'),
      tags: const [],
    );
    final meta = find.ancestor(of: find.text('Illustration'), matching: find.byType(Wrap)).first;
    String bannerUrl(WidgetTester tester) => tester.widget<AppPixivImage>(find.byType(AppPixivImage).first).url;
    final opening = find.byWidgetPredicate((widget) => widget is FrostText && widget.maxLines == 5);

    Future<void> load(WidgetTester tester, Completer<PixivisionDocument> document) async {
      document.complete(samplePixivisionDocument(_url));
      await settlePilot(tester);
    }

    for (final size in [phoneSize, wide]) {
      testWidgets('the banner frame keeps its rect when the article arrives at ${size.width.toInt()} px', (tester) async {
        final document = Completer<PixivisionDocument>();
        await _mount(tester, load: (_) => document.future, summary: summary, size: size);
        expect(bannerFrame, findsOneWidget);
        final loading = tester.getRect(bannerFrame);
        final loadingMeta = tester.getRect(meta);
        final loadingOpening = tester.getTopLeft(opening);
        expect(loading.width / loading.height, closeTo(pixivisionBannerRatio, .01));
        expect(bannerUrl(tester), summary.thumbnail, reason: 'the cover is drawn from the first frame');

        await load(tester, document);
        expect(bannerFrame, findsOneWidget);
        expect(tester.getRect(bannerFrame), loading);
        expect(bannerUrl(tester), summary.thumbnail, reason: 'the same picture stays the banner once loaded');
        expect(tester.getRect(meta), loadingMeta, reason: 'the category and date row does not change');
        expect(tester.getTopLeft(find.text(samplePixivisionArticle(_url).description!)), loadingOpening, reason: 'the opening starts where its bones did');
        expectNoLayoutErrors(tester);
      });
    }

    testWidgets('a banner repeated in the body stays in the header and leaves the body', (tester) async {
      final sample = samplePixivisionArticle(_url);
      await _mount(
        tester,
        load: (_) async => PixivisionDocument(
          article: Article(
            id: sample.id,
            url: sample.url,
            language: sample.language,
            title: sample.title,
            description: sample.description,
            thumbnail: sample.thumbnail,
            publishDate: sample.publishDate,
            category: sample.category,
            tags: const [],
            translations: const [],
            blocks: [
              ArticleBlock(
                kind: BlockKind.image,
                html: '',
                text: '',
                images: [ArticleImage(url: sample.thumbnail!, alt: 'banner')],
                links: const [],
                works: const [],
                embeds: const [],
              ),

            ],
            related: const [],
            monthlyRanking: const [],
            recommended: const [],
          ),
          imageRatios: const {},
        ),
      );
      expect(bannerFrame, findsOneWidget);
      expect(find.byType(FrostMediaFrame), findsOneWidget, reason: 'the header banner only, no copy in the body');
    });

    for (final withCard in [true, false]) {
      testWidgets('the share picture block stays out of the body ${withCard ? 'with' : 'without'} a card', (tester) async {
        final sample = samplePixivisionArticle(_url);
        await _mount(
          tester,
          summary: withCard ? summary : null,
          load: (_) async => PixivisionDocument(
            article: Article(
              id: sample.id,
              url: sample.url,
              language: sample.language,
              title: sample.title,
              description: sample.description,
              thumbnail: sample.thumbnail,
              publishDate: sample.publishDate,
              category: sample.category,
              tags: const [],
              translations: const [],
              blocks: [
                ArticleBlock(
                  kind: BlockKind.image,
                  html: '<div class="article-item _feature-article-body__article_thumbnail"><img src="${sample.thumbnail}" alt=""></div>',
                  text: '',
                  images: [ArticleImage(url: sample.thumbnail!, alt: '')],
                  links: const [],
                  works: const [],
                  embeds: const [],
                ),
              ],
              related: const [],
              monthlyRanking: const [],
              recommended: const [],
            ),
            imageRatios: const {},
          ),
        );
        expect(find.byType(FrostMediaFrame), findsOneWidget, reason: 'the banner only');
        expect(bannerUrl(tester), withCard ? summary.thumbnail : sample.thumbnail, reason: 'the card\'s picture, else the share picture');
        final block = ArticleBlock(
          kind: BlockKind.image,
          html: '<div class="article-item _feature-article-body__article_thumbnail"><img src="https://example.test/other.jpg"></div>',
          text: '',
          images: const [ArticleImage(url: 'https://example.test/other.jpg', alt: '')],
          links: const [],
          works: const [],
          embeds: const [],
        );
        expect(pixivisionBlockHasContent(block), isFalse);
      });
    }

    testWidgets('the translations menu is a toolbar action, not part of the meta row', (tester) async {
      await _mount(tester);
      final menu = find.text(t.pixivision.translations);
      expect(find.descendant(of: find.byType(FrostPageHeader), matching: menu), findsWidgets);
      expect(find.descendant(of: find.byType(Wrap), matching: menu), findsNothing);
    });

    testWidgets('the title and the toolbar actions fit a phone', (tester) async {
      await _mount(tester, size: phoneSize);
      final title = find.text(samplePixivisionArticle(_url).title);
      expect(tester.getRect(title).right, lessThanOrEqualTo(phoneSize.width));
      for (final element in find.descendant(of: find.byType(FrostPageHeader), matching: find.byType(Text)).evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget));
        expect(rect.right, lessThanOrEqualTo(phoneSize.width), reason: 'the header does not run past the window');
      }
      expectNoLayoutErrors(tester);
    });

    testWidgets('without a card the skeleton lays out the banner frame where the loaded one is', (tester) async {
      final document = Completer<PixivisionDocument>();
      await _mount(tester, load: (_) => document.future, size: wide);
      expect(bannerFrame, findsOneWidget);
      final loading = tester.getRect(bannerFrame);
      expect(find.byType(FrostTag), findsOneWidget, reason: 'the meta row is drawn as bones');

      await load(tester, document);
      expect(bannerFrame, findsOneWidget);
      expect(tester.getRect(bannerFrame), loading);
      expectNoLayoutErrors(tester);
    });
  });

  group('a table in the article', () {
    Future<void> mountTable(WidgetTester tester, String html) => mountPilotPage(
      tester,
      SingleChildScrollView(
        child: FrostContentColumn(
          maxWidth: FrostMetrics.readingMaxWidth,
          child: PixivisionBlock(
            block: ArticleBlock(kind: BlockKind.table, html: html, text: '', images: const [], links: const [], works: const [], embeds: const []),
            imageRatios: const {},
            onLink: (_) {},
          ),
        ),
      ),
    );

    Finder table() => find.byType(FrostTable<List<String>>);

    testWidgets('shows a long cell in full', (tester) async {
      const long = 'Quiet harbour towns at dusk, drawn from the water with the lamps of the shore coming on one by one';
      await mountTable(tester, '<table><tr><th>Theme</th><th>Note</th></tr><tr><td>Harbours</td><td>$long</td></tr></table>');
      final cell = find.descendant(of: table(), matching: find.text(long));
      expect(cell, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: cell, matching: find.byType(RichText)));
      expect(paragraph.didExceedMaxLines, isFalse, reason: 'not cut off');
      final line = tester.getSize(find.descendant(of: table(), matching: find.text('Harbours'))).height;
      expect(tester.getSize(cell).height, greaterThan(line * 1.5), reason: 'the long cell wraps onto more lines');
      expect(tester.widget<FrostTable<List<String>>>(table()).showHeader, isTrue);
      expect(find.descendant(of: table(), matching: find.text('Theme')), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('a table without header cells has no header row', (tester) async {
      await mountTable(tester, '<table><tr><td>Period</td><td>2026-11-01 to 2026-11-30</td></tr><tr><td>Entries</td><td>12</td></tr></table>');
      final frost = tester.widget<FrostTable<List<String>>>(table());
      expect(frost.showHeader, isFalse);
      expect(frost.rows.first, ['Period', '2026-11-01 to 2026-11-30'], reason: 'the first row is data');
      final top = tester.getTopLeft(table()).dy;
      expect(tester.getTopLeft(find.text('Period')).dy - top, lessThan(24), reason: 'the first row starts at the top of the table');
      expectNoLayoutErrors(tester);
    });
  });
}
