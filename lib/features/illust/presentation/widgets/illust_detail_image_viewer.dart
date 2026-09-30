import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_ugoira_viewer.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:url_launcher/url_launcher.dart';

class IllustImagePager extends StatelessWidget {
  const IllustImagePager({
    required this.artwork,
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

  final ArtworkSource artwork;
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
    final pageCount = isUgoira ? 1 : imagePages.length;
    final heroTag = ArtworkHeroScope.maybeOf(context);

    // No stage colour: letterboxing shows the page's artwork backdrop.
    return ColoredBox(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            key: PageStorageKey<String>('illust-image-page-${artwork.illustId}'),
            controller: pageController,
            itemCount: pageCount,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final image = imagePages[isUgoira ? 0 : index];
              Widget content = isUgoira
                  ? UgoiraPageContent(artwork: artwork, previewUrl: image.viewUrl, fallbackDownloadUrl: image.downloadUrl, showContextMenu: true)
                  : _PageImageContent(artwork: artwork, index: index, image: image, loadedImages: loadedImages);
              // The first page is what the opening card showed. It flies back
              // only while it is the page on screen; from another page the
              // return is an ordinary transition, not a jump to page one.
              if (heroTag != null && index == 0) {
                content = _StageHero(tag: heroTag, aspectRatio: image.aspectRatio ?? heroTag.aspectRatio, enabled: pageIndex == 0, child: content);
              }
              final child = isUgoira
                  ? content
                  : _ImageContextMenuRegion(
                      artwork: artwork,
                      pageIndex: index,
                      image: image,
                      imagePages: imagePages,
                      loadedImages: loadedImages,
                      onTap: onImageTap == null ? null : () => onImageTap!(index),
                      child: content,
                    );

              return ClipRect(
                // The mobile detail scroll owns vertical drags. Tapping the
                // image opens the original viewer, which retains pinch zoom.
                child: MediaQuery.sizeOf(context).width < 960
                    ? SizedBox.expand(child: child)
                    : InteractiveViewer(minScale: 1, maxScale: 4, child: SizedBox.expand(child: child)),
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
                  onPressed: pageIndex == 0 ? null : () => _animateToPage(context, pageIndex - 1),
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
                  onPressed: pageIndex >= pageCount - 1 ? null : () => _animateToPage(context, pageIndex + 1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _animateToPage(BuildContext context, int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      pageController.jumpToPage(index);
      return;
    }
    pageController.animateToPage(index, duration: AppMotion.exit, curve: Curves.easeOutCubic);
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

/// The work as the downloads list shows the pages saved from it.
ArtworkSource artworkDownloadSource(Illust illust) =>
    ArtworkSource(illustId: illust.id, title: illust.title, subtitle: illust.user.name, thumbnailUrl: illust.imageUrls.squareMedium);

/// The detail stage's pages. The first page's placeholder is the very preview
/// the artwork cards show ([previewQuality]), already cached when the work
/// was opened from a list, so the stage never loads a second small image.
List<IllustPageImage> illustPageImages(Illust illust, ViewerImageQuality quality, PreviewImageQuality previewQuality) {
  final aspectRatio = _illustAspectRatio(illust);
  final cardPreviewUrl = illustPreviewImageUrl(illust.imageUrls, previewQuality);

  if (illust.metaPages.isNotEmpty) {
    return [
      for (final (index, page) in illust.metaPages.indexed)
        IllustPageImage(
          viewUrl: illustViewerImageUrl(page.imageUrls, quality),
          originalUrl: illustViewerImageUrl(page.imageUrls, ViewerImageQuality.original),
          previewUrl: index == 0 ? cardPreviewUrl : illustImagePlaceholderUrl(page.imageUrls),
          aspectRatio: aspectRatio,
          quality: quality,
        ),
    ];
  }

  return [
    IllustPageImage(
      viewUrl: illustViewerImageUrl(illust.imageUrls, quality, originalImageUrl: illust.metaSinglePage.originalImageUrl),
      originalUrl: illustViewerImageUrl(illust.imageUrls, ViewerImageQuality.original, originalImageUrl: illust.metaSinglePage.originalImageUrl),
      previewUrl: cardPreviewUrl,
      aspectRatio: aspectRatio,
      quality: quality,
    ),
  ];
}

/// The first page's hero, sized to the picture as the stage shows it
/// (contained and centred) rather than to the whole stage. Both ends of the
/// flight are then the picture itself, so the flight only moves, scales and
/// uncrops it; a stage wider than the picture (a tall work under the height
/// cap) can no longer make it shrink and regrow on landing. The page's taps
/// and context menu still cover the whole stage.
class _StageHero extends StatelessWidget {
  const _StageHero({required this.tag, required this.aspectRatio, required this.enabled, required this.child});

  final ArtworkHeroTag tag;
  final double aspectRatio;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final picture = applyBoxFit(BoxFit.contain, Size(aspectRatio, 1), constraints.biggest).destination;
        return Center(
          child: SizedBox.fromSize(
            size: picture,
            child: HeroMode(
              enabled: enabled,
              child: ArtworkHero(tag: tag, child: child),
            ),
          ),
        );
      },
    );
  }
}

class _PageImageContent extends StatelessWidget {
  const _PageImageContent({required this.artwork, required this.index, required this.image, required this.loadedImages});

  final ArtworkSource artwork;
  final int index;
  final IllustPageImage image;
  final LoadedIllustImages loadedImages;

  @override
  Widget build(BuildContext context) {
    return _DetailPixivImage(image: image, fit: BoxFit.contain, loadedImages: loadedImages);
  }
}

class _ImageContextMenuRegion extends StatelessWidget {
  const _ImageContextMenuRegion({
    required this.artwork,
    required this.pageIndex,
    required this.image,
    required this.imagePages,
    required this.loadedImages,
    required this.child,
    this.onTap,
  });

  final ArtworkSource artwork;
  final int pageIndex;
  final IllustPageImage image;
  final List<IllustPageImage> imagePages;
  final LoadedIllustImages loadedImages;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onSecondaryTapDown: (details) {
        unawaited(showIllustImageContextMenu(context, details.globalPosition, artwork, pageIndex, image, imagePages, loadedImages));
      },
      onLongPressStart: (details) {
        unawaited(showIllustImageContextMenu(context, details.globalPosition, artwork, pageIndex, image, imagePages, loadedImages));
      },
      child: child,
    );
  }
}

class _DetailPixivImage extends ConsumerWidget {
  const _DetailPixivImage({required this.image, required this.fit, required this.loadedImages});

