import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<Directory>? _supportDirectory;

/// The application's own data directory, after older layouts were moved into
/// it. On Windows this is `%APPDATA%\io.github.normalllll\freepiv`.
Future<Directory> appSupportDirectory() => _supportDirectory ??= () async {
  final support = await getApplicationSupportDirectory();
  await flattenLegacySupportFolder(support);
  return support;
}();

/// Opens Hive in `<support>/hive`, never in the user's Documents folder.
/// Boxes an older version left in Documents move before any box opens.
Future<void> initializeHiveStorage({@visibleForTesting Directory? documentsDirectory, @visibleForTesting Directory? supportDirectory}) async {
  final Directory support;
  if (supportDirectory == null) {
    support = await appSupportDirectory();
  } else {
    support = supportDirectory;
    await flattenLegacySupportFolder(support);
  }
  final documents = documentsDirectory ?? await getApplicationDocumentsDirectory();
  final private = Directory(p.join(support.path, 'hive'));
  await private.create(recursive: true);
  await _upgradeDocumentsStorage(documents, private);
  Hive.init(private.path);
}

// Only these application-owned boxes may move; other Documents content stays.
const _legacyBoxes = ['app_settings', 'fanbox'];

Future<void> _upgradeDocumentsStorage(Directory documents, Directory private) async {
  final version = File(p.join(private.path, 'legacy-upgrade-version'));
  if (await version.exists() && await version.readAsString() == '1') return;
  for (final name in _legacyBoxes) {
    var destination = private;
    if (await File(p.join(private.path, '$name.hive')).exists() || await File(p.join(private.path, '$name.hivec')).exists()) {
      // Never overwrite newer private data; keep the older bytes for recovery.
      destination = Directory(p.join(private.path, 'legacy-documents'));
    }
    for (final extension in ['hive', 'hivec']) {
      final source = File(p.join(documents.path, '$name.$extension'));
      if (!await source.exists()) continue;
      await destination.create(recursive: true);
      var target = p.join(destination.path, '$name.$extension');
      if (await File(target).exists()) target = '$target.${DateTime.now().microsecondsSinceEpoch}';
      await _moveFile(source, target);
    }
    final lock = File(p.join(documents.path, '$name.lock'));
    if (await lock.exists()) await lock.delete();
  }
  // Mark only after every move succeeds; an interrupted upgrade is retried.
  await version.writeAsString('1', flush: true);
}

// Rename keeps bytes atomic on one volume. Documents may sit on another drive,
// so a failed rename copies to a temporary name, renames it into place and only
// then deletes the source; any failure stops initialization, losing no data.
Future<void> _moveFile(File source, String target) async {
  try {
    await source.rename(target);
  } on FileSystemException {
    final temporary = await source.copy('$target.partial');
    await temporary.rename(target);
    await source.delete();
  }
}

/// Older versions nested their data in `<support>/freepiv`, although the
/// support directory already belongs to this application. Lifts every entry
/// one level up; an entry whose name is already taken stays where it is.
@visibleForTesting
Future<void> flattenLegacySupportFolder(Directory support) async {
  final nested = Directory(p.join(support.path, 'freepiv'));
  if (!await nested.exists()) return;
  await for (final entry in nested.list(followLinks: false)) {
    final target = p.join(support.path, p.basename(entry.path));
    if (await FileSystemEntity.type(target, followLinks: false) != FileSystemEntityType.notFound) continue;
    await entry.rename(target);
  }
  if (await nested.list().isEmpty) await nested.delete();
}
