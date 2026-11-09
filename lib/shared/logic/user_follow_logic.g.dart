// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_follow_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserFollow)
final userFollowProvider = UserFollowFamily._();

final class UserFollowProvider
    extends $NotifierProvider<UserFollow, UserFollowEntry> {
  UserFollowProvider._({
    required UserFollowFamily super.from,
    required UserFollowArgs super.argument,
  }) : super(
         retry: null,
         name: r'userFollowProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userFollowHash();

  @override
  String toString() {
    return r'userFollowProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserFollow create() => UserFollow();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserFollowEntry value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserFollowEntry>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserFollowProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userFollowHash() => r'9ceee8e2155d7909e57af7746316d8f3d462135b';

final class UserFollowFamily extends $Family
    with
        $ClassFamilyOverride<
          UserFollow,
          UserFollowEntry,
          UserFollowEntry,
          UserFollowEntry,
          UserFollowArgs
        > {
  UserFollowFamily._()
    : super(
        retry: null,
        name: r'userFollowProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserFollowProvider call(UserFollowArgs args) =>
      UserFollowProvider._(argument: args, from: this);

  @override
  String toString() => r'userFollowProvider';
}

abstract class _$UserFollow extends $Notifier<UserFollowEntry> {
  late final _$args = ref.$arg as UserFollowArgs;
  UserFollowArgs get args => _$args;

  UserFollowEntry build(UserFollowArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UserFollowEntry, UserFollowEntry>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserFollowEntry, UserFollowEntry>,
              UserFollowEntry,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// How the account follows the user: public or private. Null until followed.

@ProviderFor(userFollowRestrict)
final userFollowRestrictProvider = UserFollowRestrictFamily._();

/// How the account follows the user: public or private. Null until followed.

final class UserFollowRestrictProvider
    extends
        $FunctionalProvider<
          AsyncValue<Restrict?>,
          Restrict?,
          FutureOr<Restrict?>
        >
    with $FutureModifier<Restrict?>, $FutureProvider<Restrict?> {
  /// How the account follows the user: public or private. Null until followed.
  UserFollowRestrictProvider._({
    required UserFollowRestrictFamily super.from,
    required UserFollowArgs super.argument,
  }) : super(
         retry: null,
         name: r'userFollowRestrictProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userFollowRestrictHash();

  @override
  String toString() {
    return r'userFollowRestrictProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Restrict?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Restrict?> create(Ref ref) {
    final argument = this.argument as UserFollowArgs;
    return userFollowRestrict(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserFollowRestrictProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userFollowRestrictHash() =>
    r'7a544a5378d831b039d09c8ce64a18483df93075';

/// How the account follows the user: public or private. Null until followed.

final class UserFollowRestrictFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Restrict?>, UserFollowArgs> {
  UserFollowRestrictFamily._()
    : super(
        retry: null,
        name: r'userFollowRestrictProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How the account follows the user: public or private. Null until followed.

  UserFollowRestrictProvider call(UserFollowArgs args) =>
      UserFollowRestrictProvider._(argument: args, from: this);

  @override
  String toString() => r'userFollowRestrictProvider';
}
