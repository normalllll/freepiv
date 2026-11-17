import 'dart:ui' show Size;

/// The sizes pictures declared in the first bytes of their download, by the
/// picture's cache key, so a frame can take its shape before the file has
/// arrived. Entries are kept only as long as a picture is likely to be shown
/// again; the decoded size stays the authority.
class MediaHeaderSizes {
  MediaHeaderSizes({this.capacity = 512});

  /// How many sizes are kept.
  final int capacity;

  final _sizes = <String, Size>{};
  final _listeners = <String, List<void Function(Size size)>>{};

  /// The size a download of [key] has declared, if it has.
  Size? sizeOf(String key) => _sizes[key];

  /// Records [size] for [key] and tells those waiting for it.
  void publish(String key, Size size) {
    _sizes.remove(key);
    _sizes[key] = size;
    while (_sizes.length > capacity) {
      _sizes.remove(_sizes.keys.first);
    }
    for (final listener in List.of(_listeners[key] ?? const <void Function(Size)>[])) {
      listener(size);
    }
  }

  /// Calls [listener] with the size [key] declares from now on; the returned
  /// function stops it.
  void Function() listen(String key, void Function(Size size) listener) {
    (_listeners[key] ??= []).add(listener);
    return () {
      final listeners = _listeners[key];
      if (listeners == null) return;
      listeners.remove(listener);
      if (listeners.isEmpty) _listeners.remove(key);
    };
  }
}

/// The app's header sizes, filled by the media transport.
final mediaHeaderSizes = MediaHeaderSizes();
