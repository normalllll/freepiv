// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transparency_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReduceTransparency)
final reduceTransparencyProvider = ReduceTransparencyProvider._();

final class ReduceTransparencyProvider
    extends $NotifierProvider<ReduceTransparency, bool> {
  ReduceTransparencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reduceTransparencyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reduceTransparencyHash();

  @$internal
  @override
  ReduceTransparency create() => ReduceTransparency();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$reduceTransparencyHash() =>
    r'23fcdf7dba4dc5b18d3634bc15f7ecc37ffdeaad';

abstract class _$ReduceTransparency extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
