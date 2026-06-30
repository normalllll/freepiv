import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/api/download.dart';
import 'package:freepiv/src/rust/api/image_utils.dart';
import 'package:freepiv/src/rust/api/zip_utils.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

class UgoiraPageContent extends StatefulWidget {
  const UgoiraPageContent({required this.illustId, required this.previewUrl, required this.fallbackDownloadUrl, required this.showContextMenu, super.key});

  final int illustId;
  final String previewUrl;
  final String fallbackDownloadUrl;
  final bool showContextMenu;

  @override
  State<UgoiraPageContent> createState() => _UgoiraPageContentState();
}

final _ugoiraDataCache = <int, _CachedUgoiraData>{};

class _CachedUgoiraData {
  UgoiraMetadataContent? metadata;
  Uint8List? zipBytes;
  _UgoiraFrames? frames;
  Uint8List? gifBytes;
  Future<UgoiraMetadataContent>? metadataFuture;
  Future<Uint8List>? zipBytesFuture;
  Future<_UgoiraFrames>? framesFuture;
  Future<Uint8List>? gifFuture;
}

class _UgoiraFrames {
  const _UgoiraFrames({required this.bytes, required this.delays});

  final List<Uint8List> bytes;
  final List<int> delays;
}

enum _UgoiraAction { downloadGif, copyGif }

enum _UgoiraPhase { idle, fetchingMetadata, downloadingZip, extractingFrames, decodingFrames, composingGif, savingGif, ready, failed }

class _UgoiraPageContentState extends State<UgoiraPageContent> {
  late final _CachedUgoiraData _cache;
  UgoiraMetadataContent? _metadata;
  Uint8List? _zipBytes;
  List<Uint8List>? _frameBytes;
  List<int>? _delays;
  List<ui.Image>? _frameImages;
  Uint8List? _gifBytes;
  Future<void>? _playbackFuture;
  _UgoiraPhase _phase = _UgoiraPhase.idle;
  double? _progress;

  @override
  void initState() {
    super.initState();
    _cache = _ugoiraDataCache.putIfAbsent(widget.illustId, _CachedUgoiraData.new);
    _metadata = _cache.metadata;
    _zipBytes = _cache.zipBytes;
    _frameBytes = _cache.frames?.bytes;
    _delays = _cache.frames?.delays;
    _gifBytes = _cache.gifBytes;
  }

