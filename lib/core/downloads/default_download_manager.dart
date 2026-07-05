import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:freepiv/core/downloads/download_engine.dart';
import 'package:freepiv/core/downloads/download_file_system.dart';
import 'package:freepiv/core/downloads/download_manager_contract.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/downloads/download_permission_guard.dart';
import 'package:freepiv/core/downloads/download_store.dart';
import 'package:freepiv/core/downloads/media_saver.dart';
import 'package:freepiv/core/downloads/platform/desktop_media_saver.dart';
import 'package:freepiv/core/downloads/platform/native_download_engine.dart';
import 'package:freepiv/core/downloads/platform/rust_io_download_engine.dart';
import 'package:freepiv/core/services/app_settings.dart';

final class DefaultDownloadManager implements DownloadManager {
  DownloadStore? _store;
  DownloadEngine? _engine;
  MediaSaver? _mediaSaver;
  DownloadPermissionGuard? _permissionGuard;
  StreamSubscription<DownloadEngineEvent>? _engineSubscription;
  Future<void>? _initializing;
  bool _initialized = false;
  bool _pumpingQueue = false;
  bool _queuePumpRequested = false;
  final _jobs = <String, DownloadJob>{};
  final _waiters = <String, Completer<DownloadedFile>>{};

  @override
  Future<void> initialize() {
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) {
      return;
    }

