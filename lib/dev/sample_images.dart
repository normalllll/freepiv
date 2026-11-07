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

  /// The hues of each picture's gradient, from a pale one to a deep one:
  /// rose to violet, aqua to blue, amber to orange, mint to teal, lilac to
  /// indigo, peach to crimson.
  static const _hues = [(345.0, 262.0), (187.0, 208.0), (45.0, 27.0), (122.0, 174.0), (291.0, 232.0), (14.0, 336.0)];

  static List<Color> _palette(int seed) {
    final (pale, deep) = _hues[seed % _hues.length];
    return [HSVColor.fromAHSV(1, pale, .3, 1).toColor(), HSVColor.fromAHSV(1, deep, .8, .75).toColor()];
  }

  /// The soft highlights scattered over a picture.
  static Color _highlight(double alpha) => HSVColor.fromAHSV(alpha, 0, 0, 1).toColor();

  @override
  Future<SampleImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(SampleImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(_draw().then((image) => ImageInfo(image: image)));

  Future<ui.Image> _draw() {
    final random = math.Random(seed);
    final palette = _palette(seed);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final rect = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    canvas.drawRect(rect, ui.Paint()..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, palette));
    for (var index = 0; index < 5; index++) {
      final center = ui.Offset(random.nextDouble() * width, random.nextDouble() * height);
      final radius = (.1 + random.nextDouble() * .3) * math.min(width, height);
      canvas.drawCircle(center, radius, ui.Paint()..color = _highlight(.08 + random.nextDouble() * .18));
    }
    return recorder.endRecording().toImage(width, height);
  }

  @override
  bool operator ==(Object other) => other is SampleImage && other.seed == seed && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(seed, width, height);
}
