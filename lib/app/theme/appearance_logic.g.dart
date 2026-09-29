// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appearance_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Appearance)
final appearanceProvider = AppearanceProvider._();

final class AppearanceProvider
    extends $NotifierProvider<Appearance, AppearanceState> {
  AppearanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appearanceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appearanceHash();

  @$internal
  @override
  Appearance create() => Appearance();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppearanceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppearanceState>(value),
    );
  }
}

String _$appearanceHash() => r'045e29f1a28ce8bc4a9403b4e8b2eb2c699acb95';

abstract class _$Appearance extends $Notifier<AppearanceState> {
  AppearanceState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppearanceState, AppearanceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppearanceState, AppearanceState>,
              AppearanceState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
