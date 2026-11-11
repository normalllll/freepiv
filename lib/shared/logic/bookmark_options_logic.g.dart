// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_options_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read each time the options open, so they show what Pixiv holds.

@ProviderFor(workBookmarkOptions)
final workBookmarkOptionsProvider = WorkBookmarkOptionsFamily._();

/// Read each time the options open, so they show what Pixiv holds.

final class WorkBookmarkOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkBookmarkOptions>,
          WorkBookmarkOptions,
          FutureOr<WorkBookmarkOptions>
        >
    with
        $FutureModifier<WorkBookmarkOptions>,
        $FutureProvider<WorkBookmarkOptions> {
  /// Read each time the options open, so they show what Pixiv holds.
  WorkBookmarkOptionsProvider._({
    required WorkBookmarkOptionsFamily super.from,
    required WorkBookmarkKey super.argument,
  }) : super(
         retry: null,
         name: r'workBookmarkOptionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workBookmarkOptionsHash();

  @override
  String toString() {
    return r'workBookmarkOptionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkBookmarkOptions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkBookmarkOptions> create(Ref ref) {
    final argument = this.argument as WorkBookmarkKey;
    return workBookmarkOptions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkBookmarkOptionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workBookmarkOptionsHash() =>
    r'4f2392d9c30f21199b63a56c7bcedc30dd99e5eb';

/// Read each time the options open, so they show what Pixiv holds.

final class WorkBookmarkOptionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkBookmarkOptions>,
          WorkBookmarkKey
        > {
  WorkBookmarkOptionsFamily._()
    : super(
        retry: null,
        name: r'workBookmarkOptionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Read each time the options open, so they show what Pixiv holds.

  WorkBookmarkOptionsProvider call(WorkBookmarkKey key) =>
      WorkBookmarkOptionsProvider._(argument: key, from: this);

  @override
  String toString() => r'workBookmarkOptionsProvider';
}
