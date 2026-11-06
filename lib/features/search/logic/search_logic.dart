import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frost_data/frost_data.dart';

part 'search_logic.freezed.dart';
part 'search_logic.g.dart';

enum SearchType { illust, novel, user }

enum SearchDatePreset { any, day, week, month, halfYear, year, custom }

/// How the results are ordered. A popular preview is one batch of the most
/// bookmarked works with no next page, not a sort of the full results.
enum SearchOrder { newest, oldest, popularPreview }

/// Bookmark tags a search can require (the "N users入り" tags); 0 is no tag.
/// A tag match, not a guarantee of at least that many bookmarks.
const searchBookmarkTotalOptions = <int>[0, 100, 500, 1000, 5000, 10000, 20000, 30000, 50000, 100000];

/// Minimum widths and heights, in pixels, offered for illustration search.
const searchMinSizeOptions = <int>[1000, 2000];

/// The longest date range a search covers: Pixiv keeps only the last year of
/// a longer one, so the client never sends or shows more than this.
const searchSpanDays = 365;

@freezed
sealed class SearchDraftState with _$SearchDraftState {
  const factory SearchDraftState({@Default('') String text, @Default(SearchType.illust) SearchType type}) = _SearchDraftState;
}

@freezed
sealed class SearchFiltersState with _$SearchFiltersState {
  const factory SearchFiltersState({@Default(SearchFilterState()) SearchFilterState illust, @Default(SearchFilterState()) SearchFilterState novel}) =
      _SearchFiltersState;
}

@freezed
sealed class SearchFilterState with _$SearchFilterState {
  const SearchFilterState._();

  const factory SearchFilterState({
    @Default(SearchOrder.newest) SearchOrder order,
    @Default(SearchTarget.partialMatchForTags) SearchTarget target,
    // Novels match by their own set of targets.
    @Default(SearchNovelTarget.partialMatchForTags) SearchNovelTarget novelTarget,
    @Default(SearchDatePreset.any) SearchDatePreset datePreset,
    DateTime? customStart,
    DateTime? customEnd,
    int? bookmarkTotal,
    // Illustration search only, and not in a popular preview.
    SearchContentType? contentType,
    SearchRatio? ratio,
    int? minWidth,
    int? minHeight,
    String? tool,
  }) = _SearchFilterState;

  bool get isPopularPreview => order == SearchOrder.popularPreview;

  /// The sort of a full search; a popular preview has none.
  SearchSort? get sort => switch (order) {
    SearchOrder.newest => SearchSort.dateDesc,
    SearchOrder.oldest => SearchSort.dateAsc,
    SearchOrder.popularPreview => null,
  };

  /// The request options. Each endpoint reads only the ones it supports: the
  /// preview takes the dates and bookmark tag, novels leave out the
  /// illustration-only ones.
  SearchOptions toOptions(DateTime now) {
    final range = dateRange(now);
    final tool = this.tool?.trim();
    return SearchOptions(
      startDate: _formatPixivDate(range?.$1),
      endDate: _formatPixivDate(range?.$2),
      bookmarkTotal: bookmarkTotal,
      contentType: contentType,
      ratio: ratio,
      widthMin: minWidth,
      heightMin: minHeight,
      tool: tool == null || tool.isEmpty ? null : tool,
    );
  }

  /// The dates the search covers, in order and within [searchSpanDays] of the
  /// end; null for any date.
  (DateTime, DateTime)? dateRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final range = switch (datePreset) {
      SearchDatePreset.any => null,
      SearchDatePreset.day => (today, today),
      SearchDatePreset.week => (today.subtract(const Duration(days: 6)), today),
      SearchDatePreset.month => (DateTime(today.year, today.month - 1, today.day), today),
      SearchDatePreset.halfYear => (DateTime(today.year, today.month - 6, today.day), today),
      SearchDatePreset.year => (DateTime(today.year, today.month, today.day - searchSpanDays), today),
      SearchDatePreset.custom => customStart == null || customEnd == null ? null : (customStart!, customEnd!),
    };
    return range == null ? null : clampSearchRange(range.$1, range.$2);
  }
}

/// Puts [start] and [end] in order and keeps the range within
/// [searchSpanDays] of [end], dropping the oldest days of a longer one.
(DateTime, DateTime) clampSearchRange(DateTime start, DateTime end) {
  final (first, last) = start.isAfter(end) ? (end, start) : (start, end);
  final earliest = DateTime(last.year, last.month, last.day - searchSpanDays);
  return (first.isBefore(earliest) ? earliest : first, last);
}

@freezed
sealed class SearchResultRequest with _$SearchResultRequest {
  const factory SearchResultRequest({required String keyword, required SearchFilterState filter}) = _SearchResultRequest;
}

@Riverpod(keepAlive: true, dependencies: [])
class SearchDraft extends _$SearchDraft {
  @override
  SearchDraftState build() => const SearchDraftState();

  void setDraft(SearchDraftState draft) {
    if (state == draft) {
      return;
    }
    state = draft;
  }
}

