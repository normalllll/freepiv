import 'dart:typed_data';

import 'download_models.dart';

abstract interface class DownloadManager {
  Future<void> initialize();

  Future<void> ensureReadyForDownloads();

  Future<int> enqueue(List<DownloadJob> jobs);

  Future<void> refreshQueue();

  Future<DownloadedFile> download({
    required DownloadOrigin origin,
    required DownloadSource source,
    DownloadPart? part,
    required Uri url,
    String? filename,
    DownloadNetworkOptions networkOptions = const DownloadNetworkOptions(),
    DownloadValidationOptions validation = const DownloadValidationOptions(),
    String? title,
    String? thumbnailUrl,
  });

  Future<DownloadedFile> saveBytes({
    required DownloadOrigin origin,
    required DownloadSource source,
    DownloadPart? part,
    required Uint8List bytes,
    required Uri sourceUrl,
    String? filename,
    DownloadValidationOptions validation = const DownloadValidationOptions(),
    String? title,
    String? thumbnailUrl,
  });

  /// Records a task for a file the app makes itself (a GIF composed from an
  /// animation's frames) and saves it like a download: the task shows as
  /// running with the progress [generate] reports, then saved, or failed with
  /// the error in its log.
  Future<DownloadedFile> saveGenerated({
    required DownloadOrigin origin,
    required DownloadSource source,
    required Uri sourceUrl,
    required String filename,
    required Future<Uint8List> Function(void Function(double progress) onProgress) generate,
    String? title,
    String? thumbnailUrl,
  });

  Future<void> pause(String jobId);

  Future<void> resume(String jobId);

  Future<void> cancel(String jobId);

  Future<void> deleteTask(String jobId);

  Future<void> retry(String jobId);

  Future<void> retrySave(String jobId);

  Future<List<DownloadTaskSnapshot>> listTasks({int? illustId, DownloadStatus? status, SaveState? saveState});

  Stream<List<DownloadTaskSnapshot>> watchTasks({int? illustId});

  Stream<DownloadTaskSnapshot?> watchTask(String jobId);

  Stream<DownloadSummary> watchSummary({int? illustId});

  Future<void> sync();

  Future<void> dispose();
}

extension DownloadManagerBatchActions on DownloadManager {
  Future<void> retryFailed() => _applyToTasks((task) => task.needsRetry, retry);

  Future<void> clearCompleted() => _applyToTasks((task) => task.isCompleted, deleteTask);

  Future<void> _applyToTasks(bool Function(DownloadTaskSnapshot) matches, Future<void> Function(String) action) async {
    Object? firstError;
    StackTrace? firstStack;
    for (final task in (await listTasks()).where(matches)) {
      try {
        await action(task.id);
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }
}
