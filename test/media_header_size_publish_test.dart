import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/image_size_from_header.dart';
import 'package:freepiv/core/media/media_header_sizes.dart';
import 'package:freepiv/core/media/rust_media_source.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;

RustMediaSource _source(String url, Stream<rust.MediaChunk> Function() chunks) => RustMediaSource(
  MediaRequest(url: url, allowDiskCache: false),
  stream: (_, _) => chunks(),
  streamIdentity: 'fixture',
);

rust.MediaChunk _chunk(Uint8List bytes, int received, [int? total]) => rust.MediaChunk(bytes: bytes, received: received, total: total);

void main() {
  final file = File('test/fixtures/image_headers/pximg_152069603_240mw_head.jpg').readAsBytesSync();

  test('the transport publishes the declared size once, from the first chunks, before the rest arrives', () async {
    final source = _source('https://i.pximg.net/fixtures/published.jpg', () async* {
      // Small pieces: the size is in the first thousand bytes or so.
      for (var at = 0; at < file.length; at += 200) {
        final end = at + 200 > file.length ? file.length : at + 200;
        yield _chunk(Uint8List.sublistView(file, at, end), end, 80000);
      }
    });
    final published = <Size>[];
    final off = mediaHeaderSizes.listen(source.cacheKey, published.add);
    addTearDown(off);
    var received = 0;
    var receivedWhenPublished = -1;
    await for (final chunk in source.open()) {
      received = chunk.received;
      if (published.isNotEmpty && receivedWhenPublished < 0) receivedWhenPublished = received;
    }
    expect(published, [const Size(240, 474)], reason: 'once per download');
    expect(receivedWhenPublished, lessThan(1200), reason: 'as soon as the received bytes held it');
    expect(mediaHeaderSizes.sizeOf(source.cacheKey), const Size(240, 474));
  });

  test('chunks pass through unchanged', () async {
    final source = _source(
      'https://i.pximg.net/fixtures/passed.jpg',
      () => Stream.fromIterable([_chunk(Uint8List.sublistView(file, 0, 300), 300, 900), _chunk(Uint8List.sublistView(file, 300, 900), 900, 900)]),
    );
    final chunks = await source.open().toList();
    expect([for (final chunk in chunks) chunk.bytes.length], [300, 600]);
    expect([for (final chunk in chunks) chunk.received], [300, 900]);
    expect(chunks.last.total, 900);
  });

  test('a download that never shows a size is given up on at the limit and publishes nothing', () async {
    final source = _source('https://i.pximg.net/fixtures/unknown.bin', () async* {
      for (var i = 0; i < 10; i++) {
        yield _chunk(Uint8List(imageHeaderLimit ~/ 4), (i + 1) * imageHeaderLimit ~/ 4);
      }
    });
    final published = <Size>[];
    final off = mediaHeaderSizes.listen(source.cacheKey, published.add);
    addTearDown(off);
    expect((await source.open().toList()).length, 10);
    expect(published, isEmpty);
    expect(mediaHeaderSizes.sizeOf(source.cacheKey), isNull);
  });

  test('a retry publishes again for those listening, and the newest size is the one kept', () async {
    final sizes = MediaHeaderSizes(capacity: 2);
    final heard = <Size>[];
    final off = sizes.listen('a', heard.add);
    sizes.publish('a', const Size(1, 2));
    sizes.publish('a', const Size(3, 4));
    off();
    sizes.publish('a', const Size(5, 6));
    expect(heard, [const Size(1, 2), const Size(3, 4)]);
    expect(sizes.sizeOf('a'), const Size(5, 6));
    sizes
      ..publish('b', const Size(1, 1))
      ..publish('c', const Size(1, 1));
    expect(sizes.sizeOf('a'), isNull, reason: 'the oldest entry made room');
  });
}
