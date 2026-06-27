// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_trending_tags_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchTrendingTags)
final searchTrendingTagsProvider = SearchTrendingTagsProvider._();

final class SearchTrendingTagsProvider
    extends $AsyncNotifierProvider<SearchTrendingTags, List<TrendTag>> {
  SearchTrendingTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchTrendingTagsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchTrendingTagsHash();

  @$internal
  @override
  SearchTrendingTags create() => SearchTrendingTags();
}

String _$searchTrendingTagsHash() =>
    r'79741f3b1ae1bad28a13ec3a27bb4f3944ba7b99';

abstract class _$SearchTrendingTags extends $AsyncNotifier<List<TrendTag>> {
  FutureOr<List<TrendTag>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<TrendTag>>, List<TrendTag>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TrendTag>>, List<TrendTag>>,
              AsyncValue<List<TrendTag>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
