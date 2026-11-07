import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/pixivision/article_card.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/features/pixivision/page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

/// Every listing page asked for.
final _loaded = <String>[];

Future<void> _mount(
  WidgetTester tester, {
  Future<ArticlePage> Function(String url) load = samplePixivisionPage,
  String? url,
  Size size = desktopSize,
  double textScale = 1,
  AppLocale locale = AppLocale.enUs,
}) {
  _loaded.clear();
  return mountPilotPage(
    tester,
    PixivisionPage(url: url),
    size: size,
    textScale: textScale,
    locale: locale,
    overrides: {
      pixivisionPageLoaderProvider: pixivisionPageLoaderProvider.overrideWithValue((url) {
        _loaded.add(url);
        return load(url);
      }),
    },
  );
}

Future<void> _showSection(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(FrostTabBar), matching: find.text(label)));
  await settlePilot(tester);
}

String _title(WidgetTester tester) => tester.widget<FrostTitleMenu>(find.byKey(const ValueKey('pixivision-category'))).title;

void main() {
  testWidgets('the latest articles fill cards with their category and date, then the next page', (tester) async {
    await _mount(tester);
    expect(_loaded.first, 'https://www.pixivision.net/en/');
    expect(_title(tester), '${t.pixivision.title} · ${t.pixivision.allCategories}');
    expect(find.byType(AppPixivisionCard), findsWidgets);
    expect(find.text('Illustration · 2026-11-01'), findsWidgets);
    await tester.scrollUntilVisible(find.byType(AppPixivisionCard).last, 600, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await settlePilot(tester);
    expect(_loaded, contains('https://www.pixivision.net/en/?page=2'), reason: 'the latest load on by the next link');
  });

  testWidgets('ranking and recommended come in one go; the tags show grouped with their counts', (tester) async {
    await _mount(tester);
    await _showSection(tester, t.pixivision.ranking);
    expect(tester.widgetList<AppPixivisionCard>(find.byType(AppPixivisionCard)).map((card) => card.article.id).toSet(), {for (final article in sampleArticles(count: 5)) article.id});
    await _showSection(tester, t.pixivision.tags);
    expect(find.text('Themes'), findsOneWidget);
    final tag = tester.widget<FrostTag>(find.widgetWithText(FrostTag, 'Landscape'));
    expect(tag.detail, '120');
  });

  testWidgets('a category from the title menu and a search each swap the listing in place', (tester) async {
    await _mount(tester);
    await tester.tap(find.byKey(const ValueKey('pixivision-category')));
    await settlePilot(tester);
    await tester.tap(find.text('Manga').last);
    await settlePilot(tester);
    expect(_title(tester), '${t.pixivision.title} · Manga');
    expect(_loaded, contains('https://www.pixivision.net/en/c/manga'));

    await tester.enterText(find.descendant(of: find.byType(FrostSearchInput), matching: find.byType(EditableText)), ' cats ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settlePilot(tester);
    expect(_loaded, contains('https://www.pixivision.net/en/s/?q=cats'));
    expect(_title(tester), '${t.pixivision.title} · cats');
  });

  testWidgets('the language follows the interface', (tester) async {
    await _mount(tester, locale: AppLocale.jaJp);
    expect(_loaded.first, 'https://www.pixivision.net/ja/');
  });

  testWidgets('empty, loading and failed listings each show their state', (tester) async {
    await _mount(tester, load: (url) async => ArticlePage(url: url, title: '', articles: const [], monthlyRanking: const [], recommended: const [], categories: const []));
    expect(find.text(t.pixivision.empty), findsOneWidget);

    final never = Completer<ArticlePage>();
    await _mount(tester, load: (_) => never.future);
    expect(find.byType(AppPixivisionCardsSkeleton), findsOneWidget);

    var attempts = 0;
    await _mount(
      tester,
      load: (url) {
        if (attempts++ == 0) throw StateError('offline');
        return samplePixivisionPage(url);
      },
    );
    expect(find.byType(FrostErrorContent), findsOneWidget);
    await tester.tap(find.text(t.common.retry));
    await settlePilot(tester);
    expect(find.byType(AppPixivisionCard), findsWidgets);
  });

  testWidgets('long titles fit a phone at double text size', (tester) async {
    await _mount(
      tester,
      size: phoneSize,
      textScale: 2,
      load: (url) async => ArticlePage(
        url: url,
        title: '',
        articles: [for (final article in sampleArticles(count: 3)) ArticleSummary(id: article.id, title: longText, url: article.url, publishDate: '2026-11-07', tags: const [])],
        monthlyRanking: const [],
        recommended: const [],
        categories: const [ArticleLink(title: longText, url: 'https://www.pixivision.net/en/c/long')],
      ),
    );
    expectNoLayoutErrors(tester);
  });

  test('the Pixivision strings exist in all four languages', () => expectLocalesComplete(['pixivision']));
}