  @override
  void dispose() {
    for (final image in _frameImages ?? const <ui.Image>[]) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startPlayback,
      onSecondaryTapDown: widget.showContextMenu && isDesktopPlatform ? (details) => unawaited(_showContextMenu(context, details.globalPosition)) : null,
      onLongPressStart: isDesktopPlatform ? null : (details) => unawaited(_showContextMenu(context, details.globalPosition)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_frameImages case final frames? when frames.isNotEmpty)
            _UgoiraFramePlayer(frames: frames, delays: _delays ?? const <int>[])
          else
            PixivImage(url: widget.previewUrl, fit: BoxFit.contain),
          if (_phase == _UgoiraPhase.idle || _phase == _UgoiraPhase.failed)
            Center(
              child: IgnorePointer(child: _UgoiraPlayButton(failed: _phase == _UgoiraPhase.failed)),
            ),
          if (_isBusyPhase(_phase))
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _UgoiraProgressPanel(label: _ugoiraPhaseLabel(_phase), progress: _progress),
              ),
            ),
        ],
      ),
    );

    if (widget.showContextMenu) {
      content = MouseRegion(cursor: SystemMouseCursors.click, child: content);
    }

    return content;
  }

  Future<void> _startPlayback() async {
    if (_frameImages != null) {
      return;
    }

    _playbackFuture ??= _loadPlaybackData();
    try {
      await _playbackFuture;
    } finally {
      _playbackFuture = null;
    }
  }

  Future<void> _loadPlaybackData() async {
    try {
      await _ensureFrameBytes();
      final frameBytes = _frameBytes ?? const <Uint8List>[];
      final decodedImages = <ui.Image>[];
      for (var index = 0; index < frameBytes.length; index += 1) {
        _setPhase(_UgoiraPhase.decodingFrames, progress: frameBytes.isEmpty ? null : index / frameBytes.length);
        decodedImages.add(await _decodeImage(frameBytes[index]));
      }

      _setPhase(_UgoiraPhase.decodingFrames, progress: 1);
      if (!mounted) {
        for (final image in decodedImages) {
          image.dispose();
        }
        return;
      }

      setState(() {
        _frameImages = decodedImages;
        _phase = _UgoiraPhase.ready;
        _progress = null;
      });
    } catch (error) {
      _setFailed(error);
      AppToast.errorWithCause(t.illust.toast.downloadFailed, error);
    }
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    final overlay = Navigator.of(context).overlay;
    if (overlay == null) {
      return;
    }

    final renderBox = overlay.context.findRenderObject() as RenderBox;
    final action = await showMenu<_UgoiraAction>(
      context: context,
      position: RelativeRect.fromRect(Rect.fromPoints(position, position), Offset.zero & renderBox.size),
      items: [
        PopupMenuItem(
          value: _UgoiraAction.downloadGif,
          child: ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text('${context.t.illust.contextMenu.download} GIF'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (isDesktopPlatform)
          PopupMenuItem(
            value: _UgoiraAction.copyGif,
            child: ListTile(
              leading: const Icon(Icons.content_copy_outlined),
              title: Text('${context.t.illust.contextMenu.copyImage} GIF'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );

    switch (action) {
      case _UgoiraAction.downloadGif:
        unawaited(_downloadGif());
        break;
      case _UgoiraAction.copyGif:
        unawaited(_copyGif());
        break;
      case null:
        break;
    }
  }

  Future<void> _downloadGif() async {
    try {
      await downloadManager.ensureReadyForDownloads();
      AppToast.info(t.illust.toast.downloadStarted);
      await _ensurePlaybackStartedForExport();
      final gifBytes = await _ensureGifBytes();
      _setPhase(_UgoiraPhase.savingGif, progress: null);
      final zipUrl = _metadata?.zipUrls.medium;
      final zipUri = Uri.parse(zipUrl == null || zipUrl.isEmpty ? widget.fallbackDownloadUrl : zipUrl);
      final file = await downloadManager.saveBytes(
        illustId: widget.illustId,
        bytes: gifBytes,
        sourceUrl: zipUri,
        filename: '${widget.illustId}.gif',
        thumbnailUrl: widget.previewUrl,
      );
      _setReadyAfterExport();
      AppToast.success(t.illust.toast.downloadComplete(path: file.path));
    } catch (error) {
      _setFailed(error);
      AppToast.errorWithCause(t.illust.toast.downloadFailed, error);
    }
  }

  Future<void> _copyGif() async {
    const label = 'GIF';
    AppToast.info(t.illust.toast.copying(label: label));
    try {
      await _ensurePlaybackStartedForExport();
      final gifBytes = await _ensureGifBytes();
      await copyImageBytesToClipboard(gifBytes, mimeType: 'image/gif');
      _setReadyAfterExport();
      AppToast.success(t.illust.toast.copied(label: label));
    } catch (error) {
      _setFailed(error);
      AppToast.errorWithCause(t.illust.toast.copyFailed(label: label), error);
    }
  }

  Future<void> _ensurePlaybackStartedForExport() async {
    if (_frameImages != null && _frameImages!.isNotEmpty) {
      return;
    }

    await _startPlayback();
  }

  Future<void> _ensureFrameBytes() async {
    final cachedFrames = _cache.frames;
    if (cachedFrames != null) {
      _frameBytes = cachedFrames.bytes;
      _delays = cachedFrames.delays;
      return;
    }

    _cache.framesFuture ??= _loadFrameBytes().whenComplete(() => _cache.framesFuture = null);
    final frames = await _cache.framesFuture!;
    if (!mounted) {
      return;
    }

    setState(() {
      _frameBytes = frames.bytes;
      _delays = frames.delays;
    });
  }

  Future<_UgoiraFrames> _loadFrameBytes() async {
    final metadata = await _ensureMetadata();
    final zipBytes = await _ensureZipBytes(metadata.zipUrls.medium);
    _setPhase(_UgoiraPhase.extractingFrames, progress: null);
    final frameBytes = await ZipUtils.unzipFiles(bytes: zipBytes);
    if (frameBytes.isEmpty) {
      throw StateError('Ugoira ZIP archive contains no image frames.');
    }

    final delays = _matchingDelays(frameBytes: frameBytes, metadataFrames: metadata.frames);
    final frames = _UgoiraFrames(bytes: frameBytes.take(delays.length).toList(growable: false), delays: delays);
    _cache.frames = frames;
    return frames;
  }

  Future<UgoiraMetadataContent> _ensureMetadata() async {
    final cached = _metadata ?? _cache.metadata;
    if (cached != null) {
      _metadata = cached;
      return cached;
    }

    _setPhase(_UgoiraPhase.fetchingMetadata, progress: null);
    _cache.metadataFuture ??= pixivApi
        .getUgoiraMetadata(illustId: widget.illustId)
        .then((result) {
          _cache.metadata = result.ugoiraMetadata;
          return result.ugoiraMetadata;
        })
        .whenComplete(() => _cache.metadataFuture = null);

    final metadata = await _cache.metadataFuture!;
    if (!mounted) {
      return metadata;
    }

    setState(() {
      _metadata = metadata;
    });
    return metadata;
  }

  Future<Uint8List> _ensureZipBytes(String zipUrl) async {
    final cached = _zipBytes ?? _cache.zipBytes;
    if (cached != null) {
      _zipBytes = cached;
      return cached;
    }

    _setPhase(_UgoiraPhase.downloadingZip, progress: null);
    _cache.zipBytesFuture ??= _downloadBytes(Uri.parse(zipUrl), onProgress: (progress) => _setPhase(_UgoiraPhase.downloadingZip, progress: progress))
        .then((bytes) {
          _cache.zipBytes = bytes;
          return bytes;
        })
        .whenComplete(() => _cache.zipBytesFuture = null);

    final bytes = await _cache.zipBytesFuture!;
    if (!mounted) {
      return bytes;
    }

    setState(() {
      _zipBytes = bytes;
    });
    return bytes;
  }

  Future<Uint8List> _ensureGifBytes() {
    final cached = _gifBytes ?? _cache.gifBytes;
    if (cached != null) {
      _gifBytes = cached;
      return Future.value(cached);
    }

    _cache.gifFuture ??= _buildGifBytes().whenComplete(() => _cache.gifFuture = null);
    return _cache.gifFuture!.then((bytes) {
      _gifBytes = bytes;
      return bytes;
    });
  }

  Future<Uint8List> _buildGifBytes() async {
    await _ensureFrameBytes();
    final frameBytes = _frameBytes ?? const <Uint8List>[];
    final delays = _delays ?? const <int>[];
    if (frameBytes.isEmpty || delays.isEmpty) {
      throw StateError('Ugoira frames are not ready.');
    }

    _setPhase(_UgoiraPhase.composingGif, progress: null);
    final Uint8List gifBytes;
    try {
      gifBytes = await ImageUtils.imagesToGif(images: frameBytes, delays: delays);
    } catch (_) {
      throw StateError('Failed to compose GIF from ${frameBytes.length} ugoira frames.');
    }

    _cache.gifBytes = gifBytes;
    if (!mounted) {
      return gifBytes;
    }

    setState(() {
      _gifBytes = gifBytes;
    });
    return gifBytes;
  }

  Future<Uint8List> _downloadBytes(Uri url, {required ValueChanged<double?> onProgress}) async {
    Uint8List? downloadedBytes;
    await for (final event in downloadToMemory(url: url.toString(), proxy: AppSettings.proxySettings.activeUrl)) {
      switch (event) {
        case FrbDownloadBytesEvent_Progress(:final received, :final total):
          onProgress(total > 0 ? (received / total).clamp(0.0, 1.0) : null);
        case FrbDownloadBytesEvent_Done(:final bytes):
          downloadedBytes = bytes;
          onProgress(1);
      }
    }

    final bytes = downloadedBytes;
    if (bytes == null) {
      throw const DownloadException('Download completed without data.');
    }
    return bytes;
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _setPhase(_UgoiraPhase phase, {double? progress}) {
    if (!mounted) {
      return;
    }

    setState(() {
      _phase = phase;
      _progress = progress;
    });
  }

  void _setReadyAfterExport() {
    if (!mounted) {
      return;
    }

    setState(() {
      _phase = _frameImages == null ? _UgoiraPhase.idle : _UgoiraPhase.ready;
      _progress = null;
    });
  }

  void _setFailed(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _phase = _frameImages == null || _frameImages!.isEmpty ? _UgoiraPhase.failed : _UgoiraPhase.ready;
      _progress = null;
    });
  }
}

List<int> _matchingDelays({required List<Uint8List> frameBytes, required List<Frame> metadataFrames}) {
  final count = math.min(frameBytes.length, metadataFrames.length);
  if (count <= 0) {
    return const <int>[];
  }

  return [for (var index = 0; index < count; index += 1) metadataFrames[index].delay];
}

class _UgoiraPlayButton extends StatelessWidget {
  const _UgoiraPlayButton({required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.86),
      elevation: 2,
      shape: const CircleBorder(),
      child: IconButton(
        iconSize: 48,
        tooltip: failed ? context.t.common.retry : null,
        icon: Icon(failed ? Icons.refresh_outlined : Icons.play_arrow_rounded),
        onPressed: null,
      ),
    );
  }
}

class _UgoiraProgressPanel extends StatelessWidget {
  const _UgoiraProgressPanel({required this.label, required this.progress});

  final String label;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = this.progress;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DecoratedBox(
        decoration: BoxDecoration(color: colorScheme.surface.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: textTheme.labelLarge)),
                  if (progress != null) Text('${(progress * 100).round()}%', style: textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
            ],
          ),
        ),
      ),
    );
  }
}

