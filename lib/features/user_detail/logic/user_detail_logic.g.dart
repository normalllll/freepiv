// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_detail_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserDetail)
final userDetailProvider = UserDetailFamily._();

final class UserDetailProvider
    extends $AsyncNotifierProvider<UserDetail, UserDetailResult> {
  UserDetailProvider._({
    required UserDetailFamily super.from,
    required UserDetailArgs super.argument,
  }) : super(
         retry: null,
         name: r'userDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userDetailHash();

  @override
  String toString() {
    return r'userDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserDetail create() => UserDetail();

  @override
  bool operator ==(Object other) {
    return other is UserDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userDetailHash() => r'e3123ee0814477f9beaaed5081f32befb0f175b8';

final class UserDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          UserDetail,
          AsyncValue<UserDetailResult>,
          UserDetailResult,
          FutureOr<UserDetailResult>,
          UserDetailArgs
        > {
  UserDetailFamily._()
    : super(
        retry: null,
        name: r'userDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserDetailProvider call(UserDetailArgs args) =>
      UserDetailProvider._(argument: args, from: this);

  @override
  String toString() => r'userDetailProvider';
}

abstract class _$UserDetail extends $AsyncNotifier<UserDetailResult> {
  late final _$args = ref.$arg as UserDetailArgs;
  UserDetailArgs get args => _$args;

  FutureOr<UserDetailResult> build(UserDetailArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<UserDetailResult>, UserDetailResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserDetailResult>, UserDetailResult>,
              AsyncValue<UserDetailResult>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(UserIllusts)
final userIllustsProvider = UserIllustsFamily._();

final class UserIllustsProvider
    extends $NotifierProvider<UserIllusts, UserIllustListSource> {
  UserIllustsProvider._({
    required UserIllustsFamily super.from,
    required ({int userId, IllustType illustType}) super.argument,
  }) : super(
         retry: null,
         name: r'userIllustsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userIllustsHash();

  @override
  String toString() {
    return r'userIllustsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  UserIllusts create() => UserIllusts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserIllustListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserIllustListSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserIllustsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userIllustsHash() => r'0201ee2e12ddb1c92b09fcda41d23ee07a343d16';

final class UserIllustsFamily extends $Family
    with
        $ClassFamilyOverride<
          UserIllusts,
          UserIllustListSource,
          UserIllustListSource,
          UserIllustListSource,
          ({int userId, IllustType illustType})
        > {
  UserIllustsFamily._()
    : super(
        retry: null,
        name: r'userIllustsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserIllustsProvider call({
    required int userId,
    required IllustType illustType,
  }) => UserIllustsProvider._(
    argument: (userId: userId, illustType: illustType),
    from: this,
  );

  @override
  String toString() => r'userIllustsProvider';
}

abstract class _$UserIllusts extends $Notifier<UserIllustListSource> {
  late final _$args = ref.$arg as ({int userId, IllustType illustType});
  int get userId => _$args.userId;
  IllustType get illustType => _$args.illustType;

  UserIllustListSource build({
    required int userId,
    required IllustType illustType,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UserIllustListSource, UserIllustListSource>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserIllustListSource, UserIllustListSource>,
              UserIllustListSource,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(userId: _$args.userId, illustType: _$args.illustType),
    );
  }
}

@ProviderFor(UserNovels)
final userNovelsProvider = UserNovelsFamily._();

final class UserNovelsProvider
    extends $NotifierProvider<UserNovels, UserNovelListSource> {
  UserNovelsProvider._({
    required UserNovelsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'userNovelsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userNovelsHash();

  @override
  String toString() {
    return r'userNovelsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserNovels create() => UserNovels();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserNovelListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserNovelListSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserNovelsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userNovelsHash() => r'9b46183e2b2fb504174c383eaa9f1fb9ab540b8a';

final class UserNovelsFamily extends $Family
    with
        $ClassFamilyOverride<
          UserNovels,
          UserNovelListSource,
          UserNovelListSource,
          UserNovelListSource,
          int
        > {
  UserNovelsFamily._()
    : super(
        retry: null,
        name: r'userNovelsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserNovelsProvider call({required int userId}) =>
      UserNovelsProvider._(argument: userId, from: this);

  @override
  String toString() => r'userNovelsProvider';
}

abstract class _$UserNovels extends $Notifier<UserNovelListSource> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  UserNovelListSource build({required int userId});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UserNovelListSource, UserNovelListSource>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserNovelListSource, UserNovelListSource>,
              UserNovelListSource,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(userId: _$args));
  }
}

@ProviderFor(UserIllustBookmarks)
final userIllustBookmarksProvider = UserIllustBookmarksFamily._();

final class UserIllustBookmarksProvider
    extends
        $NotifierProvider<UserIllustBookmarks, UserIllustBookmarkListSource> {
  UserIllustBookmarksProvider._({
    required UserIllustBookmarksFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'userIllustBookmarksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userIllustBookmarksHash();

  @override
  String toString() {
    return r'userIllustBookmarksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserIllustBookmarks create() => UserIllustBookmarks();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserIllustBookmarkListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserIllustBookmarkListSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserIllustBookmarksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userIllustBookmarksHash() =>
    r'90beb48e1f608291e7b4a03f7263ef0635153120';

final class UserIllustBookmarksFamily extends $Family
    with
        $ClassFamilyOverride<
          UserIllustBookmarks,
          UserIllustBookmarkListSource,
          UserIllustBookmarkListSource,
          UserIllustBookmarkListSource,
          int
        > {
  UserIllustBookmarksFamily._()
    : super(
        retry: null,
        name: r'userIllustBookmarksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserIllustBookmarksProvider call({required int userId}) =>
      UserIllustBookmarksProvider._(argument: userId, from: this);

  @override
  String toString() => r'userIllustBookmarksProvider';
}

abstract class _$UserIllustBookmarks
    extends $Notifier<UserIllustBookmarkListSource> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  UserIllustBookmarkListSource build({required int userId});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<UserIllustBookmarkListSource, UserIllustBookmarkListSource>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                UserIllustBookmarkListSource,
                UserIllustBookmarkListSource
              >,
              UserIllustBookmarkListSource,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(userId: _$args));
  }
}

@ProviderFor(UserNovelBookmarks)
final userNovelBookmarksProvider = UserNovelBookmarksFamily._();

final class UserNovelBookmarksProvider
    extends $NotifierProvider<UserNovelBookmarks, UserNovelBookmarkListSource> {
  UserNovelBookmarksProvider._({
    required UserNovelBookmarksFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'userNovelBookmarksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userNovelBookmarksHash();

  @override
  String toString() {
    return r'userNovelBookmarksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserNovelBookmarks create() => UserNovelBookmarks();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserNovelBookmarkListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserNovelBookmarkListSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserNovelBookmarksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userNovelBookmarksHash() =>
    r'2596187d59babf4477da98acbcd6374d44356cab';

final class UserNovelBookmarksFamily extends $Family
    with
        $ClassFamilyOverride<
          UserNovelBookmarks,
          UserNovelBookmarkListSource,
          UserNovelBookmarkListSource,
          UserNovelBookmarkListSource,
          int
        > {
  UserNovelBookmarksFamily._()
    : super(
        retry: null,
        name: r'userNovelBookmarksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserNovelBookmarksProvider call({required int userId}) =>
      UserNovelBookmarksProvider._(argument: userId, from: this);

  @override
  String toString() => r'userNovelBookmarksProvider';
}

abstract class _$UserNovelBookmarks
    extends $Notifier<UserNovelBookmarkListSource> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  UserNovelBookmarkListSource build({required int userId});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<UserNovelBookmarkListSource, UserNovelBookmarkListSource>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                UserNovelBookmarkListSource,
                UserNovelBookmarkListSource
              >,
              UserNovelBookmarkListSource,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(userId: _$args));
  }
}

@ProviderFor(UserFollowingUsers)
final userFollowingUsersProvider = UserFollowingUsersFamily._();

final class UserFollowingUsersProvider
    extends $NotifierProvider<UserFollowingUsers, UserFollowingListSource> {
  UserFollowingUsersProvider._({
    required UserFollowingUsersFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'userFollowingUsersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userFollowingUsersHash();

  @override
  String toString() {
    return r'userFollowingUsersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserFollowingUsers create() => UserFollowingUsers();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserFollowingListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserFollowingListSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserFollowingUsersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userFollowingUsersHash() =>
    r'478ea5648246c5d98b9825c4f072d3a018503f90';

final class UserFollowingUsersFamily extends $Family
    with
        $ClassFamilyOverride<
          UserFollowingUsers,
          UserFollowingListSource,
          UserFollowingListSource,
          UserFollowingListSource,
          int
        > {
  UserFollowingUsersFamily._()
    : super(
        retry: null,
        name: r'userFollowingUsersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserFollowingUsersProvider call({required int userId}) =>
      UserFollowingUsersProvider._(argument: userId, from: this);

  @override
  String toString() => r'userFollowingUsersProvider';
}

abstract class _$UserFollowingUsers extends $Notifier<UserFollowingListSource> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  UserFollowingListSource build({required int userId});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<UserFollowingListSource, UserFollowingListSource>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserFollowingListSource, UserFollowingListSource>,
              UserFollowingListSource,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(userId: _$args));
  }
}
