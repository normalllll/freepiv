import 'dart:async';
import 'package:flutter/painting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';

/// Resolves missing metadata before exposing article content. The existing image
/// provider keeps the fetched bytes/decoded images cached for the reading view.
Future<Map<String, double>> preparePixivisionImages(Ref ref, Article article, RustMediaTransport transport) async {
  final ratios = <String, double>{};
  final pending = <String>{};
  for (final block in article.blocks) {
    final urls = block.kind == BlockKind.pixivWork && block.works.isNotEmpty
        ? block.works.map((work) => work.preview).whereType<String>()
        : block.images.map((image) => image.url);
    for (final url in urls) {
      final metadata = block.images.where((image) => image.url == url && (image.width ?? 0) > 0 && (image.height ?? 0) > 0).firstOrNull;
      if (metadata != null) {
        ratios[url] = metadata.width! / metadata.height!;
      } else {
        pending.add(url);
      }
    }
  }
  pending.removeAll(ratios.keys);
  final queue = pending.iterator;
  Future<void> worker() async {
    while (ref.mounted && queue.moveNext()) {
      final url = queue.current;
      ratios[url] = await _readRatio(ref, transport, url);
    }
  }

  await Future.wait([for (var i = 0; i < 4; i++) worker()]);
  if (!ref.mounted) throw StateError('Article preparation cancelled');
  return Map.unmodifiable(ratios);
}

Future<double> _readRatio(Ref ref, RustMediaTransport transport, String url) {
  final result = Completer<double>();
  final provider = RustExtendedNetworkImageProvider(
    request: MediaRequest(url: url, headers: const {'Referer': 'https://www.pixivision.net/'}),
    mediaStream: transport.stream,
  );
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void stop() => stream.removeListener(listener);
  listener = ImageStreamListener(
    (info, _) {
      final width = info.image.width;
      final height = info.image.height;
      info.dispose();
      stop();
      if (!result.isCompleted) result.complete(width / height);
    },
    onError: (Object error, StackTrace? stack) {
      stop();
      if (!result.isCompleted) result.completeError(error, stack);
    },
  );
  ref.onDispose(() {
    stop();
    if (!result.isCompleted) result.completeError(StateError('Article preparation cancelled'));
  });
  stream.addListener(listener);
  return result.future;
}
