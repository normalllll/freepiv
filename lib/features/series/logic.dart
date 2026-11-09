import 'package:flutter/foundation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/logic/optimistic_mutation.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_data/frost_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

/// What a series page shows above its works.
class SeriesSummary {
  const SeriesSummary({
    required this.title,
    required this.caption,
    required this.user,
    required this.coverUrl,
    required this.workCount,
    required this.watched,
    this.concluded,
    this.characters,
    this.first,
  });

  final String title;
  final String caption;
  final User user;
  final String? coverUrl;
  final int workCount;
  final bool watched;

  /// Whether it has finished; only novel series say.
  final bool? concluded;

  /// The length of a novel series.
  final int? characters;

  /// The first work.
  final Object? first;
}

class NovelSeriesSource extends FrostCursorListSource<Novel, NovelSeriesPageResult> {
  NovelSeriesSource({required this.seriesId});

  final int seriesId;

  /// Filled by the first page, and again by a refresh.
  final summary = ValueNotifier<SeriesSummary?>(null);

  Future<NovelSeriesPageResult> fetchFirstPage() => pixivApi.getNovelSeriesPage(seriesId: seriesId);

  @override
  Future<NovelSeriesPageResult> loadFirstPage() async {
    final page = await fetchFirstPage();
    final detail = page.novelSeriesDetail;
    summary.value = SeriesSummary(
      title: detail.title,
      caption: detail.caption,
      user: detail.user,
      coverUrl: page.novelSeriesFirstNovel?.imageUrls.medium,
      workCount: detail.contentCount,
      watched: detail.watchlistAdded,
      concluded: detail.isConcluded,
      characters: detail.totalCharacterCount,
      first: page.novelSeriesFirstNovel,
    );
    return page;
  }

  @override
  Future<NovelSeriesPageResult> loadNextPage(String nextUrl) => pixivApi.getNextNovelSeriesPage(url: nextUrl);

  @override
  String? nextUrlFromPage(NovelSeriesPageResult page) => page.nextUrl;

  @override
  List<Novel> itemsFromPage(NovelSeriesPageResult page) => page.novels;

  @override
  void dispose() {
    summary.dispose();
    super.dispose();
  }
}

class MangaSeriesSource extends FrostCursorListSource<Illust, IllustSeriesPageResult> {
  MangaSeriesSource({required this.seriesId});

  final int seriesId;

  /// Filled by the first page, and again by a refresh.
  final summary = ValueNotifier<SeriesSummary?>(null);

  Future<IllustSeriesPageResult> fetchFirstPage() => pixivApi.getIllustSeriesPage(seriesId: seriesId);

  @override
  Future<IllustSeriesPageResult> loadFirstPage() async {
    final page = await fetchFirstPage();
    final detail = page.illustSeriesDetail;
    summary.value = SeriesSummary(
      title: detail.title,
      caption: detail.caption,
      user: detail.user,
      coverUrl: detail.coverImageUrls.medium,
      workCount: detail.seriesWorkCount,
      watched: detail.watchlistAdded,
      first: page.illustSeriesFirstIllust,
    );
    return page;
  }

  @override
  Future<IllustSeriesPageResult> loadNextPage(String nextUrl) => pixivApi.getNextIllustSeriesPage(url: nextUrl);

  @override
  String? nextUrlFromPage(IllustSeriesPageResult page) => page.nextUrl;

  @override
  List<Illust> itemsFromPage(IllustSeriesPageResult page) => page.illusts;

  @override
  void dispose() {
    summary.dispose();
    super.dispose();
  }
}

class WatchlistSource extends FrostCursorListSource<WatchlistSeries, WatchlistPageResult> {
  WatchlistSource({required this.kind});

  final AppSeriesKind kind;

  @override
  Future<WatchlistPageResult> loadFirstPage() => pixivApi.getWatchlistPage(isNovel: kind == AppSeriesKind.novel);

  @override
  Future<WatchlistPageResult> loadNextPage(String nextUrl) => pixivApi.getNextWatchlistPage(url: nextUrl);

  @override
  String? nextUrlFromPage(WatchlistPageResult page) => page.nextUrl;

  @override
  List<WatchlistSeries> itemsFromPage(WatchlistPageResult page) => page.series;
}

@riverpod
class NovelSeriesWorks extends _$NovelSeriesWorks {
  @override
  NovelSeriesSource build(int seriesId) {
    final source = NovelSeriesSource(seriesId: seriesId);
    ref.onDispose(source.dispose);
    return source;
  }
}

@riverpod
class MangaSeriesWorks extends _$MangaSeriesWorks {
  @override
  MangaSeriesSource build(int seriesId) {
    final source = MangaSeriesSource(seriesId: seriesId);
    ref.onDispose(source.dispose);
    return source;
  }
}

@riverpod
class WatchlistEntries extends _$WatchlistEntries {
  @override
  WatchlistSource build(AppSeriesKind kind) {
    final source = WatchlistSource(kind: kind);
    ref.onDispose(source.dispose);
    return source;
  }
}

class SeriesWatchArgs {
  const SeriesWatchArgs({required this.accountId, required this.kind, required this.seriesId, required this.watched});

  final String? accountId;
  final AppSeriesKind kind;
  final int seriesId;

  /// Where the state starts; not part of the identity.
  final bool watched;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SeriesWatchArgs && other.accountId == accountId && other.kind == kind && other.seriesId == seriesId;

  @override
  int get hashCode => Object.hash(accountId, kind, seriesId);
}

class SeriesWatchState {
  const SeriesWatchState({required this.watched, this.updating = false});

  final bool watched;
  final bool updating;

  SeriesWatchState copyWith({bool? watched, bool? updating}) => SeriesWatchState(watched: watched ?? this.watched, updating: updating ?? this.updating);
}

@riverpod
class SeriesWatch extends _$SeriesWatch {
  @override
  SeriesWatchState build(SeriesWatchArgs args) => SeriesWatchState(watched: args.watched);

  Future<void> toggle() async {
    if (state.updating) return;
    if (args.accountId == null || pixivAccountNotifier.value?.user.id != args.accountId) return;

    final previous = state;
    final watch = !previous.watched;
    final isNovel = args.kind == AppSeriesKind.novel;
    await runOptimisticMutation(
      previous: previous,
      optimistic: previous.copyWith(watched: watch, updating: true),
      read: () => state,
      write: (next) => state = next,
      mutate: () => watch
          ? pixivApi.postWatchlistAdd(seriesId: args.seriesId, isNovel: isNovel)
          : pixivApi.postWatchlistDelete(seriesId: args.seriesId, isNovel: isNovel),
      settle: (current) => current.copyWith(updating: false),
      rollback: (previous) => previous.copyWith(updating: false),
      canCommit: () => ref.mounted && pixivAccountNotifier.value?.user.id == args.accountId,
    );
  }
}
