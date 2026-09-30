import 'download_enums.dart';
import 'download_origin.dart';
import 'download_source.dart';

class DownloadTaskSnapshot {
  const DownloadTaskSnapshot({
    required this.id,
    required this.origin,
    required this.source,
    required this.title,
    required this.filename,
    required this.status,
    required this.saveState,
    required this.receivedBytes,
    required this.totalBytes,
    required this.progress,
    required this.localPath,
    required this.error,
    required this.log,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailUrl,
    this.part,
    this.galleryAssetId,
  });

  final String id;
  final DownloadOrigin origin;

  /// What the file was downloaded from, the item it shows under.
  final DownloadSource source;

  /// The part of [source] the file belongs to, if the source has parts.
  final DownloadPart? part;
  final String title;
  final String filename;
  final String? thumbnailUrl;
  final DownloadStatus status;
  final SaveState saveState;
  final int receivedBytes;
  final int? totalBytes;
  final double progress;
  final String? localPath;
  final String? galleryAssetId;
  final String? error;
  final String? log;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => status == DownloadStatus.downloaded && saveState == SaveState.saved;

  bool get needsRetry => status == DownloadStatus.failed || (status == DownloadStatus.downloaded && saveState == SaveState.failed);

  bool get isTerminal {
    return status == DownloadStatus.downloaded || status == DownloadStatus.failed || status == DownloadStatus.cancelled;
  }
}
