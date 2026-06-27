import 'dart:io';

import '../app_link_config.dart';
import 'process_output.dart';

Future<void> registerWindowsAppLinks() async {
  for (final scheme in appLinkSchemes) {
    await _registerWindowsScheme(scheme);
  }
}

Future<void> _registerWindowsScheme(String scheme) async {
  final protocolKey = r'HKCU\Software\Classes\' + scheme;
  final openCommandKey = '$protocolKey\\shell\\open\\command';
  final executable = Platform.resolvedExecutable;

  await _regAdd(protocolKey, ['/ve', '/d', 'URL:$appLinkAppName $scheme']);
  await _regAdd(protocolKey, ['/v', 'URL Protocol', '/t', 'REG_SZ', '/d', '']);
  await _regAdd(openCommandKey, ['/ve', '/d', '"$executable" "%1"']);
}

Future<void> _regAdd(String key, List<String> arguments) async {
  final result = await Process.run('reg', ['add', key, ...arguments, '/f']);
  if (result.exitCode != 0) {
    throw StateError('Windows AppLink registration failed: ${processOutput(result)}');
  }
}
