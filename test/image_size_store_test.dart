import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('image_size_store');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> sharedBehaviour(String name, Future<ImageSizeStore> Function({int capacity}) create) async {
    group(name, () {
      test('reads back a recorded size, unknown urls are null', () async {
        final store = await create();
        expect(store.sizeOf('a'), isNull);
        await store.record('a', const Size(100, 200));
        expect(store.sizeOf('a'), const Size(100, 200));
        await store.record('a', const Size(300, 400));
        expect(store.sizeOf('a'), const Size(300, 400));
      });

      test('ignores non-positive and non-finite sizes', () async {
        final store = await create();
        for (final size in [Size.zero, const Size(-1, 5), const Size(5, 0), const Size(double.infinity, 5), const Size(5, double.nan)]) {
          await store.record('a', size);
        }
        expect(store.sizeOf('a'), isNull);
      });

      test('evicts the oldest entries down to 90% of capacity', () async {
        final store = await create(capacity: 10);
        for (var i = 0; i < 10; i++) {
          await store.record('u$i', Size(1.0 + i, 1));
        }
        expect(store.sizeOf('u0'), isNotNull, reason: 'at capacity nothing is removed');
        await store.record('u10', const Size(11, 1));
        expect(store.sizeOf('u0'), isNull);
        expect(store.sizeOf('u1'), isNull);
        expect(store.sizeOf('u2'), isNotNull);
        expect([for (var i = 0; i <= 10; i++) store.sizeOf('u$i')].whereType<Size>().length, 9);
      });

      test('re-recording refreshes the entry so it outlives older ones', () async {
        final store = await create(capacity: 10);
        for (var i = 0; i < 10; i++) {
          await store.record('u$i', const Size(1, 1));
        }
        await store.record('u0', const Size(2, 2));
        await store.record('u10', const Size(1, 1));
        expect(store.sizeOf('u0'), const Size(2, 2));
        expect(store.sizeOf('u1'), isNull);
        expect(store.sizeOf('u2'), isNull);
        expect(store.sizeOf('u3'), isNotNull);
      });
    });
  }

  sharedBehaviour('memory store', ({int capacity = 5000}) async => MemoryImageSizeStore(capacity: capacity));
  sharedBehaviour('hive store', ({int capacity = 5000}) => HiveImageSizeStore.open(capacity: capacity));

  group('hive store', () {
    test('survives close and reopen', () async {
      final store = await HiveImageSizeStore.open();
      await store.record('a', const Size(832, 1216));
      await Hive.close();
      final reopened = await HiveImageSizeStore.open();
      expect(reopened.sizeOf('a'), const Size(832, 1216));
    });

    test('a corrupt entry reads as unknown and is overwritten by the next record', () async {
      final box = await Hive.openBox<dynamic>(HiveImageSizeStore.boxName);
      await box.put('a', 'garbage');
      await box.put('b', [1, 2]);
      await box.put('c', [0, 5, 1]);
      await box.put('d', ['x', 1, 1]);
      await box.close();
      final store = await HiveImageSizeStore.open();
      for (final key in ['a', 'b', 'c', 'd']) {
        expect(store.sizeOf(key), isNull);
      }
      await store.record('a', const Size(10, 20));
      expect(store.sizeOf('a'), const Size(10, 20));
    });
  });
}
