import 'package:freepiv/core/block/block_filter.dart';
import 'package:freepiv/core/block/block_list.dart';
import 'package:flutter/foundation.dart' show protected;
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frost_data/frost_data.dart';

part 'ranking_logic.g.dart';

class RankingState {
  const RankingState({
    required this.illustMode,
    required this.mangaMode,
    required this.novelMode,
    required this.illustSources,
    required this.mangaSources,
    required this.novelSources,
    this.date,
  });

  final IllustRankingMode illustMode;
  final MangaRankingMode mangaMode;
  final NovelRankingMode novelMode;

  /// The day the rankings are of, shared by every kind and mode; null for the
  /// latest ranking.
  final DateTime? date;

  /// The latest ranking of each mode. The rankings of a [date] are made and
  /// kept by [Ranking], per mode and day.
  final Map<IllustRankingMode, RankingIllustListSource> illustSources;
  final Map<MangaRankingMode, RankingMangaListSource> mangaSources;
  final Map<NovelRankingMode, RankingNovelListSource> novelSources;

  /// This state with the rankings of [date], or the latest ones for null.
  RankingState onDate(DateTime? date) => RankingState(
    illustMode: illustMode,
    mangaMode: mangaMode,
    novelMode: novelMode,
    illustSources: illustSources,
    mangaSources: mangaSources,
    novelSources: novelSources,
    date: date,
  );

  RankingState copyWith({
    IllustRankingMode? illustMode,
    MangaRankingMode? mangaMode,
    NovelRankingMode? novelMode,
    Map<IllustRankingMode, RankingIllustListSource>? illustSources,
    Map<MangaRankingMode, RankingMangaListSource>? mangaSources,
    Map<NovelRankingMode, RankingNovelListSource>? novelSources,
  }) {
    return RankingState(
      illustMode: illustMode ?? this.illustMode,
      mangaMode: mangaMode ?? this.mangaMode,
      novelMode: novelMode ?? this.novelMode,
      illustSources: illustSources ?? this.illustSources,
      mangaSources: mangaSources ?? this.mangaSources,
      novelSources: novelSources ?? this.novelSources,
      date: date,
    );
  }
}

/// The date as the ranking requests spell it: year, month and day.
String rankingApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// The first page of a ranking of a past day. Pixiv has no ranking of some
/// modes for some days and answers with nothing or an error: either way there
/// is nothing to list for that day, so a failure reads as an empty page.
Future<T> _pastRanking<T>(Future<T> Function() load, T empty) async {
  try {
    return await load();
  } catch (_) {
    return empty;
  }
}

class RankingIllustListSource extends FrostCursorListSource<Illust, IllustPageResult> with BlockFilteredCursorList<Illust, IllustPageResult> {
  RankingIllustListSource({required this.mode, this.date});

  final IllustRankingMode mode;

  /// The day of the ranking; null for the latest.
  final DateTime? date;

  @override
  bool isBlocked(BlockList blocks, Illust item) => blocks.hidesIllust(item);

  @override
  Future<IllustPageResult> loadFirstPage() {
    final date = this.date;
    if (date == null) return pixivApi.getIllustRankingPage(mode: mode);
    return _pastRanking(
      () => pixivApi.getIllustRankingPageOnDate(mode: mode, date: rankingApiDate(date)),
      const IllustPageResult(illusts: [], rankingIllusts: []),
    );
  }

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextIllustPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(IllustPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Illust> itemsFromPage(IllustPageResult page) {
    return page.illusts;
  }
}

class RankingMangaListSource extends FrostCursorListSource<Illust, IllustPageResult> with BlockFilteredCursorList<Illust, IllustPageResult> {
  RankingMangaListSource({required this.mode, this.date});

  final MangaRankingMode mode;

  /// The day of the ranking; null for the latest.
  final DateTime? date;

  @override
  bool isBlocked(BlockList blocks, Illust item) => blocks.hidesIllust(item);

  @override
  Future<IllustPageResult> loadFirstPage() {
    final date = this.date;
    if (date == null) return pixivApi.getMangaRankingPage(mode: mode);
    return _pastRanking(
      () => pixivApi.getMangaRankingPageOnDate(mode: mode, date: rankingApiDate(date)),
      const IllustPageResult(illusts: [], rankingIllusts: []),
    );
  }

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextIllustPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(IllustPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Illust> itemsFromPage(IllustPageResult page) {
    return page.illusts;
  }
}

class RankingNovelListSource extends FrostCursorListSource<Novel, NovelPageResult> with BlockFilteredCursorList<Novel, NovelPageResult> {
  RankingNovelListSource({required this.mode, this.date});

  final NovelRankingMode mode;

  /// The day of the ranking; null for the latest.
  final DateTime? date;

  @override
  bool isBlocked(BlockList blocks, Novel item) => blocks.hidesNovel(item);

  @override
  Future<NovelPageResult> loadFirstPage() {
    final date = this.date;
    if (date == null) return pixivApi.getNovelRankingPage(mode: mode);
    return _pastRanking(() => pixivApi.getNovelRankingPageOnDate(mode: mode, date: rankingApiDate(date)), const NovelPageResult(novels: [], rankingNovels: []));
  }

