import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/history/history_database.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'support/account_fakes.dart';
import 'support/memory_history.dart';

final _day = DateTime.utc(2026, 11, 1);

ReadingProgress _progress(int offset, {int total = 1000, DateTime? at}) =>
    ReadingProgress(offset: offset, totalLength: total, updatedAt: at ?? _day);

HistoryEntry _entry(int workId, DateTime at, {HistoryWorkKind kind = HistoryWorkKind.novel}) => HistoryEntry(
  kind: kind,
  workId: workId,
  title: 'A work',
  authorId: 2000,
  authorName: 'Sample artist',
  thumbnailUrl: '',
  xRestrict: 0,
  aiGenerated: false,
  viewedAt: at,
  width: kind.isNovel ? null : 1000,
  height: kind.isNovel ? null : 1400,
  pageCount: kind.isNovel ? null : 1,
  textLength: kind.isNovel ? 9000 : null,
);

void _expectProgress(ReadingProgress? actual, ReadingProgress expected) {
  expect(actual, isNotNull);
  expect(actual!.offset, expected.offset);
  expect(actual.totalLength, expected.totalLength);
  expect(actual.updatedAt.isAtSameMomentAs(expected.updatedAt), isTrue, reason: '${actual.updatedAt} vs ${expected.updatedAt}');
}

