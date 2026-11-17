import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/rust_media_source.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;

RustMediaSource _source(String name, Stream<rust.MediaChunk> Function() stream) => RustMediaSource(
  MediaRequest(url: 'https://fixtures.example.test/$name.jpg', allowDiskCache: false),
  stream: (_, _) => stream(),
  streamIdentity: 'fixture',
);

/// Resolves [image] until it fails, and returns how it failed.
Future<Object> _failure(ImageProvider image) {
  final failed = Completer<Object>();
  final stream = image.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) => info.dispose(),
    onError: (error, _) {
      stream.removeListener(listener);
      failed.complete(error);
    },
  );
  stream.addListener(listener);
  return failed.future;
}

void main() {
  tearDown(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  testWidgets('a picture the server refuses fails after one attempt, while a network failure is tried again', (tester) async {
    await tester.runAsync(() async {
      for (final refused in ['Media HTTP 404', 'Media HTTP 403', 'Invalid media URL']) {
        var attempts = 0;
        final source = _source('refused-$refused', () {
          attempts++;
          return Stream.error(AnyhowException(refused));
        });
        expect(source.shouldRetry(AnyhowException(refused)), isFalse, reason: refused);
        await _failure(CachedMediaImage(source, retryDelay: (_) => Duration.zero));
        expect(attempts, 1, reason: refused);
      }

      for (final transient in ['Media request failed', 'Media stream interrupted', 'Media HTTP 503']) {
        var attempts = 0;
        final source = _source('transient-$transient', () {
          attempts++;
          return Stream.error(AnyhowException(transient));
        });
        await _failure(CachedMediaImage(source, retryDelay: (_) => Duration.zero));
        expect(attempts, 3, reason: transient);
      }
      expect(_source('timeout', Stream.empty).shouldRetry(TimeoutException('slow')), isTrue);
    });
  });

  testWidgets('twelve downloads run at once through the package, with no limit of the app on top', (tester) async {
    await tester.runAsync(() async {
      final open = <StreamController<rust.MediaChunk>>[];
      final streams = <ImageStream>[];
      final listener = ImageStreamListener((info, _) => info.dispose(), onError: (_, _) {});
      for (var i = 0; i < 20; i++) {
        final image = CachedMediaImage(
          _source('waiting-$i', () {
            final controller = StreamController<rust.MediaChunk>();
            open.add(controller);
            return controller.stream;
          }),
        );
        streams.add(image.resolve(ImageConfiguration.empty)..addListener(listener));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(open, hasLength(MediaDownloadSlots.shared.limit));
      expect(open, hasLength(12));
      for (final stream in streams) {
        stream.removeListener(listener);
      }
    });
  });
}
