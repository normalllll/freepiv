import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;

/// The pictures kept on disk between runs, trimmed from `main`.
final appPictureStore = MediaDiskCache.forApp();

/// A picture's address, headers and the account it is fetched for, which
/// together identify its bytes.
@immutable
final class MediaRequest {
  MediaRequest({
    required this.url,
    Map<String, String> headers = const {'Referer': 'https://www.pixiv.net/'},
    this.allowDiskCache = true,
    String accountKey = '',
  }) : headers = Map.unmodifiable(headers),
       cacheKey = sha256
           .convert(
             utf8.encode(jsonEncode([url, Map.fromEntries(headers.entries.toList()..sort((a, b) => a.key.compareTo(b.key))), accountKey, allowDiskCache])),
           )
           .toString();
  final String url;
  final Map<String, String> headers;

  /// Off for a picture behind a sign-in, which must not outlive it on disk.
  final bool allowDiskCache;
  final String cacheKey;
}

/// A picture fetched through the app's Rust media transport.
final class RustMediaSource extends MediaSource {
  const RustMediaSource(this.request, {required this.stream, required this.streamIdentity});

  /// [request] through [transport].
  RustMediaSource.through(RustMediaTransport transport, this.request) : stream = transport.stream, streamIdentity = transport.imageCacheIdentity;

  final MediaRequest request;
  final Stream<rust.MediaChunk> Function(String url, Map<String, String> headers) stream;

  /// Equal for streams that fetch the same bytes. A transport is recreated
  /// with its settings, so its stream function is not a stable identity.
  final Object streamIdentity;

  @override
  String get cacheKey => request.cacheKey;

  @override
  bool get cacheOnDisk => request.allowDiskCache;

  @override
  Stream<MediaChunk> open() =>
      stream(request.url, request.headers).map((chunk) => MediaChunk(bytes: chunk.bytes, received: chunk.received, total: chunk.total));

  /// The address without its query, which may hold signatures.
  @override
  String get description => switch (Uri.tryParse(request.url)) {
    null => '(invalid URL)',
    final uri => '${uri.scheme}://${uri.host}${uri.path}',
  };

  @override
  String describe(Object cause) => '$cause'.replaceAll(request.url, description);

  @override
  bool operator ==(Object other) => other is RustMediaSource && other.request.cacheKey == request.cacheKey && other.streamIdentity == streamIdentity;

  @override
  int get hashCode => Object.hash(request.cacheKey, streamIdentity);
}
