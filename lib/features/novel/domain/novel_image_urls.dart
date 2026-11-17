import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

String novelCoverUrl(Novel novel, WebviewNovel? webviewNovel) {
  final webviewCover = webviewNovel?.coverUrl.trim() ?? '';
  if (webviewCover.isNotEmpty) {
    return webviewCover;
  }

  final original = novel.imageUrls.original;
  if (original != null && original.isNotEmpty) {
    return original;
  }

  return novel.imageUrls.large.isNotEmpty ? novel.imageUrls.large : novel.imageUrls.medium;
}

/// The image for each `[uploadedimage:<id>]` and `[pixivimage:<id>]` marker
/// in the text, keyed by the marker's payload.
Map<String, String> novelEmbeddedImageUrls(WebviewNovel webviewNovel) => {
  for (final image in webviewNovel.images)
    if (_bestNovelImageUrl(image) case final url? when _isImageUrl(url)) image.novelImageId: url,
  ...novelEmbeddedWorkUrls(webviewNovel),
};

/// Pixiv works embedded with `[pixivimage:<id>]` or `[pixivimage:<id>-<page>]`,
/// keyed like the marker.
Map<String, String> novelEmbeddedWorkUrls(WebviewNovel webviewNovel) => {
  for (final work in webviewNovel.illusts)
    if (work.imageOriginal ?? work.imageMedium case final url? when _isImageUrl(url)) work.key: url,
};

List<String> novelExtraImageUrls(Novel novel, WebviewNovel? webviewNovel) {
  if (webviewNovel == null) return const [];
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

  novelEmbeddedWorkUrls(webviewNovel).values.forEach(addUrl);

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

/// Image inside the text: 1200x1200, then 480mw, then the original.
String? novelTextImageUrl(WebviewNovelImage image) {
  final urls = image.urls;
  return _firstImageUrl([urls.size1200X1200, urls.size480Mw, urls.original]);
}

/// Embedded Pixiv work inside the text: medium, then the original.
String? novelEmbeddedWorkImageUrl(WebviewNovelEmbeddedWork work) => _firstImageUrl([work.imageMedium, work.imageOriginal]);

/// Full-screen viewer: the original, then 1200x1200.
String? novelViewerImageUrl(WebviewNovelImage image) {
  final urls = image.urls;
  return _firstImageUrl([urls.original, urls.size1200X1200]);
}

/// Detail page illustration strip: 240mw, then 480mw.
String? novelStripImageUrl(WebviewNovelImage image) {
  final urls = image.urls;
  return _firstImageUrl([urls.size240Mw, urls.size480Mw]);
}

String? _firstImageUrl(List<String?> candidates) {
  for (final candidate in candidates) {
    final trimmed = candidate?.trim();
    if (trimmed != null && _isImageUrl(trimmed)) return trimmed;
  }
  return null;
}
