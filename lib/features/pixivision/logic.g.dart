// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pixivisionApi)
final pixivisionApiProvider = PixivisionApiFamily._();

final class PixivisionApiProvider extends $FunctionalProvider<AsyncValue<PixivisionApi>, PixivisionApi, FutureOr<PixivisionApi>>
    with $FutureModifier<PixivisionApi>, $FutureProvider<PixivisionApi> {
  PixivisionApiProvider._({required PixivisionApiFamily super.from, required String super.argument})
    : super(retry: null, name: r'pixivisionApiProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$pixivisionApiHash();

  @override
  String toString() {
    return r'pixivisionApiProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PixivisionApi> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<PixivisionApi> create(Ref ref) {
    final argument = this.argument as String;
    return pixivisionApi(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PixivisionApiProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pixivisionApiHash() => r'bc9cf69ba0b4ff41213e5d981d57f9f696e68a41';

final class PixivisionApiFamily extends $Family with $FunctionalFamilyOverride<FutureOr<PixivisionApi>, String> {
  PixivisionApiFamily._() : super(retry: null, name: r'pixivisionApiProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  PixivisionApiProvider call(String language) => PixivisionApiProvider._(argument: language, from: this);

  @override
  String toString() => r'pixivisionApiProvider';
}

@ProviderFor(PixivisionBrowseSelection)
final pixivisionBrowseSelectionProvider = PixivisionBrowseSelectionProvider._();

final class PixivisionBrowseSelectionProvider extends $NotifierProvider<PixivisionBrowseSelection, ({PixivisionSection section, String? url})> {
  PixivisionBrowseSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pixivisionBrowseSelectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pixivisionBrowseSelectionHash();

  @$internal
  @override
  PixivisionBrowseSelection create() => PixivisionBrowseSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({PixivisionSection section, String? url}) value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<({PixivisionSection section, String? url})>(value));
  }
}

String _$pixivisionBrowseSelectionHash() => r'9c2892429b55de5c6e1a370109fa8974d8d9ba2d';

abstract class _$PixivisionBrowseSelection extends $Notifier<({PixivisionSection section, String? url})> {
  ({PixivisionSection section, String? url}) build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<({PixivisionSection section, String? url}), ({PixivisionSection section, String? url})>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<({PixivisionSection section, String? url}), ({PixivisionSection section, String? url})>,
              ({PixivisionSection section, String? url}),
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(PixivisionBrowse)
final pixivisionBrowseProvider = PixivisionBrowseFamily._();

final class PixivisionBrowseProvider extends $AsyncNotifierProvider<PixivisionBrowse, PixivisionListing> {
  PixivisionBrowseProvider._({required PixivisionBrowseFamily super.from, required String super.argument})
    : super(retry: null, name: r'pixivisionBrowseProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$pixivisionBrowseHash();

  @override
  String toString() {
    return r'pixivisionBrowseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PixivisionBrowse create() => PixivisionBrowse();

  @override
  bool operator ==(Object other) {
    return other is PixivisionBrowseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pixivisionBrowseHash() => r'b869d8d1c83dd1da4b09305be850eb396ee805f1';

final class PixivisionBrowseFamily extends $Family
    with $ClassFamilyOverride<PixivisionBrowse, AsyncValue<PixivisionListing>, PixivisionListing, FutureOr<PixivisionListing>, String> {
  PixivisionBrowseFamily._() : super(retry: null, name: r'pixivisionBrowseProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  PixivisionBrowseProvider call(String url) => PixivisionBrowseProvider._(argument: url, from: this);

  @override
  String toString() => r'pixivisionBrowseProvider';
}

abstract class _$PixivisionBrowse extends $AsyncNotifier<PixivisionListing> {
  late final _$args = ref.$arg as String;
  String get url => _$args;

  FutureOr<PixivisionListing> build(String url);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PixivisionListing>, PixivisionListing>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<PixivisionListing>, PixivisionListing>, AsyncValue<PixivisionListing>, Object?, Object?>;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(pixivisionArticle)
final pixivisionArticleProvider = PixivisionArticleFamily._();

final class PixivisionArticleProvider extends $FunctionalProvider<AsyncValue<PixivisionDocument>, PixivisionDocument, FutureOr<PixivisionDocument>>
    with $FutureModifier<PixivisionDocument>, $FutureProvider<PixivisionDocument> {
  PixivisionArticleProvider._({required PixivisionArticleFamily super.from, required String super.argument})
    : super(retry: null, name: r'pixivisionArticleProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$pixivisionArticleHash();

  @override
  String toString() {
    return r'pixivisionArticleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PixivisionDocument> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<PixivisionDocument> create(Ref ref) {
    final argument = this.argument as String;
    return pixivisionArticle(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PixivisionArticleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pixivisionArticleHash() => r'2e4d3b522d6ae74e53b767a591b515aaed4ae187';

final class PixivisionArticleFamily extends $Family with $FunctionalFamilyOverride<FutureOr<PixivisionDocument>, String> {
  PixivisionArticleFamily._()
    : super(retry: null, name: r'pixivisionArticleProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  PixivisionArticleProvider call(String url) => PixivisionArticleProvider._(argument: url, from: this);

  @override
  String toString() => r'pixivisionArticleProvider';
}

@ProviderFor(pixivisionTags)
final pixivisionTagsProvider = PixivisionTagsFamily._();

final class PixivisionTagsProvider extends $FunctionalProvider<AsyncValue<TagDirectory>, TagDirectory, FutureOr<TagDirectory>>
    with $FutureModifier<TagDirectory>, $FutureProvider<TagDirectory> {
  PixivisionTagsProvider._({required PixivisionTagsFamily super.from, required String super.argument})
    : super(retry: null, name: r'pixivisionTagsProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$pixivisionTagsHash();

  @override
  String toString() {
    return r'pixivisionTagsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TagDirectory> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<TagDirectory> create(Ref ref) {
    final argument = this.argument as String;
    return pixivisionTags(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PixivisionTagsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pixivisionTagsHash() => r'63ba9db333be6130ff0a36b105105aebef4f9be7';

final class PixivisionTagsFamily extends $Family with $FunctionalFamilyOverride<FutureOr<TagDirectory>, String> {
  PixivisionTagsFamily._() : super(retry: null, name: r'pixivisionTagsProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  PixivisionTagsProvider call(String language) => PixivisionTagsProvider._(argument: language, from: this);

  @override
  String toString() => r'pixivisionTagsProvider';
}
