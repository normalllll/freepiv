import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/image_size_from_header.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

int _hi(int v) => (v >> 8) & 0xFF;
int _lo(int v) => v & 0xFF;

/// A JPEG start: SOI, [segments] (each marker and its payload size) and a baseline frame header.
Uint8List _jpeg(int width, int height, {List<(int, int)> segments = const []}) => _bytes([
  0xFF,
  0xD8,
  for (final (marker, size) in segments) ...[0xFF, marker, _hi(size + 2), _lo(size + 2), ...List.filled(size, 0x41)],
  0xFF,
  0xC0,
  0x00,
  0x11,
  0x08,
  _hi(height),
  _lo(height),
  _hi(width),
  _lo(width),
  0x03,
  0x01,
  0x22,
  0x00,
  0x02,
  0x11,
  0x01,
  0x03,
  0x11,
  0x01,
]);

Uint8List _png(int width, int height) => _bytes([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  ...[24, 16, 8, 0].map((shift) => (width >> shift) & 0xFF),
  ...[24, 16, 8, 0].map((shift) => (height >> shift) & 0xFF),
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
]);

Uint8List _gif(int width, int height) => _bytes([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, _lo(width), _hi(width), _lo(height), _hi(height), 0xF7, 0x00, 0x00]);

Uint8List _riff(String kind, List<int> data) {
  final chunk = [...kind.codeUnits, data.length & 0xFF, (data.length >> 8) & 0xFF, 0, 0, ...data];
  final size = 4 + chunk.length;
  return _bytes([0x52, 0x49, 0x46, 0x46, size & 0xFF, (size >> 8) & 0xFF, 0, 0, ...'WEBP'.codeUnits, ...chunk]);
}

Uint8List _webpLossy(int width, int height) =>
    _riff('VP8 ', [0x30, 0x01, 0x00, 0x9D, 0x01, 0x2A, _lo(width), _hi(width) & 0x3F, _lo(height), _hi(height) & 0x3F, 0, 0, 0, 0]);

Uint8List _webpLossless(int width, int height) {
  final bits = (width - 1) | ((height - 1) << 14);
  return _riff('VP8L', [0x2F, bits & 0xFF, (bits >> 8) & 0xFF, (bits >> 16) & 0xFF, (bits >> 24) & 0xFF, 0, 0, 0]);
}

Uint8List _webpExtended(int width, int height) {
  final w = width - 1, h = height - 1;
  return _riff('VP8X', [0x10, 0, 0, 0, w & 0xFF, (w >> 8) & 0xFF, (w >> 16) & 0xFF, h & 0xFF, (h >> 8) & 0xFF, (h >> 16) & 0xFF]);
}

