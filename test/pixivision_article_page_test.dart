import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/pixivision/article_card.dart';
import 'package:freepiv/features/pixivision/article_page.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
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
    await _scrollTo(tester, find.byType(FrostKeyValueList));
    expect(find.text('Morning at the pier'), findsOneWidget, reason: 'the two-column table as labelled values');
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
}
