import 'package:drift/drift.dart';

import 'history_database.dart';
import 'history_models.dart';

/// The browsing history of every account, kept on this device. Each account
/// has its own entries and its own limit applies to them.
class HistoryRepository {
  HistoryRepository(this._db);

  /// The repository on the app's own database file.
  factory HistoryRepository.open() => HistoryRepository(HistoryDatabase());

  final HistoryDatabase _db;

  Future<void> close() => _db.close();

  /// Remembers [entry] for [account], replacing what an earlier view of the
  /// same work kept, then drops the account's oldest entries beyond [limit].
  Future<void> record(String account, HistoryEntry entry, {required HistoryLimit limit}) async {
    await _db.transaction(() async {
      await _db
          .into(_db.historyRecords)
          .insertOnConflictUpdate(
            HistoryRecordsCompanion.insert(
              account: account,
              kind: entry.kind,
              workId: entry.workId,
              title: entry.title,
              authorId: entry.authorId,
              authorName: entry.authorName,
              thumbnailUrl: entry.thumbnailUrl,
              xRestrict: entry.xRestrict,
              aiGenerated: entry.aiGenerated,
              viewedAt: entry.viewedAt.millisecondsSinceEpoch,
              width: Value(entry.width),
              height: Value(entry.height),
              pageCount: Value(entry.pageCount),
              textLength: Value(entry.textLength),
            ),
          );
      await _prune(account, limit);
    });
  }

  /// [account]'s illustrations and manga, or its novels, the last viewed first.
  Future<List<HistoryEntry>> list(String account, {required bool novels}) async {
    final query = _db.select(_db.historyRecords)
      ..where((row) => row.account.equals(account) & (novels ? row.kind.equalsValue(HistoryWorkKind.novel) : row.kind.equalsValue(HistoryWorkKind.novel).not()))
      ..orderBy([(row) => OrderingTerm.desc(row.viewedAt), (row) => OrderingTerm.desc(row.workId)]);
    return [for (final row in await query.get()) _entry(row)];
  }

  Future<int> count(String account) async {
    final count = _db.historyRecords.workId.count();
    final query = _db.selectOnly(_db.historyRecords)
      ..addColumns([count])
      ..where(_db.historyRecords.account.equals(account));
    return await query.map((row) => row.read(count)).getSingle() ?? 0;
  }

  /// How many entries, over every account, a lower [limit] would delete.
  Future<int> countBeyond(HistoryLimit limit) async {
    final account = _db.historyRecords.account;
    final count = _db.historyRecords.workId.count();
    final query = _db.selectOnly(_db.historyRecords)
      ..addColumns([account, count])
      ..groupBy([account]);
    var beyond = 0;
    for (final row in await query.get()) {
      final over = (row.read(count) ?? 0) - limit.count;
      if (over > 0) beyond += over;
    }
    return beyond;
  }

  /// Applies [limit] to every account at once.
  Future<void> pruneAll(HistoryLimit limit) async {
    final accounts = await (_db.selectOnly(
      _db.historyRecords,
      distinct: true,
    )..addColumns([_db.historyRecords.account])).map((row) => row.read(_db.historyRecords.account)!).get();
    await _db.transaction(() async {
      for (final account in accounts) {
        await _prune(account, limit);
      }
    });
  }

  Future<void> remove(String account, HistoryWorkKind kind, int workId) async {
    await (_db.delete(_db.historyRecords)..where((row) => row.account.equals(account) & row.kind.equalsValue(kind) & row.workId.equals(workId))).go();
  }

  /// Forgets everything [account] has viewed.
  Future<void> clear(String account) async {
    await (_db.delete(_db.historyRecords)..where((row) => row.account.equals(account))).go();
  }

  Future<void> _prune(String account, HistoryLimit limit) async {
    await _db.customUpdate(
      'DELETE FROM history_records WHERE account = ?1 AND rowid NOT IN ('
      'SELECT rowid FROM history_records WHERE account = ?1 ORDER BY viewed_at DESC, work_id DESC LIMIT ?2)',
      variables: [Variable<String>(account), Variable<int>(limit.count)],
      updates: {_db.historyRecords},
    );
  }

  HistoryEntry _entry(HistoryRow row) => HistoryEntry(
    kind: row.kind,
    workId: row.workId,
    title: row.title,
    authorId: row.authorId,
    authorName: row.authorName,
    thumbnailUrl: row.thumbnailUrl,
    xRestrict: row.xRestrict,
    aiGenerated: row.aiGenerated,
    viewedAt: DateTime.fromMillisecondsSinceEpoch(row.viewedAt),
    width: row.width,
    height: row.height,
    pageCount: row.pageCount,
    textLength: row.textLength,
  );
}
