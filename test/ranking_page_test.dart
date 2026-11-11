import 'dart:async';

import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/ranking/logic/ranking_logic.dart';
import 'package:freepiv/features/ranking/presentation/ranking_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart' show PixivApi;
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

/// Every first page asked for, by mode.
final _requested = <Enum>[];

/// The same requests with the day each was for; null for the latest.
final _requestedOn = <(Enum, DateTime?)>[];

/// Answers the rankings of a past day as the test says and the latest from the
/// sample works; any other request fails.
class _Api implements PixivApi {
  _Api({required this.onDate});

  final Future<IllustPageResult> Function(Enum mode) onDate;

  /// The dated requests made, by kind, mode and day.
  static final dates = <String>[];

  @override
  Future<IllustPageResult> getIllustRankingPage({required IllustRankingMode mode}) async =>
      IllustPageResult(illusts: sampleIllusts(count: 4), rankingIllusts: const []);

  @override
  Future<IllustPageResult> getIllustRankingPageOnDate({required IllustRankingMode mode, required String date}) {
    dates.add('illust ${mode.name} $date');
    return onDate(mode);
  }

  @override
  Future<IllustPageResult> getMangaRankingPageOnDate({required MangaRankingMode mode, required String date}) {
    dates.add('manga ${mode.name} $date');
    return onDate(mode);
  }

