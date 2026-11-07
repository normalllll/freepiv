import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/ranking/logic/ranking_logic.dart';
import 'package:freepiv/features/ranking/presentation/ranking_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

/// Every first page asked for, by mode.
final _requested = <Enum>[];

typedef _Answer = Future<IllustPageResult> Function(Enum mode);

class _Illusts extends RankingIllustListSource {
  _Illusts(IllustRankingMode mode, this.answer) : super(mode: mode);
  final _Answer answer;
  @override
  Future<IllustPageResult> loadFirstPage() {
    _requested.add(mode);
    return answer(mode);
  }
}

class _Manga extends RankingMangaListSource {
  _Manga(MangaRankingMode mode, this.answer) : super(mode: mode);
  final _Answer answer;
  @override
  Future<IllustPageResult> loadFirstPage() {
    _requested.add(mode);
    return answer(mode);
  }
}

class _Novels extends RankingNovelListSource {
  _Novels(NovelRankingMode mode) : super(mode: mode);
  @override
  Future<NovelPageResult> loadFirstPage() async {
    _requested.add(mode);
    return NovelPageResult(novels: sampleNovels(count: 4, title: longText, author: longText), rankingNovels: const []);
  }
}

class _Ranking extends Ranking {
  _Ranking(this.answer);
  final _Answer answer;
  @override
  RankingIllustListSource createIllustSource(IllustRankingMode mode) => _Illusts(mode, answer);
  @override
  RankingMangaListSource createMangaSource(MangaRankingMode mode) => _Manga(mode, answer);
  @override
  RankingNovelListSource createNovelSource(NovelRankingMode mode) => _Novels(mode);
}

/// A session that has shown illustrations by the week and manga by the month.
class _Remembering extends _Ranking {
  _Remembering() : super(_sample);
  @override
  RankingState build() => super.build().copyWith(illustMode: IllustRankingMode.week, mangaMode: MangaRankingMode.month);
}

Future<IllustPageResult> _sample(Enum mode) async => IllustPageResult(illusts: sampleIllusts(count: 8), rankingIllusts: const []);

Future<void> _mount(
  WidgetTester tester, {
  AppRankingKind kind = AppRankingKind.illust,
  String? mode,
  _Answer answer = _sample,
  Ranking Function()? ranking,
  Size size = desktopSize,
  double textScale = 1,
}) {
  _requested.clear();
  return mountPilotPage(
    tester,
    RankingPage(kind: kind, mode: mode),
    size: size,
    textScale: textScale,
    overrides: {rankingProvider: rankingProvider.overrideWith(ranking ?? () => _Ranking(answer))},
  );
}

String _title(WidgetTester tester) => tester.widget<FrostTitleMenu>(find.byKey(const ValueKey('ranking-mode'))).title;

Future<void> _pickMode(WidgetTester tester, Enum mode) async {
  await tester.tap(find.byKey(const ValueKey('ranking-mode')));
  await settlePilot(tester);
  await tester.tap(find.text(rankingModeLabel(t, mode)).last);
  await settlePilot(tester);
}

Future<void> _showKind(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(FrostTabBar), matching: find.text(label)));
  await settlePilot(tester);
}

