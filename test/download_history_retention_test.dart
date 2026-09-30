import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/downloads/default_download_manager.dart';
import 'package:freepiv/core/downloads/download_engine.dart';
import 'package:freepiv/core/downloads/download_manager_configuration.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/downloads/download_permission_guard.dart';
import 'package:freepiv/core/downloads/download_store.dart';
import 'package:freepiv/core/downloads/media_saver.dart';

class _RetainedStore implements DownloadStore {
  int deleteCount = 0;

  final completed = DownloadTaskSnapshot(
    id: 'illust_7_page_0',
    origin: const ArtworkPage(illustId: 7, pageIndex: 0),
    source: const ArtworkSource(illustId: 7, title: 'Saved work'),
    title: 'Saved work',
    filename: 'saved.png',
    status: DownloadStatus.downloaded,
    saveState: SaveState.saved,
    receivedBytes: 100,
    totalBytes: 100,
    progress: 1,
    localPath: 'saved.png',
    error: null,
    log: null,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  @override
  Future<List<DownloadTaskSnapshot>> listTasks({int? illustId, DownloadStatus? status, SaveState? saveState}) async =>
      (status == null || status == completed.status) && (saveState == null || saveState == completed.saveState) ? [completed] : [];

  @override
  Future<List<DownloadTaskSnapshot>> listRecoverableTasks() async => [];

  @override
  Future<List<DownloadTaskSnapshot>> listPendingSaveTasks() async => [];

  @override
  Future<void> deleteTask(String jobId) async => deleteCount++;

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IdleEngine implements DownloadEngine {
  @override
  DownloadEngineType get type => DownloadEngineType.desktopRust;

  @override
  Stream<DownloadEngineEvent> get events => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<List<DownloadEngineSnapshot>> syncActiveTasks() async => [];

  @override
  Future<void> acknowledge(Set<String> jobIds) async {}

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('completed download history remains available after manager startup', () async {
    final store = _RetainedStore();
    final manager = DefaultDownloadManager(
      configuration: const DownloadManagerConfiguration(maxConcurrentDownloads: _one),
      store: store,
      engine: _IdleEngine(),
      mediaSaver: const UnsupportedMediaSaver(),
      permissionGuard: const DesktopDownloadPermissionGuard(),
    );
    await manager.initialize();
    expect((await manager.listTasks()).single.id, store.completed.id);
    expect(store.deleteCount, 0);
    await manager.dispose();
  });
}

int _one() => 1;
