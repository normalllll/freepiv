import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

String illustPreviewImageUrl(ImageUrls imageUrls, PreviewImageQuality quality) {
  return switch (quality) {
    PreviewImageQuality.medium => _firstImageUrl([imageUrls.medium, imageUrls.large, imageUrls.original, imageUrls.squareMedium]),
    PreviewImageQuality.large => _firstImageUrl([imageUrls.large, imageUrls.medium, imageUrls.original, imageUrls.squareMedium]),
  };
}

String illustViewerImageUrl(ImageUrls imageUrls, ViewerImageQuality quality, {String? originalImageUrl}) {
  return switch (quality) {
    ViewerImageQuality.large => _firstImageUrl([imageUrls.large, imageUrls.medium, originalImageUrl, imageUrls.original, imageUrls.squareMedium]),
    ViewerImageQuality.original => _firstImageUrl([originalImageUrl, imageUrls.original, imageUrls.large, imageUrls.medium, imageUrls.squareMedium]),
  };
}

String illustImagePlaceholderUrl(ImageUrls imageUrls) {
  return _firstImageUrl([imageUrls.medium, imageUrls.squareMedium, imageUrls.large, imageUrls.original]);
}

String _firstImageUrl(Iterable<String?> urls) {
  for (final url in urls) {
    if (url != null && url.isNotEmpty) {
      return url;
    }
  }

  return '';
}
