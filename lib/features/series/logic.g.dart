// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NovelSeriesWorks)
final novelSeriesWorksProvider = NovelSeriesWorksFamily._();

final class NovelSeriesWorksProvider extends $NotifierProvider<NovelSeriesWorks, NovelSeriesSource> {
  NovelSeriesWorksProvider._({required NovelSeriesWorksFamily super.from, required int super.argument})
    : super(retry: null, name: r'novelSeriesWorksProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$novelSeriesWorksHash();

  @override
  String toString() {
    return r'novelSeriesWorksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NovelSeriesWorks create() => NovelSeriesWorks();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NovelSeriesSource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<NovelSeriesSource>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is NovelSeriesWorksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$novelSeriesWorksHash() => r'39abd0b06cb8d3ad8cf70f6d424b8b0e60ad2c85';

final class NovelSeriesWorksFamily extends $Family with $ClassFamilyOverride<NovelSeriesWorks, NovelSeriesSource, NovelSeriesSource, NovelSeriesSource, int> {
  NovelSeriesWorksFamily._() : super(retry: null, name: r'novelSeriesWorksProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  NovelSeriesWorksProvider call(int seriesId) => NovelSeriesWorksProvider._(argument: seriesId, from: this);

  @override
  String toString() => r'novelSeriesWorksProvider';
}

abstract class _$NovelSeriesWorks extends $Notifier<NovelSeriesSource> {
  late final _$args = ref.$arg as int;
  int get seriesId => _$args;

  NovelSeriesSource build(int seriesId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NovelSeriesSource, NovelSeriesSource>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<NovelSeriesSource, NovelSeriesSource>, NovelSeriesSource, Object?, Object?>;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(MangaSeriesWorks)
final mangaSeriesWorksProvider = MangaSeriesWorksFamily._();

final class MangaSeriesWorksProvider extends $NotifierProvider<MangaSeriesWorks, MangaSeriesSource> {
  MangaSeriesWorksProvider._({required MangaSeriesWorksFamily super.from, required int super.argument})
    : super(retry: null, name: r'mangaSeriesWorksProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$mangaSeriesWorksHash();

  @override
  String toString() {
    return r'mangaSeriesWorksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MangaSeriesWorks create() => MangaSeriesWorks();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MangaSeriesSource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<MangaSeriesSource>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is MangaSeriesWorksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mangaSeriesWorksHash() => r'51a9f442adef4545a0b470f026bcb930035d55fb';

final class MangaSeriesWorksFamily extends $Family with $ClassFamilyOverride<MangaSeriesWorks, MangaSeriesSource, MangaSeriesSource, MangaSeriesSource, int> {
  MangaSeriesWorksFamily._() : super(retry: null, name: r'mangaSeriesWorksProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  MangaSeriesWorksProvider call(int seriesId) => MangaSeriesWorksProvider._(argument: seriesId, from: this);

  @override
  String toString() => r'mangaSeriesWorksProvider';
}

abstract class _$MangaSeriesWorks extends $Notifier<MangaSeriesSource> {
  late final _$args = ref.$arg as int;
  int get seriesId => _$args;

  MangaSeriesSource build(int seriesId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MangaSeriesSource, MangaSeriesSource>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<MangaSeriesSource, MangaSeriesSource>, MangaSeriesSource, Object?, Object?>;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(WatchlistEntries)
final watchlistEntriesProvider = WatchlistEntriesFamily._();

final class WatchlistEntriesProvider extends $NotifierProvider<WatchlistEntries, WatchlistSource> {
  WatchlistEntriesProvider._({required WatchlistEntriesFamily super.from, required AppSeriesKind super.argument})
    : super(retry: null, name: r'watchlistEntriesProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$watchlistEntriesHash();

  @override
  String toString() {
    return r'watchlistEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WatchlistEntries create() => WatchlistEntries();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchlistSource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<WatchlistSource>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is WatchlistEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchlistEntriesHash() => r'4a5ddaaf22d273d664112388f52020881ef4f1c1';

final class WatchlistEntriesFamily extends $Family
    with $ClassFamilyOverride<WatchlistEntries, WatchlistSource, WatchlistSource, WatchlistSource, AppSeriesKind> {
  WatchlistEntriesFamily._() : super(retry: null, name: r'watchlistEntriesProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  WatchlistEntriesProvider call(AppSeriesKind kind) => WatchlistEntriesProvider._(argument: kind, from: this);

  @override
  String toString() => r'watchlistEntriesProvider';
}

abstract class _$WatchlistEntries extends $Notifier<WatchlistSource> {
  late final _$args = ref.$arg as AppSeriesKind;
  AppSeriesKind get kind => _$args;

  WatchlistSource build(AppSeriesKind kind);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WatchlistSource, WatchlistSource>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<WatchlistSource, WatchlistSource>, WatchlistSource, Object?, Object?>;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(SeriesWatch)
final seriesWatchProvider = SeriesWatchFamily._();

final class SeriesWatchProvider extends $NotifierProvider<SeriesWatch, SeriesWatchState> {
  SeriesWatchProvider._({required SeriesWatchFamily super.from, required SeriesWatchArgs super.argument})
    : super(retry: null, name: r'seriesWatchProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

  @override
  String debugGetCreateSourceHash() => _$seriesWatchHash();

  @override
  String toString() {
    return r'seriesWatchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SeriesWatch create() => SeriesWatch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeriesWatchState value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<SeriesWatchState>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is SeriesWatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seriesWatchHash() => r'ded2d570fdbd834dfc576abb230d1cf9e526f3b9';

final class SeriesWatchFamily extends $Family with $ClassFamilyOverride<SeriesWatch, SeriesWatchState, SeriesWatchState, SeriesWatchState, SeriesWatchArgs> {
  SeriesWatchFamily._() : super(retry: null, name: r'seriesWatchProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  SeriesWatchProvider call(SeriesWatchArgs args) => SeriesWatchProvider._(argument: args, from: this);

  @override
  String toString() => r'seriesWatchProvider';
}

abstract class _$SeriesWatch extends $Notifier<SeriesWatchState> {
  late final _$args = ref.$arg as SeriesWatchArgs;
  SeriesWatchArgs get args => _$args;

  SeriesWatchState build(SeriesWatchArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SeriesWatchState, SeriesWatchState>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<SeriesWatchState, SeriesWatchState>, SeriesWatchState, Object?, Object?>;
    return element.handleCreate(ref, () => build(_$args));
  }
}
