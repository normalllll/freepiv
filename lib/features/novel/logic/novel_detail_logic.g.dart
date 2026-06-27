// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel_detail_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NovelDetail)
final novelDetailProvider = NovelDetailFamily._();

final class NovelDetailProvider
    extends $AsyncNotifierProvider<NovelDetail, NovelDetailData> {
  NovelDetailProvider._({
    required NovelDetailFamily super.from,
    required NovelDetailArgs super.argument,
  }) : super(
         retry: noRetry,
         name: r'novelDetailProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$novelDetailHash();

  @override
  String toString() {
    return r'novelDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NovelDetail create() => NovelDetail();

  @override
  bool operator ==(Object other) {
    return other is NovelDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$novelDetailHash() => r'4144a9ffc23f27ea43c68fc1a5f01d41b749b9b0';

final class NovelDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          NovelDetail,
          AsyncValue<NovelDetailData>,
          NovelDetailData,
          FutureOr<NovelDetailData>,
          NovelDetailArgs
        > {
  NovelDetailFamily._()
    : super(
        retry: noRetry,
        name: r'novelDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  NovelDetailProvider call(NovelDetailArgs args) =>
      NovelDetailProvider._(argument: args, from: this);

  @override
  String toString() => r'novelDetailProvider';
}

abstract class _$NovelDetail extends $AsyncNotifier<NovelDetailData> {
  late final _$args = ref.$arg as NovelDetailArgs;
  NovelDetailArgs get args => _$args;

  FutureOr<NovelDetailData> build(NovelDetailArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<NovelDetailData>, NovelDetailData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NovelDetailData>, NovelDetailData>,
              AsyncValue<NovelDetailData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(NovelComments)
final novelCommentsProvider = NovelCommentsFamily._();

final class NovelCommentsProvider
    extends $AsyncNotifierProvider<NovelComments, CommentPageResult> {
  NovelCommentsProvider._({
    required NovelCommentsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'novelCommentsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$novelCommentsHash();

  @override
  String toString() {
    return r'novelCommentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NovelComments create() => NovelComments();

  @override
  bool operator ==(Object other) {
    return other is NovelCommentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$novelCommentsHash() => r'18cfc0549bd24ebb6669f9de71e46aa30eb76fe6';

final class NovelCommentsFamily extends $Family
    with
        $ClassFamilyOverride<
          NovelComments,
          AsyncValue<CommentPageResult>,
          CommentPageResult,
          FutureOr<CommentPageResult>,
          int
        > {
  NovelCommentsFamily._()
    : super(
        retry: null,
        name: r'novelCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  NovelCommentsProvider call(int novelId) =>
      NovelCommentsProvider._(argument: novelId, from: this);

  @override
  String toString() => r'novelCommentsProvider';
}

abstract class _$NovelComments extends $AsyncNotifier<CommentPageResult> {
  late final _$args = ref.$arg as int;
  int get novelId => _$args;

  FutureOr<CommentPageResult> build(int novelId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CommentPageResult>, CommentPageResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CommentPageResult>, CommentPageResult>,
              AsyncValue<CommentPageResult>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(NovelUserWorks)
final novelUserWorksProvider = NovelUserWorksFamily._();

final class NovelUserWorksProvider
    extends $AsyncNotifierProvider<NovelUserWorks, NovelPageResult> {
  NovelUserWorksProvider._({
    required NovelUserWorksFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'novelUserWorksProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$novelUserWorksHash();

  @override
  String toString() {
    return r'novelUserWorksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NovelUserWorks create() => NovelUserWorks();

  @override
  bool operator ==(Object other) {
    return other is NovelUserWorksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$novelUserWorksHash() => r'd244645c5f5aafd647f7a2f658e4feb20025884c';

final class NovelUserWorksFamily extends $Family
    with
        $ClassFamilyOverride<
          NovelUserWorks,
          AsyncValue<NovelPageResult>,
          NovelPageResult,
          FutureOr<NovelPageResult>,
          int
        > {
  NovelUserWorksFamily._()
    : super(
        retry: null,
        name: r'novelUserWorksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  NovelUserWorksProvider call(int userId) =>
      NovelUserWorksProvider._(argument: userId, from: this);

  @override
  String toString() => r'novelUserWorksProvider';
}

abstract class _$NovelUserWorks extends $AsyncNotifier<NovelPageResult> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  FutureOr<NovelPageResult> build(int userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<NovelPageResult>, NovelPageResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NovelPageResult>, NovelPageResult>,
              AsyncValue<NovelPageResult>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(NovelRelatedWorks)
final novelRelatedWorksProvider = NovelRelatedWorksFamily._();

final class NovelRelatedWorksProvider
    extends $NotifierProvider<NovelRelatedWorks, NovelRelatedListSource> {
  NovelRelatedWorksProvider._({
    required NovelRelatedWorksFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'novelRelatedWorksProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$novelRelatedWorksHash();

  @override
  String toString() {
    return r'novelRelatedWorksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NovelRelatedWorks create() => NovelRelatedWorks();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NovelRelatedListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NovelRelatedListSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NovelRelatedWorksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$novelRelatedWorksHash() => r'83610093c05646d53ea5897f25f54f1ed862a539';

final class NovelRelatedWorksFamily extends $Family
    with
        $ClassFamilyOverride<
          NovelRelatedWorks,
          NovelRelatedListSource,
          NovelRelatedListSource,
          NovelRelatedListSource,
          int
        > {
  NovelRelatedWorksFamily._()
    : super(
        retry: null,
        name: r'novelRelatedWorksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  NovelRelatedWorksProvider call(int novelId) =>
      NovelRelatedWorksProvider._(argument: novelId, from: this);

  @override
  String toString() => r'novelRelatedWorksProvider';
}

abstract class _$NovelRelatedWorks extends $Notifier<NovelRelatedListSource> {
  late final _$args = ref.$arg as int;
  int get novelId => _$args;

  NovelRelatedListSource build(int novelId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<NovelRelatedListSource, NovelRelatedListSource>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NovelRelatedListSource, NovelRelatedListSource>,
              NovelRelatedListSource,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
