import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

/// Intrinsic pixel size of remote images, remembered across launches so
/// layouts can reserve the right space before an image loads.
abstract interface class ImageSizeStore {
  Size? sizeOf(String url);

  /// Remembers [size] for [url]; non-positive or non-finite sizes are ignored.
  Future<void> record(String url, Size size);
}

/// Size the novel reader assumes for an image whose size is not known yet.
const novelImageFallbackSize = Size(832, 1216);

final imageSizeStoreProvider = Provider<ImageSizeStore>((ref) {
  throw StateError('imageSizeStoreProvider must be overridden with an opened store.');
});

bool _usable(Size size) => size.width.isFinite && size.height.isFinite && size.width > 0 && size.height > 0;

/// Entry count a full store is trimmed down to: eviction then does not run on
/// every write.
int _retainedCount(int capacity) => math.max(1, (capacity * 0.9).floor());

/// Stored in a Hive box as `[width, height, recordedAtMicroseconds]`.
final class HiveImageSizeStore implements ImageSizeStore {
  HiveImageSizeStore._(this._box, this._capacity);

  static const boxName = 'image_sizes';

  /// Opens the box; Hive must already be initialised.
  static Future<HiveImageSizeStore> open({int capacity = 5000}) async => HiveImageSizeStore._(await Hive.openBox<dynamic>(boxName), capacity);

  final Box<dynamic> _box;
  final int _capacity;
  int _lastRecorded = 0;

  @override
  Size? sizeOf(String url) {
    final entry = _read(_box.get(url));
    return entry == null ? null : Size(entry.$1, entry.$2);
  }

  @override
  Future<void> record(String url, Size size) async {
    if (!_usable(size)) return;
    // Strictly increasing, so two records never tie when evicting oldest first.
    _lastRecorded = math.max(_lastRecorded + 1, DateTime.now().microsecondsSinceEpoch);
    await _box.put(url, <double>[size.width, size.height, _lastRecorded.toDouble()]);
    if (_box.length > _capacity) await _evict();
  }

  Future<void> _evict() async {
    final entries = <(Object, double)>[for (final key in _box.keys) (key as Object, _read(_box.get(key))?.$3 ?? double.negativeInfinity)]
      ..sort((a, b) => a.$2.compareTo(b.$2));
    final excess = entries.length - _retainedCount(_capacity);
    if (excess > 0) await _box.deleteAll(entries.take(excess).map((e) => e.$1));
  }

  (double, double, double)? _read(Object? value) {
    if (value is! List || value.length != 3) return null;
    final [width, height, time] = value;
    if (width is! num || height is! num || time is! num) return null;
    final w = width.toDouble();
    final h = height.toDouble();
    if (!_usable(Size(w, h)) || !time.isFinite) return null;
    return (w, h, time.toDouble());
  }
}

/// Keeps sizes in memory only, for the sample entry and tests.
final class MemoryImageSizeStore implements ImageSizeStore {
  MemoryImageSizeStore({this._capacity = 5000});

  final int _capacity;
  // Insertion order is recording order: re-recording moves an entry last.
  final _entries = <String, Size>{};

  @override
  Size? sizeOf(String url) => _entries[url];

  @override
  Future<void> record(String url, Size size) async {
    if (!_usable(size)) return;
    _entries
      ..remove(url)
      ..[url] = size;
    if (_entries.length > _capacity) {
      final excess = _entries.length - _retainedCount(_capacity);
      _entries.keys.take(excess).toList().forEach(_entries.remove);
    }
  }
}