void main() {
  group('real 240mw headers from i.pximg.net', () {
    for (final (name, size) in [
      ('pximg_152069551_240mw_head.jpg', const Size(240, 173)),
      ('pximg_152069603_240mw_head.jpg', const Size(240, 474)),
      ('pximg_152118896_240mw_head.jpg', const Size(240, 175)),
    ]) {
      test('$name is ${size.width.toInt()}x${size.height.toInt()}', () {
        final bytes = File('test/fixtures/image_headers/$name').readAsBytesSync();
        expect(bytes.length, lessThan(30 * 1024));
        expect(imageSizeFromHeader(bytes), size);
      });

      test('$name gives the size from its first thousand bytes and never a wrong one', () {
        final bytes = File('test/fixtures/image_headers/$name').readAsBytesSync();
        var first = -1;
        for (var length = 0; length <= bytes.length; length++) {
          final found = imageSizeFromHeader(Uint8List.sublistView(bytes, 0, length));
          if (found != null) {
            first = first < 0 ? length : first;
            expect(found, size, reason: 'at $length bytes');
          } else {
            expect(first, -1, reason: 'once found it stays found: $length');
          }
        }
        expect(first, inInclusiveRange(1, 1000));
      });
    }
  });

  group('formats', () {
    test('a JPEG with a long EXIF segment before the frame header', () {
      expect(imageSizeFromHeader(_jpeg(1600, 900, segments: [(0xE0, 14), (0xE1, 40000), (0xE2, 3000)])), const Size(1600, 900));
    });

    test('JPEG frame markers SOF0 to SOF15 count, DHT, JPG and DAC do not', () {
      for (final marker in [0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF]) {
        final bytes = _jpeg(30, 20);
        bytes[3] = marker;
        expect(imageSizeFromHeader(bytes), const Size(30, 20), reason: marker.toRadixString(16));
      }
      for (final marker in [0xC4, 0xC8, 0xCC]) {
        final bytes = _jpeg(30, 20);
        bytes[3] = marker;
        expect(imageSizeFromHeader(bytes), isNull, reason: marker.toRadixString(16));
      }
    });

    test('padding bytes before a marker are skipped', () {
      final plain = _jpeg(64, 48);
      final padded = _bytes([0xFF, 0xD8, 0xFF, 0xFF, 0xFF, ...plain.sublist(3)]);
      expect(imageSizeFromHeader(padded), const Size(64, 48));
    });

    test('PNG', () => expect(imageSizeFromHeader(_png(1200, 3000)), const Size(1200, 3000)));
    test('GIF', () => expect(imageSizeFromHeader(_gif(320, 240)), const Size(320, 240)));
    test('WebP lossy (VP8)', () => expect(imageSizeFromHeader(_webpLossy(480, 683)), const Size(480, 683)));
    test('WebP lossless (VP8L)', () => expect(imageSizeFromHeader(_webpLossless(1200, 675)), const Size(1200, 675)));
    test('WebP extended (VP8X)', () => expect(imageSizeFromHeader(_webpExtended(4096, 2160)), const Size(4096, 2160)));
  });

  group('truncated at every byte', () {
    final samples = {
      'jpeg with EXIF': (_jpeg(1600, 900, segments: [(0xE1, 300)]), const Size(1600, 900)),
      'png': (_png(800, 600), const Size(800, 600)),
      'gif': (_gif(100, 50), const Size(100, 50)),
      'webp VP8': (_webpLossy(480, 640), const Size(480, 640)),
      'webp VP8L': (_webpLossless(480, 640), const Size(480, 640)),
      'webp VP8X': (_webpExtended(480, 640), const Size(480, 640)),
    };
    for (final MapEntry(key: name, value: (bytes, size)) in samples.entries) {
      test(name, () {
        var found = false;
        for (var length = 0; length <= bytes.length; length++) {
          final result = imageSizeFromHeader(Uint8List.sublistView(bytes, 0, length));
          if (result != null) {
            expect(result, size, reason: 'at $length');
            found = true;
          } else {
            expect(found, isFalse, reason: 'null after a size at $length');
          }
        }
        expect(found, isTrue);
        expect(imageSizeFromHeader(Uint8List.sublistView(bytes, 0, 4)), isNull);
      });
    }
  });

  group('garbage', () {
    test('empty and tiny input', () {
      for (var length = 0; length < 4; length++) {
        expect(imageSizeFromHeader(Uint8List(length)), isNull);
      }
    });

    test('random bytes never throw', () {
      final random = Random(7);
      for (var round = 0; round < 500; round++) {
        final bytes = Uint8List.fromList(List.generate(random.nextInt(300), (_) => random.nextInt(256)));
        expect(() => imageSizeFromHeader(bytes), returnsNormally);
      }
    });

    test('headers with impossible content are refused', () {
      expect(imageSizeFromHeader(_bytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x01, 0x00])), isNull, reason: 'a segment shorter than its length field');
      expect(imageSizeFromHeader(Uint8List.fromList(List.filled(100, 0xFF))), isNull);
      expect(imageSizeFromHeader(_bytes([0xFF, 0xD8, 0xFF, 0xDA, 0x00, 0x08, 0, 0, 0, 0, 0, 0])), isNull, reason: 'the scan starts before any frame header');
      expect(imageSizeFromHeader(_png(0, 10)), isNull);
      expect(imageSizeFromHeader(_gif(0, 0)), isNull);
      expect(imageSizeFromHeader(_riff('XXXX', List.filled(16, 0))), isNull);
      expect(imageSizeFromHeader(Uint8List.fromList('not a picture at all, just text'.codeUnits)), isNull);
    });
  });
}
