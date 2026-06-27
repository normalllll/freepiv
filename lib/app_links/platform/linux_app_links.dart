import 'dart:io';

import '../app_link_config.dart';
import 'process_output.dart';

const _linuxDesktopId = 'io.github.normalllll.freepiv.desktop';

Future<void> registerLinuxAppLinks() async {
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    throw StateError('HOME environment variable is empty; cannot register Linux scheme handler.');
  }

  final applicationsDir = Directory('$home/.local/share/applications');
  await applicationsDir.create(recursive: true);

  final desktopFile = File('${applicationsDir.path}/$_linuxDesktopId');
  final mimeTypes = appLinkSchemes.map((scheme) => 'x-scheme-handler/$scheme').join(';');
  await desktopFile.writeAsString('''
[Desktop Entry]
Version=1.0
Type=Application
Name=$appLinkAppName
Exec=${_desktopExecArgument(Platform.resolvedExecutable)} %u
Terminal=false
NoDisplay=true
Categories=Utility;
MimeType=$mimeTypes;
''');

  try {
    await Process.run('update-desktop-database', [applicationsDir.path]);
  } on ProcessException {
    // Optional on many desktop environments; xdg-mime below is the critical step.
  }

  for (final scheme in appLinkSchemes) {
    final result = await Process.run('xdg-mime', ['default', _linuxDesktopId, 'x-scheme-handler/$scheme']);
    if (result.exitCode != 0) {
      throw StateError('xdg-mime registration failed: ${processOutput(result)}');
    }
  }
}

String _desktopExecArgument(String value) {
  final escaped = value.replaceAll('\\', '\\\\').replaceAll('"', r'\"');
  return '"$escaped"';
}
