// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Ranking)
final rankingProvider = RankingProvider._();

final class RankingProvider extends $NotifierProvider<Ranking, RankingState> {
  RankingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rankingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rankingHash();

  @$internal
  @override
  Ranking create() => Ranking();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RankingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RankingState>(value),
    );
  }
}

String _$rankingHash() => r'3407440fbc92846b835a564d3817de40e02af7a8';

abstract class _$Ranking extends $Notifier<RankingState> {
  RankingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RankingState, RankingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RankingState, RankingState>,
              RankingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
