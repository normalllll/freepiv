import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

bool get isDesktopPlatform {
  if (kIsWeb) {
    return false;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.linux || TargetPlatform.macOS || TargetPlatform.windows => true,
    _ => false,
  };
}

/// Whether the system itself confirms every clipboard write, as Android 13
/// (API 33) and later do with their own bubble. The app then skips its own
/// “copied” notice so a copy never shows two. Queried once.
Future<bool> systemConfirmsClipboardCopies() => _systemConfirmsClipboardCopies ??= _querySystemClipboardConfirmation();

Future<bool>? _systemConfirmsClipboardCopies;

Future<bool> _querySystemClipboardConfirmation() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    return (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33;
  } catch (_) {
    return false;
  }
}
