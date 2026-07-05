import 'dart:typed_data';

import 'download_models.dart';

abstract interface class DownloadManager {
  Future<void> initialize();

  Future<void> ensureReadyForDownloads();

  Future<int> enqueue(List<DownloadJob> jobs);

  Future<void> refreshQueue();

  Future<DownloadedFile> download({
    required int illustId,
    required int pageIndex,
    required Uri url,
    String? filename,
    Map<String, String> headers,
    String? title,
    String? thumbnailUrl,
  });

  Future<DownloadedFile> saveBytes({
    required int illustId,
    required int pageIndex,
    required Uint8List bytes,
    required Uri sourceUrl,
    String? filename,
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
}
