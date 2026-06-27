import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';

class OriginalImageViewerArgs {
  const OriginalImageViewerArgs({required this.workId, required this.pages, required this.initialIndex, this.title});

  final int workId;
  final List<OriginalImagePage> pages;
  final int initialIndex;
  final String? title;
}

class OriginalImagePage {
  const OriginalImagePage({required this.url, required this.previewUrl, this.aspectRatio});

  final String url;
  final String previewUrl;
  final double? aspectRatio;
}

class OriginalImageViewerPage extends StatefulWidget {
  const OriginalImageViewerPage({required this.args, super.key});

  final OriginalImageViewerArgs args;

  @override
  State<OriginalImageViewerPage> createState() => _OriginalImageViewerPageState();
}

class _OriginalImageViewerPageState extends State<OriginalImageViewerPage> {
  late final PageController _pageController;
  late int _pageIndex;
  final _loadedImages = <int, _LoadedOriginalImageData>{};
  bool _downloading = false;

  List<OriginalImagePage> get _pages => widget.args.pages;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.args.initialIndex.clamp(0, _pages.length - 1).toInt();
    _pageController = PageController(initialPage: _pageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = _pages.length;
    final currentLoaded = _loadedImages.containsKey(_pageIndex);
    final canDownload = currentLoaded && !_downloading;

    return AutoScaffold(
      builder: (context, layout, orientation, shouldUseDesktopShell) {
        final colorScheme = Theme.of(context).colorScheme;
        final backgroundColor = colorScheme.surfaceContainerHighest;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: !shouldUseDesktopShell,
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            title: Text('${_pageIndex + 1}/$pageCount'),
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: TextButton.icon(
                  onPressed: canDownload ? _downloadCurrentImage : null,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(t.illust.contextMenu.download),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.48),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ColoredBox(
              color: backgroundColor,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: pageCount,
                    onPageChanged: (index) => setState(() => _pageIndex = index),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return _OriginalImageZoomPage(
                        key: ValueKey<String>('original-image-${page.url}'),
                        page: page,
                        onLoaded: (data) {
                          if (!mounted) {
                            return;
                          }

                          setState(() => _loadedImages[index] = data);
                        },
                      );
                    },
                  ),
                  if (shouldUseDesktopShell && pageCount > 1) ...[
                    PositionedDirectional(
                      start: 24,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: SurfaceIconButton(
                          icon: Icons.chevron_left,
                          tooltip: context.t.illust.tooltip.previousImage,
                          iconSize: 30,
                          onPressed: _pageIndex == 0 ? null : () => _animateToPage(_pageIndex - 1),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: 24,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: SurfaceIconButton(
                          icon: Icons.chevron_right,
                          tooltip: context.t.illust.tooltip.nextImage,
                          iconSize: 30,
                          onPressed: _pageIndex >= pageCount - 1 ? null : () => _animateToPage(_pageIndex + 1),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _animateToPage(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
  }

  Future<void> _downloadCurrentImage() async {
    final loadedImage = _loadedImages[_pageIndex];
    if (loadedImage == null || _downloading) {
      return;
    }

    setState(() => _downloading = true);
    try {
      await downloadManager.ensureReadyForDownloads();
      AppToast.info(t.illust.toast.downloadStarted);
      final page = _pages[_pageIndex];
      final file = await downloadManager.saveBytes(
        illustId: widget.args.workId,
        bytes: loadedImage.bytes,
        sourceUrl: Uri.parse(page.url),
        title: widget.args.title,
        thumbnailUrl: page.previewUrl,
      );
      AppToast.success(t.illust.toast.downloadComplete(path: file.path));
    } catch (error) {
      AppToast.errorWithCause(t.illust.toast.downloadFailed, error);
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }
}

class _OriginalImageZoomPage extends StatefulWidget {
  const _OriginalImageZoomPage({required this.page, required this.onLoaded, super.key});

  final OriginalImagePage page;
  final ValueChanged<_LoadedOriginalImageData> onLoaded;

  @override
  State<_OriginalImageZoomPage> createState() => _OriginalImageZoomPageState();
}

class _OriginalImageZoomPageState extends State<_OriginalImageZoomPage> {
  bool _notifiedLoaded = false;

  @override
  void didUpdateWidget(covariant _OriginalImageZoomPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.url != widget.page.url) {
      _notifiedLoaded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return ClipRect(
      child: ColoredBox(
        color: backgroundColor,
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 6,
          boundaryMargin: const EdgeInsets.all(96),
          child: SizedBox.expand(
            child: ExtendedImage.network(
              widget.page.url,
              fit: BoxFit.contain,
              cache: true,
              cacheKey: base64Url.encode(widget.page.url.codeUnits),
              cacheRawData: true,
              headers: const {'Referer': 'https://www.pixiv.net/'},
              handleLoadingProgress: true,
              loadStateChanged: (state) {
                return switch (state.extendedImageLoadState) {
                  LoadState.loading => _OriginalImageLoadingPlaceholder(page: widget.page, progress: _imageLoadProgress(state.loadingProgress)),
                  LoadState.failed => _OriginalImageLoadError(page: widget.page, onRetry: state.reLoadImage),
                  LoadState.completed => _rememberLoadedImageData(state),
                };
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget? _rememberLoadedImageData(ExtendedImageState state) {
    if (_notifiedLoaded) {
      return null;
    }

    final bytes = _rawImageDataFrom(state);
    if (bytes == null) {
      return null;
    }

    _notifiedLoaded = true;
    final data = _LoadedOriginalImageData(bytes: bytes, mimeType: _imageMimeTypeFromUrl(widget.page.url));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onLoaded(data);
      }
    });

    return null;
  }
}

class _LoadedOriginalImageData {
  const _LoadedOriginalImageData({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

class _OriginalImageLoadingPlaceholder extends StatelessWidget {
  const _OriginalImageLoadingPlaceholder({required this.page, this.progress});

  final OriginalImagePage page;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (page.previewUrl != page.url) PixivImage(url: page.previewUrl, fit: BoxFit.contain) else ColoredBox(color: colorScheme.surfaceContainerHighest),
        LayoutBuilder(
          builder: (context, constraints) {
            final imageRect = _containedImageRect(constraints: constraints, aspectRatio: page.aspectRatio);
            final progressWidth = _progressWidth(constraints: constraints, imageRect: imageRect);
            final topPadding = math.max(14.0, imageRect.top + 14.0);

            return Padding(
              padding: EdgeInsets.only(top: topPadding, left: 20, right: 20),
              child: Align(
                alignment: Alignment.topCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: SizedBox(
                      width: progressWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(value: progress, minHeight: 4),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OriginalImageLoadError extends StatelessWidget {
  const _OriginalImageLoadError({required this.page, required this.onRetry});

  final OriginalImagePage page;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (page.previewUrl != page.url) PixivImage(url: page.previewUrl, fit: BoxFit.contain) else ColoredBox(color: colorScheme.surfaceContainerHighest),
        Center(
          child: Material(
            color: colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
            child: IconButton(tooltip: context.t.common.retry, color: colorScheme.onSurface, icon: const Icon(Icons.refresh_outlined), onPressed: onRetry),
          ),
        ),
      ],
    );
  }
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

double _progressWidth({required BoxConstraints constraints, required Rect imageRect}) {
  final availableWidth = constraints.maxWidth.isFinite ? math.max(0.0, constraints.maxWidth - 40) : 360.0;
  final imageWidth = imageRect.width > 0 ? imageRect.width : availableWidth;
  return math.min(520.0, math.max(180.0, math.min(availableWidth, imageWidth * 0.72)));
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
