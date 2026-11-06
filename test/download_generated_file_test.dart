import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/downloads/default_download_manager.dart';
import 'package:freepiv/core/downloads/download_engine.dart';
import 'package:freepiv/core/downloads/download_manager_configuration.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/downloads/download_permission_guard.dart';
import 'package:freepiv/core/downloads/download_store.dart';
import 'package:freepiv/core/downloads/media_saver.dart';

/// Records what the manager writes about each task.
class _RecordingStore implements DownloadStore {
  final events = <String>[];
  DownloadJob? job;

  @override
  Future<void> upsertJob(DownloadJob job) async {
    this.job = job;
    events.add('job ${job.id} ${job.filename}');
  }

  @override
  Future<void> updateStatus(String jobId, DownloadStatus status, {String? error}) async => events.add('status ${status.name}');

  @override
  Future<void> updateProgress(String jobId, {int? receivedBytes, int? totalBytes, double? progress}) async => events.add('progress $progress');

  @override
  Future<void> updateSaveState(String jobId, SaveState state, {String? localPath, String? galleryAssetId, String? error}) async =>
      events.add('save ${state.name}');

  @override
  Future<void> appendLog(String jobId, String message) async => events.add('log');

  @override
  Future<List<DownloadTaskSnapshot>> listTasks({int? illustId, DownloadStatus? status, SaveState? saveState}) async => [];

  @override
  Future<List<DownloadTaskSnapshot>> listRecoverableTasks() async => [];

  @override
  Future<List<DownloadTaskSnapshot>> listPendingSaveTasks() async => [];

  @override
  Future<DownloadTaskSnapshot?> getTask(String jobId) async => null;

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
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

class _Saver implements MediaSaver {
  final saved = <String>[];

  @override
  Future<SaveResult> saveBytes({required DownloadJob job, required Uint8List bytes}) async {
    saved.add(job.filename);
    return SaveResult(path: 'out/${job.filename}', bytesWritten: bytes.length);
  }

  @override
  Future<SaveResult> saveDownloadedFile({required DownloadJob job, required DownloadedFile file}) => throw UnimplementedError();
}

int _one() => 1;

void main() {
  late _RecordingStore store;
  late _Saver saver;
  late DefaultDownloadManager manager;
  final zip = Uri.parse('https://i.pximg.net/img-zip-ugoira/img/1/2_ugoira600x600.zip');

  setUp(() async {
    store = _RecordingStore();
    saver = _Saver();
    manager = DefaultDownloadManager(
      configuration: const DownloadManagerConfiguration(maxConcurrentDownloads: _one),
      store: store,
      engine: _IdleEngine(),
      mediaSaver: saver,
      permissionGuard: _Ready(),
    );
    await manager.initialize();
  });
  tearDown(() => manager.dispose());

  test('a GIF is a download task from the start, with its progress, then saved', () async {
    final file = await manager.saveGenerated(
      origin: ContentFile.of(zip.replace(path: '${zip.path}.gif')),
      source: const ArtworkSource(illustId: 2, title: 'Animation'),
      sourceUrl: zip,
      filename: '2.gif',
      generate: (onProgress) async {
        // The task exists and runs before the frames are composed.
        expect(store.events, ['job ${store.job!.id} 2.gif', 'status running']);
        onProgress(.5);
        await Future<void>.delayed(Duration.zero);
        return Uint8List.fromList([71, 73, 70]);
      },
    );
    expect(file.path, 'out/2.gif');
    expect(saver.saved, ['2.gif']);
    expect(store.events, containsAllInOrder(['status running', 'progress 0.5', 'progress 1.0', 'status downloaded', 'save saving', 'save saved']));
    expect(store.job!.source, isA<ArtworkSource>(), reason: 'it stays a task of the work');
    expect(store.job!.id, isNot('illust_2_page_0'), reason: 'it is not the work\'s first page');
  });

  test('a GIF that cannot be composed is a failed task with a log', () async {
    await expectLater(
      manager.saveGenerated(
        origin: ContentFile.of(zip.replace(path: '${zip.path}.gif')),
        source: const ArtworkSource(illustId: 2, title: 'Animation'),
        sourceUrl: zip,
        filename: '2.gif',
        generate: (_) async => throw StateError('frames unavailable'),
      ),
      throwsStateError,
    );
    expect(store.events, containsAllInOrder(['status running', 'log', 'status failed']));
    expect(saver.saved, isEmpty);
  });
}

class _Ready implements DownloadPermissionGuard {
  @override
  Future<void> ensureReadyForDownload() async {}
}
