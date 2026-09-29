import 'package:path/path.dart' as p;

/// What a download is of. It decides the task's identity, its default file
/// name, and whether the task can open a page.
sealed class DownloadOrigin {
  const DownloadOrigin();

  /// The work page a Pixiv image address shows
  /// (`…/img-master|img-original/img/<date>/<id>_p<page>…`); any other image
  /// is a content image.
  factory DownloadOrigin.ofImageUrl(Uri url) {
    if (_workPageImage.firstMatch(url.path) case final match?) {
      return ArtworkPage(illustId: int.parse(match[1]!), pageIndex: int.parse(match[2]!));
    }
    return ContentImage.of(url);
  }

  static final _workPageImage = RegExp(r'/img-(?:master|original)/img/(?:\d+/){6}(\d+)_p(\d+)');

  String get jobId;

  String defaultFilename(Uri url);
}

/// A page of a Pixiv work; a task per work page, whatever quality it saves.
final class ArtworkPage extends DownloadOrigin {
  const ArtworkPage({required this.illustId, required this.pageIndex});

  final int illustId;
  final int pageIndex;

  @override
  String get jobId => 'illust_${illustId}_page_$pageIndex';

  @override
  String defaultFilename(Uri url) {
    final extension = p.extension(url.path).toLowerCase();
    final safeExtension = RegExp(r'^\.[a-z0-9]{1,10}$').hasMatch(extension) ? extension : '';
    return '${illustId}_p$pageIndex$safeExtension';
  }

  @override
  bool operator ==(Object other) => other is ArtworkPage && other.illustId == illustId && other.pageIndex == pageIndex;

  @override
  int get hashCode => Object.hash(illustId, pageIndex);
}

/// An image shown inside other content (a Pixivision article, a novel) that
/// is not a Pixiv work page; a task per image address.
final class ContentImage extends DownloadOrigin {
  const ContentImage(this.address);

  /// The image at [url], identified without its query or fragment.
  ContentImage.of(Uri url) : address = Uri(scheme: url.scheme, host: url.host, port: url.hasPort ? url.port : null, path: url.path);

  /// The image's address without query or fragment, which identifies it.
  final Uri address;

  @override
  String get jobId => 'image_${address.host}${address.path}';

  @override
  String defaultFilename(Uri url) => p.basename(url.path);

  @override
  bool operator ==(Object other) => other is ContentImage && other.jobId == jobId;

  @override
  int get hashCode => jobId.hashCode;
}
