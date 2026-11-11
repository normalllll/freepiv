// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'illust_detail_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IllustDetail)
final illustDetailProvider = IllustDetailFamily._();

final class IllustDetailProvider
    extends $AsyncNotifierProvider<IllustDetail, Illust> {
  IllustDetailProvider._({
    required IllustDetailFamily super.from,
    required IllustDetailArgs super.argument,
  }) : super(
         retry: null,
         name: r'illustDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$illustDetailHash();

  @override
  String toString() {
    return r'illustDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  IllustDetail create() => IllustDetail();

  @override
  bool operator ==(Object other) {
    return other is IllustDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$illustDetailHash() => r'7c60466255bd8796502e0696a80626592516403c';

final class IllustDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          IllustDetail,
          AsyncValue<Illust>,
          Illust,
          FutureOr<Illust>,
          IllustDetailArgs
        > {
  IllustDetailFamily._()
    : super(
        retry: null,
        name: r'illustDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IllustDetailProvider call(IllustDetailArgs args) =>
      IllustDetailProvider._(argument: args, from: this);

  @override
  String toString() => r'illustDetailProvider';
}

abstract class _$IllustDetail extends $AsyncNotifier<Illust> {
  late final _$args = ref.$arg as IllustDetailArgs;
  IllustDetailArgs get args => _$args;

  FutureOr<Illust> build(IllustDetailArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Illust>, Illust>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Illust>, Illust>,
              AsyncValue<Illust>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// How many comments a work has. List responses leave the count out, so a
/// work handed over by a list asks for it here, while its page is open.

@ProviderFor(illustCommentTotal)
final illustCommentTotalProvider = IllustCommentTotalFamily._();

/// How many comments a work has. List responses leave the count out, so a
/// work handed over by a list asks for it here, while its page is open.

final class IllustCommentTotalProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  /// How many comments a work has. List responses leave the count out, so a
  /// work handed over by a list asks for it here, while its page is open.
  IllustCommentTotalProvider._({
    required IllustCommentTotalFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'illustCommentTotalProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$illustCommentTotalHash();

  @override
  String toString() {
    return r'illustCommentTotalProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    final argument = this.argument as int;
    return illustCommentTotal(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IllustCommentTotalProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$illustCommentTotalHash() =>
    r'b0c905fb63b3d2119bd8762405c013ee863e7a33';

/// How many comments a work has. List responses leave the count out, so a
/// work handed over by a list asks for it here, while its page is open.

final class IllustCommentTotalFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int?>, int> {
  IllustCommentTotalFamily._()
    : super(
        retry: null,
        name: r'illustCommentTotalProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How many comments a work has. List responses leave the count out, so a
  /// work handed over by a list asks for it here, while its page is open.

  IllustCommentTotalProvider call(int illustId) =>
      IllustCommentTotalProvider._(argument: illustId, from: this);

  @override
  String toString() => r'illustCommentTotalProvider';
}

@ProviderFor(IllustComments)
final illustCommentsProvider = IllustCommentsFamily._();

final class IllustCommentsProvider
    extends $AsyncNotifierProvider<IllustComments, CommentPageResult> {
  IllustCommentsProvider._({
    required IllustCommentsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'illustCommentsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$illustCommentsHash();

  @override
  String toString() {
    return r'illustCommentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  IllustComments create() => IllustComments();

  @override
  bool operator ==(Object other) {
    return other is IllustCommentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$illustCommentsHash() => r'7a8d3c265702107b44c26cd3f36aed41de8787f1';

final class IllustCommentsFamily extends $Family
    with
        $ClassFamilyOverride<
          IllustComments,
          AsyncValue<CommentPageResult>,
          CommentPageResult,
          FutureOr<CommentPageResult>,
          int
        > {
  IllustCommentsFamily._()
    : super(
        retry: null,
        name: r'illustCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  IllustCommentsProvider call(int illustId) =>
      IllustCommentsProvider._(argument: illustId, from: this);

  @override
  String toString() => r'illustCommentsProvider';
}

abstract class _$IllustComments extends $AsyncNotifier<CommentPageResult> {
  late final _$args = ref.$arg as int;
  int get illustId => _$args;

  FutureOr<CommentPageResult> build(int illustId);
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

@ProviderFor(IllustUserWorks)
final illustUserWorksProvider = IllustUserWorksFamily._();

final class IllustUserWorksProvider
    extends $AsyncNotifierProvider<IllustUserWorks, IllustPageResult> {
  IllustUserWorksProvider._({
    required IllustUserWorksFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'illustUserWorksProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$illustUserWorksHash();

  @override
  String toString() {
    return r'illustUserWorksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  IllustUserWorks create() => IllustUserWorks();

  @override
  bool operator ==(Object other) {
    return other is IllustUserWorksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$illustUserWorksHash() => r'd7e7bbdc6a4c3dd35169f467fbe12920fdab60f7';

final class IllustUserWorksFamily extends $Family
    with
        $ClassFamilyOverride<
          IllustUserWorks,
          AsyncValue<IllustPageResult>,
          IllustPageResult,
          FutureOr<IllustPageResult>,
          int
        > {
  IllustUserWorksFamily._()
    : super(
        retry: null,
        name: r'illustUserWorksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  IllustUserWorksProvider call(int userId) =>
      IllustUserWorksProvider._(argument: userId, from: this);

  @override
  String toString() => r'illustUserWorksProvider';
}

abstract class _$IllustUserWorks extends $AsyncNotifier<IllustPageResult> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  FutureOr<IllustPageResult> build(int userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<IllustPageResult>, IllustPageResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<IllustPageResult>, IllustPageResult>,
              AsyncValue<IllustPageResult>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(IllustRelatedWorks)
final illustRelatedWorksProvider = IllustRelatedWorksFamily._();

final class IllustRelatedWorksProvider
    extends $NotifierProvider<IllustRelatedWorks, IllustRelatedListSource> {
  IllustRelatedWorksProvider._({
    required IllustRelatedWorksFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'illustRelatedWorksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$illustRelatedWorksHash();

  @override
  String toString() {
    return r'illustRelatedWorksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  IllustRelatedWorks create() => IllustRelatedWorks();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IllustRelatedListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IllustRelatedListSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IllustRelatedWorksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$illustRelatedWorksHash() =>
    r'86d8f3962ec21325d70b237cfe623eed8bac0321';

final class IllustRelatedWorksFamily extends $Family
    with
        $ClassFamilyOverride<
          IllustRelatedWorks,
          IllustRelatedListSource,
          IllustRelatedListSource,
          IllustRelatedListSource,
          int
        > {
  IllustRelatedWorksFamily._()
    : super(
        retry: null,
        name: r'illustRelatedWorksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IllustRelatedWorksProvider call(int illustId) =>
      IllustRelatedWorksProvider._(argument: illustId, from: this);

  @override
  String toString() => r'illustRelatedWorksProvider';
}

abstract class _$IllustRelatedWorks extends $Notifier<IllustRelatedListSource> {
  late final _$args = ref.$arg as int;
  int get illustId => _$args;

  IllustRelatedListSource build(int illustId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<IllustRelatedListSource, IllustRelatedListSource>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IllustRelatedListSource, IllustRelatedListSource>,
              IllustRelatedListSource,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