void main() {
  testWidgets('every mode of every kind can be picked from the title menu and asks for its own ranking', (tester) async {
    await _mount(tester);
    expect(_requested, [IllustRankingMode.day]);
    for (final (kind, label) in [
      (AppRankingKind.illust, t.ranking.types.illustrations),
      (AppRankingKind.manga, t.ranking.types.manga),
      (AppRankingKind.novel, t.ranking.types.novels),
    ]) {
      await _showKind(tester, label);
      for (final mode in rankingModes(kind).reversed) {
        await _pickMode(tester, mode);
        expect(_requested, contains(mode));
        expect(_title(tester), '${t.navigation.ranking} · ${rankingModeLabel(t, mode)}');
      }
    }
    expect(_requested.toSet(), {...IllustRankingMode.values, ...MangaRankingMode.values, ...NovelRankingMode.values}, reason: 'illust 13, manga 6, novel 7');
    expectNoLayoutErrors(tester);
  });

  testWidgets('R-18 modes sit in their own section of the menu', (tester) async {
    await _mount(tester);
    await tester.tap(find.byKey(const ValueKey('ranking-mode')));
    await settlePilot(tester);
    final menu = tester.widget<FrostTitleMenu>(find.byKey(const ValueKey('ranking-mode')));
    final sections = menu.entries.whereType<FrostMenuSection>().toList();
    expect(sections.last.header, t.ranking.r18Section);
    expect(sections.last.entries, hasLength(IllustRankingMode.values.where(rankingModeIsR18).length));
    expect(sections.first.entries.whereType<FrostMenuAction>().map((action) => action.label), isNot(contains(t.ranking.modes.dayR18)));
  });

  testWidgets('ranks run on from 1 in the cards; a mode the next kind lacks gives way to that kind\'s own', (tester) async {
    await _mount(tester, mode: IllustRankingMode.dayMaleR18.name);
    expect(_title(tester), endsWith(t.ranking.modes.dayMaleR18));
    final ranks = tester.widgetList<AppArtworkCard>(find.byType(AppArtworkCard)).map((card) => card.rank).toList();
    expect(ranks, [for (var rank = 1; rank <= ranks.length; rank++) rank]);

    await _showKind(tester, t.ranking.types.manga);
    expect(_title(tester), endsWith(t.ranking.modes.day), reason: 'manga has no Daily Male R-18');
    expect(_requested.last, MangaRankingMode.day);

    await _pickMode(tester, MangaRankingMode.week);
    await _showKind(tester, t.ranking.types.novels);
    expect(_title(tester), endsWith(t.ranking.modes.week), reason: 'novels have Weekly too');
    expect(_requested.last, NovelRankingMode.week);
    final novelRanks = tester.widgetList<AppNovelRow>(find.byType(AppNovelRow)).map((row) => row.rank).toList();
    expect(novelRanks.first, 1);
  });

  testWidgets('each kind keeps its mode for the session; a mode the route names wins', (tester) async {
    await _mount(tester, ranking: _Remembering.new);
    expect(_title(tester), endsWith(t.ranking.modes.week), reason: 'illustrations were last shown by the week');
    expect(_requested, [IllustRankingMode.week]);
    final container = ProviderScope.containerOf(tester.element(find.byType(RankingPage)));

    await _pickMode(tester, IllustRankingMode.dayMale);
    expect(container.read(rankingProvider).illustMode, IllustRankingMode.dayMale, reason: 'the pick is kept for the session');
    await _showKind(tester, t.ranking.types.manga);
    expect(_title(tester), endsWith(t.ranking.modes.month), reason: 'manga has no Daily Male: it keeps its own month');

    await _mount(tester, ranking: _Remembering.new, mode: IllustRankingMode.dayAi.name);
    expect(_title(tester), endsWith(t.ranking.modes.dayAi));
    final remembered = ProviderScope.containerOf(tester.element(find.byType(RankingPage))).read(rankingProvider);
    expect(remembered.illustMode, IllustRankingMode.week, reason: 'opening a ranking at a mode changes nothing shared');
  });

  testWidgets('empty, loading and failed rankings each show their state', (tester) async {
    await _mount(tester, answer: (_) async => const IllustPageResult(illusts: [], rankingIllusts: []));
    expect(find.text(t.ranking.emptyTitle), findsOneWidget);

    final never = Completer<IllustPageResult>();
    await _mount(tester, answer: (_) => never.future);
    expect(find.byType(AppArtworkWaterfallSkeleton), findsOneWidget);

    var attempts = 0;
    await _mount(
      tester,
      answer: (mode) async {
        if (attempts++ == 0) throw StateError('offline');
        return _sample(mode);
      },
    );
    expect(find.byType(FrostErrorContent), findsOneWidget);
    await tester.tap(find.text(t.common.retry));
    await settlePilot(tester);
    expect(find.byType(AppArtworkCard), findsWidgets);
  });

  testWidgets('long novel titles and the title menu fit a phone at double text size', (tester) async {
    await _mount(tester, kind: AppRankingKind.novel, mode: NovelRankingMode.weekRookie.name, size: phoneSize, textScale: 2);
    expect(find.byType(AppNovelRow), findsWidgets);
    expectNoLayoutErrors(tester);
  });

  test('the ranking strings exist in all four languages', () => expectLocalesComplete(['ranking']));
}
