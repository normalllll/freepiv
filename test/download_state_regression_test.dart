import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/downloads/default_download_manager.dart';
import 'package:freepiv/core/downloads/download_database.dart' hide DownloadJob;
import 'package:freepiv/core/downloads/download_engine.dart';
import 'package:freepiv/core/downloads/download_file_system.dart';
import 'package:freepiv/core/downloads/download_manager_configuration.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/downloads/download_permission_guard.dart';
import 'package:freepiv/core/downloads/download_store.dart';
import 'package:freepiv/core/downloads/media_saver.dart';
import 'package:freepiv/core/downloads/platform/native_download_engine.dart';
import 'package:freepiv/core/downloads/platform/rust_io_download_engine.dart';
import 'package:path/path.dart' as p;

class _Engine extends Fake implements DownloadEngine {
  _Engine(this.files);

  final Directory files;
  final changes = StreamController<DownloadEngineEvent>.broadcast();
  final running = <String>{};
  final acknowledged = <String>{};
  Set<String>? kept;
  bool failAcknowledge = false;

  @override
  DownloadEngineType get type => DownloadEngineType.desktopRust;
  @override
  DownloadCapabilities get capabilities => const DownloadCapabilities(
    supportsBackground: false,
    supportsCancel: true,
    supportsPauseResume: false,
    handlesSaving: false,
    supportsHeaders: true,
    supportsProxy: true,
    supportsHostOverride: true,
    supportsCertificateBypass: true,
    supportsValidation: true,
  );
  @override
  Stream<DownloadEngineEvent> get events => changes.stream;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> acknowledge(Set<String> jobIds) async {
    if (failAcknowledge) throw StateError('acknowledge failed');
    acknowledged.addAll(jobIds);
  }

  @override
  Future<void> removeLeftovers(Set<String> keepPaths) async => kept = keepPaths;
  @override
  Future<void> dispose() => changes.close();
  @override
  Future<List<DownloadEngineSnapshot>> syncActiveTasks() async => [
    for (final id in running)
      DownloadEngineSnapshot(jobId: id, status: DownloadStatus.running, saveState: SaveState.none, receivedBytes: 1, totalBytes: 10, progress: .1),
  ];
  @override
  Future<void> start(List<DownloadJob> jobs) async => running.addAll(jobs.map((job) => job.id));
  @override
  Future<void> cancel(String jobId) async {
    if (running.remove(jobId)) changes.add(EngineCancelledEvent(jobId: jobId));
  }

  void complete(String id) {
    running.remove(id);
    final file = File(p.join(files.path, id))..writeAsStringSync('x');
    changes.add(EngineCompletedEvent(jobId: id, localPath: file.path, bytesWritten: 10));
  }

  void progress(String id, double value) => changes.add(EngineProgressEvent(jobId: id, receivedBytes: 5, totalBytes: 10, progress: value));
}

class _Saver implements MediaSaver {
  final holds = <String, Completer<void>>{};
  final saved = <String>[];

  @override
  Future<SaveResult> saveDownloadedFile({required DownloadJob job, required DownloadedFile file}) async {
    saved.add(job.id);
    await holds[job.id]?.future;
    return SaveResult(path: '/saved/${job.id}', bytesWritten: 10);
  }

  @override
  Future<SaveResult> saveBytes({required DownloadJob job, required Uint8List bytes}) async {
    saved.add(job.id);
    return SaveResult(path: '/saved/${job.id}', bytesWritten: bytes.length);
  }
}

class _Ready implements DownloadPermissionGuard {
  @override
  Future<void> ensureReadyForDownload() async {}
}

Future<void> _settle([int milliseconds = 150]) => Future<void>.delayed(Duration(milliseconds: milliseconds));

