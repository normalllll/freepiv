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
