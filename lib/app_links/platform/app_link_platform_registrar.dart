import 'dart:io';

import 'android_app_links.dart';
import 'ios_app_links.dart';
import 'linux_app_links.dart';
import 'macos_app_links.dart';
import 'windows_app_links.dart';

Future<void> registerPlatformAppLinks() {
  if (Platform.isAndroid) {
    return registerAndroidAppLinks();
  }
  if (Platform.isIOS) {
    return registerIosAppLinks();
  }
  if (Platform.isLinux) {
    return registerLinuxAppLinks();
  }
  if (Platform.isMacOS) {
    return registerMacosAppLinks();
  }
  if (Platform.isWindows) {
    return registerWindowsAppLinks();
  }

  return Future<void>.value();
}
