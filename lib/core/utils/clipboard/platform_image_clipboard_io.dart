import 'dart:io';
import 'dart:typed_data';

import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';

Future<void> copyPlatformImageBytesToClipboard(Uint8List bytes, {required String mimeType}) async {
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
