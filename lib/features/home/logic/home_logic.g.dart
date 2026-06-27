// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeIllustSource)
final homeIllustSourceProvider = HomeIllustSourceProvider._();

final class HomeIllustSourceProvider
    extends
        $FunctionalProvider<
          HomeIllustListSource,
          HomeIllustListSource,
          HomeIllustListSource
        >
    with $Provider<HomeIllustListSource> {
  HomeIllustSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeIllustSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeIllustSourceHash();

  @$internal
  @override
  $ProviderElement<HomeIllustListSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomeIllustListSource create(Ref ref) {
    return homeIllustSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeIllustListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeIllustListSource>(value),
    );
  }
}

String _$homeIllustSourceHash() => r'fb3217f4099309e7c18b904eb82add14149b9541';

@ProviderFor(homeMangaSource)
final homeMangaSourceProvider = HomeMangaSourceProvider._();

final class HomeMangaSourceProvider
    extends
        $FunctionalProvider<
          HomeIllustListSource,
          HomeIllustListSource,
          HomeIllustListSource
        >
    with $Provider<HomeIllustListSource> {
  HomeMangaSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeMangaSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeMangaSourceHash();

  @$internal
  @override
  $ProviderElement<HomeIllustListSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomeIllustListSource create(Ref ref) {
    return homeMangaSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeIllustListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeIllustListSource>(value),
    );
  }
}

String _$homeMangaSourceHash() => r'01f945050bbabd1e3e43150a6d2bcc23ccf4d8be';

@ProviderFor(homeNovelSource)
final homeNovelSourceProvider = HomeNovelSourceProvider._();

final class HomeNovelSourceProvider
    extends
        $FunctionalProvider<
          HomeNovelListSource,
          HomeNovelListSource,
          HomeNovelListSource
        >
    with $Provider<HomeNovelListSource> {
  HomeNovelSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeNovelSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeNovelSourceHash();

  @$internal
  @override
  $ProviderElement<HomeNovelListSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomeNovelListSource create(Ref ref) {
    return homeNovelSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeNovelListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeNovelListSource>(value),
    );
  }
}

String _$homeNovelSourceHash() => r'ec260a93a443f0ec43cbb29b6a84a3efafe7bbce';

@ProviderFor(homeUserSource)
final homeUserSourceProvider = HomeUserSourceProvider._();

final class HomeUserSourceProvider
    extends
        $FunctionalProvider<
          HomeUserListSource,
          HomeUserListSource,
          HomeUserListSource
        >
    with $Provider<HomeUserListSource> {
  HomeUserSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeUserSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeUserSourceHash();

  @$internal
  @override
  $ProviderElement<HomeUserListSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomeUserListSource create(Ref ref) {
    return homeUserSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeUserListSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeUserListSource>(value),
    );
  }
}

String _$homeUserSourceHash() => r'8b486f65f8c6f7e2a29a9a47a7c1390247bd2436';

@ProviderFor(Home)
final homeProvider = HomeProvider._();

final class HomeProvider extends $NotifierProvider<Home, HomeType> {
  HomeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeHash();

  @$internal
  @override
  Home create() => Home();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeType>(value),
    );
  }
}

String _$homeHash() => r'e35c637113df26ac689e7663536e23185b7d5947';

abstract class _$Home extends $Notifier<HomeType> {
  HomeType build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HomeType, HomeType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HomeType, HomeType>,
              HomeType,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
