import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/core/media/media_header_sizes.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;
import 'package:freepiv/ui/compositions/pixiv_image.dart';

import 'support/frost_test_app.dart';

/// A download of [file] that starts when [gate] completes.
class _Transport extends RustMediaTransport {
  const _Transport(this.file, this.gate) : super(null);

  final Uint8List file;
  final Future<void> gate;

  @override
  Stream<rust.MediaChunk> stream(String url, Map<String, String> headers) =>
      Stream.fromFuture(gate.then((_) => rust.MediaChunk(bytes: file, received: file.length, total: file.length)));
}

void main() {
  Future<Uint8List> png(WidgetTester tester, int width, int height) async => (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(const Color(0xFF2196F3), BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    try {
      return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }))!;

  Future<List<Size>> sizesOf(WidgetTester tester, String url, Uint8List file, {Size? declared, String? placeholder, Size? placeholderDeclared}) async {
    final sizes = <Size>[];
    final gate = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rustMediaTransportProvider.overrideWithValue(_Transport(file, gate.future))],
        child: frostTestApp(
          home: Align(
            child: SizedBox(
              width: 100,
              height: 100,
              child: AppPixivImage(url: url, placeholderUrl: placeholder, accountKey: 'test', onImageSize: sizes.add),
            ),
          ),
        ),
      ),
    );
    if (placeholder != null && placeholderDeclared != null) {
      mediaHeaderSizes.publish(pixivMediaRequest(placeholder, accountKey: 'test').cacheKey, placeholderDeclared);
      await tester.pump();
    }
    if (declared != null) {
      mediaHeaderSizes.publish(pixivMediaRequest(url, accountKey: 'test').cacheKey, declared);
      await tester.pump();
    }
    gate.complete();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    return sizes;
  }

  testWidgets('the declared size arrives first and the decoded size only when its shape differs', (tester) async {
    final file = await png(tester, 6, 3);
    final sizes = await sizesOf(tester, 'https://fixtures.example.test/differs.png', file, declared: const Size(60, 40));
    expect(sizes, [const Size(60, 40), const Size(6, 3)]);
  });

  testWidgets('a decoded size within 1 % of the reported ratio is the same size', (tester) async {
    final file = await png(tester, 100, 67);
    final sizes = await sizesOf(tester, 'https://fixtures.example.test/rounding.png', file, declared: const Size(240, 161));
    expect(sizes, [const Size(240, 161)], reason: '240 x 161 and 100 x 67 differ by 0.3 %');
  });

  testWidgets('a placeholder header that arrives first counts, and the picture own header of the same shape adds nothing', (tester) async {
    final file = await png(tester, 6, 4);
    final sizes = await sizesOf(
      tester,
      'https://fixtures.example.test/main.png',
      file,
      placeholder: 'https://fixtures.example.test/main-240.png',
      placeholderDeclared: const Size(240, 160),
      declared: const Size(1200, 801),
    );
    expect(sizes, [const Size(240, 160)]);
  });

  testWidgets('a decoded size the declared one already gave is not reported twice', (tester) async {
    final file = await png(tester, 6, 4);
    final sizes = await sizesOf(tester, 'https://fixtures.example.test/same.png', file, declared: const Size(6, 4));
    expect(sizes, [const Size(6, 4)]);
  });

  testWidgets('without a declared size, as for a picture from the disk cache, the decoded size is the one report', (tester) async {
    final file = await png(tester, 6, 4);
    final sizes = await sizesOf(tester, 'https://fixtures.example.test/decoded-only.png', file);
    expect(sizes, [const Size(6, 4)]);
  });

  testWidgets('a size already declared when the picture is built is reported at once', (tester) async {
    final file = await png(tester, 6, 4);
    const url = 'https://fixtures.example.test/known.png';
    mediaHeaderSizes.publish(pixivMediaRequest(url, accountKey: 'test').cacheKey, const Size(30, 20));
    final sizes = await sizesOf(tester, url, file);
    expect(sizes.first, const Size(30, 20));
  });
}
