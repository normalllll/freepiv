import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/downloads/download_database.dart' show DownloadDatabase;
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/downloads/download_store.dart';
import 'package:sqlite3/sqlite3.dart';

/// The download tables as schema version 4 created them.
const _version4 = [
  '''
  CREATE TABLE download_jobs (
    id TEXT NOT NULL, illust_id INTEGER NOT NULL, page_index INTEGER NOT NULL DEFAULT 0,
    url TEXT NOT NULL, filename TEXT NOT NULL, headers_json TEXT NOT NULL DEFAULT '{}',
    network_options_json TEXT NOT NULL DEFAULT '{}', validation_json TEXT NOT NULL DEFAULT '{}',
    save_target_json TEXT NOT NULL DEFAULT '{}', thumbnail_url TEXT, title TEXT,
    created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, PRIMARY KEY (id))
  ''',
  '''
  CREATE TABLE download_states (
    job_id TEXT NOT NULL REFERENCES download_jobs (id) ON DELETE CASCADE, status TEXT NOT NULL,
    save_state TEXT NOT NULL, received_bytes INTEGER NOT NULL DEFAULT 0, total_bytes INTEGER,
    progress REAL NOT NULL DEFAULT 0, local_path TEXT, gallery_asset_id TEXT, error TEXT, log TEXT,
    updated_at INTEGER NOT NULL, PRIMARY KEY (job_id))
  ''',
];

void _createVersion4(Database db) {
  _version4.forEach(db.execute);
  db.execute(
    "INSERT INTO download_jobs (id, illust_id, page_index, url, filename, created_at, updated_at) "
    "VALUES ('illust_7_page_1', 7, 1, 'https://i.pximg.net/img-original/img/7_p1.png', '7_p1.png', 1, 1)",
  );
  db.execute("INSERT INTO download_states (job_id, status, save_state, progress, updated_at) VALUES ('illust_7_page_1', 'downloaded', 'saved', 1, 1)");
  db.userVersion = 4;
}

void main() {
  test('upgrading keeps existing history and then stores content images', () async {
    final store = DriftDownloadStore(DownloadDatabase.withExecutor(NativeDatabase.memory(setup: _createVersion4)));
    addTearDown(store.close);

    final [kept] = await store.listTasks();
    expect(kept.origin, const ArtworkPage(illustId: 7, pageIndex: 1));
    expect(kept.saveState, SaveState.saved);

    final image = Uri.parse('https://i.pximg.net/imgaz/upload/article.jpg');
    final job = DownloadJob.create(origin: ContentImage(image), url: image, saveTarget: const SaveTarget.downloadsFolder());
    await store.upsertJob(job);

    expect((await store.getJob(job.id))?.origin, ContentImage(image));
    expect((await store.listTasks()).map((task) => task.origin), containsAll([const ArtworkPage(illustId: 7, pageIndex: 1), ContentImage(image)]));
    expect(await store.listTasks(illustId: 7), hasLength(1), reason: 'content images never match a work');
  });

  test('a database that cannot be upgraded is cleared instead of blocking downloads', () async {
    // Version 4 in name only: the jobs table lacks columns the upgrade copies.
    final store = DriftDownloadStore(
      DownloadDatabase.withExecutor(
        NativeDatabase.memory(
          setup: (db) {
            db.execute('CREATE TABLE download_jobs (id TEXT NOT NULL PRIMARY KEY)');
            db.execute("INSERT INTO download_jobs (id) VALUES ('broken')");
            db.execute('CREATE TABLE download_states (job_id TEXT NOT NULL PRIMARY KEY)');
            db.userVersion = 4;
          },
        ),
      ),
    );
    addTearDown(store.close);

    expect(await store.listTasks(), isEmpty);
    final url = Uri.parse('https://i.pximg.net/img-original/img/9_p0.png');
    await store.upsertJob(DownloadJob.create(origin: const ArtworkPage(illustId: 9, pageIndex: 0), url: url, saveTarget: const SaveTarget.downloadsFolder()));
    expect(await store.listTasks(illustId: 9), hasLength(1));
  });
}
