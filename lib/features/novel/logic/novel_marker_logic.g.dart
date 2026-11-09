// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel_marker_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The novel's reading bookmark on Pixiv. Kept once read: the text the reader
/// opens with is not fetched again after the bookmark changes.

@ProviderFor(NovelMarker)
final novelMarkerProvider = NovelMarkerFamily._();

/// The novel's reading bookmark on Pixiv. Kept once read: the text the reader
/// opens with is not fetched again after the bookmark changes.
final class NovelMarkerProvider
    extends $NotifierProvider<NovelMarker, NovelMarkerState> {
  /// The novel's reading bookmark on Pixiv. Kept once read: the text the reader
  /// opens with is not fetched again after the bookmark changes.
  NovelMarkerProvider._({
    required NovelMarkerFamily super.from,
    required NovelMarkerArgs super.argument,
  }) : super(
         retry: null,
         name: r'novelMarkerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$novelMarkerHash();

  @override
  String toString() {
    return r'novelMarkerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NovelMarker create() => NovelMarker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NovelMarkerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NovelMarkerState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NovelMarkerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$novelMarkerHash() => r'eb5c631f7026f6907cdac6d792db68633c08dfac';

/// The novel's reading bookmark on Pixiv. Kept once read: the text the reader
/// opens with is not fetched again after the bookmark changes.

final class NovelMarkerFamily extends $Family
    with
        $ClassFamilyOverride<
          NovelMarker,
          NovelMarkerState,
          NovelMarkerState,
          NovelMarkerState,
          NovelMarkerArgs
        > {
  NovelMarkerFamily._()
    : super(
        retry: null,
        name: r'novelMarkerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The novel's reading bookmark on Pixiv. Kept once read: the text the reader
  /// opens with is not fetched again after the bookmark changes.

  NovelMarkerProvider call(NovelMarkerArgs args) =>
      NovelMarkerProvider._(argument: args, from: this);

  @override
  String toString() => r'novelMarkerProvider';
}

/// The novel's reading bookmark on Pixiv. Kept once read: the text the reader
/// opens with is not fetched again after the bookmark changes.

abstract class _$NovelMarker extends $Notifier<NovelMarkerState> {
  late final _$args = ref.$arg as NovelMarkerArgs;
  NovelMarkerArgs get args => _$args;

  NovelMarkerState build(NovelMarkerArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NovelMarkerState, NovelMarkerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NovelMarkerState, NovelMarkerState>,
              NovelMarkerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
