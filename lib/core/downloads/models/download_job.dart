import 'save_target.dart';

class DownloadJob {
  DownloadJob({
    required this.id,
    required this.illustId,
    required this.pageIndex,
    required this.url,
    required this.filename,
    required this.headers,
    required this.saveTarget,
    required this.createdAt,
    this.thumbnailUrl,
    this.title,
  });

  factory DownloadJob.create({
    required int illustId,
    required int pageIndex,
    required Uri url,
    required String filename,
    required SaveTarget saveTarget,
    Map<String, String> headers = const {},
    String? thumbnailUrl,
    String? title,
  }) {
    final now = DateTime.now();
    return DownloadJob(
      id: downloadJobId(illustId: illustId, pageIndex: pageIndex),
      illustId: illustId,
      pageIndex: pageIndex,
      url: url,
      filename: filename,
      headers: headers,
      saveTarget: saveTarget,
      thumbnailUrl: thumbnailUrl,
      title: title,
      createdAt: now,
    );
  }

  final String id;
  final int illustId;
  final int pageIndex;
  final Uri url;
  final String filename;
  final Map<String, String> headers;
  final SaveTarget saveTarget;
  final String? thumbnailUrl;
  final String? title;
  final DateTime createdAt;

  DownloadJob copyWith({
    String? id,
    int? illustId,
    int? pageIndex,
    Uri? url,
    String? filename,
    Map<String, String>? headers,
    SaveTarget? saveTarget,
    String? thumbnailUrl,
    String? title,
    DateTime? createdAt,
  }) {
    return DownloadJob(
      id: id ?? this.id,
      illustId: illustId ?? this.illustId,
      pageIndex: pageIndex ?? this.pageIndex,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      headers: headers ?? this.headers,
      saveTarget: saveTarget ?? this.saveTarget,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toPlatformJson() {
    return {
      'id': id,
      'illustId': illustId,
      'pageIndex': pageIndex,
      'url': url.toString(),
      'filename': filename,
      'headers': headers,
      'saveTarget': saveTarget.toJson(),
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

String downloadJobId({required int illustId, required int pageIndex}) {
  return 'illust_${illustId}_page_$pageIndex';
}
