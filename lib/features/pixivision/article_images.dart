import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';

/// Pixivision's images are served only to requests from its own pages.
const pixivisionImageHeaders = {'Referer': 'https://www.pixivision.net/'};

/// Metadata is available before any article image bytes are fetched.
Map<String, double> pixivisionKnownImageRatios(Article article) => Map.unmodifiable({
  for (final block in article.blocks)
    for (final image in block.images)
      if ((image.width ?? 0) > 0 && (image.height ?? 0) > 0) image.url: image.width! / image.height!,
});

/// Observe the same image stream used by the visible media widget, so slow
/// sources do not trigger a second download. The listener has a finite life;
/// the reserved slot remains stable if a ratio cannot be obtained in time.
Future<double?> probePixivisionImageRatio(RustMediaTransport transport, String url, {Duration timeout = const Duration(seconds: 20)}) async {
  final provider = RustExtendedNetworkImageProvider(
    request: MediaRequest(url: url, headers: pixivisionImageHeaders),
    mediaStream: transport.stream,
    mediaStreamCacheIdentity: transport.imageCacheIdentity,
  );
  final stream = provider.resolve(ImageConfiguration.empty);
  final result = Completer<double?>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      final ratio = info.image.width / info.image.height;
      info.dispose();
      if (!result.isCompleted) result.complete(ratio.isFinite && ratio > 0 ? ratio : null);
    },
    onError: (Object _, StackTrace? _) {
      if (!result.isCompleted) result.complete(null);
    },
  );
  stream.addListener(listener);
  try {
    return await result.future.timeout(timeout, onTimeout: () => null);
  } finally {
    stream.removeListener(listener);
  }
}
