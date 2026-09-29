import 'package:flutter/services.dart';
import 'package:freepiv/core/utils/clipboard/platform_image_clipboard_stub.dart'
    if (dart.library.io) 'package:freepiv/core/utils/clipboard/platform_image_clipboard_io.dart';

Future<void> copyTextToClipboard(String text) {
  return Clipboard.setData(ClipboardData(text: text));
}

Future<void> copyImageBytesToClipboard(Uint8List bytes, {required String mimeType}) {
  return copyPlatformImageBytesToClipboard(bytes, mimeType: mimeType);
}

/// The image type an address names by its extension; PNG when unknown.
String imageMimeTypeFromUrl(String imageUrl) {
  final uri = Uri.tryParse(imageUrl);
  final path = (uri?.path ?? imageUrl).toLowerCase();
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (path.endsWith('.gif')) {
    return 'image/gif';
  }
  if (path.endsWith('.webp')) {
    return 'image/webp';
  }

  return 'image/png';
}
