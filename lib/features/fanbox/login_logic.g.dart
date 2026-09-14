// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FanboxWebLogin)
final fanboxWebLoginProvider = FanboxWebLoginProvider._();

final class FanboxWebLoginProvider extends $NotifierProvider<FanboxWebLogin, AsyncValue<FanboxLoginStage>> {
  FanboxWebLoginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fanboxWebLoginProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fanboxWebLoginHash();

  @$internal
  @override
  FanboxWebLogin create() => FanboxWebLogin();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<FanboxLoginStage> value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AsyncValue<FanboxLoginStage>>(value));
  }
}

String _$fanboxWebLoginHash() => r'f11d119ca7a4f0315b63403a6943370ee25d3314';

abstract class _$FanboxWebLogin extends $Notifier<AsyncValue<FanboxLoginStage>> {
  AsyncValue<FanboxLoginStage> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FanboxLoginStage>, AsyncValue<FanboxLoginStage>>;
    final element =
        ref.element
            as $ClassProviderElement<AnyNotifier<AsyncValue<FanboxLoginStage>, AsyncValue<FanboxLoginStage>>, AsyncValue<FanboxLoginStage>, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
