import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';

void main() {
  test('recreated media transport retains the same image cache key', () {
    final firstTransport = RustMediaTransport(null);
    final nextTransport = RustMediaTransport(null);
    final differentProxy = RustMediaTransport('http://proxy.example.test:8080');
    final request = MediaRequest(url: 'https://example.test/art.png');

    RustExtendedNetworkImageProvider image(RustMediaTransport transport) =>
        RustExtendedNetworkImageProvider(request: request, mediaStream: transport.stream, mediaStreamCacheIdentity: transport.imageCacheIdentity);

    expect(image(firstTransport), image(nextTransport));
    expect(image(firstTransport).hashCode, image(nextTransport).hashCode);
    expect(image(firstTransport), isNot(image(differentProxy)));
  });
}
