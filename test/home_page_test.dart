import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
import 'package:freepiv/features/home/presentation/home_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:freepiv/ui/compositions/user_card.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

/// A feed answering with [first], then failing or answering [next].
class _Feed extends HomeIllustListSource {
  _Feed(this.first, {this.next}) : super(illustType: IllustType.illust);

  final Future<IllustPageResult> Function() first;
  final Future<IllustPageResult> Function()? next;

  @override
  Future<IllustPageResult> loadFirstPage() => first();

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) => next!();
}

/// Novels that are still on their way.
class _NeverNovels extends HomeNovelListSource {
  @override
  Future<NovelPageResult> loadFirstPage() => Completer<NovelPageResult>().future;

  @override
  Future<NovelPageResult> loadNextPage(String nextUrl) => Completer<NovelPageResult>().future;
}

/// Users that are still on their way.
class _NeverUsers extends HomeUserListSource {
  @override
  Future<UserPageResult> loadFirstPage() => Completer<UserPageResult>().future;

  @override
  Future<UserPageResult> loadNextPage(String nextUrl) => Completer<UserPageResult>().future;
}

Future<void> _mountFeed(WidgetTester tester, HomeIllustListSource source, {Size size = desktopSize}) => mountPilotPage(
  tester,
  const HomePage(),
  size: size,
  overrides: {
    homeIllustSourceProvider: homeIllustSourceProvider.overrideWith((ref) {
      ref.onDispose(source.dispose);
      return source;
    }),
  },
);

Widget _column(Widget row) => SingleChildScrollView(
  child: FrostContentColumn(maxWidth: FrostMetrics.readingMaxWidth, child: row),
);

