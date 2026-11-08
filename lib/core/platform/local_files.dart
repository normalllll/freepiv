import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

/// The command that shows the file at [path] in the system's file manager.
/// Windows and macOS select it; Linux has no common way, so it opens the
/// folder. The Windows path follows `/select,` as its own argument, so a path
/// with spaces is quoted on its own, the form Explorer accepts.
({String executable, List<String> arguments}) revealFileCommand(String path, {TargetPlatform? platform}) => switch (platform ?? defaultTargetPlatform) {
  TargetPlatform.windows => (executable: 'explorer.exe', arguments: ['/select,', p.windows.normalize(path)]),
  TargetPlatform.macOS => (executable: 'open', arguments: ['-R', path]),
  _ => (executable: 'xdg-open', arguments: [p.dirname(path)]),
};

/// Shows the file at [path] in the file manager; a missing file throws.
Future<void> revealLocalFile(String path) async {
  await _requireFile(path);
  final command = revealFileCommand(path);
  // Explorer's exit code says nothing about whether it showed the file.
  await Process.run(command.executable, command.arguments);
}

/// Opens the file at [path] in its default app; a missing file throws.
Future<void> openLocalFile(String path) async {
  await _requireFile(path);
  if (!await launchUrl(Uri.file(path))) throw FileSystemException('No app opened the file', path);
}

Future<void> _requireFile(String path) async {
  if (!await File(path).exists()) throw PathNotFoundException(path, const OSError('File not found'));
}
