import 'dart:convert';
import 'dart:typed_data' show BytesBuilder;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart' show AnyhowException;
import 'package:freepiv/core/media/image_size_from_header.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/core/media/media_header_sizes.dart';
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

  /// False for failures another try cannot fix: the server refused the
  /// picture (401, 403, 404, 410), or the request itself is invalid or was
  /// answered with something that is not a picture. Network failures and
  /// timeouts are tried again. The Rust transport reports its failures as
  /// the text of an [AnyhowException].
  @override
  bool shouldRetry(Object error) => !(error is AnyhowException && _final.hasMatch(error.message));

  static final _final = RegExp(
    r'^(Media HTTP (401|403|404|410)$|Invalid media |Media requires an HTTPS URL|FANBOX cookies require|Media response is not binary|Media exceeds)',
  );

  /// The chunks of the download. The size the file declares is published to
  /// [mediaHeaderSizes] once, as soon as the bytes so far hold it; the start of
  /// the file is kept only until then, and given up on at [imageHeaderLimit].
  @override
  Stream<MediaChunk> open() {
    final head = BytesBuilder(copy: false);
    var looking = true;
    return stream(request.url, request.headers).map((chunk) {
      if (looking) {
        head.add(chunk.bytes);
        final size = imageSizeFromHeader(head.toBytes());
        if (size != null) {
          looking = false;
          mediaHeaderSizes.publish(cacheKey, size);
        } else if (head.length >= imageHeaderLimit) {
          looking = false;
        }
        if (!looking) head.clear();
      }
      return MediaChunk(bytes: chunk.bytes, received: chunk.received, total: chunk.total);
    });
  }

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
