import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

@riverpod
RustMediaTransport rustMediaTransport(Ref ref) => RustMediaTransport(ref.watch(proxySettingsProvider).activeUrl);

class RustMediaTransport {
  const RustMediaTransport(this._proxy);
  final String? _proxy;

  // A remounted image widget must resolve to the same memory-cache entry when
  // the transport configuration is unchanged. Instance method tear-offs are
  // tied to this transport object's lifetime, which is shorter than a route.
  Object get imageCacheIdentity => (proxy: _proxy);

  /// The download of [url]. Cancelling the stream stops the Rust request at
  /// once, even before its response arrives, which frees its connection.
  Stream<rust.MediaChunk> stream(String url, Map<String, String> headers) {
    final cancel = rust.MediaCancel();
    return stopOnCancel(
      rust.streamMedia(url: url, proxy: _proxy, headers: headers, cancel: cancel),
      stop: cancel.cancel,
      release: cancel.dispose,
    );
  }
}

/// [source], calling [stop] when a listener cancels it before it ends, and
/// [release] once it has ended or been stopped.
@visibleForTesting
Stream<T> stopOnCancel<T>(Stream<T> source, {required void Function() stop, required void Function() release}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  var over = false;
  void end() {
    if (over) return;
    over = true;
    release();
  }

  controller = StreamController<T>(
    onListen: () {
      subscription = source.listen(
        controller.add,
        // The Rust download reports an error only as it ends.
        onError: (Object error, StackTrace stack) {
          end();
          controller.addError(error, stack);
        },
        onDone: () {
          end();
          unawaited(controller.close());
        },
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () {
      if (!over) stop();
      end();
      return subscription?.cancel();
    },
  );
  return controller.stream;
}
