// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'newest_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Newest)
final newestProvider = NewestProvider._();

final class NewestProvider extends $NotifierProvider<Newest, NewestState> {
  NewestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newestHash();

  @$internal
  @override
  Newest create() => Newest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewestState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewestState>(value),
    );
  }
}

String _$newestHash() => r'345dacdd0a33608558c6492ee5aee4436f02b48f';

abstract class _$Newest extends $Notifier<NewestState> {
  NewestState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NewestState, NewestState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NewestState, NewestState>,
              NewestState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