  @override
  Future<NovelPageResult> getNovelRankingPageOnDate({required NovelRankingMode mode, required String date}) async {
    dates.add('novel ${mode.name} $date');
    await onDate(mode);
    return const NovelPageResult(novels: [], rankingNovels: []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

typedef _Answer = Future<IllustPageResult> Function(Enum mode);

class _Illusts extends RankingIllustListSource {
  _Illusts(IllustRankingMode mode, this.answer, DateTime? date) : super(mode: mode, date: date);
  final _Answer answer;
  @override
  Future<IllustPageResult> loadFirstPage() {
    _requested.add(mode);
    _requestedOn.add((mode, date));
    return answer(mode);
  }
}

class _Manga extends RankingMangaListSource {
  _Manga(MangaRankingMode mode, this.answer, DateTime? date) : super(mode: mode, date: date);
  final _Answer answer;
  @override
  Future<IllustPageResult> loadFirstPage() {
    _requested.add(mode);
    _requestedOn.add((mode, date));
    return answer(mode);
  }
}

class _Novels extends RankingNovelListSource {
  _Novels(NovelRankingMode mode, DateTime? date) : super(mode: mode, date: date);
  @override
  Future<NovelPageResult> loadFirstPage() async {
    _requested.add(mode);
    _requestedOn.add((mode, date));
    return NovelPageResult(
      novels: sampleNovels(count: 4, title: longText, author: longText),
      rankingNovels: const [],
    );
  }
}

class _Ranking extends Ranking {
  _Ranking(this.answer);
  final _Answer answer;
  @override
  RankingIllustListSource createIllustSource(IllustRankingMode mode, DateTime? date) => _Illusts(mode, answer, date);
  @override
  RankingMangaListSource createMangaSource(MangaRankingMode mode, DateTime? date) => _Manga(mode, answer, date);
  @override
  RankingNovelListSource createNovelSource(NovelRankingMode mode, DateTime? date) => _Novels(mode, date);
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
  _requestedOn.clear();
  _Api.dates.clear();
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
    await _mount(
      tester,
      answer: (_) async => const IllustPageResult(illusts: [], rankingIllusts: []),
    );
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

  group('rankings by date', () {
    final now = DateTime.now();
    // Past days the calendar reaches in a few steps; Pixiv ranks up to yesterday.
    final day = DateTime(now.year, now.month, now.day - 3);
    final otherDay = DateTime(now.year, now.month, now.day - 40);
    final today = DateTime(now.year, now.month, now.day);
    setUp(_Api.dates.clear);

    Finder dateControl({String? shows}) =>
        find.bySemanticsLabel(shows == null ? RegExp('^${RegExp.escape(t.ranking.date.label)}, ') : '${t.ranking.date.label}, $shows');

    String fullDate(WidgetTester tester, DateTime date) => MaterialLocalizations.of(tester.element(find.byType(RankingPage))).formatFullDate(date);

    /// Opens the header's date choice and picks [date], stepping the calendar
    /// to its month, or clears it for null.
    Future<void> pickDate(WidgetTester tester, DateTime? date) async {
      final semantics = tester.ensureSemantics();
      await tester.tap(dateControl());
      await settlePilot(tester);
      if (date == null) {
        await tester.tap(find.text(t.frost.clear).last);
      } else {
        final cell = find.bySemanticsLabel(fullDate(tester, date));
        for (final step in [t.frost.next, t.frost.next, t.frost.previous, t.frost.previous, t.frost.previous, t.frost.previous]) {
          if (cell.evaluate().isNotEmpty) break;
          await tester.tap(find.bySemanticsLabel(step).last, warnIfMissed: false);
          await settlePilot(tester);
        }
        await tester.tap(cell.first);
      }
      await settlePilot(tester);
      semantics.dispose();
    }

    /// Whether the header's date choice shows Latest.
    bool showsLatest(WidgetTester tester) {
      final semantics = tester.ensureSemantics();
      final latest = dateControl(shows: t.ranking.date.latest).evaluate().isNotEmpty;
      semantics.dispose();
      return latest;
    }

    Ranking notifierOf(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(RankingPage))).read(rankingProvider.notifier);

    for (final (label, size) in [('wide', desktopSize), ('narrow', phoneSize)]) {
      testWidgets('$label: the date is one control in the header row, showing Latest', (tester) async {
        await _mount(tester, size: size);
        expect(find.byType(FrostDatePicker), findsNothing, reason: 'no field in the content');
        expect(find.descendant(of: find.byType(FrostPageHeader), matching: find.text(t.ranking.date.latest).hitTestable()), findsOneWidget);
        expect(showsLatest(tester), isTrue);
        expectNoLayoutErrors(tester);
      });
    }

    testWidgets('today cannot be picked; Pixiv ranks up to yesterday', (tester) async {
      await _mount(tester);
      final semantics = tester.ensureSemantics();
      await tester.tap(dateControl());
      await settlePilot(tester);
      await tester.tap(find.bySemanticsLabel(fullDate(tester, today)).first, warnIfMissed: false);
      await settlePilot(tester);
      semantics.dispose();
      expect(_requestedOn, [(IllustRankingMode.day, null)]);
    });

    testWidgets('picking a day asks for that day\'s ranking, and the request spells it year-month-day', (tester) async {
      await _mount(tester);
      expect(_requestedOn, [(IllustRankingMode.day, null)]);
      await pickDate(tester, day);
      expect(_requestedOn.last, (IllustRankingMode.day, day));
      expect(showsLatest(tester), isFalse);
      expect(rankingApiDate(DateTime(2024, 3, 5)), '2024-03-05');
      expect(rankingApiDate(DateTime(2007, 9, 13)), '2007-09-13');
      expect(find.byType(AppArtworkCard), findsWidgets);
    });

    testWidgets('clearing goes back to the latest ranking without asking for it again', (tester) async {
      await _mount(tester);
      final latest = notifierOf(tester).illustSourceFor(IllustRankingMode.day);
      await pickDate(tester, day);
      final asked = _requestedOn.length;
      final dated = notifierOf(tester).illustSourceFor(IllustRankingMode.day);
      expect(dated, isNot(same(latest)));
      await pickDate(tester, null);
      expect(showsLatest(tester), isTrue);
      expect(notifierOf(tester).illustSourceFor(IllustRankingMode.day), same(latest), reason: 'the latest ranking is kept');
      expect(_requestedOn, hasLength(asked), reason: 'nothing asked for again');

      await pickDate(tester, day);
      expect(notifierOf(tester).illustSourceFor(IllustRankingMode.day), same(dated), reason: 'a day looked at is kept too');
      expect(_requestedOn, hasLength(asked));
      await pickDate(tester, otherDay);
      expect(_requestedOn.last, (IllustRankingMode.day, otherDay));
    });

    testWidgets('switching the kind or the mode keeps the day, and the next kind and mode are of that day', (tester) async {
      await _mount(tester);
      await pickDate(tester, day);
      await _showKind(tester, t.ranking.types.manga);
      expect(showsLatest(tester), isFalse);
      expect(_requestedOn.last, (MangaRankingMode.day, day));
      await _pickMode(tester, MangaRankingMode.week);
      expect(showsLatest(tester), isFalse);
      expect(_requestedOn.last, (MangaRankingMode.week, day));
      await _showKind(tester, t.ranking.types.novels);
      expect(showsLatest(tester), isFalse);
      expect(_requestedOn.last, (NovelRankingMode.week, day));
      await _pickMode(tester, NovelRankingMode.dayR18);
      expect(_requestedOn.last, (NovelRankingMode.dayR18, day));
      await _showKind(tester, t.ranking.types.illustrations);
      expect(showsLatest(tester), isFalse);
    });

    group('a day with no ranking', () {
      Future<void> mountReal(WidgetTester tester, _Api api) {
        pixivApi = api;
        return mountPilotPage(tester, const RankingPage(kind: AppRankingKind.illust), overrides: {rankingProvider: rankingProvider.overrideWith(Ranking.new)});
      }

      testWidgets('that fails says so as an empty state, with no retry', (tester) async {
        await mountReal(tester, _Api(onDate: (_) async => throw StateError('no such ranking')));
        expect(find.byType(AppArtworkCard), findsWidgets, reason: 'the latest ranking lists');
        await pickDate(tester, day);
        expect(find.text(t.ranking.date.empty), findsOneWidget);
        expect(find.text(t.common.retry), findsNothing);
        expect(find.byType(FrostErrorContent), findsNothing);
        expect(find.text(t.ranking.emptyTitle), findsNothing);
      });

      testWidgets('that comes back empty says the same, and the latest ranking keeps its own empty state', (tester) async {
        await mountReal(
          tester,
          _Api(
            onDate: (_) async => const IllustPageResult(illusts: [], rankingIllusts: []),
          ),
        );
        await pickDate(tester, day);
        expect(find.text(t.ranking.date.empty), findsOneWidget);
        expect(_Api.dates.last, 'illust day ${rankingApiDate(day)}');
        await pickDate(tester, null);
        expect(find.text(t.ranking.date.empty), findsNothing);
        expect(find.byType(AppArtworkCard), findsWidgets);
      });

      testWidgets('asks the dated request of each kind', (tester) async {
        final api = _Api(
          onDate: (_) async => const IllustPageResult(illusts: [], rankingIllusts: []),
        );
        pixivApi = api;
        final day = DateTime(2024, 3, 5);
        await RankingIllustListSource(mode: IllustRankingMode.week, date: day).refresh(true);
        await RankingMangaListSource(mode: MangaRankingMode.month, date: day).refresh(true);
        await RankingNovelListSource(mode: NovelRankingMode.dayR18, date: day).refresh(true);
        expect(_Api.dates, ['illust week 2024-03-05', 'manga month 2024-03-05', 'novel dayR18 2024-03-05']);
      });
    });
  });

  test('the ranking strings exist in all four languages', () => expectLocalesComplete(['ranking']));
}