    final components = _createPlatformComponents();
    _store = DriftDownloadStore.open();
    _engine = components.engine;
    _mediaSaver = components.mediaSaver;
    _permissionGuard = components.permissionGuard;
    await components.engine.initialize();
    _engineSubscription = components.engine.events.listen((event) => unawaited(_handleEngineEvent(event)));
    _initialized = true;
    await sync();
  }

  @override
  Future<void> ensureReadyForDownloads() async {
    await _ensureInitialized();
    await _activePermissionGuard.ensureReadyForDownload();
  }

  @override
  Future<int> enqueue(List<DownloadJob> jobs) async {
    await _ensureInitialized();
    final normalizedJobs = [for (final job in jobs) _normalizeJob(job)];
    if (normalizedJobs.isEmpty) {
      return 0;
    }
    await _activePermissionGuard.ensureReadyForDownload();
    var enqueued = 0;
    for (final job in normalizedJobs) {
      final activeTask = await _activeTaskForJob(job);
      if (activeTask != null) {
        continue;
      }
      _jobs[job.id] = job;
      await _activeStore.upsertJob(job);
      enqueued += 1;
    }

    if (enqueued == 0) {
      throw const DownloadException('This image is already queued or downloading.');
    }

    await _pumpQueue();
    return enqueued;
  }

  @override
  Future<void> refreshQueue() async {
    await _ensureInitialized();
    await _pumpQueue();
  }

  @override
  Future<DownloadedFile> download({
    required int illustId,
    required int pageIndex,
    required Uri url,
    String? filename,
    Map<String, String> headers = const {},
    String? title,
    String? thumbnailUrl,
  }) async {
    await _ensureInitialized();
    final job = DownloadJob.create(
      illustId: illustId,
      pageIndex: pageIndex,
      url: url,
      filename: filename ?? filenameFromUrl(url),
      headers: headers,
      saveTarget: _defaultSaveTarget(),
      title: title,
      thumbnailUrl: thumbnailUrl,
    );
    final waiter = Completer<DownloadedFile>();
    _waiters[job.id] = waiter;
    try {
      await enqueue([job]);
    } catch (_) {
      _waiters.remove(job.id);
      rethrow;
    }
    return waiter.future;
  }

  @override
  Future<DownloadedFile> saveBytes({
    required int illustId,
    required int pageIndex,
    required Uint8List bytes,
    required Uri sourceUrl,
    String? filename,
    String? title,
    String? thumbnailUrl,
  }) async {
    await _ensureInitialized();
    await _activePermissionGuard.ensureReadyForDownload();
    final job = DownloadJob.create(
      illustId: illustId,
      pageIndex: pageIndex,
      url: sourceUrl,
      filename: filename ?? filenameFromUrl(sourceUrl),
      saveTarget: _defaultSaveTarget(),
      title: title,
      thumbnailUrl: thumbnailUrl,
    );
    final activeTask = await _activeTaskForJob(job);
    if (activeTask != null) {
      throw const DownloadException('This image is already queued or downloading.');
    }

    _jobs[job.id] = job;
    await _activeStore.upsertJob(job);
    await _activeStore.updateStatus(job.id, DownloadStatus.running);
    await _activeStore.updateProgress(job.id, receivedBytes: bytes.lengthInBytes, totalBytes: bytes.lengthInBytes, progress: 1);
    await _activeStore.updateStatus(job.id, DownloadStatus.downloaded);
    await _activeStore.updateSaveState(job.id, SaveState.saving);
    try {
      final result = await _activeMediaSaver.saveBytes(job: job, bytes: bytes);
      await _activeStore.updateSaveState(job.id, SaveState.saved, localPath: result.path, galleryAssetId: result.galleryAssetId);
      return DownloadedFile(path: result.path, bytesWritten: result.bytesWritten);
    } catch (error) {
      await _activeStore.updateSaveState(job.id, SaveState.failed, error: error.toString());
      throw DownloadException('Failed to save downloaded file', error);
    }
  }

  @override
  Future<void> pause(String jobId) async {
    await _ensureInitialized();
    await _activeEngine.pause(jobId);
  }

  @override
  Future<void> resume(String jobId) async {
    await _ensureInitialized();
    await _activeEngine.resume(jobId);
  }

  @override
  Future<void> cancel(String jobId) async {
    await _ensureInitialized();
    final task = await _activeStore.getTask(jobId);
    if (task?.status == DownloadStatus.queued) {
      await _activeStore.updateStatus(jobId, DownloadStatus.cancelled);
      _completeWithError(jobId, const DownloadException('Download cancelled'));
      await _pumpQueue();
      return;
    }
    await _activeEngine.cancel(jobId);
  }

  @override
  Future<void> deleteTask(String jobId) async {
    await _ensureInitialized();
    final task = await _activeStore.getTask(jobId);
    if (task == null) {
      return;
    }

    if (task.status == DownloadStatus.running || task.status == DownloadStatus.paused) {
      await _activeEngine.cancel(jobId);
    }

    _jobs.remove(jobId);
    _completeWithError(jobId, const DownloadException('Download task deleted'));
    await _activeStore.deleteTask(jobId);
    await _pumpQueue();
  }

  @override
  Future<void> retry(String jobId) async {
    await _ensureInitialized();
    final job = await _activeStore.getJob(jobId);
    if (job == null) {
      throw DownloadException('Download task does not exist: $jobId');
    }
    await _activeStore.updateSaveState(jobId, SaveState.none);
    await enqueue([job]);
  }

  @override
  Future<void> retrySave(String jobId) async {
    await _ensureInitialized();
    final snapshot = await _activeStore.getTask(jobId);
    final job = await _activeStore.getJob(jobId);
    final localPath = snapshot?.localPath;
    if (snapshot == null || job == null || localPath == null || localPath.isEmpty) {
      throw DownloadException('Download task has no local file to save: $jobId');
    }

    await _activePermissionGuard.ensureReadyForDownload();
    await _saveCompletedFile(job, DownloadedFile(path: localPath, bytesWritten: snapshot.receivedBytes));
  }

  @override
  Future<List<DownloadTaskSnapshot>> listTasks({int? illustId, DownloadStatus? status, SaveState? saveState}) async {
    await _ensureInitialized();
    return _activeStore.listTasks(illustId: illustId, status: status, saveState: saveState);
  }

  @override
  Stream<List<DownloadTaskSnapshot>> watchTasks({int? illustId}) {
    return _activeStore.watchTasks(illustId: illustId);
  }

  @override
  Stream<DownloadTaskSnapshot?> watchTask(String jobId) {
    return _activeStore.watchTask(jobId);
  }

  @override
  Stream<DownloadSummary> watchSummary({int? illustId}) {
    return _activeStore.watchSummary(illustId: illustId);
  }

  @override
  Future<void> sync() async {
    await _ensureInitialized();
    final snapshots = await _activeEngine.syncActiveTasks();
    final activeIds = <String>{};
    for (final snapshot in snapshots) {
      if (snapshot.jobId.isEmpty) {
        continue;
      }
      activeIds.add(snapshot.jobId);
      await _activeStore.applyEngineSnapshot(snapshot);
    }

    final recoverableTasks = await _activeStore.listRecoverableTasks();
    for (final task in recoverableTasks) {
      if (task.status == DownloadStatus.running && !activeIds.contains(task.id)) {
        await _activeStore.updateStatus(task.id, DownloadStatus.failed, error: 'Download was interrupted.');
      }
    }

    if (!_activeEngine.capabilities.handlesSaving) {
      await _resumePendingSaves();
    }
    await _pumpQueue();
  }

  Future<void> _handleEngineEvent(DownloadEngineEvent event) async {
    await _ensureInitialized();
    switch (event) {
      case EngineProgressEvent():
        await _activeStore.updateProgress(event.jobId, receivedBytes: event.receivedBytes, totalBytes: event.totalBytes, progress: event.progress);
      case EngineCompletedEvent():
        await _activeStore.updateProgress(event.jobId, receivedBytes: event.bytesWritten, progress: 1);
        await _activeStore.updateStatus(event.jobId, DownloadStatus.downloaded);
        await _activeStore.updateSaveState(
          event.jobId,
          _activeEngine.capabilities.handlesSaving ? SaveState.saving : SaveState.pending,
          localPath: event.localPath,
        );
        if (!_activeEngine.capabilities.handlesSaving) {
          final job = await _jobFor(event.jobId);
          if (job != null) {
            await _saveCompletedFile(job, DownloadedFile(path: event.localPath, bytesWritten: event.bytesWritten));
          }
        }
        await _pumpQueue();
      case EngineFailedEvent():
        await _activeStore.updateStatus(event.jobId, DownloadStatus.failed, error: event.error);
        _completeWithError(event.jobId, DownloadException(event.error));
        await _pumpQueue();
      case EnginePausedEvent():
        await _activeStore.updateStatus(event.jobId, DownloadStatus.paused);
        await _pumpQueue();
      case EngineCancelledEvent():
        await _activeStore.updateStatus(event.jobId, DownloadStatus.cancelled);
        _completeWithError(event.jobId, const DownloadException('Download cancelled'));
        await _pumpQueue();
      case EngineSaveCompletedEvent():
        await _activeStore.updateSaveState(event.jobId, SaveState.saved, localPath: event.path, galleryAssetId: event.galleryAssetId);
        await _completeWithSnapshot(event.jobId);
      case EngineSaveFailedEvent():
        await _activeStore.updateSaveState(event.jobId, SaveState.failed, localPath: event.localPath, error: event.error);
        _completeWithError(event.jobId, DownloadException(event.error));
    }
  }

  Future<void> _saveCompletedFile(DownloadJob job, DownloadedFile file) async {
    await _activeStore.updateSaveState(job.id, SaveState.saving, localPath: file.path);
    try {
      final result = await _activeMediaSaver.saveDownloadedFile(job: job, file: file);
      await _activeStore.updateSaveState(job.id, SaveState.saved, localPath: result.path, galleryAssetId: result.galleryAssetId);
      _complete(job.id, DownloadedFile(path: result.path, bytesWritten: result.bytesWritten));
    } catch (error) {
      await _activeStore.updateSaveState(job.id, SaveState.failed, localPath: file.path, error: error.toString());
      _completeWithError(job.id, DownloadException('Failed to save downloaded file', error));
    }
  }

  Future<void> _resumePendingSaves() async {
    final pendingTasks = await _activeStore.listPendingSaveTasks();
    for (final task in pendingTasks) {
      final job = await _jobFor(task.id);
      final localPath = task.localPath;
      if (job == null || localPath == null || localPath.isEmpty) {
        await _activeStore.updateSaveState(task.id, SaveState.failed, error: 'Download task has no local file to save.');
        continue;
      }
      await _saveCompletedFile(job, DownloadedFile(path: localPath, bytesWritten: task.receivedBytes));
    }
  }

  Future<void> _pumpQueue() async {
    if (_pumpingQueue) {
      _queuePumpRequested = true;
      return;
    }

    _pumpingQueue = true;
    try {
      do {
        _queuePumpRequested = false;
        await _pumpQueueOnce();
      } while (_queuePumpRequested);
    } finally {
      _pumpingQueue = false;
    }
  }

  Future<void> _pumpQueueOnce() async {
    final runningTasks = await _activeStore.listTasks(status: DownloadStatus.running);
    var availableSlots = AppSettings.maxConcurrentDownloads - runningTasks.length;
    if (availableSlots <= 0) {
      return;
    }

    final queuedTasks = await _activeStore.listTasks(status: DownloadStatus.queued);
    queuedTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final task in queuedTasks) {
      if (availableSlots <= 0) {
        return;
      }

      final job = await _jobFor(task.id);
      if (job == null) {
        await _activeStore.updateStatus(task.id, DownloadStatus.failed, error: 'Download task has no job data.');
        continue;
      }

      await _activeStore.updateStatus(job.id, DownloadStatus.running);
      try {
        await _activeEngine.start([job]);
        availableSlots -= 1;
      } catch (error) {
        await _activeStore.updateStatus(job.id, DownloadStatus.failed, error: error.toString());
        _completeWithError(job.id, DownloadException('Failed to start download', error));
      }
    }
  }

  Future<void> _completeWithSnapshot(String jobId) async {
    final waiter = _waiters.remove(jobId);
    if (waiter == null || waiter.isCompleted) {
      return;
    }
    final snapshot = await _activeStore.getTask(jobId);
    waiter.complete(DownloadedFile(path: snapshot?.localPath ?? snapshot?.galleryAssetId ?? '', bytesWritten: snapshot?.receivedBytes ?? 0));
  }

  void _complete(String jobId, DownloadedFile file) {
    final waiter = _waiters.remove(jobId);
    if (waiter == null || waiter.isCompleted) {
      return;
    }
    waiter.complete(file);
  }

  void _completeWithError(String jobId, Object error) {
    final waiter = _waiters.remove(jobId);
    if (waiter == null || waiter.isCompleted) {
      return;
    }
    waiter.completeError(error);
  }

  Future<DownloadJob?> _jobFor(String jobId) async {
    return _jobs[jobId] ?? await _activeStore.getJob(jobId);
  }

  DownloadJob _normalizeJob(DownloadJob job) {
    return job.copyWith(saveTarget: _defaultSaveTarget(job.saveTarget));
  }

  bool _isActiveDownloadTask(DownloadTaskSnapshot task) {
    return task.status == DownloadStatus.queued ||
        task.status == DownloadStatus.running ||
        task.status == DownloadStatus.paused ||
        task.saveState == SaveState.pending ||
        task.saveState == SaveState.saving;
  }

  Future<DownloadTaskSnapshot?> _activeTaskForJob(DownloadJob job) async {
    final task = await _activeStore.getTask(job.id);
    if (task != null && _isActiveDownloadTask(task)) {
      return task;
    }

    final illustTasks = await _activeStore.listTasks(illustId: job.illustId);
    for (final illustTask in illustTasks) {
      if (illustTask.pageIndex == job.pageIndex && _isActiveDownloadTask(illustTask)) {
        return illustTask;
      }
    }
    return null;
  }

  SaveTarget _defaultSaveTarget([SaveTarget? requested]) {
    if (requested != null && requested.type != SaveTargetType.downloadsFolder) {
      return requested;
    }
    if (Platform.isAndroid) {
      return const SaveTarget.mediaStore();
    }
    if (Platform.isIOS) {
      return const SaveTarget.photos();
    }
    return requested ?? const SaveTarget.downloadsFolder();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  DownloadStore get _activeStore {
    final store = _store;
    if (store == null) {
      throw StateError('DownloadManager.initialize() has not completed.');
    }
    return store;
  }

  DownloadEngine get _activeEngine {
    final engine = _engine;
    if (engine == null) {
      throw StateError('DownloadManager.initialize() has not completed.');
    }
    return engine;
  }

  MediaSaver get _activeMediaSaver {
    final mediaSaver = _mediaSaver;
    if (mediaSaver == null) {
      throw StateError('DownloadManager.initialize() has not completed.');
    }
    return mediaSaver;
  }

  DownloadPermissionGuard get _activePermissionGuard {
    final permissionGuard = _permissionGuard;
    if (permissionGuard == null) {
      throw StateError('DownloadManager.initialize() has not completed.');
    }
    return permissionGuard;
  }

  Future<void> dispose() async {
    await _engineSubscription?.cancel();
  }
}

