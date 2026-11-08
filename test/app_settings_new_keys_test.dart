import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Reopens a real Hive box so every value goes through Hive's own encoding.
Future<void> _reopen(Directory directory, Future<void> Function() write) async {
  Hive.init(directory.path);
  var box = await Hive.openBox<dynamic>(AppSettings.boxName);
  await AppSettings.initialize(store: HiveAppSettingsStore(box));
  await write();
  // AppSettings writes in the background; give the write a turn, then flush.
  await Future<void>.delayed(Duration.zero);
  await box.flush();
  await box.close();
  box = await Hive.openBox<dynamic>(AppSettings.boxName);
  await AppSettings.initialize(store: HiveAppSettingsStore(box));
}

void main() {
  late Directory directory;

  setUp(() async => directory = await Directory.systemTemp.createTemp('freepiv_new_keys_'));
  tearDown(() async {
    await Hive.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('a fresh install reads every new key as its default', () async {
    await _reopen(directory, () async {});
    expect(AppSettings.sidebarExpanded, isFalse);
    expect(AppSettings.windowPlacement, isNull);
    expect(AppSettings.readerFontSize, 18);
    expect(AppSettings.readerLineHeight, 1.78);
    expect(AppSettings.readerAutoScrollSpeed, 36);
    expect(AppSettings.readerVolumeKeys, isFalse);
    expect(AppSettings.downloadEntryPosition.edge, FrostFloatingEntryEdge.end);
    expect(AppSettings.downloadEntryPosition.fraction, 1);
  });

  test('sidebar, reader and download entry values survive a restart', () async {
    await _reopen(directory, () async {
      AppSettings.sidebarExpanded = true;
      AppSettings.readerFontSize = 22;
      AppSettings.readerLineHeight = 2;
      AppSettings.readerAutoScrollSpeed = 60;
      AppSettings.readerVolumeKeys = true;
      AppSettings.downloadEntryPosition = const FrostFloatingEntryPosition(edge: FrostFloatingEntryEdge.start, fraction: .25);
    });
    expect(AppSettings.sidebarExpanded, isTrue);
    expect(AppSettings.readerFontSize, 22);
    expect(AppSettings.readerLineHeight, 2);
    expect(AppSettings.readerAutoScrollSpeed, 60);
    expect(AppSettings.readerVolumeKeys, isTrue);
    expect(AppSettings.downloadEntryPosition.edge, FrostFloatingEntryEdge.start);
    expect(AppSettings.downloadEntryPosition.fraction, .25);
  });

  test('windowPlacement stores FrostWindowPlacement.toMap and reads it back', () async {
    const placement = FrostWindowPlacement(
      displayId: 'DISPLAY1',
      rect: Rect.fromLTWH(40, 30, 1147, 717),
      maximized: true,
      workAreaSize: Size(1920, 1040),
      displayScale: 1.5,
    );
    await _reopen(directory, () async => AppSettings.windowPlacement = placement);
    expect(AppSettings.windowPlacement, placement);

    await _reopen(directory, () async => AppSettings.windowPlacement = null);
    expect(AppSettings.windowPlacement, isNull);
  });

  test('reader values are clamped to the reader ranges', () async {
    await _reopen(directory, () async {
      AppSettings.readerFontSize = 40;
      AppSettings.readerLineHeight = 1;
      AppSettings.readerAutoScrollSpeed = 500;
    });
    expect(AppSettings.readerFontSize, 26);
    expect(AppSettings.readerLineHeight, 1.45);
    expect(AppSettings.readerAutoScrollSpeed, 96);
  });

  test('corrupt stored values fall back without disturbing the others', () async {
    Hive.init(directory.path);
    final box = await Hive.openBox<dynamic>(AppSettings.boxName);
    await box.putAll({
      'sidebarExpanded': 'yes',
      'windowPlacement': {'rect': 'nowhere'},
      'readerFontSize': 3,
      'readerVolumeKeys': true,
      'downloadEntryPosition': {'edge': 'start', 'fraction': 4},
    });
    await AppSettings.initialize(store: HiveAppSettingsStore(box));
    expect(AppSettings.sidebarExpanded, isFalse);
    expect(AppSettings.windowPlacement, isNull);
    expect(AppSettings.readerFontSize, 18);
    expect(AppSettings.readerVolumeKeys, isTrue);
    expect(AppSettings.downloadEntryPosition.edge, FrostFloatingEntryEdge.end);
  });

  test('the providers write through to the settings box', () async {
    await _reopen(directory, () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(sidebarExpandedProvider.notifier).setExpanded(true);
      container.read(readerSettingsProvider.notifier)
        ..setTextSize(20)
        ..setVolumeKeys(true);
      expect(container.read(readerSettingsProvider).textSize, 20);
    });
    expect(AppSettings.sidebarExpanded, isTrue);
    expect(AppSettings.readerFontSize, 20);
    expect(AppSettings.readerVolumeKeys, isTrue);
  });

  group('the background material', () {
    Future<Map<String, dynamic>> stored(Directory directory, Map<String, dynamic> values) async {
      Hive.init(directory.path);
      final box = await Hive.openBox<dynamic>(AppSettings.boxName);
      await box.putAll(values);
      await AppSettings.initialize(store: HiveAppSettingsStore(box));
      return {for (final key in box.keys) key as String: box.get(key)};
    }

    test('reduced transparency becomes Off and the old key goes', () async {
      final box = await stored(directory, {'reduceTransparency': true});
      expect(AppSettings.backgroundMaterial, BackgroundMaterial.off);
      expect(box['backgroundMaterial'], 'off');
      expect(box.containsKey('reduceTransparency'), isFalse);
    });

    test('with nothing stored it is the blur at full intensity', () async {
      await stored(directory, {});
      expect(AppSettings.backgroundMaterial, BackgroundMaterial.ambient);
      expect(AppSettings.backgroundIntensity, 100);
    });

    test('reduce transparency switched off leaves the blur, and the old key goes', () async {
      final box = await stored(directory, {'reduceTransparency': false});
      expect(AppSettings.backgroundMaterial, BackgroundMaterial.ambient);
      expect(box.containsKey('reduceTransparency'), isFalse);
    });

    test('a chosen material wins over the old key', () async {
      await stored(directory, {'reduceTransparency': true, 'backgroundMaterial': 'mica'});
      expect(AppSettings.backgroundMaterial, BackgroundMaterial.mica);
    });

    test('invalid values fall back', () async {
      await stored(directory, {'backgroundMaterial': 'glass', 'backgroundIntensity': 7});
      expect(AppSettings.backgroundMaterial, BackgroundMaterial.ambient);
      expect(AppSettings.backgroundIntensity, 100);
      for (final value in [5, 105, 33, '50']) {
        await Hive.close();
        await stored(directory, {'backgroundMaterial': 'off', 'backgroundIntensity': value});
        expect(AppSettings.backgroundIntensity, 100, reason: '$value');
      }
    });

    test('material and intensity survive a restart; intensity is kept to its scale', () async {
      await _reopen(directory, () async {
        AppSettings.backgroundMaterial = BackgroundMaterial.mica;
        AppSettings.backgroundIntensity = 43;
      });
      expect(AppSettings.backgroundMaterial, BackgroundMaterial.mica);
      expect(AppSettings.backgroundIntensity, 45);
    });

    test('a stored navigation placement is dropped without an error', () async {
      final box = await stored(directory, {'navigationPlacement': 'bottom', 'sidebarExpanded': true});
      expect(box.containsKey('navigationPlacement'), isFalse);
      expect(AppSettings.sidebarExpanded, isTrue);
    });

    test('moving the slider previews without saving; letting go saves', () async {
      await _reopen(directory, () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(backgroundSettingsProvider.notifier);
        notifier.previewIntensity(62);
        expect(container.read(backgroundSettingsProvider).intensity, 60);
        expect(AppSettings.backgroundIntensity, 100);
        notifier.saveIntensity(62);
        expect(AppSettings.backgroundIntensity, 60);
        notifier.setMaterial(BackgroundMaterial.off);
        notifier.setMaterial(BackgroundMaterial.ambient);
        expect(container.read(backgroundSettingsProvider).intensity, 60, reason: 'kept across another material');
      });
    });
  });
}
