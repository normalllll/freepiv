// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_edit_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The account's details as Pixiv holds them now. Both edit forms replace
/// everything they cover, so they never start from a kept copy.

@ProviderFor(editableUserDetail)
final editableUserDetailProvider = EditableUserDetailFamily._();

/// The account's details as Pixiv holds them now. Both edit forms replace
/// everything they cover, so they never start from a kept copy.

final class EditableUserDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserDetailResult>,
          UserDetailResult,
          FutureOr<UserDetailResult>
        >
    with $FutureModifier<UserDetailResult>, $FutureProvider<UserDetailResult> {
  /// The account's details as Pixiv holds them now. Both edit forms replace
  /// everything they cover, so they never start from a kept copy.
  EditableUserDetailProvider._({
    required EditableUserDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'editableUserDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$editableUserDetailHash();

  @override
  String toString() {
    return r'editableUserDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserDetailResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserDetailResult> create(Ref ref) {
    final argument = this.argument as int;
    return editableUserDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EditableUserDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$editableUserDetailHash() =>
    r'a37b431d031c4c44b28e6e8079ae921e50f52e96';

/// The account's details as Pixiv holds them now. Both edit forms replace
/// everything they cover, so they never start from a kept copy.

final class EditableUserDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserDetailResult>, int> {
  EditableUserDetailFamily._()
    : super(
        retry: null,
        name: r'editableUserDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The account's details as Pixiv holds them now. Both edit forms replace
  /// everything they cover, so they never start from a kept copy.

  EditableUserDetailProvider call(int userId) =>
      EditableUserDetailProvider._(argument: userId, from: this);

  @override
  String toString() => r'editableUserDetailProvider';
}

@ProviderFor(profilePresets)
final profilePresetsProvider = ProfilePresetsProvider._();

final class ProfilePresetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProfilePresets>,
          ProfilePresets,
          FutureOr<ProfilePresets>
        >
    with $FutureModifier<ProfilePresets>, $FutureProvider<ProfilePresets> {
  ProfilePresetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profilePresetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profilePresetsHash();

  @$internal
  @override
  $FutureProviderElement<ProfilePresets> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProfilePresets> create(Ref ref) {
    return profilePresets(ref);
  }
}

String _$profilePresetsHash() => r'255235e88b909889a3b6cb4543c8dc7f947146e4';

/// Whether Pixiv shows the account AI-generated works.

@ProviderFor(AiShowSetting)
final aiShowSettingProvider = AiShowSettingFamily._();

/// Whether Pixiv shows the account AI-generated works.
final class AiShowSettingProvider
    extends $AsyncNotifierProvider<AiShowSetting, bool> {
  /// Whether Pixiv shows the account AI-generated works.
  AiShowSettingProvider._({
    required AiShowSettingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'aiShowSettingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$aiShowSettingHash();

  @override
  String toString() {
    return r'aiShowSettingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AiShowSetting create() => AiShowSetting();

  @override
  bool operator ==(Object other) {
    return other is AiShowSettingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$aiShowSettingHash() => r'1f0513a428cbe0946c214e85f0760aa38a8a929c';

/// Whether Pixiv shows the account AI-generated works.

final class AiShowSettingFamily extends $Family
    with
        $ClassFamilyOverride<
          AiShowSetting,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          String
        > {
  AiShowSettingFamily._()
    : super(
        retry: null,
        name: r'aiShowSettingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether Pixiv shows the account AI-generated works.

  AiShowSettingProvider call(String accountId) =>
      AiShowSettingProvider._(argument: accountId, from: this);

  @override
  String toString() => r'aiShowSettingProvider';
}

/// Whether Pixiv shows the account AI-generated works.

abstract class _$AiShowSetting extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as String;
  String get accountId => _$args;

  FutureOr<bool> build(String accountId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
