import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

@riverpod
RustMediaTransport rustMediaTransport(Ref ref) => RustMediaTransport(ref.watch(proxySettingsProvider).activeUrl);

class RustMediaTransport {
  const RustMediaTransport(this._proxy);
  final String? _proxy;

  Stream<rust.MediaChunk> stream(String url, Map<String, String> headers) => rust.streamMedia(url: url, proxy: _proxy, headers: headers);
}
