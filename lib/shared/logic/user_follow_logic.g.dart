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
         isAutoDispose: false,
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

String _$userFollowHash() => r'9217b7f3fb77a360fca5bfcd578c45e9a9c7fc3f';

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
        isAutoDispose: false,
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
