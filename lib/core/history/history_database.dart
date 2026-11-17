import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../services/app_storage.dart';
import 'history_models.dart';

part 'history_database.g.dart';

/// The works each account has viewed, as they were when last viewed.
@DataClassName('HistoryRow')
class HistoryRecords extends Table {
  /// The account's ID in the account book.
  TextColumn get account => text()();
  TextColumn get kind => textEnum<HistoryWorkKind>()();
  IntColumn get workId => integer()();
  TextColumn get title => text()();
  IntColumn get authorId => integer()();
  TextColumn get authorName => text()();
  TextColumn get thumbnailUrl => text()();
  IntColumn get xRestrict => integer()();
  BoolColumn get aiGenerated => boolean()();
  IntColumn get viewedAt => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get pageCount => integer().nullable()();
  IntColumn get textLength => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {account, kind, workId};
}

/// Where each account stopped reading each novel.
@DataClassName('ReadingProgressRow')
class ReadingProgressRecords extends Table {
  /// The account's ID in the account book.
  TextColumn get account => text()();
  IntColumn get novelId => integer()();

  /// Character offset in the parsed text.
  IntColumn get offset => integer()();

  /// The parsed text's length when the offset was saved.
  IntColumn get totalLength => integer()();

  /// Milliseconds since the epoch, UTC.
  IntColumn get updatedAt => integer()();

  /// How far the reading line sat inside its line, as a share of the line's
  /// height: 0 up to, not including, 1.
  RealColumn get depth => real().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {account, novelId};
}

@DriftDatabase(tables: [HistoryRecords, ReadingProgressRecords])
class HistoryDatabase extends _$HistoryDatabase {
  HistoryDatabase() : super(_openConnection());

  /// The database in [file], which is deleted and created again when it
  /// cannot be opened or migrated; a second failure is thrown to the first
  /// caller that uses the database.
  HistoryDatabase.atFile(File file) : super(LazyDatabase(() => _openFile(file)));

  /// Opens [executor] instead of the app's database file, e.g. in memory.
  HistoryDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(readingProgressRecords);
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await appSupportDirectory();
    await directory.create(recursive: true);
    return _openFile(File(p.join(directory.path, 'history.sqlite')));
  });
}

/// Opens [file], first checking on a probe connection that it opens and
/// migrates. A file that does not is deleted and tried once more, losing its
/// history, which is a convenience; the next failure is thrown.
Future<QueryExecutor> _openFile(File file) async {
  for (var attempt = 0; ; attempt++) {
    try {
      final probe = HistoryDatabase.withExecutor(NativeDatabase(file));
      try {
        await probe.customSelect('SELECT 1').get();
      } finally {
        await probe.close();
      }
      return NativeDatabase.createInBackground(file);
    } catch (_) {
      if (attempt > 0) rethrow;
      for (final path in [file.path, '${file.path}-wal', '${file.path}-shm', '${file.path}-journal']) {
        final stale = File(path);
        if (stale.existsSync()) stale.deleteSync();
      }
    }
  }
}
