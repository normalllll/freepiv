import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/rust_media_source.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;

void main() {
  testWidgets('media stream failure reaches the image error UI after bounded retries', (tester) async {
    var attempts = 0;
    Object? displayedError;
    final provider = CachedMediaImage(
      RustMediaSource(
        MediaRequest(url: 'https://fixtures.example.test/failed.png', allowDiskCache: false),
        stream: (_, _) {
          attempts++;
          return Stream<rust.MediaChunk>.error(AnyhowException('Media request failed'));
        },
        streamIdentity: 'failed',
      ),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Image(
            image: provider,
            errorBuilder: (_, error, _) {
              displayedError = error;
              return const Text('Retry image');
            },
          ),
        ),
      );
      // The retries back off in real time; a busy machine needs longer than an idle one.
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (displayedError == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pump();
    expect(attempts, 3);
    expect(displayedError, isA<MediaImageException>());
    expect((displayedError! as MediaImageException).cause, isA<AnyhowException>());
    expect(find.text('Retry image'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a media stream retry can recover without leaving an unhandled failure', (tester) async {
    final bytes = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(const Color(0xFF2196F3), BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(2, 2);
      try {
        return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      } finally {
        image.dispose();
        picture.dispose();
      }
    });
    var attempts = 0;
    final provider = CachedMediaImage(
      RustMediaSource(
        MediaRequest(url: 'https://fixtures.example.test/recovered.png', allowDiskCache: false),
        stream: (_, _) => ++attempts == 1
            ? Stream<rust.MediaChunk>.error(AnyhowException('Media request failed'))
            : Stream.value(rust.MediaChunk(bytes: bytes!, received: bytes.length, total: bytes.length)),
        streamIdentity: 'recovered',
      ),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Image(image: provider, errorBuilder: (_, _, _) => const Text('Failure')),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('Failure'), findsNothing);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await provider.evict();
  });
}
