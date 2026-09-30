import 'dart:convert';

import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

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

/// Pixiv works embedded with `[pixivimage:<id>]` or `[pixivimage:<id>-<page>]`,
/// keyed like the marker. The webview reports them as one JSON object, which
/// the bridge passes through as a string:
/// `{"<key>": {"illust": {"images": {"original": …, "medium": …}}}}`.
Map<String, String> novelEmbeddedWorkUrls(WebviewNovel webviewNovel) {
  final urls = <String, String>{};
  for (final raw in webviewNovel.illusts) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      continue;
    }
    if (decoded is! Map<String, Object?>) continue;
    for (final MapEntry(:key, :value) in decoded.entries) {
      if (_bestWorkImageUrl(value) case final url?) urls[key] = url;
    }
  }
  return urls;
}

String? _bestWorkImageUrl(Object? work) {
  if (work case {'illust': {'images': final Map<String, Object?> images}} || {'images': final Map<String, Object?> images}) {
    for (final size in const ['original', 'large', 'medium', 'small']) {
      if (images[size] case final String url when _isImageUrl(url)) return url;
    }
  }
  return null;
}

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
