import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:freepiv/src/rust/api/fanbox_login.dart';

const fanboxLoginChannel = MethodChannel('freepiv/fanbox_login');

bool get supportsFanboxWebLogin => Platform.isWindows || Platform.isAndroid || Platform.isIOS;

Future<void> clearFanboxLoginData() async {
  if (Platform.isWindows) {
    await clearFanboxBrowser(supportDirectory: (await getApplicationSupportDirectory()).path);
  } else if (Platform.isAndroid || Platform.isIOS) {
    await fanboxLoginChannel.invokeMethod<void>('clear');
  }
}

Future<String?> readFanboxLoginSession() => fanboxLoginChannel.invokeMethod<String>('session');
