import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models/download_source.dart';

part 'download_database.g.dart';

class DownloadJobs extends Table {
  TextColumn get id => text()();

  /// The work page downloaded; both null for a content image (see
  /// DownloadOrigin), which is identified by its [url].
  IntColumn get illustId => integer().nullable()();
  IntColumn get pageIndex => integer().nullable()();
  TextColumn get url => text()();
  TextColumn get filename => text()();
  TextColumn get headersJson => text().withDefault(const Constant('{}'))();
  TextColumn get networkOptionsJson => text().withDefault(const Constant('{}'))();
  TextColumn get validationJson => text().withDefault(const Constant('{}'))();
  TextColumn get saveTargetJson => text().withDefault(const Constant('{}'))();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get title => text().nullable()();

  /// The source the file was downloaded from (see DownloadSource): its kind,
  /// its id within the kind, and its label when downloaded.
  TextColumn get sourceKind => text()();
  TextColumn get sourceId => text()();
  TextColumn get sourceTitle => text().nullable()();
  TextColumn get sourceSubtitle => text().nullable()();
  TextColumn get sourceThumbnailUrl => text().nullable()();

  /// The page a source opens where it is not derived from its id.
  TextColumn get sourceUrl => text().nullable()();

  /// The part of the source the file belongs to, if the source has parts.
  TextColumn get partId => text().nullable()();
  TextColumn get partTitle => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DownloadStates extends Table {
  TextColumn get jobId => text().references(DownloadJobs, #id, onDelete: KeyAction.cascade)();
  TextColumn get status => text()();
  TextColumn get saveState => text()();
  IntColumn get receivedBytes => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  TextColumn get localPath => text().nullable()();
  TextColumn get galleryAssetId => text().nullable()();
  TextColumn get error => text().nullable()();
  TextColumn get log => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {jobId};
}

@DriftDatabase(tables: [DownloadJobs, DownloadStates])
class DownloadDatabase extends _$DownloadDatabase {
  DownloadDatabase() : super(_openConnection());

  /// Opens [executor] instead of the app's database file, e.g. in memory.
  DownloadDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        try {
          await _upgrade(migrator, from);
        } catch (_) {
          // Download history is a convenience record; a database that cannot
          // be carried forward is cleared rather than blocking downloads.
          await _reset(migrator);
        }
      },
    );
  }

  Future<void> _upgrade(Migrator migrator, int from) async {
    if (from < 2) {
      await migrator.addColumn(downloadJobs, downloadJobs.pageIndex);
    }
    if (from < 3) {
      await migrator.addColumn(downloadStates, downloadStates.log);
    }
    if (from < 4) {
      await migrator.addColumn(downloadJobs, downloadJobs.networkOptionsJson);
      await migrator.addColumn(downloadJobs, downloadJobs.validationJson);
    }
    if (from < 6) {
      // Rebuilding the table copies every row: the work columns became
      // nullable for content images (v5), and each row gains its source (v6),
      // known only for work pages; any other file stands alone.
      final isWorkPage = downloadJobs.illustId.isNotNull() & downloadJobs.pageIndex.isNotNull();
      await migrator.alterTable(
        TableMigration(
          downloadJobs,
          newColumns: [
            downloadJobs.sourceKind,
            downloadJobs.sourceId,
            downloadJobs.sourceTitle,
            downloadJobs.sourceSubtitle,
            downloadJobs.sourceThumbnailUrl,
            downloadJobs.sourceUrl,
            downloadJobs.partId,
            downloadJobs.partTitle,
          ],
          columnTransformer: {
            downloadJobs.sourceKind: CaseWhenExpression(
              cases: [CaseWhen(isWorkPage, then: Constant(DownloadSourceKind.artwork.name))],
              orElse: Constant(DownloadSourceKind.standalone.name),
            ),
            downloadJobs.sourceId: CaseWhenExpression(
              cases: [CaseWhen(isWorkPage, then: downloadJobs.illustId.cast<String>())],
              orElse: downloadJobs.id,
            ),
            downloadJobs.sourceTitle: CaseWhenExpression(
              cases: [CaseWhen(isWorkPage, then: downloadJobs.title)],
              orElse: coalesce([downloadJobs.title, downloadJobs.filename]),
            ),
            downloadJobs.sourceSubtitle: const Constant<String>(null),
            downloadJobs.sourceThumbnailUrl: downloadJobs.thumbnailUrl,
            downloadJobs.sourceUrl: const Constant<String>(null),
            downloadJobs.partId: const Constant<String>(null),
            downloadJobs.partTitle: const Constant<String>(null),
          },
        ),
      );
    }
  }

  Future<void> _reset(Migrator migrator) async {
    for (final table in allTables.toList().reversed) {
      await migrator.deleteTable(table.actualTableName);
    }
    await migrator.createAll();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final directory = Directory(p.join(supportDirectory.path, 'freepiv'));
    await directory.create(recursive: true);
    return NativeDatabase.createInBackground(File(p.join(directory.path, 'downloads.sqlite')));
  });
}
