import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/media.dart';
import 'package:path/path.dart' as p;

class OriginalImageViewerArgs {
  const OriginalImageViewerArgs({required this.title, required this.source, required this.pages, this.initialIndex = 0});

  /// What the viewer shows, for its title row and download tasks.
  final String title;

  /// What the pages are part of, which their downloads are filed under.
  final DownloadSource source;
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

/// The original image viewer: black, over the content
/// area only; zoom, pan, double tap and pull down to close; pages turn by
/// swipe, the edge buttons or the arrow keys, but not while zoomed. The top
/// row closes and names the work and the page, the bottom row copies
/// (desktop) and downloads once the original has loaded. Escape and Back
/// close it.
class OriginalImageViewerPage extends StatefulWidget {
  const OriginalImageViewerPage({required this.args, super.key});

  final OriginalImageViewerArgs args;

  @override
  State<OriginalImageViewerPage> createState() => _OriginalImageViewerPageState();
}

class _OriginalImageViewerPageState extends State<OriginalImageViewerPage> {
  late final _pages = PageController(initialPage: widget.args.initialIndex);
  late int _index = widget.args.initialIndex;
  final _loaded = <int, Uint8List?>{};
  bool _zoomed = false;
  bool _busy = false;

  List<OriginalImagePage> get _all => widget.args.pages;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _turn(int by) {
    final next = _index + by;
    if (_zoomed || next < 0 || next >= _all.length) return;
    final duration = FrostMotion.duration(context, FrostMotion.navigation);
    if (duration == Duration.zero) {
      _pages.jumpToPage(next);
    } else {
      unawaited(_pages.animateToPage(next, duration: duration, curve: Curves.easeOutCubic));
    }
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    // Arrow keys belong to a focused text field.
    if (FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _turn(-1);
      case LogicalKeyboardKey.arrowRight:
        _turn(1);
      case LogicalKeyboardKey.escape:
        _close();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _download(Rect? origin) async {
    final bytes = _loaded[_index];
    if (bytes == null || _busy) return;
    setState(() => _busy = true);
    try {
      await downloadManager.ensureReadyForDownloads();
      final page = _all[_index];
      DownloadFlight.launch(
        origin: origin,
        artwork: AppPixivImage(url: page.previewUrl),
      );
      final file = await downloadManager.saveBytes(
        origin: page.downloadOrigin,
        source: widget.args.source,
        bytes: bytes,
        sourceUrl: Uri.parse(page.url),
        thumbnailUrl: page.previewUrl,
      );
      FrostToast.success(t.illust.toast.downloadComplete(name: p.basename(file.path)));
    } catch (error) {
      toastErrorWithCause(t.illust.toast.downloadFailed, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final bytes = _loaded[_index];
    if (bytes == null || _busy) return;
    setState(() => _busy = true);
    final label = t.illust.imageLabels.original;
    try {
      await copyImageBytesToClipboard(bytes, mimeType: imageMimeTypeFromUrl(_all[_index].url));
      FrostToast.copied(t.illust.toast.copied(label: label));
    } catch (error) {
      toastErrorWithCause(t.illust.toast.copyFailed(label: label), error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final ready = _loaded[_index] != null && !_busy;
    Widget chrome(BuildContext context) => FrostMediaChrome(
      top: Row(
        spacing: FrostGap.related,
        children: [
          FrostButton.iconOnMedia(icon: PivIcons.close, label: FrostScope.labelsOf(context).close, onPressed: _close),
          Expanded(
            child: FrostText(
              t.viewer.position(title: widget.args.title, page: _index + 1, total: _all.length),
              content: true,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      bottom: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: FrostGap.related,
        children: [
          if (isDesktopPlatform) FrostButton.iconOnMedia(icon: PivIcons.copy, label: t.illust.contextMenu.copyImage, onPressed: ready ? _copy : null),
          Builder(
            builder: (buttonContext) => FrostButton.iconOnMedia(
              icon: PivIcons.download,
              label: t.illust.contextMenu.download,
              onPressed: ready ? () => unawaited(_download(DownloadFlight.originOf(buttonContext))) : null,
            ),
          ),
        ],
      ),
      start: _index > 0 && !_zoomed
          ? FrostButton.iconOnMedia(icon: FrostIconSet.of(context).chevronLeft, label: t.illust.tooltip.previousImage, onPressed: () => _turn(-1))
          : null,
      end: _index < _all.length - 1 && !_zoomed
          ? FrostButton.iconOnMedia(icon: FrostIconSet.of(context).chevronRight, label: t.illust.tooltip.nextImage, onPressed: () => _turn(1))
          : null,
    );
    return Focus(
      autofocus: true,
      onKeyEvent: _key,
      child: FrostMediaSystemChrome(
        child: PageView.builder(
          controller: _pages,
          physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
          itemCount: _all.length,
          onPageChanged: (index) => setState(() {
            _index = index;
            _zoomed = false;
          }),
          itemBuilder: (context, index) => _ViewerPage(
            page: _all[index],
            overlay: chrome(context),
            onDismiss: _close,
            onZoomChanged: (zoomed) {
              if (index == _index && zoomed != _zoomed) setState(() => _zoomed = zoomed);
            },
            onLoaded: (bytes) {
              if (_loaded[index] == null) setState(() => _loaded[index] = bytes);
            },
            menu: [
              FrostMenuAction(
                t.illust.contextMenu.download,
                leading: const FrostGlyph.icon(PivIcons.download),
                enabled: ready,
                onSelected: () => unawaited(_download(null)),
              ),
              if (isDesktopPlatform)
                FrostMenuAction(
                  t.illust.contextMenu.copyImage,
                  leading: const FrostGlyph.icon(PivIcons.copy),
                  enabled: ready,
                  onSelected: () => unawaited(_copy()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One page: the original over its preview, zoomable, with its own retry.
class _ViewerPage extends ConsumerStatefulWidget {
  const _ViewerPage({
    required this.page,
    required this.overlay,
    required this.onDismiss,
    required this.onZoomChanged,
    required this.onLoaded,
    required this.menu,
  });

  final OriginalImagePage page;
  final Widget overlay;
  final VoidCallback onDismiss;
  final ValueChanged<bool> onZoomChanged;

  /// The encoded original once it has loaded; null where the file is not
  /// kept (sample pictures), which leaves copy and download unavailable.
  final ValueChanged<Uint8List?> onLoaded;
  final List<FrostMenuEntry> menu;

  @override
  ConsumerState<_ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends ConsumerState<_ViewerPage> {
  final _viewport = FrostMediaViewportController();
  ImageStream? _stream;
  ImageStreamListener? _listener;
  int _revision = 0;
  Object? _error;

  /// Zoomed past this the page no longer turns.
  static const _zoomedScale = 1.01;

  @override
  void dispose() {
    _unlisten();
    super.dispose();
  }

  void _unlisten() {
    if (_listener case final listener?) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  void _watch(ImageProvider image) {
    final stream = image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _unlisten();
    final listener = ImageStreamListener(
      // A cached image reports while this page builds.
      (info, _) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoaded(pixivImageBytes(image));
      }),
      onError: (error, _) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _error = error);
      }),
    );
    _stream = stream..addListener(listener);
    _listener = listener;
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final image = pixivImageProvider(ref, page.url, keepBytes: true, revision: _revision);
    _watch(image);
    return FrostContextMenuRegion(
      entries: widget.menu,
      child: FrostMediaViewport(
        controller: _viewport,
        onDismiss: widget.onDismiss,
        onScaleChanged: (scale) => widget.onZoomChanged(scale > _zoomedScale),
        // The media scrim at full strength: the viewer's black ground.
        background: ColoredBox(color: FrostThemeTokens.of(context).onMediaScrim.withValues(alpha: 1), child: const SizedBox.expand()),
        overlay: widget.overlay,
        child: _error != null
            ? Center(
                child: FrostButton.iconOnMedia(
                  icon: PivIcons.refreshCw,
                  label: context.t.common.retry,
                  onPressed: () => setState(() {
                    _error = null;
                    _revision++;
                  }),
                ),
              )
            : Image(
                image: image,
                fit: BoxFit.contain,
                semanticLabel: page.url,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          AppPixivImage(url: page.previewUrl, radius: 0, fit: BoxFit.contain),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: FrostProgressBar(
                              value: switch (progress.expectedTotalBytes) {
                                final total? when total > 0 => progress.cumulativeBytesLoaded / total,
                                _ => 0,
                              },
                              semanticLabel: context.t.viewer.loading,
                            ),
                          ),
                        ],
                      ),
                errorBuilder: (context, error, _) => Center(
                  child: FrostButton.iconOnMedia(icon: PivIcons.refreshCw, label: context.t.common.retry, onPressed: () => setState(() => _revision++)),
                ),
              ),
      ),
    );
  }
}
