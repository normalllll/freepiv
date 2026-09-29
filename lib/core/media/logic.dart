import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

@riverpod
RustMediaTransport rustMediaTransport(Ref ref) => RustMediaTransport(ref.watch(proxySettingsProvider).activeUrl);

class RustMediaTransport {
  const RustMediaTransport(this._proxy);
  final String? _proxy;

  // A remounted image widget must resolve to the same memory-cache entry when
  // the transport configuration is unchanged. Instance method tear-offs are
  // tied to this transport object's lifetime, which is shorter than a route.
  Object get imageCacheIdentity => (proxy: _proxy);

  Stream<rust.MediaChunk> stream(String url, Map<String, String> headers) => rust.streamMedia(url: url, proxy: _proxy, headers: headers);
}
