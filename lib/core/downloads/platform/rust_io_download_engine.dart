import 'dart:async';
import 'dart:io';

import 'package:freepiv/core/downloads/download_engine.dart';
import 'package:freepiv/core/downloads/download_file_system.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/src/rust/api/download.dart';
import 'package:path/path.dart' as p;

final class RustIoDownloadEngine implements DownloadEngine {
  RustIoDownloadEngine({required this.type});

  @override
  final DownloadEngineType type;

  @override
  DownloadCapabilities get capabilities {
    return const DownloadCapabilities(supportsBackground: false, supportsCancel: true, supportsPauseResume: false, handlesSaving: false);
  }

  final _events = StreamController<DownloadEngineEvent>.broadcast();
  final _running = <String, _RunningDownload>{};

  @override
  Stream<DownloadEngineEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start(List<DownloadJob> jobs) async {
    for (final job in jobs) {
      if (_running.containsKey(job.id)) {
        continue;
      }
      unawaited(_download(job));
    }
  }

  @override
  Future<void> pause(String jobId) {
    throw UnsupportedError('Pause is not supported by the Rust IO download engine.');
  }

  @override
  Future<void> resume(String jobId) {
    throw UnsupportedError('Resume is not supported by the Rust IO download engine.');
  }

  @override
  Future<void> cancel(String jobId) async {
    final running = _running[jobId];
    if (running == null) {
      return;
    }
    running.cancelled = true;
    running.completeWithError(const DownloadException('Download cancelled'));
    await running.subscription?.cancel();
  }

  @override
  Future<List<DownloadEngineSnapshot>> syncActiveTasks() async {
    return [
      for (final running in _running.values)
        DownloadEngineSnapshot(
          jobId: running.job.id,
          status: DownloadStatus.running,
          saveState: SaveState.none,
          receivedBytes: running.receivedBytes,
          totalBytes: running.totalBytes,
          progress: running.progress,
        ),
    ];
  }

  Future<void> _download(DownloadJob job) async {
    final running = _RunningDownload(job: job);
    _running[job.id] = running;

    File? partialFile;
    File? downloadedFile;
    try {
      final tempDirectory = await downloadTempDirectory();
      final jobDirectory = Directory(p.join(tempDirectory.path, job.id));
      await jobDirectory.create(recursive: true);
      final filename = safeDownloadFilename(job.filename);
      partialFile = File(p.join(jobDirectory.path, '$filename.part'));
      final destination = File(p.join(jobDirectory.path, filename));
      await deleteFileIfExists(partialFile);
      await deleteFileIfExists(destination);

      var lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
      final downloadedPath = await running.download(
        job.url.toString(),
        partialFile.path,
        onProgress: (receivedBytes, totalBytes) {
          running.receivedBytes = receivedBytes;
          running.totalBytes = totalBytes;
          running.progress = totalBytes == null ? 0 : (receivedBytes / totalBytes).clamp(0.0, 1.0);

          final now = DateTime.now();
          if (now.difference(lastEmit).inMilliseconds >= 300 || running.progress >= 1) {
            lastEmit = now;
            _events.add(EngineProgressEvent(jobId: job.id, receivedBytes: running.receivedBytes, totalBytes: running.totalBytes, progress: running.progress));
          }
        },
      );

      downloadedFile = File(downloadedPath);
      if (running.cancelled) {
        throw const DownloadException('Download cancelled');
      }
      if (!await downloadedFile.exists()) {
        throw DownloadException('Downloaded file does not exist: $downloadedPath');
      }

      final bytesWritten = await downloadedFile.length();
      running.receivedBytes = bytesWritten;
      running.totalBytes ??= bytesWritten;
      running.progress = 1;
      await deleteFileIfExists(destination);
      final savedTempFile = await downloadedFile.rename(destination.path);
      _events.add(EngineProgressEvent(jobId: job.id, receivedBytes: running.receivedBytes, totalBytes: running.totalBytes, progress: 1));
      _events.add(EngineCompletedEvent(jobId: job.id, localPath: savedTempFile.path, bytesWritten: running.receivedBytes));
    } catch (error) {
      if (partialFile != null && await partialFile.exists()) {
        await partialFile.delete();
      }
      if (downloadedFile != null && downloadedFile.path != partialFile?.path && await downloadedFile.exists()) {
        await downloadedFile.delete();
      }

      if (running.cancelled) {
        _events.add(EngineCancelledEvent(jobId: job.id));
      } else {
        _events.add(EngineFailedEvent(jobId: job.id, error: error.toString()));
      }
    } finally {
      _running.remove(job.id);
      await running.subscription?.cancel();
    }
  }
}

class _RunningDownload {
  _RunningDownload({required this.job});

  final DownloadJob job;
  StreamSubscription<FrbDownloadFileEvent>? subscription;
  Completer<String>? _pathCompleter;
  bool cancelled = false;
  int receivedBytes = 0;
  int? totalBytes;
  double progress = 0;

  Future<String> download(String url, String path, {required void Function(int receivedBytes, int? totalBytes) onProgress}) {
    final completer = Completer<String>();
    final proxy = AppSettings.proxySettings.activeUrl;
    _pathCompleter = completer;
    subscription = downloadToFile(url: url, path: path, proxy: proxy).listen(
      (event) {
        if (cancelled) {
          return;
        }
        switch (event) {
          case FrbDownloadFileEvent_Progress(:final received, :final total):
            onProgress(received, total > 0 ? total : null);
          case FrbDownloadFileEvent_Done(:final path):
            complete(path);
        }
      },
      onError: completeWithError,
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(const DownloadException('Download completed without file path.'));
        }
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  void complete(String path) {
    final completer = _pathCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete(path);
  }

  void completeWithError(Object error, [StackTrace? stackTrace]) {
    final completer = _pathCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.completeError(error, stackTrace);
  }
}
