import 'dart:typed_data';

Future<void> copyPlatformImageBytesToClipboard(Uint8List bytes, {required String mimeType}) {
  throw UnsupportedError('Image clipboard is not implemented on this platform.');
}

Future<void> copyPlatformNetworkImageToClipboard(Uri url, {Map<String, String> headers = const {}}) {
  throw UnsupportedError('Image clipboard is not implemented on this platform.');
}