@Riverpod(keepAlive: true, dependencies: [])
class SearchFilters extends _$SearchFilters {
  @override
  SearchFiltersState build() => const SearchFiltersState();

  void apply(SearchFiltersState filters) => state = filters;

  void setFilter(SearchType type, SearchFilterState filter) {
    final next = switch (type) {
      SearchType.illust => state.copyWith(illust: filter),
      SearchType.novel => state.copyWith(novel: filter),
      SearchType.user => state,
    };
    if (state == next) {
      return;
    }
    state = next;
  }
}

@Riverpod(dependencies: [SearchDraft])
SearchIllustListSource searchIllustResultSource(Ref ref, SearchResultRequest request) {
  final source = SearchIllustListSource(request: request);
  ref.onDispose(source.dispose);
  return source;
}

@Riverpod(dependencies: [SearchDraft])
SearchNovelListSource searchNovelResultSource(Ref ref, SearchResultRequest request) {
  final source = SearchNovelListSource(request: request);
  ref.onDispose(source.dispose);
  return source;
}

@Riverpod(dependencies: [SearchDraft])
SearchUserListSource searchUserResultSource(Ref ref, String keyword) {
  final source = SearchUserListSource(keyword: keyword);
  ref.onDispose(source.dispose);
  return source;
}

class SearchIllustListSource extends FrostCursorListSource<Illust, SearchIllustPageResult> {
  SearchIllustListSource({required this.request});

  final SearchResultRequest request;
  int? _searchSpanLimit;

  int? get searchSpanLimit => _searchSpanLimit;

  @override
  Future<SearchIllustPageResult> loadFirstPage() async {
    if (request.keyword.trim().isEmpty) {
      return const SearchIllustPageResult(illusts: [], nextUrl: null, searchSpanLimit: 0);
    }

    final filter = request.filter;
    final options = filter.toOptions(DateTime.now());
    if (filter.sort case final sort?) {
      return pixivApi.getSearchIllustPage(word: request.keyword.trim(), sort: sort, target: filter.target, options: options);
    }
    return pixivApi.getSearchPopularPreviewIllust(word: request.keyword.trim(), target: filter.target, options: options);
  }

  @override
  Future<SearchIllustPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextSearchIllustPage(url: nextUrl);
  }

  // An empty page ends the results even where the server still names a next
  // one.
  @override
  String? nextUrlFromPage(SearchIllustPageResult page) {
    return page.illusts.isEmpty ? null : page.nextUrl;
  }

  @override
  List<Illust> itemsFromPage(SearchIllustPageResult page) {
    return page.illusts;
  }

  @override
  void didApplyPage(SearchIllustPageResult page) {
    _searchSpanLimit = page.searchSpanLimit;
  }

  @override
  void clearData() {
    _searchSpanLimit = null;
    super.clearData();
  }
}

class SearchNovelListSource extends FrostCursorListSource<Novel, SearchNovelPageResult> {
  SearchNovelListSource({required this.request});

  final SearchResultRequest request;
  int? _searchSpanLimit;

  int? get searchSpanLimit => _searchSpanLimit;

  @override
  Future<SearchNovelPageResult> loadFirstPage() async {
    if (request.keyword.trim().isEmpty) {
      return const SearchNovelPageResult(novels: [], nextUrl: null, searchSpanLimit: 0);
    }

    final filter = request.filter;
    final options = filter.toOptions(DateTime.now());
    if (filter.sort case final sort?) {
      return pixivApi.getSearchNovelPage(word: request.keyword.trim(), sort: sort, target: filter.novelTarget, options: options);
    }
    return pixivApi.getSearchPopularPreviewNovel(word: request.keyword.trim(), target: filter.novelTarget, options: options);
  }

  @override
  Future<SearchNovelPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextSearchNovelPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(SearchNovelPageResult page) {
    return page.novels.isEmpty ? null : page.nextUrl;
  }

  @override
  List<Novel> itemsFromPage(SearchNovelPageResult page) {
    return page.novels;
  }

  @override
  void didApplyPage(SearchNovelPageResult page) {
    _searchSpanLimit = page.searchSpanLimit;
  }

  @override
  void clearData() {
    _searchSpanLimit = null;
    super.clearData();
  }
}

class SearchUserListSource extends FrostCursorListSource<UserPreview, UserPageResult> {
  SearchUserListSource({required this.keyword});

  final String keyword;

  @override
  Future<UserPageResult> loadFirstPage() async {
    if (keyword.trim().isEmpty) {
      return const UserPageResult(userPreviews: [], nextUrl: null);
    }

    return pixivApi.getSearchUserPage(word: keyword.trim());
  }

  @override
  Future<UserPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextUserPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(UserPageResult page) {
    return page.nextUrl;
  }

  @override
  List<UserPreview> itemsFromPage(UserPageResult page) {
    return page.userPreviews;
  }
}

String? _formatPixivDate(DateTime? date) {
  if (date == null) {
    return null;
  }

  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
