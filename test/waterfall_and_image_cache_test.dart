import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/core/media/rust_media_source.dart';

void main() {
  test('recreated media transport retains the same image cache key', () {
    final firstTransport = RustMediaTransport(null);
    final nextTransport = RustMediaTransport(null);
    final differentProxy = RustMediaTransport('http://proxy.example.test:8080');
    final request = MediaRequest(url: 'https://example.test/art.png');

    CachedMediaImage image(RustMediaTransport transport) => CachedMediaImage(RustMediaSource.through(transport, request));

    expect(image(firstTransport), image(nextTransport));
    expect(image(firstTransport).hashCode, image(nextTransport).hashCode);
    expect(image(firstTransport), isNot(image(differentProxy)));
  });
}
