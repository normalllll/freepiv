import 'dart:async';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;

class _MediaTransport extends RustMediaTransport {
  _MediaTransport(this.bytes, {this.release, this.failuresRemaining = 0}) : super(null);

  final Uint8List bytes;
  final Future<void>? release;
  int failuresRemaining;
  int requests = 0;
  int yielded = 0;

  @override
  Stream<rust.MediaChunk> stream(String url, Map<String, String> headers) async* {
    requests++;
    if (release case final pending?) await pending;
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('fixture media failure');
    }
    yielded++;
    yield rust.MediaChunk(bytes: bytes, received: bytes.length, total: bytes.length);
  }
}

Future<Uint8List> _imageBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 8, 8), ui.Paint()..color = const ui.Color(0xFFFC619D));
  final image = await recorder.endRecording().toImage(8, 8);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Widget _host(_MediaTransport transport) => ProviderScope(
  key: UniqueKey(),
  overrides: [rustMediaTransportProvider.overrideWithValue(transport)],
  child: TranslationProvider(
    child: FrostScope(
      config: freepivFrostConfig,
      child: MaterialApp(
        theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en', 'US')),
        home: const Scaffold(
          body: Center(
            child: SizedBox.square(dimension: 80, child: PixivImage(url: 'https://fixture.example.test/cached.png', cache: false)),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a slow failed image keeps its retry action and can recover', (tester) async {
    PaintingBinding.instance.imageCache.clear();
    final bytes = await tester.runAsync(_imageBytes);
    final release = Completer<void>();
    final transport = _MediaTransport(bytes!, release: release.future, failuresRemaining: 3);
    await tester.pumpWidget(_host(transport));
    expect((tester.state(find.byType(ExtendedImage)) as ExtendedImageState).extendedImageLoadState, LoadState.loading);

    release.complete();
    for (var attempt = 0; attempt < 12; attempt++) {
      await tester.pump(const Duration(milliseconds: 120));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if ((tester.state(find.byType(ExtendedImage)) as ExtendedImageState).extendedImageLoadState == LoadState.failed) break;
    }
    expect((tester.state(find.byType(ExtendedImage)) as ExtendedImageState).extendedImageLoadState, LoadState.failed);
    await tester.tap(find.byIcon(Icons.refresh_outlined));
    for (var attempt = 0; attempt < 12; attempt++) {
      await tester.pump(const Duration(milliseconds: 120));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if ((tester.state(find.byType(ExtendedImage)) as ExtendedImageState).extendedImageLoadState == LoadState.completed) break;
    }
    expect(transport.requests, 4);
    expect((tester.state(find.byType(ExtendedImage)) as ExtendedImageState).extendedImageLoadState, LoadState.completed);
  });

  testWidgets('returning to an already shown image uses the memory frame without a second fade or request', (tester) async {
    PaintingBinding.instance.imageCache.clear();
    final bytes = await tester.runAsync(_imageBytes);
    final imageRelease = Completer<void>();
    final first = _MediaTransport(bytes!, release: imageRelease.future);
    await tester.pumpWidget(_host(first));
    expect(first.requests, 1);
    imageRelease.complete();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    expect(first.yielded, 1);
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 160));
    expect(first.requests, 1);
    final firstImageState = tester.state(find.byType(ExtendedImage)) as ExtendedImageState;
    expect(firstImageState.extendedImageLoadState, LoadState.completed);
    expect(firstImageState.wasSynchronouslyLoaded, isFalse);
    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final revisit = _MediaTransport(bytes);
    await tester.pumpWidget(_host(revisit));
    await tester.pump();
    expect(revisit.requests, 0);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });
}
