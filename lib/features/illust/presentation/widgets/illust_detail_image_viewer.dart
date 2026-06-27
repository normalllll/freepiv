import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_ugoira_viewer.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

class IllustImagePager extends StatelessWidget {
  const IllustImagePager({
    required this.illustId,
    required this.imagePages,
    required this.isUgoira,
    required this.loadedImages,
    required this.pageController,
    required this.pageIndex,
    required this.onPageChanged,
    required this.onImageTap,
    required this.showControls,
    super.key,
  });

  final int illustId;
  final List<IllustPageImage> imagePages;
  final bool isUgoira;
  final LoadedIllustImages loadedImages;
  final PageController pageController;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onImageTap;
  final bool showControls;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageCount = isUgoira ? 1 : imagePages.length;

    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: pageCount,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final image = imagePages[isUgoira ? 0 : index];
              final imageContent = _PageImageContent(illustId: illustId, index: index, image: image, loadedImages: loadedImages);
              final child = isUgoira
                  ? UgoiraPageContent(illustId: illustId, previewUrl: image.viewUrl, fallbackDownloadUrl: image.downloadUrl, showContextMenu: showControls)
                  : _ImageContextMenuRegion(
                      illustId: illustId,
                      image: image,
                      loadedImages: loadedImages,
                      onTap: onImageTap == null ? null : () => onImageTap!(index),
                      child: imageContent,
                    );

