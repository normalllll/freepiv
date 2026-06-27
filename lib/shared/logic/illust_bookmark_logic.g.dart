// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'illust_bookmark_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IllustBookmark)
final illustBookmarkProvider = IllustBookmarkFamily._();

final class IllustBookmarkProvider
    extends $NotifierProvider<IllustBookmark, IllustBookmarkState> {
  IllustBookmarkProvider._({
    required IllustBookmarkFamily super.from,
    required IllustBookmarkArgs super.argument,
  }) : super(
         retry: null,
         name: r'illustBookmarkProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$illustBookmarkHash();

  @override
  String toString() {
    return r'illustBookmarkProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  IllustBookmark create() => IllustBookmark();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IllustBookmarkState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IllustBookmarkState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IllustBookmarkProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$illustBookmarkHash() => r'7408379ee47059b4eb8cfab04cda31dc3ed21b5e';

final class IllustBookmarkFamily extends $Family
    with
        $ClassFamilyOverride<
          IllustBookmark,
          IllustBookmarkState,
          IllustBookmarkState,
          IllustBookmarkState,
          IllustBookmarkArgs
        > {
  IllustBookmarkFamily._()
    : super(
        retry: null,
        name: r'illustBookmarkProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  IllustBookmarkProvider call(IllustBookmarkArgs args) =>
      IllustBookmarkProvider._(argument: args, from: this);

  @override
  String toString() => r'illustBookmarkProvider';
}

abstract class _$IllustBookmark extends $Notifier<IllustBookmarkState> {
  late final _$args = ref.$arg as IllustBookmarkArgs;
  IllustBookmarkArgs get args => _$args;

  IllustBookmarkState build(IllustBookmarkArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<IllustBookmarkState, IllustBookmarkState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IllustBookmarkState, IllustBookmarkState>,
              IllustBookmarkState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
