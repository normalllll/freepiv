import 'package:flutter/services.dart';
import 'package:freepiv/core/utils/clipboard/platform_image_clipboard_stub.dart'
    if (dart.library.io) 'package:freepiv/core/utils/clipboard/platform_image_clipboard_io.dart';

Future<void> copyTextToClipboard(String text) {
  return Clipboard.setData(ClipboardData(text: text));
}

Future<void> copyImageBytesToClipboard(Uint8List bytes, {required String mimeType}) {
  return copyPlatformImageBytesToClipboard(bytes, mimeType: mimeType);
}
