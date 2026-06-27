import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_logic.freezed.dart';
part 'search_logic.g.dart';

enum SearchType { illust, novel, user }

enum SearchDatePreset { any, day, week, month, halfYear, year, custom }

const searchBookmarkTotalOptions = <int>[0, 100, 500, 1000, 5000, 10000];

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
    @Default(SearchSort.dateDesc) SearchSort sort,
    @Default(SearchTarget.partialMatchForTags) SearchTarget target,
    @Default(SearchDatePreset.any) SearchDatePreset datePreset,
    DateTime? customStart,
    DateTime? customEnd,
    int? bookmarkTotal,
  }) = _SearchFilterState;

  SearchOptions toOptions(DateTime now) {
    final range = _dateRange(now);
    return SearchOptions(startDate: _formatPixivDate(range?.$1), endDate: _formatPixivDate(range?.$2), bookmarkTotal: bookmarkTotal);
  }

  (DateTime, DateTime)? _dateRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (datePreset) {
      SearchDatePreset.any => null,
      SearchDatePreset.day => (today, today),
      SearchDatePreset.week => (today.subtract(const Duration(days: 6)), today),
      SearchDatePreset.month => (DateTime(today.year, today.month - 1, today.day), today),
      SearchDatePreset.halfYear => (DateTime(today.year, today.month - 6, today.day), today),
      SearchDatePreset.year => (DateTime(today.year - 1, today.month, today.day), today),
      SearchDatePreset.custom => customStart == null || customEnd == null ? null : (customStart!, customEnd!),
    };
  }
}

@freezed
sealed class SearchResultRequest with _$SearchResultRequest {
  const factory SearchResultRequest({required String keyword, required SearchFilterState filter}) = _SearchResultRequest;
}

@Riverpod(keepAlive: true)
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

@Riverpod(keepAlive: true)
class SearchFilters extends _$SearchFilters {
  @override
  SearchFiltersState build() => const SearchFiltersState();

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

@Riverpod()
SearchIllustListSource searchIllustResultSource(Ref ref, SearchResultRequest request) {
  final source = SearchIllustListSource(request: request);
  ref.onDispose(source.dispose);
  return source;
}

@Riverpod()
SearchNovelListSource searchNovelResultSource(Ref ref, SearchResultRequest request) {
  final source = SearchNovelListSource(request: request);
  ref.onDispose(source.dispose);
  return source;
}

@Riverpod()
SearchUserListSource searchUserResultSource(Ref ref, String keyword) {
  final source = SearchUserListSource(keyword: keyword);
  ref.onDispose(source.dispose);
  return source;
}

class SearchIllustListSource extends NextUrlListSource<Illust, SearchIllustPageResult> {
  SearchIllustListSource({required this.request});

  final SearchResultRequest request;
  int? _searchSpanLimit;

  int? get searchSpanLimit => _searchSpanLimit;

  @override
  Future<SearchIllustPageResult> loadFirstPage() async {
    if (request.keyword.trim().isEmpty) {
      return const SearchIllustPageResult(illusts: [], nextUrl: null, searchSpanLimit: 0);
    }

    return pixivApi.getSearchIllustPage(
      word: request.keyword.trim(),
      sort: request.filter.sort,
      target: request.filter.target,
      options: request.filter.toOptions(DateTime.now()),
    );
  }

  @override
  Future<SearchIllustPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextSearchIllustPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(SearchIllustPageResult page) {
    return page.nextUrl;
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

class SearchNovelListSource extends NextUrlListSource<Novel, SearchNovelPageResult> {
  SearchNovelListSource({required this.request});

  final SearchResultRequest request;
  int? _searchSpanLimit;

  int? get searchSpanLimit => _searchSpanLimit;

  @override
  Future<SearchNovelPageResult> loadFirstPage() async {
    if (request.keyword.trim().isEmpty) {
      return const SearchNovelPageResult(novels: [], nextUrl: null, searchSpanLimit: 0);
    }

    return pixivApi.getSearchNovelPage(
      word: request.keyword.trim(),
      sort: request.filter.sort,
      target: request.filter.target,
      options: request.filter.toOptions(DateTime.now()),
    );
  }

  @override
  Future<SearchNovelPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextSearchNovelPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(SearchNovelPageResult page) {
    return page.nextUrl;
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

class SearchUserListSource extends NextUrlListSource<UserPreview, UserPageResult> {
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
