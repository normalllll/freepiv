// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fanboxStore)
final fanboxStoreProvider = FanboxStoreProvider._();

final class FanboxStoreProvider extends $FunctionalProvider<AsyncValue<Box<String>>, Box<String>, FutureOr<Box<String>>>
    with $FutureModifier<Box<String>>, $FutureProvider<Box<String>> {
  FanboxStoreProvider._()
    : super(from: null, argument: null, retry: null, name: r'fanboxStoreProvider', isAutoDispose: false, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$fanboxStoreHash();

  @$internal
  @override
  $FutureProviderElement<Box<String>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Box<String>> create(Ref ref) {
    return fanboxStore(ref);
  }
}

String _$fanboxStoreHash() => r'a844f699d5d618cfa2e7a91cb5fc6b9e894e7c94';

@ProviderFor(FanboxOperation)
final fanboxOperationProvider = FanboxOperationFamily._();

final class FanboxOperationProvider extends $AsyncNotifierProvider<FanboxOperation, void> {
  FanboxOperationProvider._({required FanboxOperationFamily super.from, required String super.argument})
    : super(retry: null, name: r'fanboxOperationProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$fanboxOperationHash();

  @override
  String toString() {
    return r'fanboxOperationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FanboxOperation create() => FanboxOperation();

  @override
  bool operator ==(Object other) {
    return other is FanboxOperationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fanboxOperationHash() => r'679604249499d6f67b27ea720fb7864b23d0f5e8';

final class FanboxOperationFamily extends $Family with $ClassFamilyOverride<FanboxOperation, AsyncValue<void>, void, FutureOr<void>, String> {
  FanboxOperationFamily._() : super(retry: null, name: r'fanboxOperationProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  FanboxOperationProvider call(String scope) => FanboxOperationProvider._(argument: scope, from: this);

  @override
  String toString() => r'fanboxOperationProvider';
}

abstract class _$FanboxOperation extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get scope => _$args;

  FutureOr<void> build(String scope);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<void>, void>, AsyncValue<void>, Object?, Object?>;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(FanboxSession)
final fanboxSessionProvider = FanboxSessionProvider._();

final class FanboxSessionProvider extends $AsyncNotifierProvider<FanboxSession, String?> {
  FanboxSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fanboxSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fanboxSessionHash();

  @$internal
  @override
  FanboxSession create() => FanboxSession();
}

String _$fanboxSessionHash() => r'ca088872606dbcf24526884f93778e0c0aea770f';

abstract class _$FanboxSession extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<String?>, String?>, AsyncValue<String?>, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(fanboxApi)
final fanboxApiProvider = FanboxApiProvider._();

final class FanboxApiProvider extends $FunctionalProvider<AsyncValue<FanboxApi>, FanboxApi, FutureOr<FanboxApi>>
    with $FutureModifier<FanboxApi>, $FutureProvider<FanboxApi> {
  FanboxApiProvider._()
    : super(from: null, argument: null, retry: null, name: r'fanboxApiProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$fanboxApiHash();

  @$internal
  @override
  $FutureProviderElement<FanboxApi> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<FanboxApi> create(Ref ref) {
    return fanboxApi(ref);
  }
}

String _$fanboxApiHash() => r'3d3a779204f1947750e5a7c2efefbb4a6de4205d';

@ProviderFor(FanboxBrowseSelection)
final fanboxBrowseSelectionProvider = FanboxBrowseSelectionProvider._();

final class FanboxBrowseSelectionProvider extends $NotifierProvider<FanboxBrowseSelection, FanboxLocation> {
  FanboxBrowseSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fanboxBrowseSelectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fanboxBrowseSelectionHash();

  @$internal
  @override
  FanboxBrowseSelection create() => FanboxBrowseSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FanboxLocation value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<FanboxLocation>(value));
  }
}

String _$fanboxBrowseSelectionHash() => r'18194c2c8a978ca1495e55a3da3cb013efac98a2';

abstract class _$FanboxBrowseSelection extends $Notifier<FanboxLocation> {
  FanboxLocation build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FanboxLocation, FanboxLocation>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<FanboxLocation, FanboxLocation>, FanboxLocation, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(FanboxBrowse)
final fanboxBrowseProvider = FanboxBrowseFamily._();

final class FanboxBrowseProvider extends $AsyncNotifierProvider<FanboxBrowse, FanboxCollection> {
  FanboxBrowseProvider._({required FanboxBrowseFamily super.from, required FanboxLocation super.argument})
    : super(retry: null, name: r'fanboxBrowseProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$fanboxBrowseHash();

  @override
  String toString() {
    return r'fanboxBrowseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FanboxBrowse create() => FanboxBrowse();

  @override
  bool operator ==(Object other) {
    return other is FanboxBrowseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fanboxBrowseHash() => r'195df43046f4e495777f35a74aabe649b4b1a936';

final class FanboxBrowseFamily extends $Family
    with $ClassFamilyOverride<FanboxBrowse, AsyncValue<FanboxCollection>, FanboxCollection, FutureOr<FanboxCollection>, FanboxLocation> {
  FanboxBrowseFamily._() : super(retry: null, name: r'fanboxBrowseProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  FanboxBrowseProvider call(FanboxLocation location) => FanboxBrowseProvider._(argument: location, from: this);

  @override
  String toString() => r'fanboxBrowseProvider';
}

abstract class _$FanboxBrowse extends $AsyncNotifier<FanboxCollection> {
  late final _$args = ref.$arg as FanboxLocation;
  FanboxLocation get location => _$args;

  FutureOr<FanboxCollection> build(FanboxLocation location);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FanboxCollection>, FanboxCollection>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<FanboxCollection>, FanboxCollection>, AsyncValue<FanboxCollection>, Object?, Object?>;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(fanboxPost)
final fanboxPostProvider = FanboxPostFamily._();

final class FanboxPostProvider extends $FunctionalProvider<AsyncValue<FanboxPost>, FanboxPost, FutureOr<FanboxPost>>
    with $FutureModifier<FanboxPost>, $FutureProvider<FanboxPost> {
  FanboxPostProvider._({required FanboxPostFamily super.from, required String super.argument})
    : super(retry: null, name: r'fanboxPostProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$fanboxPostHash();

  @override
  String toString() {
    return r'fanboxPostProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FanboxPost> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<FanboxPost> create(Ref ref) {
    final argument = this.argument as String;
    return fanboxPost(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FanboxPostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fanboxPostHash() => r'c9470c7f1893efa7ef0ccbfcca41090a02f791bf';

final class FanboxPostFamily extends $Family with $FunctionalFamilyOverride<FutureOr<FanboxPost>, String> {
  FanboxPostFamily._() : super(retry: null, name: r'fanboxPostProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  FanboxPostProvider call(String id) => FanboxPostProvider._(argument: id, from: this);

  @override
  String toString() => r'fanboxPostProvider';
}

@ProviderFor(fanboxCreator)
final fanboxCreatorProvider = FanboxCreatorFamily._();

final class FanboxCreatorProvider extends $FunctionalProvider<AsyncValue<FanboxCreator>, FanboxCreator, FutureOr<FanboxCreator>>
    with $FutureModifier<FanboxCreator>, $FutureProvider<FanboxCreator> {
  FanboxCreatorProvider._({required FanboxCreatorFamily super.from, required String super.argument})
    : super(retry: null, name: r'fanboxCreatorProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$fanboxCreatorHash();

  @override
  String toString() {
    return r'fanboxCreatorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FanboxCreator> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<FanboxCreator> create(Ref ref) {
    final argument = this.argument as String;
    return fanboxCreator(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FanboxCreatorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fanboxCreatorHash() => r'ad01f5c0ea5ac93a767e536584704a41277566a9';

final class FanboxCreatorFamily extends $Family with $FunctionalFamilyOverride<FutureOr<FanboxCreator>, String> {
  FanboxCreatorFamily._() : super(retry: null, name: r'fanboxCreatorProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  FanboxCreatorProvider call(String id) => FanboxCreatorProvider._(argument: id, from: this);

  @override
  String toString() => r'fanboxCreatorProvider';
}

@ProviderFor(fanboxPlans)
final fanboxPlansProvider = FanboxPlansFamily._();

final class FanboxPlansProvider extends $FunctionalProvider<AsyncValue<List<FanboxPlan>>, List<FanboxPlan>, FutureOr<List<FanboxPlan>>>
    with $FutureModifier<List<FanboxPlan>>, $FutureProvider<List<FanboxPlan>> {
  FanboxPlansProvider._({required FanboxPlansFamily super.from, required String super.argument})
    : super(retry: null, name: r'fanboxPlansProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$fanboxPlansHash();

  @override
  String toString() {
    return r'fanboxPlansProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FanboxPlan>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FanboxPlan>> create(Ref ref) {
    final argument = this.argument as String;
    return fanboxPlans(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FanboxPlansProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fanboxPlansHash() => r'7ecf8b3a34aa7ecd41ecac85b148f6c60178b796';

final class FanboxPlansFamily extends $Family with $FunctionalFamilyOverride<FutureOr<List<FanboxPlan>>, String> {
  FanboxPlansFamily._() : super(retry: null, name: r'fanboxPlansProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  FanboxPlansProvider call(String creatorId) => FanboxPlansProvider._(argument: creatorId, from: this);

  @override
  String toString() => r'fanboxPlansProvider';
}

@ProviderFor(fanboxTags)
final fanboxTagsProvider = FanboxTagsFamily._();

final class FanboxTagsProvider extends $FunctionalProvider<AsyncValue<List<FanboxTag>>, List<FanboxTag>, FutureOr<List<FanboxTag>>>
    with $FutureModifier<List<FanboxTag>>, $FutureProvider<List<FanboxTag>> {
  FanboxTagsProvider._({required FanboxTagsFamily super.from, required String super.argument})
    : super(retry: null, name: r'fanboxTagsProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$fanboxTagsHash();

  @override
  String toString() {
    return r'fanboxTagsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FanboxTag>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FanboxTag>> create(Ref ref) {
    final argument = this.argument as String;
    return fanboxTags(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FanboxTagsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fanboxTagsHash() => r'ea701ef689797ee391d842ba58c6e04689111174';

final class FanboxTagsFamily extends $Family with $FunctionalFamilyOverride<FutureOr<List<FanboxTag>>, String> {
  FanboxTagsFamily._() : super(retry: null, name: r'fanboxTagsProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  FanboxTagsProvider call(String creatorId) => FanboxTagsProvider._(argument: creatorId, from: this);

  @override
  String toString() => r'fanboxTagsProvider';
}

@ProviderFor(fanboxSupport)
final fanboxSupportProvider = FanboxSupportFamily._();

final class FanboxSupportProvider extends $FunctionalProvider<AsyncValue<FanboxSupport>, FanboxSupport, FutureOr<FanboxSupport>>
    with $FutureModifier<FanboxSupport>, $FutureProvider<FanboxSupport> {
  FanboxSupportProvider._({required FanboxSupportFamily super.from, required String super.argument})
    : super(retry: null, name: r'fanboxSupportProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$fanboxSupportHash();

  @override
  String toString() {
    return r'fanboxSupportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FanboxSupport> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<FanboxSupport> create(Ref ref) {
    final argument = this.argument as String;
    return fanboxSupport(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FanboxSupportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fanboxSupportHash() => r'ee5ebab2f04a350ee4f4d3fd1999f6dade3651d9';

final class FanboxSupportFamily extends $Family with $FunctionalFamilyOverride<FutureOr<FanboxSupport>, String> {
  FanboxSupportFamily._() : super(retry: null, name: r'fanboxSupportProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  FanboxSupportProvider call(String creatorId) => FanboxSupportProvider._(argument: creatorId, from: this);

  @override
  String toString() => r'fanboxSupportProvider';
}

@ProviderFor(fanboxMedia)
final fanboxMediaProvider = FanboxMediaFamily._();

final class FanboxMediaProvider extends $FunctionalProvider<AsyncValue<Uint8List>, Uint8List, FutureOr<Uint8List>>
    with $FutureModifier<Uint8List>, $FutureProvider<Uint8List> {
  FanboxMediaProvider._({required FanboxMediaFamily super.from, required String super.argument})
    : super(retry: null, name: r'fanboxMediaProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$fanboxMediaHash();

  @override
  String toString() {
    return r'fanboxMediaProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Uint8List> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Uint8List> create(Ref ref) {
    final argument = this.argument as String;
    return fanboxMedia(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FanboxMediaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fanboxMediaHash() => r'4500560c95fadb3c7b00960d4e902aba0d8b003a';

final class FanboxMediaFamily extends $Family with $FunctionalFamilyOverride<FutureOr<Uint8List>, String> {
  FanboxMediaFamily._() : super(retry: null, name: r'fanboxMediaProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  FanboxMediaProvider call(String url) => FanboxMediaProvider._(argument: url, from: this);

  @override
  String toString() => r'fanboxMediaProvider';
}

@ProviderFor(FanboxComments)
final fanboxCommentsProvider = FanboxCommentsFamily._();

final class FanboxCommentsProvider extends $AsyncNotifierProvider<FanboxComments, FanboxCommentPage> {
  FanboxCommentsProvider._({required FanboxCommentsFamily super.from, required String super.argument})
    : super(retry: null, name: r'fanboxCommentsProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$fanboxCommentsHash();

  @override
  String toString() {
    return r'fanboxCommentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FanboxComments create() => FanboxComments();

  @override
  bool operator ==(Object other) {
    return other is FanboxCommentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fanboxCommentsHash() => r'f7f0c19323095720a10364881c910857aa78c2a9';

final class FanboxCommentsFamily extends $Family
    with $ClassFamilyOverride<FanboxComments, AsyncValue<FanboxCommentPage>, FanboxCommentPage, FutureOr<FanboxCommentPage>, String> {
  FanboxCommentsFamily._() : super(retry: null, name: r'fanboxCommentsProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  FanboxCommentsProvider call(String postId) => FanboxCommentsProvider._(argument: postId, from: this);

  @override
  String toString() => r'fanboxCommentsProvider';
}

abstract class _$FanboxComments extends $AsyncNotifier<FanboxCommentPage> {
  late final _$args = ref.$arg as String;
  String get postId => _$args;

  FutureOr<FanboxCommentPage> build(String postId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FanboxCommentPage>, FanboxCommentPage>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<FanboxCommentPage>, FanboxCommentPage>, AsyncValue<FanboxCommentPage>, Object?, Object?>;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(FanboxBookmarks)
final fanboxBookmarksProvider = FanboxBookmarksProvider._();

final class FanboxBookmarksProvider extends $AsyncNotifierProvider<FanboxBookmarks, List<String>> {
  FanboxBookmarksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fanboxBookmarksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fanboxBookmarksHash();

  @$internal
  @override
  FanboxBookmarks create() => FanboxBookmarks();
}

String _$fanboxBookmarksHash() => r'6f6f364f3c1477ff3124addfd7743823a57171f7';

abstract class _$FanboxBookmarks extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<List<String>>, List<String>>, AsyncValue<List<String>>, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(FanboxDownloads)
final fanboxDownloadsProvider = FanboxDownloadsProvider._();

final class FanboxDownloadsProvider extends $NotifierProvider<FanboxDownloads, FanboxDownloadProgress> {
  FanboxDownloadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fanboxDownloadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fanboxDownloadsHash();

  @$internal
  @override
  FanboxDownloads create() => FanboxDownloads();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FanboxDownloadProgress value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<FanboxDownloadProgress>(value));
  }
}

String _$fanboxDownloadsHash() => r'39f80abcbac73a866be52068c17d2c7c573439fe';

abstract class _$FanboxDownloads extends $Notifier<FanboxDownloadProgress> {
  FanboxDownloadProgress build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FanboxDownloadProgress, FanboxDownloadProgress>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<FanboxDownloadProgress, FanboxDownloadProgress>, FanboxDownloadProgress, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
