import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart' show FrostAmbientBackdrop, FrostAmbientBackdropHost;

Future<ui.Image> _solid(Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 8, 8), Paint()..color = color);
  return recorder.endRecording().toImage(8, 8);
}

/// The window's backdrop with the artwork [image], and over it, when
/// [scale] is given, a page's copy of the backdrop shrunk about the centre.
/// Returns the colour at [at] once the artwork has faded in.
Future<Color> _pixel(WidgetTester tester, ImageProvider? image, Offset at, {double? scale}) async {
  final boundary = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en')),
      home: RepaintBoundary(
        key: boundary,
        child: FrostAmbientBackdropHost(
          image: image,
          child: scale == null ? const SizedBox.expand() : Transform.scale(scale: scale, child: const FrostAmbientBackdrop()),
        ),
      ),
    ),
  );
  // The artwork is decoded and blurred off the frame, then fades in.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  late Color color;
  await tester.runAsync(() async {
    final picture = await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
    final data = (await picture.toByteData())!;
    final offset = (at.dy.round() * picture.width + at.dx.round()) * 4;
    color = Color.fromARGB(255, data.getUint8(offset), data.getUint8(offset + 1), data.getUint8(offset + 2));
    picture.dispose();
  });
  return color;
}

List<int> _channels(Color color) => [color.r, color.g, color.b].map((value) => (value * 255).round()).toList();

void main() {
  testWidgets('a scaled page\'s backdrop copy still fills the page with the window\'s material', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    final artwork = await tester.runAsync(() => _solid(const Color(0xFFFF00FF)));
    final provider = _ImageProvider(artwork!);

    // A point inside the shrunk page (it spans 100..300 by 200..600), near its
    // far corner: the copy must show the same material as the window there.
    const inside = Offset(290, 590);
    final window = await _pixel(tester, provider, inside);
    final copy = await _pixel(tester, provider, inside, scale: .5);

    for (final (index, expected) in _channels(window).indexed) {
      expect(_channels(copy)[index], closeTo(expected, 2), reason: 'channel $index');
    }
    // The artwork does tint the window there, so the comparison means something.
    final plain = await _pixel(tester, null, inside);
    expect((_channels(window)[1] - _channels(plain)[1]).abs(), greaterThan(4));
  });
}

class _ImageProvider extends ImageProvider<_ImageProvider> {
  const _ImageProvider(this.image);

  final ui.Image image;

  @override
  Future<_ImageProvider> obtainKey(ImageConfiguration configuration) => Future.value(this);

  @override
  ImageStreamCompleter loadImage(_ImageProvider key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Future.value(ImageInfo(image: image.clone())));
}