  final IllustPageImage image;
  final BoxFit fit;
  final LoadedIllustImages loadedImages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExtendedImage(
      image: RustExtendedNetworkImageProvider(
        request: MediaRequest(url: image.viewUrl),
        cacheRawData: true,
        mediaStream: ref.watch(rustMediaTransportProvider).stream,
      ),
      fit: fit,
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
      loadedImages.put(image.viewUrl, LoadedImageData(bytes: bytes, mimeType: imageMimeTypeFromUrl(image.viewUrl)));
    }

    return null;
  }
}

enum _ImageContextAction { download, downloadAll, copy, copyLink, openOriginal }

Future<void> showIllustImageContextMenu(
  BuildContext context,
  Offset position,
  ArtworkSource artwork,
  int pageIndex,
  IllustPageImage image,
  List<IllustPageImage> imagePages,
  LoadedIllustImages loadedImages, {
  bool linkOnly = false,
  bool secondaryOnly = false,
}) async {
  final overlay = Navigator.of(context).overlay;
  if (overlay == null) {
    return;
  }
  final overlayContext = overlay.context;

  final translations = t;
  final loadedImageData = loadedImages.get(image.viewUrl);
  final downloadNeedsLoadedData = image.canUseLoadedDataForDownload;
  final alreadyDownloading = linkOnly ? false : await _isImageAlreadyDownloading(artwork.illustId, pageIndex);
  if (!context.mounted || !overlayContext.mounted) {
    return;
  }

  // Both button and pointer anchors arrive in global coordinates. showMenu
  // positions within this Navigator's Overlay, which may be offset by the
  // desktop rail and caption bar.
  final renderBox = overlayContext.findRenderObject() as RenderBox;
  final localPosition = renderBox.globalToLocal(position);
  final anchor = Offset(
    localPosition.dx.clamp(8.0, math.max(8.0, renderBox.size.width - 8)),
    localPosition.dy.clamp(8.0, math.max(8.0, renderBox.size.height - 8)),
  );
  final canDownload = (!downloadNeedsLoadedData || loadedImageData != null) && !alreadyDownloading;
  final action = await showMenu<_ImageContextAction>(
    context: context,
    clipBehavior: Clip.antiAlias,
    position: RelativeRect.fromRect(Rect.fromPoints(anchor, anchor), Offset.zero & renderBox.size),
    items: [
      if (!linkOnly && !secondaryOnly)
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
      if (!linkOnly && imagePages.length > 1)
        PopupMenuItem(
          value: _ImageContextAction.downloadAll,
          child: ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: Text(translations.illust.contextMenu.downloadAll),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      if (!linkOnly && isDesktopPlatform)
        PopupMenuItem(
          value: _ImageContextAction.copy,
          enabled: loadedImageData != null,
          child: ListTile(
            enabled: loadedImageData != null,
            leading: const Icon(Icons.content_copy_outlined),
            title: Text(translations.illust.contextMenu.copyImage),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      if (!secondaryOnly)
        PopupMenuItem(
          value: _ImageContextAction.copyLink,
          child: ListTile(leading: const Icon(Icons.link_outlined), title: Text(translations.illust.contextMenu.copyLink), contentPadding: EdgeInsets.zero),
        ),
      PopupMenuItem(
        value: _ImageContextAction.openOriginal,
        child: ListTile(
          leading: const Icon(Icons.open_in_new_outlined),
          title: Text(translations.illust.contextMenu.openOriginal),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ],
  );

  switch (action) {
    case _ImageContextAction.download:
      unawaited(_downloadImage(artwork, pageIndex, image, loadedImages, origin: Rect.fromCenter(center: position, width: 48, height: 48)));
      break;
    case _ImageContextAction.downloadAll:
      unawaited(_downloadAllImages(artwork, imagePages, origin: Rect.fromCenter(center: position, width: 48, height: 48)));
      break;
    case _ImageContextAction.copy:
      unawaited(_copyLoadedImage(image, loadedImages));
      break;
    case _ImageContextAction.copyLink:
      unawaited(_copyIllustLink(artwork.illustId));
      break;
    case _ImageContextAction.openOriginal:
      unawaited(_openIllustOnPixiv(artwork.illustId));
      break;
    case null:
      break;
  }
}

Future<void> _copyIllustLink(int illustId) async {
  final url = 'https://www.pixiv.net/artworks/$illustId';
  try {
    await copyTextToClipboard(url);
    unawaited(AppToast.copied(t.illust.toast.linkCopied));
  } catch (error) {
    AppToast.errorWithCause(t.illust.toast.linkCopyFailed, error);
  }
}

Future<void> _openIllustOnPixiv(int illustId) async {
  try {
    final opened = await launchUrl(Uri.parse('https://www.pixiv.net/artworks/$illustId'), mode: LaunchMode.externalApplication);
    if (!opened) {
      throw StateError('No external application accepted the artwork URL.');
    }
  } catch (error) {
    AppToast.errorWithCause(t.illust.toast.openFailed, error);
  }
}

/// [origin] is where the download was asked for (the tapped button, or the
/// pointer for a context menu); a copy of the page flies from there to the
/// download badge once the task is accepted.
Future<void> _downloadImage(ArtworkSource artwork, int pageIndex, IllustPageImage image, LoadedIllustImages loadedImages, {Rect? origin}) async {
  try {
    await downloadManager.ensureReadyForDownloads();
    DownloadFlight.launch(
      origin: origin,
      artwork: PixivImage(url: image.previewUrl),
    );
    final downloadUri = Uri.parse(image.downloadUrl);
    final loadedImageData = image.canUseLoadedDataForDownload ? loadedImages.get(image.viewUrl) : null;
    final file = loadedImageData == null
        ? await downloadManager.download(
            origin: ArtworkPage(illustId: artwork.illustId, pageIndex: pageIndex),
            source: artwork,
            url: downloadUri,
            networkOptions: const DownloadNetworkOptions(headers: {'Referer': 'https://www.pixiv.net/'}),
            thumbnailUrl: image.previewUrl,
          )
        : await downloadManager.saveBytes(
            origin: ArtworkPage(illustId: artwork.illustId, pageIndex: pageIndex),
            source: artwork,
            bytes: loadedImageData.bytes,
            sourceUrl: downloadUri,
            thumbnailUrl: image.previewUrl,
          );
    AppToast.success(t.illust.toast.downloadComplete(name: p.basename(file.path)));
  } catch (error) {
    AppToast.errorWithCause(t.illust.toast.downloadFailed, error);
  }
}

Future<void> _downloadAllImages(ArtworkSource artwork, List<IllustPageImage> imagePages, {Rect? origin}) async {
  try {
    await downloadManager.ensureReadyForDownloads();
    DownloadFlight.launch(
      origin: origin,
      artwork: switch (imagePages.firstOrNull) {
        final page? => PixivImage(url: page.previewUrl),
        null => null,
      },
    );
    final jobs = [
      for (var index = 0; index < imagePages.length; index++)
        DownloadJob.create(
          origin: ArtworkPage(illustId: artwork.illustId, pageIndex: index),
          source: artwork,
          url: Uri.parse(imagePages[index].downloadUrl),
          networkOptions: const DownloadNetworkOptions(headers: {'Referer': 'https://www.pixiv.net/'}),
          saveTarget: const SaveTarget.downloadsFolder(),
          thumbnailUrl: imagePages[index].previewUrl,
        ),
    ];
    final queuedCount = await downloadManager.enqueue(jobs);
    AppToast.info(t.illust.toast.downloadAllQueued(count: queuedCount));
  } catch (error) {
    AppToast.errorWithCause(t.illust.toast.downloadFailed, error);
  }
}

Future<bool> _isImageAlreadyDownloading(int illustId, int pageIndex) async {
  final tasks = await downloadManager.listTasks(illustId: illustId);
  return tasks.any((task) {
    return task.origin == ArtworkPage(illustId: illustId, pageIndex: pageIndex) &&
        (task.status == DownloadStatus.queued ||
            task.status == DownloadStatus.running ||
            task.status == DownloadStatus.paused ||
            task.saveState == SaveState.pending ||
            task.saveState == SaveState.saving);
  });
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
    unawaited(AppToast.copied(t.illust.toast.copied(label: label)));
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
            borderRadius: BorderRadius.circular(AppMetrics.controlRadius),
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
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.58), borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
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

String _imageQualityLabel(ViewerImageQuality quality) {
  return switch (quality) {
    ViewerImageQuality.large => t.illust.imageLabels.large,
    ViewerImageQuality.original => t.illust.imageLabels.original,
  };
}

/// Work actions for the page currently shown. The wide and narrow detail
/// layouts render the same set in one action row: download and copy link
/// directly, everything else in "more", so each action has one entry.
class IllustPageActions {
  const IllustPageActions({required this.artwork, required this.pageIndex, required this.imagePages, required this.loadedImages, required this.isUgoira});

  final ArtworkSource artwork;
  final int pageIndex;
  final List<IllustPageImage> imagePages;
  final LoadedIllustImages loadedImages;
  final bool isUgoira;

  bool get canDownload => !isUgoira && imagePages.isNotEmpty;

  IllustPageImage get _page => imagePages[pageIndex.clamp(0, imagePages.length - 1)];

  /// Downloads the current page; [origin] is the tapped button's rect, for
  /// the flight to the download badge.
  Future<void> download({Rect? origin}) async {
    if (!canDownload) return;
    final index = pageIndex.clamp(0, imagePages.length - 1);
    if (await _isImageAlreadyDownloading(artwork.illustId, index)) {
      AppToast.info(t.illust.toast.alreadyDownloading);
      return;
    }
    await _downloadImage(artwork, index, _page, loadedImages, origin: origin);
  }

  Future<void> copyLink() => _copyIllustLink(artwork.illustId);

  Future<void> showMore(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject();
    if (box is! RenderBox || imagePages.isEmpty) {
      await _openIllustOnPixiv(artwork.illustId);
      return;
    }
    await showIllustImageContextMenu(
      buttonContext,
      box.localToGlobal(box.size.bottomLeft(Offset.zero)),
      artwork,
      pageIndex.clamp(0, imagePages.length - 1),
      _page,
      imagePages,
      loadedImages,
      linkOnly: isUgoira,
      secondaryOnly: true,
    );
  }
}