              return ClipRect(
                child: InteractiveViewer(minScale: 1, maxScale: 4, child: SizedBox.expand(child: child)),
              );
            },
          ),
          if (pageCount > 1)
            PositionedDirectional(
              bottom: 16,
              start: 16,
              end: 16,
              child: Center(
                child: _PageIndicator(pageIndex: pageIndex, pageCount: pageCount),
              ),
            ),
          if (showControls && pageCount > 1) ...[
            PositionedDirectional(
              start: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: SurfaceIconButton(
                  icon: Icons.chevron_left,
                  tooltip: context.t.illust.tooltip.previousImage,
                  onPressed: pageIndex == 0 ? null : () => _animateToPage(pageIndex - 1),
                ),
              ),
            ),
            PositionedDirectional(
              end: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: SurfaceIconButton(
                  icon: Icons.chevron_right,
                  tooltip: context.t.illust.tooltip.nextImage,
                  onPressed: pageIndex >= pageCount - 1 ? null : () => _animateToPage(pageIndex + 1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _animateToPage(int index) {
    pageController.animateToPage(index, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
  }
}

class LoadedIllustImages {
  final _images = <String, LoadedImageData>{};

  LoadedImageData? get(String url) {
    return _images[url];
  }

  void put(String url, LoadedImageData data) {
    if (url.isEmpty) {
      return;
    }

    _images[url] = data;
  }
}

class LoadedImageData {
  const LoadedImageData({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

class IllustPageImage {
  const IllustPageImage({required this.viewUrl, required this.originalUrl, required this.previewUrl, required this.aspectRatio, required this.quality});

  final String viewUrl;
  final String originalUrl;
  final String previewUrl;
  final double? aspectRatio;
  final ViewerImageQuality quality;

  String get downloadUrl => originalUrl;

  bool get canUseLoadedDataForDownload {
    return quality == ViewerImageQuality.original && viewUrl == downloadUrl;
  }
}

List<IllustPageImage> illustPageImages(Illust illust, ViewerImageQuality quality) {
  final aspectRatio = _illustAspectRatio(illust);

  if (illust.metaPages.isNotEmpty) {
    return [
      for (final page in illust.metaPages)
        IllustPageImage(
          viewUrl: illustViewerImageUrl(page.imageUrls, quality),
          originalUrl: illustViewerImageUrl(page.imageUrls, ViewerImageQuality.original),
          previewUrl: illustImagePlaceholderUrl(page.imageUrls),
          aspectRatio: aspectRatio,
          quality: quality,
        ),
    ];
  }

  return [
    IllustPageImage(
      viewUrl: illustViewerImageUrl(illust.imageUrls, quality, originalImageUrl: illust.metaSinglePage.originalImageUrl),
      originalUrl: illustViewerImageUrl(illust.imageUrls, ViewerImageQuality.original, originalImageUrl: illust.metaSinglePage.originalImageUrl),
      previewUrl: illustImagePlaceholderUrl(illust.imageUrls),
      aspectRatio: aspectRatio,
      quality: quality,
    ),
  ];
}

class _PageImageContent extends StatelessWidget {
  const _PageImageContent({required this.illustId, required this.index, required this.image, required this.loadedImages});

  final int illustId;
  final int index;
  final IllustPageImage image;
  final LoadedIllustImages loadedImages;

  @override
  Widget build(BuildContext context) {
    return _DetailPixivImage(image: image, fit: BoxFit.contain, loadedImages: loadedImages);
  }
}

class _ImageContextMenuRegion extends StatelessWidget {
  const _ImageContextMenuRegion({required this.illustId, required this.image, required this.loadedImages, required this.child, this.onTap});

  final int illustId;
  final IllustPageImage image;
  final LoadedIllustImages loadedImages;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onSecondaryTapDown: isDesktopPlatform
          ? (details) {
              unawaited(_showImageContextMenu(context, details.globalPosition, illustId, image, loadedImages));
            }
          : null,
      onLongPressStart: isDesktopPlatform
          ? null
          : (details) {
              unawaited(_showImageContextMenu(context, details.globalPosition, illustId, image, loadedImages));
            },
      child: child,
    );
  }
}

class _DetailPixivImage extends StatelessWidget {
  const _DetailPixivImage({required this.image, required this.fit, required this.loadedImages});

  final IllustPageImage image;
  final BoxFit fit;
  final LoadedIllustImages loadedImages;

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      image.viewUrl,
      fit: fit,
      cache: true,
      cacheKey: base64Url.encode(image.viewUrl.codeUnits),
      cacheRawData: true,
      headers: const {'Referer': 'https://www.pixiv.net/'},
      handleLoadingProgress: true,
      loadStateChanged: (state) {
        return switch (state.extendedImageLoadState) {
          LoadState.loading => _ImageLoadingPlaceholder(
            previewUrl: image.previewUrl,
            aspectRatio: image.aspectRatio,
            progress: _imageLoadProgress(state.loadingProgress),
          ),
          LoadState.failed => _ImageLoadError(previewUrl: image.previewUrl, onRetry: state.reLoadImage),
          LoadState.completed => _rememberLoadedImageData(state),
        };
      },
    );
  }

  Widget? _rememberLoadedImageData(ExtendedImageState state) {
    final bytes = _rawImageDataFrom(state);
    if (bytes != null) {
      loadedImages.put(image.viewUrl, LoadedImageData(bytes: bytes, mimeType: _imageMimeTypeFromUrl(image.viewUrl)));
    }

    return null;
  }
}

enum _ImageContextAction { download, copy }

Future<void> _showImageContextMenu(BuildContext context, Offset position, int illustId, IllustPageImage image, LoadedIllustImages loadedImages) async {
  final overlay = Navigator.of(context).overlay;
  if (overlay == null) {
    return;
  }

  final renderBox = overlay.context.findRenderObject() as RenderBox;
  final translations = t;
  final loadedImageData = loadedImages.get(image.viewUrl);
  final downloadNeedsLoadedData = image.canUseLoadedDataForDownload;
  final canDownload = !downloadNeedsLoadedData || loadedImageData != null;
  final action = await showMenu<_ImageContextAction>(
    context: context,
    position: RelativeRect.fromRect(Rect.fromPoints(position, position), Offset.zero & renderBox.size),
    items: [
      PopupMenuItem(
        value: _ImageContextAction.download,
        enabled: canDownload,
        child: ListTile(
          enabled: canDownload,
          leading: const Icon(Icons.download_outlined),
          title: Text(translations.illust.contextMenu.download),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      if (isDesktopPlatform)
        PopupMenuItem(
          value: _ImageContextAction.copy,
          enabled: loadedImageData != null,
          child: ListTile(
            enabled: loadedImageData != null,
            leading: const Icon(Icons.content_copy_outlined),
            title: Text(context.t.illust.contextMenu.copyImage),
            contentPadding: EdgeInsets.zero,
          ),
        ),
    ],
  );

  switch (action) {
    case _ImageContextAction.download:
      unawaited(_downloadImage(illustId, image, loadedImages));
      break;
    case _ImageContextAction.copy:
      unawaited(_copyLoadedImage(image, loadedImages));
      break;
    case null:
      break;
  }
}

Future<void> _downloadImage(int illustId, IllustPageImage image, LoadedIllustImages loadedImages) async {
  try {
    await downloadManager.ensureReadyForDownloads();
    AppToast.info(t.illust.toast.downloadStarted);
    final downloadUri = Uri.parse(image.downloadUrl);
    final loadedImageData = image.canUseLoadedDataForDownload ? loadedImages.get(image.viewUrl) : null;
    final file = loadedImageData == null
        ? await downloadManager.download(
            illustId: illustId,
            url: downloadUri,
            headers: const {'Referer': 'https://www.pixiv.net/'},
            thumbnailUrl: image.previewUrl,
          )
        : await downloadManager.saveBytes(illustId: illustId, bytes: loadedImageData.bytes, sourceUrl: downloadUri, thumbnailUrl: image.previewUrl);
    AppToast.success(t.illust.toast.downloadComplete(path: file.path));
  } catch (error) {
    AppToast.errorWithCause(t.illust.toast.downloadFailed, error);
  }
}

Future<void> _copyLoadedImage(IllustPageImage image, LoadedIllustImages loadedImages) async {
  final label = _imageQualityLabel(image.quality);
  final loadedImageData = loadedImages.get(image.viewUrl);
  if (loadedImageData == null) {
    AppToast.errorWithCause(t.illust.toast.copyFailed(label: label), StateError('Image has not finished loading.'));
    return;
  }

  try {
    await copyImageBytesToClipboard(loadedImageData.bytes, mimeType: loadedImageData.mimeType);
    AppToast.success(t.illust.toast.copied(label: label));
  } catch (error) {
    AppToast.errorWithCause(t.illust.toast.copyFailed(label: label), error);
  }
}

class _ImageLoadingPlaceholder extends StatelessWidget {
  const _ImageLoadingPlaceholder({required this.previewUrl, required this.aspectRatio, this.progress});

  final String previewUrl;
  final double? aspectRatio;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PixivImage(url: previewUrl, fit: BoxFit.contain),
        LayoutBuilder(
          builder: (context, constraints) {
            final rect = _containedImageRect(constraints: constraints, aspectRatio: aspectRatio);

            return Padding(
              padding: EdgeInsets.only(top: rect.top),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: rect.width,
                  child: LinearProgressIndicator(value: progress, minHeight: 3),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ImageLoadError extends StatelessWidget {
  const _ImageLoadError({required this.previewUrl, required this.onRetry});

  final String previewUrl;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        PixivImage(url: previewUrl, fit: BoxFit.contain),
        Center(
          child: Material(
            color: colorScheme.surface.withValues(alpha: 0.9),
            elevation: 2,
            borderRadius: BorderRadius.circular(999),
            child: IconButton(tooltip: context.t.common.retry, icon: const Icon(Icons.refresh_outlined), onPressed: onRetry),
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.pageIndex, required this.pageCount});

  final int pageIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.58), borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          '${pageIndex + 1} / $pageCount',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

double? _illustAspectRatio(Illust illust) {
  if (illust.width <= 0 || illust.height <= 0) {
    return null;
  }

  return illust.width / illust.height;
}

Rect _containedImageRect({required BoxConstraints constraints, required double? aspectRatio}) {
  final width = constraints.maxWidth;
  final height = constraints.maxHeight;
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0 || aspectRatio == null || aspectRatio <= 0) {
    return Rect.fromLTWH(0, 0, width.isFinite ? math.max(0, width) : 0, 0);
  }

  final viewportAspectRatio = width / height;
  if (viewportAspectRatio > aspectRatio) {
    final imageWidth = height * aspectRatio;
    return Rect.fromLTWH((width - imageWidth) / 2, 0, imageWidth, height);
  }

  final imageHeight = width / aspectRatio;
  return Rect.fromLTWH(0, (height - imageHeight) / 2, width, imageHeight);
}

double? _imageLoadProgress(ImageChunkEvent? event) {
  if (event == null) {
    return null;
  }

  final total = event.expectedTotalBytes;
  if (total == null || total <= 0) {
    return null;
  }

  return (event.cumulativeBytesLoaded / total).clamp(0.0, 1.0);
}

Uint8List? _rawImageDataFrom(ExtendedImageState state) {
  try {
    final imageProvider = state.imageWidget.image;
    if (imageProvider is! ExtendedImageProvider<dynamic>) {
      return null;
    }

    return (imageProvider as ExtendedImageProvider<dynamic>).rawImageData;
  } catch (_) {
    return null;
  }
}

String _imageMimeTypeFromUrl(String imageUrl) {
  final uri = Uri.tryParse(imageUrl);
  final path = (uri?.path ?? imageUrl).toLowerCase();
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (path.endsWith('.gif')) {
    return 'image/gif';
  }
  if (path.endsWith('.webp')) {
    return 'image/webp';
  }

  return 'image/png';
}

String _imageQualityLabel(ViewerImageQuality quality) {
  return switch (quality) {
    ViewerImageQuality.large => t.illust.imageLabels.large,
    ViewerImageQuality.original => t.illust.imageLabels.original,
  };
}
