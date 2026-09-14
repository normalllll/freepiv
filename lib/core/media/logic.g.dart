// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rustMediaTransport)
final rustMediaTransportProvider = RustMediaTransportProvider._();

final class RustMediaTransportProvider extends $FunctionalProvider<RustMediaTransport, RustMediaTransport, RustMediaTransport>
    with $Provider<RustMediaTransport> {
  RustMediaTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rustMediaTransportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rustMediaTransportHash();

  @$internal
  @override
  $ProviderElement<RustMediaTransport> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  RustMediaTransport create(Ref ref) {
    return rustMediaTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RustMediaTransport value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<RustMediaTransport>(value));
  }
}

String _$rustMediaTransportHash() => r'47cf39f1714ae44c64d727492637cea477880d77';
