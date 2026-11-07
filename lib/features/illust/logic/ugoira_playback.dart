import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/src/rust/api/download.dart';
import 'package:freepiv/src/rust/api/image_utils.dart';
import 'package:freepiv/src/rust/api/zip_utils.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

/// Where an animation is on its way to playing, or to a GIF.
enum UgoiraPhase { idle, fetchingMetadata, downloadingZip, extractingFrames, decodingFrames, composingGif, savingGif, ready, failed }

extension UgoiraPhaseBusy on UgoiraPhase {
  bool get busy => switch (this) {
    UgoiraPhase.fetchingMetadata ||
    UgoiraPhase.downloadingZip ||
    UgoiraPhase.extractingFrames ||
    UgoiraPhase.decodingFrames ||
    UgoiraPhase.composingGif ||
    UgoiraPhase.savingGif => true,
    UgoiraPhase.idle || UgoiraPhase.ready || UgoiraPhase.failed => false,
  };
}

class _UgoiraFrames {
  const _UgoiraFrames({required this.bytes, required this.delays});

  final List<Uint8List> bytes;
  final List<int> delays;
}

/// What is already fetched for a work, kept for the run so opening it again
/// plays at once.
class _UgoiraCache {
  UgoiraMetadataContent? metadata;
  Uint8List? zipBytes;
  _UgoiraFrames? frames;
  Uint8List? gifBytes;
  Future<UgoiraMetadataContent>? metadataFuture;
  Future<Uint8List>? zipBytesFuture;
  Future<_UgoiraFrames>? framesFuture;
  Future<Uint8List>? gifFuture;
}

final _caches = <int, _UgoiraCache>{};

/// Fetches an animation's metadata and frames, decodes them for playback and
/// composes its GIF: idle → metadata → ZIP →
/// frames → decoded → ready, or failed with a retry.
class UgoiraPlayback extends ChangeNotifier {
  UgoiraPlayback(this.illustId) : _cache = _caches.putIfAbsent(illustId, _UgoiraCache.new);

  final int illustId;
  final _UgoiraCache _cache;

  UgoiraPhase _phase = UgoiraPhase.idle;
  UgoiraPhase get phase => _phase;

  double? _progress;
  double? get progress => _progress;

  List<ui.Image>? _images;

  /// The decoded frames once playing.
  List<ui.Image>? get frames => _images;
  List<int> get delays => _cache.frames?.delays ?? const [];

  Future<void>? _playing;
  bool _disposed = false;

  /// The download task's progress while a GIF download composes.
  void Function(double progress)? exportProgress;

  Future<void> play() async {
    if (_images != null) return;
    _playing ??= _decode();
    try {
      await _playing;
    } finally {
      _playing = null;
    }
  }

  Future<void> _decode() async {
    try {
      final frames = await _frames();
      final decoded = <ui.Image>[];
      for (var index = 0; index < frames.bytes.length; index++) {
        _set(UgoiraPhase.decodingFrames, progress: index / frames.bytes.length);
        final codec = await ui.instantiateImageCodec(frames.bytes[index]);
        decoded.add((await codec.getNextFrame()).image);
      }
      if (_disposed) {
        for (final image in decoded) {
          image.dispose();
        }
        return;
      }
      _images = decoded;
      _set(UgoiraPhase.ready);
    } catch (error) {
      failed();
      rethrow;
    }
  }

  Future<_UgoiraFrames> _frames() async {
    if (_cache.frames case final frames?) return frames;
    _cache.framesFuture ??= _loadFrames().whenComplete(() => _cache.framesFuture = null);
    return _cache.framesFuture!;
  }

  Future<_UgoiraFrames> _loadFrames() async {
    final metadata = await _metadata();
    final zip = await _zip(metadata.zipUrls.medium);
    _set(UgoiraPhase.extractingFrames);
    final bytes = await ZipUtils.unzipFiles(bytes: zip);
    if (bytes.isEmpty) throw StateError('Ugoira ZIP archive contains no image frames.');
    final count = math.min(bytes.length, metadata.frames.length);
    final delays = [for (var index = 0; index < count; index++) metadata.frames[index].delay];
    return _cache.frames = _UgoiraFrames(bytes: bytes.take(delays.length).toList(growable: false), delays: delays);
  }

  Future<UgoiraMetadataContent> _metadata() async {
    if (_cache.metadata case final metadata?) return metadata;
    _set(UgoiraPhase.fetchingMetadata);
    _cache.metadataFuture ??= pixivApi
        .getUgoiraMetadata(illustId: illustId)
        .then((result) => _cache.metadata = result.ugoiraMetadata)
        .whenComplete(() => _cache.metadataFuture = null);
    return _cache.metadataFuture!;
  }

  Future<Uint8List> _zip(String url) async {
    if (_cache.zipBytes case final bytes?) return bytes;
    _set(UgoiraPhase.downloadingZip);
    _cache.zipBytesFuture ??= _download(Uri.parse(url)).then((bytes) => _cache.zipBytes = bytes).whenComplete(() => _cache.zipBytesFuture = null);
    return _cache.zipBytesFuture!;
  }

  Future<Uint8List> _download(Uri url) async {
    Uint8List? bytes;
    await for (final event in downloadToMemory(url: url.toString(), proxy: AppSettings.proxySettings.activeUrl)) {
      switch (event) {
        case FrbDownloadBytesEvent_Progress(:final received, :final total):
          _set(UgoiraPhase.downloadingZip, progress: total > 0 ? (received / total).clamp(0.0, 1.0) : null);
        case FrbDownloadBytesEvent_Done(bytes: final done):
          bytes = done;
          _set(UgoiraPhase.downloadingZip, progress: 1);
      }
    }
    if (bytes == null) throw const DownloadException('Download completed without data.');
    return bytes;
  }

  /// The animation as a GIF, composed once per run.
  Future<Uint8List> gif() async {
    if (_images == null) await play();
    if (_cache.gifBytes case final bytes?) return bytes;
    _cache.gifFuture ??= _composeGif().whenComplete(() => _cache.gifFuture = null);
    return _cache.gifFuture!;
  }

  Future<Uint8List> _composeGif() async {
    final frames = await _frames();
    if (frames.bytes.isEmpty || frames.delays.isEmpty) throw StateError('Ugoira frames are not ready.');
    _set(UgoiraPhase.composingGif);
    try {
      return _cache.gifBytes = await ImageUtils.imagesToGif(images: frames.bytes, delays: frames.delays);
    } catch (_) {
      throw StateError('Failed to compose GIF from ${frames.bytes.length} ugoira frames.');
    }
  }

  void saving() => _set(UgoiraPhase.savingGif);

  /// Back to playing, or to the poster, after a GIF is done.
  void exported() => _set(_images == null ? UgoiraPhase.idle : UgoiraPhase.ready);

  /// Failed before playing (offering a retry), or keeps playing.
  void failed() => _set(_images == null || _images!.isEmpty ? UgoiraPhase.failed : UgoiraPhase.ready);

  void _set(UgoiraPhase phase, {double? progress}) {
    if (progress != null) exportProgress?.call(progress);
    if (_disposed) return;
    _phase = phase;
    _progress = progress;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final image in _images ?? const <ui.Image>[]) {
      image.dispose();
    }
    super.dispose();
  }
}
