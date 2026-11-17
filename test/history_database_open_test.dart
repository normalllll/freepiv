import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_database.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory directory;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    directory = await Directory.systemTemp.createTemp('history_open_test');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
  });

  ReadingProgress progress() => ReadingProgress(offset: 5, totalLength: 10, updatedAt: DateTime.utc(2026, 11, 1));

  test('a file that is not a database is replaced by an empty one', () async {
    final file = File(p.join(directory.path, 'history.sqlite'));
    await file.writeAsString('this is not a database, and it is long enough to be read as a header ' * 8);

    final repository = HistoryRepository(HistoryDatabase.atFile(file));
    addTearDown(repository.close);

    expect(await repository.count('1000'), 0);
    await repository.saveReadingProgress('1000', 7, progress());
    expect((await repository.readingProgress('1000', 7))!.offset, 5);
  });

  test('a healthy file is kept as it is', () async {
    final file = File(p.join(directory.path, 'history.sqlite'));
    final first = HistoryRepository(HistoryDatabase.atFile(file));
    await first.saveReadingProgress('1000', 7, progress());
    await first.close();

    final second = HistoryRepository(HistoryDatabase.atFile(file));
    addTearDown(second.close);
    expect((await second.readingProgress('1000', 7))!.offset, 5);
  });

  test('a file that still cannot be opened after a new start is an error for the caller', () async {
    final blocker = File(p.join(directory.path, 'blocker'));
    await blocker.writeAsString('a file where a folder is needed');
    final repository = HistoryRepository(HistoryDatabase.atFile(File(p.join(blocker.path, 'history.sqlite'))));
    addTearDown(() => repository.close().catchError((_) {}));

    await expectLater(repository.count('1000'), throwsA(anything));
  });
}
