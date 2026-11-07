// Generated pictures for the sample app and its screenshots: each sample
// address (`sample:<seed>:<width>x<height>`) draws a soft gradient with a
// few shapes, so works look like works without any network.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

const sampleImageScheme = 'sample:';

/// The address of a generated sample picture.
String sampleImageUrl(int seed, {int width = 600, int height = 800}) => '$sampleImageScheme$seed:${width}x$height';

/// The picture for a sample address, or null for any other address.
ImageProvider? sampleImageProvider(String url) {
  if (!url.startsWith(sampleImageScheme)) return null;
  final parts = url.substring(sampleImageScheme.length).split(':');
  final size = parts.length > 1 ? parts[1].split('x') : const ['600', '800'];
  return SampleImage(seed: int.tryParse(parts.first) ?? 0, width: int.tryParse(size.first) ?? 600, height: int.tryParse(size.last) ?? 800);
}

@immutable
class SampleImage extends ImageProvider<SampleImage> {
  const SampleImage({required this.seed, required this.width, required this.height});

  final int seed;
  final int width;
  final int height;

  static const _palettes = [
    [Color(0xFFFFB3C7), Color(0xFF7E57C2)],
    [Color(0xFF80DEEA), Color(0xFF1E88E5)],
    [Color(0xFFFFE082), Color(0xFFEF6C00)],
    [Color(0xFFA5D6A7), Color(0xFF00796B)],
    [Color(0xFFCE93D8), Color(0xFF283593)],
    [Color(0xFFFFCCBC), Color(0xFFC2185B)],
  ];

  @override
  Future<SampleImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(SampleImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(_draw().then((image) => ImageInfo(image: image)));

  Future<ui.Image> _draw() {
    final random = math.Random(seed);
    final palette = _palettes[seed % _palettes.length];
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final rect = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    canvas.drawRect(rect, ui.Paint()..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, palette));
    for (var index = 0; index < 5; index++) {
      final center = ui.Offset(random.nextDouble() * width, random.nextDouble() * height);
      final radius = (.1 + random.nextDouble() * .3) * math.min(width, height);
      canvas.drawCircle(center, radius, ui.Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: .08 + random.nextDouble() * .18));
    }
    return recorder.endRecording().toImage(width, height);
  }

  @override
  bool operator ==(Object other) => other is SampleImage && other.seed == seed && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(seed, width, height);
}
