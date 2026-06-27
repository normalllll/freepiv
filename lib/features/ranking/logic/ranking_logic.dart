import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ranking_logic.g.dart';

class RankingState {
  const RankingState({
    required this.illustMode,
    required this.mangaMode,
    required this.novelMode,
    required this.illustSources,
    required this.mangaSources,
    required this.novelSources,
  });

  final IllustRankingMode illustMode;
  final MangaRankingMode mangaMode;
  final NovelRankingMode novelMode;

  final Map<IllustRankingMode, RankingIllustListSource> illustSources;
  final Map<MangaRankingMode, RankingMangaListSource> mangaSources;
  final Map<NovelRankingMode, RankingNovelListSource> novelSources;

  RankingIllustListSource get currentIllustSource {
    return illustSources[illustMode]!;
  }

  RankingMangaListSource get currentMangaSource {
    return mangaSources[mangaMode]!;
  }

  RankingNovelListSource get currentNovelSource {
    return novelSources[novelMode]!;
  }

  RankingIllustListSource illustSourceFor(IllustRankingMode mode) {
    return illustSources[mode]!;
  }

  RankingMangaListSource mangaSourceFor(MangaRankingMode mode) {
    return mangaSources[mode]!;
  }

  RankingNovelListSource novelSourceFor(NovelRankingMode mode) {
    return novelSources[mode]!;
  }

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
    );
  }
}

class RankingIllustListSource extends NextUrlListSource<Illust, IllustPageResult> {
  RankingIllustListSource({required this.mode});

  final IllustRankingMode mode;

  @override
  Future<IllustPageResult> loadFirstPage() {
    return pixivApi.getIllustRankingPage(mode: mode);
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

class RankingMangaListSource extends NextUrlListSource<Illust, IllustPageResult> {
  RankingMangaListSource({required this.mode});

  final MangaRankingMode mode;

  @override
  Future<IllustPageResult> loadFirstPage() {
    return pixivApi.getMangaRankingPage(mode: mode);
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

class RankingNovelListSource extends NextUrlListSource<Novel, NovelPageResult> {
  RankingNovelListSource({required this.mode});

  final NovelRankingMode mode;

  @override
  Future<NovelPageResult> loadFirstPage() {
    return pixivApi.getNovelRankingPage(mode: mode);
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
    final illustSources = {for (final mode in IllustRankingMode.values) mode: RankingIllustListSource(mode: mode)};

    final mangaSources = {for (final mode in MangaRankingMode.values) mode: RankingMangaListSource(mode: mode)};

    final novelSources = {for (final mode in NovelRankingMode.values) mode: RankingNovelListSource(mode: mode)};

    ref.onDispose(() {
      for (final source in illustSources.values) {
        source.dispose();
      }

      for (final source in mangaSources.values) {
        source.dispose();
      }

      for (final source in novelSources.values) {
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

  void loadCurrentIfNeeded() {
    loadIllustCurrentIfNeeded();
  }

  void loadIllustCurrentIfNeeded() {
    _loadIllustSourceIfNeeded(state.currentIllustSource);
  }

  void loadMangaCurrentIfNeeded() {
    _loadMangaSourceIfNeeded(state.currentMangaSource);
  }

  void loadNovelCurrentIfNeeded() {
    _loadNovelSourceIfNeeded(state.currentNovelSource);
  }

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
