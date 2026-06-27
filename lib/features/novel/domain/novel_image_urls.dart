import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

String novelCoverUrl(Novel novel, WebviewNovel webviewNovel) {
  final webviewCover = webviewNovel.coverUrl.trim();
  if (webviewCover.isNotEmpty) {
    return webviewCover;
  }

  final original = novel.imageUrls.original;
  if (original != null && original.isNotEmpty) {
    return original;
  }

  return novel.imageUrls.large.isNotEmpty ? novel.imageUrls.large : novel.imageUrls.medium;
}

// final _uploadedImagePattern = RegExp(r'\[uploadedimage:([^\]]+)\]');

List<String> novelExtraImageUrls(Novel novel, WebviewNovel webviewNovel) {
  final coverUrl = novelCoverUrl(novel, webviewNovel).trim();
  final seen = <String>{coverUrl};
  final urls = <String>[];

  void addUrl(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }

    if (!_isImageUrl(trimmed) || seen.contains(trimmed)) {
      return;
    }

    seen.add(trimmed);
    urls.add(trimmed);
  }

  for (final image in webviewNovel.images) {
    addUrl(_bestNovelImageUrl(image));
  }

  for (final url in webviewNovel.illusts) {
    addUrl(url);
  }

  return urls;
}

String? _bestNovelImageUrl(WebviewNovelImage image) {
  final urls = image.urls;

  return urls.original ?? urls.size1200X1200 ?? urls.size480Mw ?? urls.size240Mw ?? urls.size128X128;
}

bool _isImageUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}
