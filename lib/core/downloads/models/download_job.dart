import 'download_origin.dart';
import 'save_target.dart';
import 'download_request_options.dart';

class DownloadJob {
  DownloadJob({
    required this.origin,
    required this.url,
    required this.filename,
    required this.networkOptions,
    required this.validation,
    required this.saveTarget,
    required this.createdAt,
    this.thumbnailUrl,
    this.title,
  });

  factory DownloadJob.create({
    required DownloadOrigin origin,
    required Uri url,
    String? filename,
    required SaveTarget saveTarget,
    DownloadNetworkOptions networkOptions = const DownloadNetworkOptions(),
    DownloadValidationOptions validation = const DownloadValidationOptions(),
    String? thumbnailUrl,
    String? title,
  }) {
    return DownloadJob(
      origin: origin,
      url: url,
      filename: filename ?? origin.defaultFilename(url),
      networkOptions: networkOptions.normalizedFor(url),
      validation: validation.normalized(),
      saveTarget: saveTarget,
      thumbnailUrl: thumbnailUrl,
      title: title,
      createdAt: DateTime.now(),
    );
  }

  final DownloadOrigin origin;
  final Uri url;
  final String filename;
  final DownloadNetworkOptions networkOptions;
  final DownloadValidationOptions validation;
  final SaveTarget saveTarget;
  final String? thumbnailUrl;
  final String? title;
  final DateTime createdAt;

  String get id => origin.jobId;

  DownloadJob copyWith({
    DownloadOrigin? origin,
    Uri? url,
    String? filename,
    DownloadNetworkOptions? networkOptions,
    DownloadValidationOptions? validation,
    SaveTarget? saveTarget,
    String? thumbnailUrl,
    String? title,
    DateTime? createdAt,
  }) {
    return DownloadJob(
      origin: origin ?? this.origin,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      networkOptions: networkOptions ?? this.networkOptions,
      validation: validation ?? this.validation,
      saveTarget: saveTarget ?? this.saveTarget,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toPlatformJson() {
    final (illustId, pageIndex) = switch (origin) {
      ArtworkPage(:final illustId, :final pageIndex) => (illustId, pageIndex),
      ContentImage() => (null, null),
    };
    return {
      'id': id,
      'illustId': illustId,
      'pageIndex': pageIndex,
      'url': url.toString(),
      'filename': filename,
      'networkOptions': networkOptions.toJson(),
      'validation': validation.toJson(),
      'saveTarget': saveTarget.toJson(),
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
