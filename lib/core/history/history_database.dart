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

@DriftDatabase(tables: [HistoryRecords])
class HistoryDatabase extends _$HistoryDatabase {
  HistoryDatabase() : super(_openConnection());

  /// Opens [executor] instead of the app's database file, e.g. in memory.
  HistoryDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await appSupportDirectory();
    await directory.create(recursive: true);
    return NativeDatabase.createInBackground(File(p.join(directory.path, 'history.sqlite')));
  });
}
