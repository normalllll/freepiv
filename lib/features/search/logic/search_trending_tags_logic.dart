import 'dart:async';

import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_trending_tags_logic.g.dart';

@Riverpod(keepAlive: true)
class SearchTrendingTags extends _$SearchTrendingTags {
  @override
  Future<List<TrendTag>> build() async {
    return _fetchTrendingTags();
  }

  Future<void> reload({bool keepPreviousData = true}) async {
    final previousTags = state.value;
    if (!keepPreviousData || previousTags == null || previousTags.isEmpty) {
      state = const AsyncLoading<List<TrendTag>>();
    }

    state = await AsyncValue.guard(_fetchTrendingTags);
  }

  Future<List<TrendTag>> _fetchTrendingTags() async {
    final result = await pixivApi.getTrendingTagList();
    return result.trendTags;
  }
}