void main() {
  testWidgets('recommended works fill the feed with the ranking shelf above, each with its bookmark button', (tester) async {
    await mountPilotPage(tester, const HomePage());
    expect(find.byType(FrostShelf), findsOneWidget);
    expect(find.byType(AppArtworkCard), findsWidgets);
    // Shown on every card, whatever the input, filled where bookmarked.
    final cards = tester.widgetList(find.byType(AppArtworkCard)).length;
    expect(find.byType(AppCardBookmarkButton), findsNWidgets(cards));
    expect(
      find.descendant(of: find.byType(AppCardBookmarkButton), matching: find.byWidgetPredicate((widget) => widget is FrostButton && widget.selected == true)),
      findsWidgets,
    );
    expectNoLayoutErrors(tester);
  });

  testWidgets('empty: the feed says there is nothing recommended yet', (tester) async {
    await _mountFeed(tester, _Feed(() async => const IllustPageResult(illusts: [], rankingIllusts: [])));
    expect(find.text('No recommendations yet'), findsOneWidget);
    expect(find.byType(FrostShelf), findsNothing);
  });

  testWidgets('loading: placeholders the size of the cards stand in', (tester) async {
    final never = Completer<IllustPageResult>();
    await _mountFeed(tester, _Feed(() => never.future));
    expect(find.byType(AppArtworkWaterfallSkeleton), findsOneWidget);
    expect(find.byType(AppArtworkCard), findsNothing);
  });

  for (final size in [desktopSize, const Size(1800, 1100), phoneSize]) {
    testWidgets('loading: the Home skeleton has the loaded page\'s titles, shelf and columns at $size', (tester) async {
      final answer = Completer<IllustPageResult>();
      await _mountFeed(tester, _Feed(() => answer.future), size: size);
      expect(find.text(t.home.rankings), findsOneWidget);
      expect(find.text(t.home.seeMore), findsOneWidget);
      expect(find.text(t.home.recommended), findsOneWidget);
      final shelf = find.descendant(of: find.byType(FrostShelf), matching: find.byType(AppArtworkCardSkeleton));
      expect(shelf, findsWidgets);
      final grid = find.descendant(of: find.byType(AppArtworkWaterfallSkeleton), matching: find.byType(AppArtworkCardSkeleton));

      Offset at(String label) => tester.getTopLeft(find.text(label));
      final (rankings, seeMore, recommended) = (at(t.home.rankings), at(t.home.seeMore), at(t.home.recommended));
      final tile = tester.getRect(shelf.first);
      final card = tester.getRect(grid.first);

      answer.complete(IllustPageResult(illusts: sampleIllusts(count: 12), rankingIllusts: sampleIllusts(count: 10)));
      await settlePilot(tester);
      expect(find.byType(AppArtworkCardSkeleton), findsNothing);
      expect(at(t.home.rankings), rankings);
      expect(at(t.home.seeMore), seeMore);
      expect(at(t.home.recommended), recommended);
      final tiles = find.descendant(of: find.byType(FrostShelf), matching: find.byType(AppArtworkCard));
      expect(tester.getRect(tiles.first), tile);
      final cards = find.byWidgetPredicate((widget) => widget is AppArtworkCard && !widget.square);
      final loaded = tester.getRect(cards.first);
      expect((loaded.left, loaded.top, loaded.width), (card.left, card.top, card.width), reason: 'the same column edges and start');
      expectNoLayoutErrors(tester);
    });
  }

  testWidgets('loading: the Novels tab has its shelf of covers and novel rows, the Users tab its user rows', (tester) async {
    await mountPilotPage(
      tester,
      const HomePage(),
      overrides: {
        homeNovelSourceProvider: homeNovelSourceProvider.overrideWith((ref) => _NeverNovels()),
        homeUserSourceProvider: homeUserSourceProvider.overrideWith((ref) => _NeverUsers()),
      },
    );
    await tester.tap(find.text(t.home.novels).first);
    await settlePilot(tester);
    expect(find.text(t.home.rankings), findsOneWidget);
    expect(find.text(t.home.recommended), findsOneWidget);
    expect(find.descendant(of: find.byType(FrostShelf), matching: find.byType(AppArtworkCardSkeleton)), findsWidgets);
    expect(find.descendant(of: find.byType(AppNovelCardsSkeleton), matching: find.byType(AppNovelCard)), findsWidgets);
    await tester.tap(find.text(t.home.users).first);
    await settlePilot(tester);
    expect(find.descendant(of: find.byType(AppUserCardsSkeleton), matching: find.byType(AppUserCard)), findsWidgets);
    expectNoLayoutErrors(tester);
  });

  testWidgets('error: a feed that never loaded offers a retry over the page', (tester) async {
    var attempts = 0;
    await _mountFeed(
      tester,
      _Feed(() async {
        attempts++;
        if (attempts == 1) throw StateError('offline');
        return IllustPageResult(illusts: sampleIllusts(count: 4), rankingIllusts: const []);
      }),
    );
    expect(find.byType(FrostErrorContent), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await settlePilot(tester);
    expect(find.byType(AppArtworkCard), findsNWidgets(4));
  });

  testWidgets('partial failure: without a ranking the shelf is left out, and a failed next page keeps the works', (tester) async {
    await _mountFeed(
      tester,
      _Feed(
        () async => IllustPageResult(illusts: sampleIllusts(count: 4), rankingIllusts: const [], nextUrl: 'next'),
        next: () async => throw StateError('offline'),
      ),
    );
    expect(find.byType(FrostShelf), findsNothing);
    expect(find.byType(AppArtworkCard), findsNWidgets(4));
    expect(find.byType(FrostErrorContent), findsNothing, reason: 'the page-wide error is only for a feed that never loaded');
    expect(find.text('Retry'), findsOneWidget, reason: 'the next page retries in place');
  });

  testWidgets('long novel titles, author names and tags fit a phone at double text size', (tester) async {
    final novel = sampleNovels(count: 1).single;
    final long = Novel(
      id: novel.id,
      title: longText,
      caption: longText,
      restrict: 0,
      xRestrict: 0,
      isOriginal: true,
      imageUrls: novel.imageUrls,
      createDate: novel.createDate,
      tags: const [
        Tag(name: longText),
        Tag(name: longText),
      ],
      pageCount: 1,
      textLength: 123456,
      user: User(
        id: 1,
        name: longText,
        account: longText,
        profileImageUrls: const ProfileImageUrls(medium: ''),
      ),
      series: const Series(id: 1, title: longText),
      totalBookmarks: 0,
      isBookmarked: false,
      totalView: 0,
      visible: true,
      totalComments: 0,
      isMuted: false,
      isMypixivOnly: false,
      isXRestricted: false,
      novelAiType: 1,
    );
    await mountPilotPage(
      tester,
      _column(AppNovelRow(novel: long)),
      size: phoneSize,
      textScale: 2,
      locale: longestLocale,
    );
    expectNoLayoutErrors(tester);
    await mountPilotPage(
      tester,
      _column(
        AppUserCard(
          preview: UserPreview(
            user: User(
              id: 1,
              name: longText,
              account: longText,
              profileImageUrls: const ProfileImageUrls(medium: ''),
            ),
            illusts: sampleIllusts(count: 3),
            isMuted: false,
          ),
        ),
      ),
      size: phoneSize,
      textScale: 2,
      locale: longestLocale,
    );
    expectNoLayoutErrors(tester);
  });

  testWidgets('every section renders on a phone at double text size in each language', (tester) async {
    for (final locale in AppLocale.values) {
      for (final section in [0, 1, 2, 3]) {
        await mountPilotPage(tester, const HomePage(), size: phoneSize, textScale: 2, locale: locale);
        final label = [t.home.illustrations, t.home.manga, t.home.novels, t.home.users][section];
        await tester.ensureVisible(find.text(label).first);
        await tester.tap(find.text(label).first);
        await settlePilot(tester);
        expectNoLayoutErrors(tester);
      }
    }
  });

  test('the home strings exist in all four languages', () {
    expectLocalesComplete(['home', 'artworkCard', 'navigation', 'appSearch']);
  });
}
