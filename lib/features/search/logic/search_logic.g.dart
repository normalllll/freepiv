// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchDraft)
final searchDraftProvider = SearchDraftProvider._();

final class SearchDraftProvider
    extends $NotifierProvider<SearchDraft, SearchDraftState> {
  SearchDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchDraftProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchDraftHash();

  @$internal
  @override
  SearchDraft create() => SearchDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchDraftState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchDraftState>(value),
    );
  }
}

String _$searchDraftHash() => r'b760e5bbb17faece571b3cee30df2b1542da8d3b';

abstract class _$SearchDraft extends $Notifier<SearchDraftState> {
  SearchDraftState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SearchDraftState, SearchDraftState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchDraftState, SearchDraftState>,
              SearchDraftState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SearchFilters)
final searchFiltersProvider = SearchFiltersProvider._();

final class SearchFiltersProvider
    extends $NotifierProvider<SearchFilters, SearchFiltersState> {
  SearchFiltersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchFiltersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchFiltersHash();

  @$internal
  @override
  SearchFilters create() => SearchFilters();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchFiltersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchFiltersState>(value),
    );
  }
}

String _$searchFiltersHash() => r'a0971265ac9d9c3f798dcff38bddd1c9441dd4e0';

abstract class _$SearchFilters extends $Notifier<SearchFiltersState> {
  SearchFiltersState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SearchFiltersState, SearchFiltersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchFiltersState, SearchFiltersState>,
              SearchFiltersState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(searchIllustResultSource)
final searchIllustResultSourceProvider = SearchIllustResultSourceFamily._();

final class SearchIllustResultSourceProvider
    extends
        $FunctionalProvider<
          SearchIllustListSource,
          SearchIllustListSource,
          SearchIllustListSource
        >
    with $Provider<SearchIllustListSource> {
  SearchIllustResultSourceProvider._({
    required SearchIllustResultSourceFamily super.from,
    required SearchResultRequest super.argument,
  }) : super(
         retry: null,
         name: r'searchIllustResultSourceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchIllustResultSourceHash();

  @override
  String toString() {
    return r'searchIllustResultSourceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<SearchIllustListSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SearchIllustListSource create(Ref ref) {
    final argument = this.argument as SearchResultRequest;
    return searchIllustResultSource(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchIllustListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchIllustListSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchIllustResultSourceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchIllustResultSourceHash() =>
    r'eae66c043c05ed1918e048057116651c5881e277';

final class SearchIllustResultSourceFamily extends $Family
    with
        $FunctionalFamilyOverride<SearchIllustListSource, SearchResultRequest> {
  SearchIllustResultSourceFamily._()
    : super(
        retry: null,
        name: r'searchIllustResultSourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SearchIllustResultSourceProvider call(SearchResultRequest request) =>
      SearchIllustResultSourceProvider._(argument: request, from: this);

  @override
  String toString() => r'searchIllustResultSourceProvider';
}

@ProviderFor(searchNovelResultSource)
final searchNovelResultSourceProvider = SearchNovelResultSourceFamily._();

final class SearchNovelResultSourceProvider
    extends
        $FunctionalProvider<
          SearchNovelListSource,
          SearchNovelListSource,
          SearchNovelListSource
        >
    with $Provider<SearchNovelListSource> {
  SearchNovelResultSourceProvider._({
    required SearchNovelResultSourceFamily super.from,
    required SearchResultRequest super.argument,
  }) : super(
         retry: null,
         name: r'searchNovelResultSourceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchNovelResultSourceHash();

  @override
  String toString() {
    return r'searchNovelResultSourceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<SearchNovelListSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SearchNovelListSource create(Ref ref) {
    final argument = this.argument as SearchResultRequest;
    return searchNovelResultSource(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchNovelListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchNovelListSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchNovelResultSourceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchNovelResultSourceHash() =>
    r'3da1b97037ec545120aa9adb8d8cf4e140149538';

final class SearchNovelResultSourceFamily extends $Family
    with $FunctionalFamilyOverride<SearchNovelListSource, SearchResultRequest> {
  SearchNovelResultSourceFamily._()
    : super(
        retry: null,
        name: r'searchNovelResultSourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SearchNovelResultSourceProvider call(SearchResultRequest request) =>
      SearchNovelResultSourceProvider._(argument: request, from: this);

  @override
  String toString() => r'searchNovelResultSourceProvider';
}

@ProviderFor(searchUserResultSource)
final searchUserResultSourceProvider = SearchUserResultSourceFamily._();

final class SearchUserResultSourceProvider
    extends
        $FunctionalProvider<
          SearchUserListSource,
          SearchUserListSource,
          SearchUserListSource
        >
    with $Provider<SearchUserListSource> {
  SearchUserResultSourceProvider._({
    required SearchUserResultSourceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'searchUserResultSourceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchUserResultSourceHash();

  @override
  String toString() {
    return r'searchUserResultSourceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<SearchUserListSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SearchUserListSource create(Ref ref) {
    final argument = this.argument as String;
    return searchUserResultSource(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchUserListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchUserListSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchUserResultSourceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchUserResultSourceHash() =>
    r'29951a4b5fa1a143ae48cf4656c60b934018a0ac';

final class SearchUserResultSourceFamily extends $Family
    with $FunctionalFamilyOverride<SearchUserListSource, String> {
  SearchUserResultSourceFamily._()
    : super(
        retry: null,
        name: r'searchUserResultSourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SearchUserResultSourceProvider call(String keyword) =>
      SearchUserResultSourceProvider._(argument: keyword, from: this);

  @override
  String toString() => r'searchUserResultSourceProvider';
}
