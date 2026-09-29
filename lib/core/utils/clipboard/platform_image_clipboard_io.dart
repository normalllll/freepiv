import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';

Future<void> copyPlatformImageBytesToClipboard(Uint8List bytes, {required String mimeType}) async {
  if (Platform.isWindows) return _copyWindowsImage(bytes, mimeType: mimeType);
  final file = await _writeClipboardImageTempFile(bytes, mimeType: mimeType);

  await Pasteboard.writeFiles([file.path]);
}

Future<File> _writeClipboardImageTempFile(Uint8List bytes, {required String mimeType}) async {
  final extension = _imageExtensionFromMimeType(mimeType);
  final dir = await getTemporaryDirectory();

  final file = File('${dir.path}/clipboard_image_${DateTime.now().millisecondsSinceEpoch}.$extension');

  await file.writeAsBytes(bytes, flush: true);
  return file;
}

String _imageExtensionFromMimeType(String mimeType) {
  switch (mimeType.toLowerCase()) {
    case 'image/png':
      return 'png';

    case 'image/jpeg':
    case 'image/jpg':
      return 'jpg';

    case 'image/webp':
      return 'webp';

    case 'image/gif':
      return 'gif';

    case 'image/bmp':
      return 'bmp';

    default:
      throw UnsupportedError('Unsupported image mime type: $mimeType');
  }
}

const _desktopWindowChannel = MethodChannel('desktop_window');

/// Copies an image as image data, not as a file reference. The pasteboard
/// plugin's Windows path writes CF_HDROP without owning or emptying the
/// clipboard, which other applications can stall on. Decoding and pixel
/// conversion stay off the UI thread; the runner writes CF_DIBV5 and PNG.
Future<void> _copyWindowsImage(Uint8List bytes, {required String mimeType}) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    if (rgba == null) throw StateError('The image could not be decoded.');
    final png = mimeType.toLowerCase() == 'image/png' ? bytes : (await image.toByteData(format: ui.ImageByteFormat.png))?.buffer.asUint8List();
    final dib = await compute(_buildDibV5, (TransferableTypedData.fromList([rgba.buffer.asUint8List()]), image.width, image.height));
    await _desktopWindowChannel.invokeMethod<void>('copyImage', {'dib': dib, 'png': png});
  } finally {
    image.dispose();
    codec.dispose();
  }
}

/// BITMAPV5HEADER plus bottom-up 32-bit BGRA rows with an alpha mask.
Uint8List _buildDibV5((TransferableTypedData, int, int) input) {
  final (data, width, height) = input;
  final rgba = data.materialize().asUint8List();
  const headerSize = 124;
  final rowBytes = width * 4;
  final out = Uint8List(headerSize + rowBytes * height);
  final header = ByteData.sublistView(out, 0, headerSize);
  header
    ..setUint32(0, headerSize, Endian.little)
    ..setInt32(4, width, Endian.little)
    ..setInt32(8, height, Endian.little) // positive: bottom-up rows
    ..setUint16(12, 1, Endian.little)
    ..setUint16(14, 32, Endian.little)
    ..setUint32(16, 3, Endian.little) // BI_BITFIELDS
    ..setUint32(20, rowBytes * height, Endian.little)
    ..setUint32(40, 0x00FF0000, Endian.little) // red mask
    ..setUint32(44, 0x0000FF00, Endian.little) // green mask
    ..setUint32(48, 0x000000FF, Endian.little) // blue mask
    ..setUint32(52, 0xFF000000, Endian.little) // alpha mask
    ..setUint32(56, 0x73524742, Endian.little) // LCS_sRGB
    ..setUint32(108, 4, Endian.little); // LCS_GM_IMAGES
  for (var y = 0; y < height; y++) {
    final source = y * rowBytes;
    final target = headerSize + (height - 1 - y) * rowBytes;
    for (var x = 0; x < rowBytes; x += 4) {
      out[target + x] = rgba[source + x + 2];
      out[target + x + 1] = rgba[source + x + 1];
      out[target + x + 2] = rgba[source + x];
      out[target + x + 3] = rgba[source + x + 3];
    }
  }
  return out;
}