_DownloadComponents _createPlatformComponents() {
  if (Platform.isAndroid) {
    return _DownloadComponents(
      engine: NativeDownloadEngine(type: DownloadEngineType.androidOkHttpForeground),
      mediaSaver: const NativeMediaSaver(),
      permissionGuard: const NativeDownloadPermissionGuard(),
    );
  }
  if (Platform.isIOS) {
    return _DownloadComponents(
      engine: NativeDownloadEngine(type: DownloadEngineType.iosUrlSession),
      mediaSaver: const NativeMediaSaver(),
      permissionGuard: const NativeDownloadPermissionGuard(),
    );
  }
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    return _DownloadComponents(
      engine: RustIoDownloadEngine(type: DownloadEngineType.desktopRust),
      mediaSaver: const DesktopMediaSaver(),
      permissionGuard: const DesktopDownloadPermissionGuard(),
    );
  }
  return _DownloadComponents(
    engine: RustIoDownloadEngine(type: DownloadEngineType.unsupported),
    mediaSaver: const UnsupportedMediaSaver(),
    permissionGuard: const UnsupportedDownloadPermissionGuard(),
  );
}

class _DownloadComponents {
  const _DownloadComponents({required this.engine, required this.mediaSaver, required this.permissionGuard});

  final DownloadEngine engine;
  final MediaSaver mediaSaver;
  final DownloadPermissionGuard permissionGuard;
}
