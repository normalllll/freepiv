import 'dart:async';

import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/app/window/window_title.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';

import 'dart:math' as math;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';
import 'package:freepiv/shared/ui/fp_icon.dart';

class OriginalImageViewerArgs {
  const OriginalImageViewerArgs({required this.title, required this.pages, required this.initialIndex});

  /// What the viewer shows, for the window title and download tasks.
  final String title;
  final List<OriginalImagePage> pages;
  final int initialIndex;
}

class OriginalImagePage {
  const OriginalImagePage({required this.url, required this.previewUrl, required this.downloadOrigin, this.aspectRatio});

  final String url;
  final String previewUrl;

  /// What saving this page downloads: a work page, or an image of other
  /// content such as a novel.
  final DownloadOrigin downloadOrigin;
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
  final _zoomedPages = <int, bool>{};
  bool _downloading = false;
  bool _copying = false;

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
    final canCopy = currentLoaded && !_copying;

    final appTheme = Theme.of(context);
    final appTokens = FreepivThemeTokens.of(context);
    // The viewer is always a dark neutral stage with dark chrome, whatever
    // the app theme, so artwork is judged against the same surround.
    final viewerTheme = AppTheme.dark(platform: appTheme.platform, locale: Localizations.localeOf(context), accent: appTokens.accent);
    return WindowTitleContribution(
      path: AppRoute.originalImageViewer.path,
      work: WorkWindowTitle(
        id: widget.args,
        kind: 'viewer',
        title: t.nativeWindow.viewerTitle(title: widget.args.title, page: '${_pageIndex + 1}', total: '$pageCount'),
      ),
      child: Theme(data: viewerTheme, child: _buildViewer(pageCount, canDownload, canCopy)),
    );
  }

  Widget _buildViewer(int pageCount, bool canDownload, bool canCopy) {
    return AutoScaffold(
      builder: (context, layout, orientation, useHorizontalLayout) {
        final colorScheme = Theme.of(context).colorScheme;
        const backgroundColor = Color(0xFF111214);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: (useHorizontalLayout)
              ? null
              : AppBar(
                  automaticallyImplyLeading: !useHorizontalLayout,
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                  title: Text('${_pageIndex + 1}/$pageCount'),
                  actions: [
                    IconButton(tooltip: t.illust.contextMenu.copyImage, onPressed: canCopy ? _copyCurrentImage : null, icon: const FpIcon(FpIconName.copy)),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Builder(
                        builder: (buttonContext) => IconButton(
                          tooltip: t.illust.contextMenu.download,
                          onPressed: canDownload ? () => _downloadCurrentImage(origin: DownloadFlight.originOf(buttonContext)) : null,
                          icon: const Icon(Icons.download_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
          body: Focus(
            autofocus: true,
            onKeyEvent: _handleKey,
            child: SafeArea(
              top: false,
              child: ColoredBox(
                color: backgroundColor,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      physics: _zoomedPages[_pageIndex] == true ? const NeverScrollableScrollPhysics() : null,
                      itemCount: pageCount,
                      onPageChanged: (index) => setState(() => _pageIndex = index),
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return _OriginalImageZoomPage(
                          key: ValueKey<String>('original-image-${page.url}'),
                          page: page,
                          onZoomChanged: (zoomed) {
                            if (_zoomedPages[index] != zoomed && mounted) setState(() => _zoomedPages[index] = zoomed);
                          },
                          onLoaded: (data) {
                            if (!mounted) {
                              return;
                            }

                            setState(() => _loadedImages[index] = data);
                          },
                        );
                      },
                    ),
                    if (useHorizontalLayout)
                      PositionedDirectional(
                        top: 12,
                        end: 12,
                        child: FpSurface(
                          role: FpSurfaceRole.chrome,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${_pageIndex + 1}/$pageCount'),
                                const SizedBox(width: 16),
                                IconButton(
                                  tooltip: t.illust.contextMenu.copyImage,
                                  onPressed: canCopy ? _copyCurrentImage : null,
                                  icon: const FpIcon(FpIconName.copy),
                                ),
                                Builder(
                                  builder: (buttonContext) => IconButton(
                                    tooltip: t.illust.contextMenu.download,
                                    onPressed: canDownload ? () => _downloadCurrentImage(origin: DownloadFlight.originOf(buttonContext)) : null,
                                    icon: const Icon(Icons.download_outlined),
                                  ),
                                ),
                                IconButton(
                                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                                  onPressed: () => Navigator.of(context).maybePop(),
                                  icon: const FpIcon(FpIconName.close),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (useHorizontalLayout && pageCount > 1) ...[
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
          ),
        );
      },
    );
  }

  void _animateToPage(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(index);
      return;
    }
    _pageController.animateToPage(index, duration: AppMotion.exit, curve: Curves.easeOutCubic);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    final editing = FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
    if (editing || _zoomedPages[_pageIndex] == true) return KeyEventResult.ignored;
    if ((key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) && _pages.length > 1) {
      final direction = key == LogicalKeyboardKey.arrowRight ? 1 : -1;
      final next = _pageIndex + direction;
      if (next >= 0 && next < _pages.length) _animateToPage(next);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _copyCurrentImage() async {
    final image = _loadedImages[_pageIndex];
    if (image == null || _copying) return;
    setState(() => _copying = true);
    try {
      await copyImageBytesToClipboard(image.bytes, mimeType: image.mimeType);
      unawaited(AppToast.copied(t.illust.toast.copied(label: t.illust.imageLabels.original)));
    } catch (error) {
      AppToast.errorWithCause(t.illust.toast.copyFailed(label: t.illust.imageLabels.original), error);
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  /// [origin] is the tapped button, for the flight to the download badge.
  Future<void> _downloadCurrentImage({Rect? origin}) async {
    final loadedImage = _loadedImages[_pageIndex];
    if (loadedImage == null || _downloading) {
      return;
    }

    setState(() => _downloading = true);
    try {
      await downloadManager.ensureReadyForDownloads();
      final page = _pages[_pageIndex];
      DownloadFlight.launch(origin: origin, imageUrl: page.previewUrl);
      final file = await downloadManager.saveBytes(
        origin: page.downloadOrigin,
        bytes: loadedImage.bytes,
        sourceUrl: Uri.parse(page.url),
        title: widget.args.title,
        thumbnailUrl: page.previewUrl,
      );
      AppToast.success(t.illust.toast.downloadComplete(name: p.basename(file.path)));
    } catch (error) {
      AppToast.errorWithCause(t.illust.toast.downloadFailed, error);
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }
}

class _OriginalImageZoomPage extends ConsumerStatefulWidget {
  const _OriginalImageZoomPage({required this.page, required this.onLoaded, required this.onZoomChanged, super.key});

  final OriginalImagePage page;
  final ValueChanged<_LoadedOriginalImageData> onLoaded;
  final ValueChanged<bool> onZoomChanged;

  @override
  ConsumerState<_OriginalImageZoomPage> createState() => _OriginalImageZoomPageState();
}

class _OriginalImageZoomPageState extends ConsumerState<_OriginalImageZoomPage> {
  bool _notifiedLoaded = false;
  final TransformationController _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _transform.addListener(_notifyZoom);
  }

  void _notifyZoom() => widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.01);

  @override
  void dispose() {
    _transform.removeListener(_notifyZoom);
    _transform.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _OriginalImageZoomPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.url != widget.page.url) {
      _notifiedLoaded = false;
      _transform.value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = FreepivThemeTokens.of(context).surfaceInset;

    return ClipRect(
      child: ColoredBox(
        color: backgroundColor,
        child: InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: 6,
          boundaryMargin: const EdgeInsets.all(96),
          child: SizedBox.expand(
            child: ExtendedImage(
              image: RustExtendedNetworkImageProvider(
                request: MediaRequest(url: widget.page.url),
                cacheRawData: true,
                mediaStream: ref.watch(rustMediaTransportProvider).stream,
              ),
              fit: BoxFit.contain,
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
        if (page.previewUrl != page.url)
          PixivImage(url: page.previewUrl, fit: BoxFit.contain)
        else
          ColoredBox(color: FreepivThemeTokens.of(context).surfaceInset),
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
                    borderRadius: BorderRadius.circular(AppMetrics.controlRadius),
                    boxShadow: [BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: SizedBox(
                      width: progressWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppMetrics.controlRadius),
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
        if (page.previewUrl != page.url)
          PixivImage(url: page.previewUrl, fit: BoxFit.contain)
        else
          ColoredBox(color: FreepivThemeTokens.of(context).surfaceInset),
        Center(
          child: Material(
            color: colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppMetrics.controlRadius),
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