  @override
  Future<NovelPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextNovelPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(NovelPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Novel> itemsFromPage(NovelPageResult page) {
    return page.novels;
  }
}

@Riverpod(keepAlive: true)
class Ranking extends _$Ranking {
  @override
  RankingState build() {
    final illustSources = {for (final mode in IllustRankingMode.values) mode: createIllustSource(mode, null)};

    final mangaSources = {for (final mode in MangaRankingMode.values) mode: createMangaSource(mode, null)};

    final novelSources = {for (final mode in NovelRankingMode.values) mode: createNovelSource(mode, null)};

    final pastIllust = _pastIllust = {};
    final pastManga = _pastManga = {};
    final pastNovel = _pastNovel = {};

    ref.onDispose(() {
      for (final source in [...illustSources.values, ...pastIllust.values]) {
        source.dispose();
      }

      for (final source in [...mangaSources.values, ...pastManga.values]) {
        source.dispose();
      }

      for (final source in [...novelSources.values, ...pastNovel.values]) {
        source.dispose();
      }
    });

    return RankingState(
      illustMode: IllustRankingMode.day,
      mangaMode: MangaRankingMode.day,
      novelMode: NovelRankingMode.day,
      illustSources: illustSources,
      mangaSources: mangaSources,
      novelSources: novelSources,
    );
  }

  /// The rankings of the days looked at so far, kept per mode and day so that
  /// coming back to one needs no new request.
  late Map<(IllustRankingMode, DateTime), RankingIllustListSource> _pastIllust;
  late Map<(MangaRankingMode, DateTime), RankingMangaListSource> _pastManga;
  late Map<(NovelRankingMode, DateTime), RankingNovelListSource> _pastNovel;

  /// The ranking of [mode] on [date], the latest one for a null [date]; sample
  /// data answers its own.
  @protected
  RankingIllustListSource createIllustSource(IllustRankingMode mode, DateTime? date) => RankingIllustListSource(mode: mode, date: date);

  @protected
  RankingMangaListSource createMangaSource(MangaRankingMode mode, DateTime? date) => RankingMangaListSource(mode: mode, date: date);

  @protected
  RankingNovelListSource createNovelSource(NovelRankingMode mode, DateTime? date) => RankingNovelListSource(mode: mode, date: date);

  /// The ranking of [mode] on the day the rankings are of now.
  RankingIllustListSource illustSourceFor(IllustRankingMode mode) {
    final date = state.date;
    return date == null ? state.illustSources[mode]! : _pastIllust.putIfAbsent((mode, date), () => createIllustSource(mode, date));
  }

  RankingMangaListSource mangaSourceFor(MangaRankingMode mode) {
    final date = state.date;
    return date == null ? state.mangaSources[mode]! : _pastManga.putIfAbsent((mode, date), () => createMangaSource(mode, date));
  }

  RankingNovelListSource novelSourceFor(NovelRankingMode mode) {
    final date = state.date;
    return date == null ? state.novelSources[mode]! : _pastNovel.putIfAbsent((mode, date), () => createNovelSource(mode, date));
  }

  /// Shows the rankings of the day [date] (its date, not its time), or the
  /// latest ones for null. Every kind and mode follows.
  void setDate(DateTime? date) {
    final day = date == null ? null : DateTime(date.year, date.month, date.day);
    if (state.date == day) return;
    state = state.onDate(day);
  }

  void setIllustMode(IllustRankingMode mode) {
    if (state.illustMode == mode) {
      return;
    }

    state = state.copyWith(illustMode: mode);
    loadIllustCurrentIfNeeded();
  }

  void setMangaMode(MangaRankingMode mode) {
    if (state.mangaMode == mode) {
      return;
    }

    state = state.copyWith(mangaMode: mode);
    loadMangaCurrentIfNeeded();
  }

  void setNovelMode(NovelRankingMode mode) {
    if (state.novelMode == mode) {
      return;
    }

    state = state.copyWith(novelMode: mode);
    loadNovelCurrentIfNeeded();
  }

  void loadIllustCurrentIfNeeded() => loadIllustModeIfNeeded(state.illustMode);

  void loadMangaCurrentIfNeeded() => loadMangaModeIfNeeded(state.mangaMode);

  void loadNovelCurrentIfNeeded() => loadNovelModeIfNeeded(state.novelMode);

  /// Loads one mode's ranking for a page showing it, whatever mode the
  /// other ranking pages show.
  void loadIllustModeIfNeeded(IllustRankingMode mode) => _loadIllustSourceIfNeeded(illustSourceFor(mode));

  void loadMangaModeIfNeeded(MangaRankingMode mode) => _loadMangaSourceIfNeeded(mangaSourceFor(mode));

  void loadNovelModeIfNeeded(NovelRankingMode mode) => _loadNovelSourceIfNeeded(novelSourceFor(mode));

  void _loadIllustSourceIfNeeded(RankingIllustListSource source) {
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }

  void _loadMangaSourceIfNeeded(RankingMangaListSource source) {
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }

  void _loadNovelSourceIfNeeded(RankingNovelListSource source) {
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }
}