void main() {
  late HistoryRepository history;

  setUp(() async {
    history = useMemoryHistory();
    await AppSettings.initialize(store: SampleSettingsStore(accountSettings()));
  });

  group('repository', () {
    test('a saved progress reads back', () async {
      await history.saveReadingProgress('1000', 7, _progress(250));

      _expectProgress(await history.readingProgress('1000', 7), _progress(250));
    });

    test('nothing saved reads as null', () async {
      expect(await history.readingProgress('1000', 7), isNull);
    });

    test('saving again replaces the earlier progress', () async {
      await history.saveReadingProgress('1000', 7, _progress(250));
      final later = _progress(600, total: 1200, at: _day.add(const Duration(hours: 1)));
      await history.saveReadingProgress('1000', 7, later);

      _expectProgress(await history.readingProgress('1000', 7), later);
      expect((await history.readingProgressOf('1000', [7])).length, 1);
    });

    test('the accounts keep their own progress', () async {
      await history.saveReadingProgress('1000', 7, _progress(100));
      await history.saveReadingProgress('1001', 7, _progress(900));

      expect((await history.readingProgress('1000', 7))!.offset, 100);
      expect((await history.readingProgress('1001', 7))!.offset, 900);
      expect(await history.readingProgress('1002', 7), isNull);
    });

    test('readingProgressOf returns only the novels that have a stored progress', () async {
      await history.saveReadingProgress('1000', 1, _progress(10));
      await history.saveReadingProgress('1000', 2, _progress(20));
      await history.saveReadingProgress('1000', 3, _progress(30));
      await history.saveReadingProgress('1001', 4, _progress(40));

      final found = await history.readingProgressOf('1000', [2, 3, 4, 5]);

      expect(found.keys.toSet(), {2, 3});
      expect(found[2]!.offset, 20);
      expect(found[3]!.offset, 30);
    });

    test('readingProgressOf of no IDs is empty', () async {
      await history.saveReadingProgress('1000', 1, _progress(10));

      expect(await history.readingProgressOf('1000', const []), isEmpty);
    });
  });

  group('fraction and percent', () {
    test('a zero total is zero', () {
      final progress = _progress(0, total: 0);
      expect(progress.fraction, 0);
      expect(progress.percent, 0);
    });

    test('an offset past the total is the whole text', () {
      final progress = _progress(1500);
      expect(progress.fraction, 1);
      expect(progress.percent, 100);
    });

    test('the end is 100 and the start is 0', () {
      expect(_progress(1000).percent, 100);
      expect(_progress(0).percent, 0);
      expect(_progress(500).fraction, 0.5);
    });

    test('the percent is rounded down', () {
      expect(_progress(379).percent, 37);
      expect(_progress(999).percent, 99);
    });
  });

  group('removing', () {
    setUp(() async {
      await history.saveReadingProgress('1000', 1, _progress(100));
      await history.saveReadingProgress('1000', 2, _progress(200));
      await history.saveReadingProgress('1001', 1, _progress(300));
    });

    test('clearing an account removes its progress and no other account\'s', () async {
      await history.clear('1000');

      expect(await history.readingProgressOf('1000', [1, 2]), isEmpty);
      expect((await history.readingProgress('1001', 1))!.offset, 300);
    });

    test('removing a novel from the history removes that novel\'s progress only', () async {
      await history.remove('1000', HistoryWorkKind.novel, 1);

      expect(await history.readingProgress('1000', 1), isNull);
      expect((await history.readingProgress('1000', 2))!.offset, 200);
      expect((await history.readingProgress('1001', 1))!.offset, 300);
    });

    test('removing an illustration with the same ID keeps the novel\'s progress', () async {
      await history.remove('1000', HistoryWorkKind.illust, 1);

      expect((await history.readingProgress('1000', 1))!.offset, 100);
    });
  });

  test('pruning the history by its limit keeps the progress', () async {
    const limit = HistoryLimit.fiveHundred;
    await history.saveReadingProgress('1000', 0, _progress(10));
    for (var index = 0; index < limit.count + 2; index++) {
      await history.record('1000', _entry(index, _day.add(Duration(minutes: index))), limit: limit);
    }
    expect(await history.count('1000'), limit.count);
    expect((await history.list('1000', novels: true)).map((entry) => entry.workId), isNot(contains(0)), reason: 'the oldest entry went');

    expect((await history.readingProgress('1000', 0))!.offset, 10);

    await history.pruneAll(HistoryLimit.fiveHundred);
    expect((await history.readingProgress('1000', 0))!.offset, 10);
  });

  group('on disk', () {
    late Directory directory;

    setUp(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      directory = await Directory.systemTemp.createTemp('reading_progress_test');
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
    });

    test('progress saved before the database was closed is there after reopening', () async {
      final file = File(p.join(directory.path, 'history.sqlite'));
      final first = HistoryRepository(HistoryDatabase.withExecutor(NativeDatabase(file)));
      await first.saveReadingProgress('1000', 7, _progress(420, total: 900));
      await first.close();

      final second = HistoryRepository(HistoryDatabase.withExecutor(NativeDatabase(file)));
      addTearDown(second.close);
      _expectProgress(await second.readingProgress('1000', 7), _progress(420, total: 900));
    });

    test('a database of the first schema keeps its history and accepts progress', () async {
      final file = File(p.join(directory.path, 'old.sqlite'));
      final raw = sqlite.sqlite3.open(file.path);
      raw.execute('''
        CREATE TABLE history_records (
          account TEXT NOT NULL,
          kind TEXT NOT NULL,
          work_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          author_id INTEGER NOT NULL,
          author_name TEXT NOT NULL,
          thumbnail_url TEXT NOT NULL,
          x_restrict INTEGER NOT NULL,
          ai_generated INTEGER NOT NULL CHECK ("ai_generated" IN (0, 1)),
          viewed_at INTEGER NOT NULL,
          width INTEGER NULL,
          height INTEGER NULL,
          page_count INTEGER NULL,
          text_length INTEGER NULL,
          PRIMARY KEY (account, kind, work_id)
        )
      ''');
      raw.execute(
        'INSERT INTO history_records (account, kind, work_id, title, author_id, author_name, thumbnail_url, x_restrict, ai_generated, viewed_at, text_length) '
        "VALUES ('1000', 'novel', 5, 'Kept', 2000, 'Sample artist', '', 0, 0, ${_day.millisecondsSinceEpoch}, 9000)",
      );
      raw.execute('PRAGMA user_version = 1');
      raw.close();

      final upgraded = HistoryRepository(HistoryDatabase.withExecutor(NativeDatabase(file)));
      addTearDown(upgraded.close);

      final entries = await upgraded.list('1000', novels: true);
      expect(entries.map((entry) => entry.workId), [5]);
      expect(entries.single.title, 'Kept');
      expect(await upgraded.readingProgress('1000', 5), isNull);
      await upgraded.saveReadingProgress('1000', 5, _progress(300));
      _expectProgress(await upgraded.readingProgress('1000', 5), _progress(300));
      expect(await upgraded.count('1000'), 1);
    });
  });

  group('service', () {
    test('saving stamps the time, and loading returns what was saved for the current account', () async {
      final before = DateTime.now();
      await saveReadingProgress(7, offset: 300, totalLength: 1000);
      final after = DateTime.now();

      final loaded = await loadReadingProgress(7);
      expect(loaded, isNotNull);
      expect(loaded!.offset, 300);
      expect(loaded.totalLength, 1000);
      expect(loaded.percent, 30);
      // Stored in whole milliseconds.
      expect(loaded.updatedAt.millisecondsSinceEpoch, inInclusiveRange(before.millisecondsSinceEpoch - 1, after.millisecondsSinceEpoch));
      _expectProgress(await history.readingProgress('1000', 7), loaded);
    });

    test('progress is saved while history recording is off, and no history entry appears', () async {
      AppSettings.recordHistory = false;

      await saveReadingProgress(7, offset: 300, totalLength: 1000);

      expect((await loadReadingProgress(7))!.offset, 300);
      expect(await history.count('1000'), 0);
      expect(await history.list('1000', novels: true), isEmpty);
    });

    test('signed out saves nothing and loads null', () async {
      await saveReadingProgress(7, offset: 300, totalLength: 1000);
      AppSettings.accounts = AppSettings.accounts.deactivated();

      await saveReadingProgress(8, offset: 100, totalLength: 1000);

      expect(await loadReadingProgress(7), isNull);
      expect(await loadReadingProgress(8), isNull);
      expect(await history.readingProgress('1000', 8), isNull);
    });

    test('the accounts keep their own progress through the service', () async {
      await saveReadingProgress(7, offset: 300, totalLength: 1000);
      AppSettings.accounts = AppSettings.accounts.activate(sampleSecondAccount, DateTime.now());

      expect(await loadReadingProgress(7), isNull);
      await saveReadingProgress(7, offset: 800, totalLength: 1000);
      expect((await loadReadingProgress(7))!.offset, 800);
      expect((await history.readingProgress('1000', 7))!.offset, 300);
    });

    test('an unreadable history database does not fail saving or loading', () async {
      await history.close();

      await saveReadingProgress(7, offset: 300, totalLength: 1000);
      expect(await loadReadingProgress(7), isNull);
    });
  });
}