class _UgoiraFramePlayer extends StatefulWidget {
  const _UgoiraFramePlayer({required this.frames, required this.delays});

  final List<ui.Image> frames;
  final List<int> delays;

  @override
  State<_UgoiraFramePlayer> createState() => _UgoiraFramePlayerState();
}

class _UgoiraFramePlayerState extends State<_UgoiraFramePlayer> {
  Timer? _timer;
  int _index = 0;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _scheduleNextFrame();
  }

  @override
  void didUpdateWidget(covariant _UgoiraFramePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.frames, oldWidget.frames)) {
      _index = 0;
      _playing = true;
      _timer?.cancel();
      _scheduleNextFrame();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.frames;
    final frame = frames[_index.clamp(0, frames.length - 1)];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RawImage(image: frame, fit: BoxFit.contain),
          if (!_playing)
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.42), shape: BoxShape.circle),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 52),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _togglePlayback() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _scheduleNextFrame();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _scheduleNextFrame() {
    if (!_playing || widget.frames.length <= 1) {
      return;
    }

    final delayMs = widget.delays.isEmpty ? 100 : widget.delays[_index.clamp(0, widget.delays.length - 1)];
    _timer = Timer(Duration(milliseconds: math.max(16, delayMs)), () {
      if (!mounted || !_playing) {
        return;
      }

      setState(() => _index = (_index + 1) % widget.frames.length);
      _scheduleNextFrame();
    });
  }
}

bool _isBusyPhase(_UgoiraPhase phase) {
  return switch (phase) {
    _UgoiraPhase.fetchingMetadata ||
    _UgoiraPhase.downloadingZip ||
    _UgoiraPhase.extractingFrames ||
    _UgoiraPhase.decodingFrames ||
    _UgoiraPhase.composingGif ||
    _UgoiraPhase.savingGif => true,
    _UgoiraPhase.idle || _UgoiraPhase.ready || _UgoiraPhase.failed => false,
  };
}

String _ugoiraPhaseLabel(_UgoiraPhase phase) {
  return switch (phase) {
    _UgoiraPhase.fetchingMetadata => 'Loading animation metadata',
    _UgoiraPhase.downloadingZip => 'Downloading animation frames',
    _UgoiraPhase.extractingFrames => 'Extracting frames',
    _UgoiraPhase.decodingFrames => 'Preparing playback',
    _UgoiraPhase.composingGif => 'Compositing GIF',
    _UgoiraPhase.savingGif => 'Saving GIF',
    _UgoiraPhase.idle || _UgoiraPhase.ready || _UgoiraPhase.failed => '',
  };
}