DownloadJob _job(int id) => DownloadJob.create(
  origin: ArtworkPage(illustId: id, pageIndex: 0),
  source: ArtworkSource(illustId: id, title: '$id'),
  url: Uri.parse('https://i.pximg.net/$id.png'),
  filename: '$id.png',
  saveTarget: const SaveTarget.downloadsFolder(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late DriftDownloadStore store;
  late _Engine engine;
  late _Saver saver;
  DefaultDownloadManager? manager;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('freepiv-downloads-');
    store = DriftDownloadStore(DownloadDatabase.withExecutor(NativeDatabase.memory()));
    engine = _Engine(root);
    saver = _Saver();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => root.path,
    );
  });

  tearDown(() async {
    for (final hold in saver.holds.values) {
      if (!hold.isCompleted) hold.complete();
    }
    await _settle();
    await manager?.dispose();
    manager = null;
    await store.close();
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // A locked file in the temp folder must not decide the test.
    }
  });

  Future<void> make(int slots, {DownloadSessionHeaders? headers}) async {
    final created = DefaultDownloadManager(
      configuration: headers == null
          ? DownloadManagerConfiguration(maxConcurrentDownloads: () => slots)
          : DownloadManagerConfiguration(maxConcurrentDownloads: () => slots, sessionHeaders: headers),
      store: store,
      engine: engine,
      mediaSaver: saver,
      permissionGuard: _Ready(),
    );
    manager = created;
    await created.initialize();
  }

  Future<DownloadStatus?> status(DownloadJob job) async => (await store.getTask(job.id))?.status;

  group('saving', () {
    test('a long save does not hold up the progress of other tasks', () async {
      await make(2);
      final first = _job(1), second = _job(2);
      await manager!.enqueue([first, second]);
      saver.holds[first.id] = Completer<void>();
      engine.complete(first.id);
      await _settle();
      engine.progress(second.id, .5);
      await _settle();
      expect((await store.getTask(second.id))?.progress, .5);
    });

    test('a long save does not hold up the queue', () async {
      await make(1);
      final first = _job(1), second = _job(2);
      await manager!.enqueue([first, second]);
      saver.holds[first.id] = Completer<void>();
      engine.complete(first.id);
      await _settle();
      expect(engine.running, contains(second.id));
    });

    test('saves run one at a time', () async {
      await make(2);
      final first = _job(1), second = _job(2);
      await manager!.enqueue([first, second]);
      final hold = saver.holds[first.id] = Completer<void>();
      engine.complete(first.id);
      engine.complete(second.id);
      await _settle();
      expect(saver.saved, [first.id]);
      hold.complete();
      await _settle();
      expect(saver.saved, [first.id, second.id]);
    });

    test('a sync during a save does not save the file a second time', () async {
      await make(1);
      final only = _job(1);
      await manager!.enqueue([only]);
      final hold = saver.holds[only.id] = Completer<void>();
      engine.complete(only.id);
      await _settle();
      await manager!.sync();
      hold.complete();
      await _settle();
      expect(saver.saved, [only.id]);
      expect((await store.getTask(only.id))?.saveState, SaveState.saved);
    });

    test('pressing retry twice saves the file once', () async {
      final only = _job(1);
      await store.upsertJob(only);
      await store.updateStatus(only.id, DownloadStatus.downloaded);
      final file = File(p.join(root.path, 'kept'))..writeAsStringSync('x');
      await store.updateSaveState(only.id, SaveState.failed, localPath: file.path);
      await make(1);
      final hold = saver.holds[only.id] = Completer<void>();
      final retries = [manager!.retrySave(only.id), manager!.retrySave(only.id)];
      await _settle();
      hold.complete();
      await Future.wait(retries);
      expect(saver.saved, [only.id]);
    });

    test('a task deleted while its save waits is not saved', () async {
      await make(2);
      final first = _job(1), second = _job(2);
      await manager!.enqueue([first, second]);
      final hold = saver.holds[first.id] = Completer<void>();
      engine.complete(first.id);
      engine.complete(second.id);
      await _settle();
      await manager!.deleteTask(second.id);
      hold.complete();
      await _settle();
      expect(saver.saved, [first.id]);
    });

    test('saved bytes wait for the save before them', () async {
      await make(1);
      final first = _job(1);
      await manager!.enqueue([first]);
      final hold = saver.holds[first.id] = Completer<void>();
      engine.complete(first.id);
      await _settle();
      final saving = manager!.saveBytes(
        origin: const ArtworkPage(illustId: 9, pageIndex: 0),
        source: const ArtworkSource(illustId: 9, title: '9'),
        bytes: Uint8List(3),
        sourceUrl: Uri.parse('https://i.pximg.net/9.png'),
        filename: '9.png',
      );
      await _settle();
      expect(saver.saved, [first.id]);
      hold.complete();
      expect((await saving).path, '/saved/illust_9_page_0');
    });

    test('a failed release does not undo a save', () async {
      final uncaught = <Object>[];
      final only = _job(1);
      await runZonedGuarded(() async {
        await make(1);
        await manager!.enqueue([only]);
      }, (error, _) => uncaught.add(error));
      engine.failAcknowledge = true;
      engine.complete(only.id);
      await _settle();
      engine.failAcknowledge = false;
      expect((await store.getTask(only.id))?.saveState, SaveState.saved);
      expect(uncaught, hasLength(1));
    });

    test('a saved task releases its temporary files', () async {
      await make(1);
      final only = _job(1);
      await manager!.enqueue([only]);
      engine.complete(only.id);
      await _settle();
      expect((await store.getTask(only.id))?.saveState, SaveState.saved);
      expect(engine.acknowledged, contains(only.id));
    });

    test('a task whose save failed keeps its temporary files to retry', () async {
      final failing = _FailingSaver();
      final created = DefaultDownloadManager(
        configuration: DownloadManagerConfiguration(maxConcurrentDownloads: () => 1),
        store: store,
        engine: engine,
        mediaSaver: failing,
        permissionGuard: _Ready(),
      );
      manager = created;
      await created.initialize();
      final only = _job(1);
      await created.enqueue([only]);
      engine.complete(only.id);
      await _settle();
      expect((await store.getTask(only.id))?.saveState, SaveState.failed);
      expect(engine.acknowledged, isNot(contains(only.id)));
    });

    test('dispose waits for the save under way and leaves the others to the next launch', () async {
      await make(2);
      final first = _job(1), second = _job(2);
      await manager!.enqueue([first, second]);
      final hold = saver.holds[first.id] = Completer<void>();
      engine.complete(first.id);
      engine.complete(second.id);
      await _settle();
      var disposed = false;
      final disposing = manager!.dispose().whenComplete(() => disposed = true);
      manager = null;
      await _settle();
      expect(disposed, isFalse);
      hold.complete();
      await disposing;
      expect((await store.getTask(first.id))?.saveState, SaveState.saved);
      expect((await store.getTask(second.id))?.saveState, SaveState.pending);
      expect(saver.saved, [first.id]);
    });
  });

  group('sync', () {
    test('leaves a finished task alone while its event waits', () async {
      await make(2);
      final first = _job(1), second = _job(2);
      await manager!.enqueue([first, second]);
      final hold = saver.holds[first.id] = Completer<void>();
      engine.complete(first.id);
      engine.complete(second.id);
      await _settle();
      await manager!.sync();
      hold.complete();
      await _settle(300);
      final task = await store.getTask(second.id);
      expect(task?.status, DownloadStatus.downloaded, reason: 'error: ${task?.error}');
      expect(task?.saveState, SaveState.saved);
    });

    test('leaves a task alone while it is starting', () async {
      final gate = Completer<void>();
      await make(
        1,
        headers: (_) async {
          await gate.future;
          return const {};
        },
      );
      final only = _job(1);
      unawaited(manager!.enqueue([only]));
      await _settle();
      await manager!.sync();
      expect(await status(only), DownloadStatus.running);
      gate.complete();
      await _settle();
      expect(engine.running, contains(only.id));
    });

    test('launch still fails a running row left by the old process', () async {
      final stale = _job(1);
      await store.upsertJob(stale);
      await store.updateStatus(stale.id, DownloadStatus.running);
      await make(1);
      expect(await status(stale), DownloadStatus.failed);
    });

    test('launch still finishes a save left by the old process', () async {
      final waiting = _job(1);
      await store.upsertJob(waiting);
      await store.updateStatus(waiting.id, DownloadStatus.downloaded);
      final file = File(p.join(root.path, 'left'))..writeAsStringSync('x');
      await store.updateSaveState(waiting.id, SaveState.saving, localPath: file.path);
      await make(1);
      await _settle();
      expect(saver.saved, [waiting.id]);
      expect((await store.getTask(waiting.id))?.saveState, SaveState.saved);
    });

    test('a save left by the old process holds up neither launch nor the queue', () async {
      final waiting = _job(1), queued = _job(2);
      await store.upsertJob(waiting);
      await store.updateStatus(waiting.id, DownloadStatus.downloaded);
      final file = File(p.join(root.path, 'left'))..writeAsStringSync('x');
      await store.updateSaveState(waiting.id, SaveState.saving, localPath: file.path);
      await store.upsertJob(queued);
      saver.holds[waiting.id] = Completer<void>();
      await make(1).timeout(const Duration(seconds: 5));
      expect(engine.running, contains(queued.id));
    });

    test('does not write a transfer snapshot over a finished task', () async {
      await make(1);
      final only = _job(1);
      await manager!.enqueue([only]);
      await store.updateStatus(only.id, DownloadStatus.downloaded);
      await store.updateSaveState(only.id, SaveState.saved, localPath: '/d/x');
      expect(engine.running, contains(only.id), reason: 'the engine still reports it');
      await manager!.sync();
      expect(await status(only), DownloadStatus.downloaded);
      expect((await store.getTask(only.id))?.saveState, SaveState.saved);
    });

    test('launch keeps only the files of saves still to finish or retry', () async {
      final waiting = _job(1), retry = _job(2), done = _job(3);
      for (final job in [waiting, retry, done]) {
        await store.upsertJob(job);
        await store.updateStatus(job.id, DownloadStatus.downloaded);
      }
      await store.updateSaveState(waiting.id, SaveState.saving, localPath: '/t/w');
      await store.updateSaveState(retry.id, SaveState.failed, localPath: '/t/r');
      await store.updateSaveState(done.id, SaveState.saved, localPath: '/d/x');
      await make(1);
      expect(engine.kept, unorderedEquals(['/t/w', '/t/r']));
    });
  });

  group('a task on its way to the engine', () {
    late Completer<void> gate;
    late DownloadJob only;

    setUp(() async {
      gate = Completer<void>();
      await make(
        1,
        headers: (_) async {
          await gate.future;
          return const {};
        },
      );
      only = _job(1);
      unawaited(manager!.enqueue([only]));
      await _settle();
    });

    test('can be cancelled, and does not start', () async {
      await manager!.cancel(only.id);
      expect(await status(only), DownloadStatus.cancelled);
      gate.complete();
      await _settle();
      expect(engine.running, isEmpty);
      expect(await status(only), DownloadStatus.cancelled);
    });

    test('stays cancelled when the session then fails', () async {
      await manager!.cancel(only.id);
      gate.completeError(StateError('session expired'));
      await _settle();
      final task = await store.getTask(only.id);
      expect(task?.status, DownloadStatus.cancelled);
      expect(task?.error, isNull);
    });

    test('can be deleted, and does not start', () async {
      await manager!.deleteTask(only.id);
      gate.complete();
      await _settle();
      expect(engine.running, isEmpty);
      expect(engine.acknowledged, contains(only.id));
    });
  });

  test('a cancel still goes through the engine for a transfer it holds', () async {
    await make(1);
    final only = _job(1);
    await manager!.enqueue([only]);
    await manager!.cancel(only.id);
    await _settle();
    expect(engine.running, isEmpty);
    expect(await status(only), DownloadStatus.cancelled);
    expect(engine.acknowledged, contains(only.id));
  });

  test('a completion for a cancelled task releases its temporary files', () async {
    await make(1);
    final only = _job(1);
    await store.upsertJob(only);
    await store.updateStatus(only.id, DownloadStatus.cancelled);
    engine.complete(only.id);
    await _settle();
    expect(saver.saved, isEmpty);
    expect(engine.acknowledged, contains(only.id));
  });

  test('a saveBytes that fails validation leaves no task to download', () async {
    await make(1);
    await expectLater(
      manager!.saveBytes(
        origin: const ArtworkPage(illustId: 9, pageIndex: 0),
        source: const ArtworkSource(illustId: 9, title: '9'),
        bytes: Uint8List(0),
        sourceUrl: Uri.parse('https://i.pximg.net/9.png'),
        filename: '9.png',
      ),
      throwsA(anything),
    );
    expect(await store.listTasks(illustId: 9), isEmpty);
  });

  group('replacing a file', () {
    test('a failed move keeps the existing file', () async {
      final destination = File(p.join(root.path, 'a.png'))..writeAsStringSync('old');
      await expectLater(moveFileWithFallback(source: File(p.join(root.path, 'missing.tmp')), destination: destination), throwsA(anything));
      expect(destination.existsSync() ? destination.readAsStringSync() : '<deleted>', 'old');
    });

    test('a successful move replaces the existing file', () async {
      final source = File(p.join(root.path, 'new.tmp'))..writeAsStringSync('new');
      final destination = File(p.join(root.path, 'a.png'))..writeAsStringSync('old');
      await moveFileWithFallback(source: source, destination: destination);
      expect(destination.readAsStringSync(), 'new');
      expect(source.existsSync(), isFalse);
    });

    test('writing bytes replaces the existing file', () async {
      final destination = File(p.join(root.path, 'a.png'))..writeAsStringSync('old');
      await writeBytesAtomically(bytes: Uint8List.fromList([110]), directory: root, filename: 'a.png');
      expect(destination.readAsStringSync(), 'n');
    });
  });

  group('the Rust engine', () {
    Directory tempFolder() => Directory(p.join(root.path, downloadTempDirectoryName));

    test('a locked partial file still reports the failure', () async {
      final only = _job(1);
      final directory = Directory(p.join(tempFolder().path, downloadTempFolderName(only.id)))..createSync(recursive: true);
      final locked = File(p.join(directory.path, '1.png.part'))..writeAsStringSync('x');
      final handle = locked.openSync(mode: FileMode.append);
      final rust = RustIoDownloadEngine(type: DownloadEngineType.desktopRust);
      final events = <DownloadEngineEvent>[];
      final subscription = rust.events.listen(events.add);
      final uncaught = <Object>[];
      try {
        await runZonedGuarded(() => rust.start([only]), (error, _) => uncaught.add(error));
        await _settle(400);
      } finally {
        handle.closeSync();
        await subscription.cancel();
      }
      expect(events.whereType<EngineFailedEvent>(), hasLength(1), reason: 'uncaught: $uncaught');
    }, skip: Platform.isWindows ? false : 'Only Windows locks open files');

    test('acknowledge removes the job directory', () async {
      final directory = Directory(p.join(tempFolder().path, downloadTempFolderName('a/b')))..createSync(recursive: true);
      File(p.join(directory.path, 'a.png')).writeAsStringSync('x');
      await RustIoDownloadEngine(type: DownloadEngineType.desktopRust).acknowledge({'a/b'});
      expect(directory.existsSync(), isFalse);
    });

    test('removeLeftovers spares kept files, also inside folders of an older version', () async {
      final kept = File(p.join(tempFolder().path, 'hash', 'a.png'))..createSync(recursive: true);
      final nested = File(p.join(tempFolder().path, 'image_host', 'dir', 'b.png', 'b.png'))..createSync(recursive: true);
      final stale = Directory(p.join(tempFolder().path, 'stale'))..createSync(recursive: true);
      final bytes = File(p.join(tempFolder().path, 'hash-c.gif'))..createSync(recursive: true);
      await RustIoDownloadEngine(type: DownloadEngineType.desktopRust).removeLeftovers({kept.path, nested.path, '/d/saved.png'});
      expect(kept.existsSync(), isTrue);
      expect(nested.existsSync(), isTrue);
      expect(stale.existsSync(), isFalse);
      expect(bytes.existsSync(), isFalse);
    });
  });

  test('a temporary name has no path separators', () {
    expect(downloadTempFolderName('image_ugoira/2.gif'), matches(RegExp(r'^[0-9a-f]+$')));
  });

  test('the native saver saves bytes of any job and removes the temporary file', () async {
    const channel = MethodChannel('freepiv/download_engine');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final paths = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      final path = (call.arguments as Map)['path'] as String;
      expect(File(path).existsSync(), isTrue);
      paths.add(path);
      return {'path': 'content://saved', 'bytesWritten': 3};
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final generated = DownloadJob.create(
      origin: ContentFile(generatedDownloadAddress('ugoira', '2.gif')),
      source: const ArtworkSource(illustId: 2, title: 'Animation'),
      url: generatedDownloadAddress('ugoira', '2.gif'),
      filename: '2.gif',
      saveTarget: const SaveTarget.downloadsFolder(),
    );
    await NativeMediaSaver().saveBytes(job: _job(1), bytes: Uint8List(3));
    await NativeMediaSaver().saveBytes(job: generated, bytes: Uint8List(3));
    expect(paths, hasLength(2));
    expect(Directory(p.join(root.path, downloadTempDirectoryName)).listSync(), isEmpty);
  });
}

class _FailingSaver implements MediaSaver {
  @override
  Future<SaveResult> saveDownloadedFile({required DownloadJob job, required DownloadedFile file}) async => throw const DownloadException('disk full');

  @override
  Future<SaveResult> saveBytes({required DownloadJob job, required Uint8List bytes}) async => throw const DownloadException('disk full');
}
