import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/app_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root, documents, support;
  Future<void> initialize() => initializeHiveStorage(documentsDirectory: documents, supportDirectory: support);
  setUp(() async {
    root = await Directory.systemTemp.createTemp('freepiv-storage-');
    documents = await Directory(p.join(root.path, 'Documents')).create();
    support = await Directory(p.join(root.path, 'Support')).create();
  });
  tearDown(() async {
    await Hive.close();
    await root.delete(recursive: true);
  });

  test('boxes move out of Documents with their data, other Documents files stay', () async {
    Hive.init(documents.path);
    for (final name in ['app_settings', 'fanbox']) {
      await (await Hive.openBox<dynamic>(name)).put('value', name);
    }
    await Hive.close();
    final unrelated = File(p.join(documents.path, 'settings.hive'));
    await unrelated.writeAsBytes([1, 2]);
    await initialize();
    for (final name in ['app_settings', 'fanbox']) {
      final box = await Hive.openBox<dynamic>(name);
      expect(box.path, startsWith(p.join(support.path, 'hive')));
      expect(box.get('value'), name);
      expect(File(p.join(documents.path, '$name.hive')).existsSync(), false);
      expect(File(p.join(documents.path, '$name.lock')).existsSync(), false);
    }
    expect(await unrelated.readAsBytes(), [1, 2]);
  });

  test('existing private data wins and the older Documents bytes stay recoverable', () async {
    Hive.init(documents.path);
    await (await Hive.openBox<dynamic>('app_settings')).put('value', 'legacy');
    await Hive.close();
    final oldBytes = await File(p.join(documents.path, 'app_settings.hive')).readAsBytes();
    Hive.init(p.join(support.path, 'hive'));
    await (await Hive.openBox<dynamic>('app_settings')).put('value', 'current');
    await Hive.close();
    await initialize();
    expect((await Hive.openBox<dynamic>('app_settings')).get('value'), 'current');
    expect(await File(p.join(support.path, 'hive', 'legacy-documents', 'app_settings.hive')).readAsBytes(), oldBytes);
  });

  test('data nested in an app-named folder moves up', () async {
    final nested = Directory(p.join(support.path, 'freepiv'));
    await nested.create();
    await File(p.join(nested.path, 'downloads.sqlite')).writeAsBytes([7, 8]);
    await initialize();
    expect(nested.existsSync(), false);
    expect(await File(p.join(support.path, 'downloads.sqlite')).readAsBytes(), [7, 8]);
  });
}
