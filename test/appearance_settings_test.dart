import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/core/services/app_settings.dart';

class MemorySettingsStore implements AppSettingsStore {
  MemorySettingsStore([Map<String, dynamic>? seed]) : values = {...?seed};
  final Map<String, dynamic> values;
  Future<void> Function(String, dynamic)? onWrite;
  final writes = <MapEntry<String, dynamic>>[];

  @override
  Map<String, dynamic> load() => {...values};

  @override
  Future<void> write(String key, dynamic value) async {
    await onWrite?.call(key, value);
    values[key] = value;
    writes.add(MapEntry(key, value));
  }
}

void main() {
  test('system always resolves neutral without erasing manual tones or accents', () {
    final saved = FrostAppearance.initial(
      FrostPalettes.pink,
    ).copyWith(lightTone: FrostTone.cool, darkTone: FrostTone.warm, lightAccent: Color(0xFF4C8DFF), darkAccent: Color(0xFF00A68C));
    expect(saved.effectiveToneFor(Brightness.light), FrostTone.neutral);
    expect(saved.effectiveToneFor(Brightness.dark), FrostTone.neutral);
    expect(saved.accentFor(Brightness.light), const Color(0xFF4C8DFF));
    expect(saved.accentFor(Brightness.dark), const Color(0xFF00A68C));
    final manual = saved.copyWith(mode: ThemeMode.dark);
    expect(manual.effectiveToneFor(Brightness.dark), FrostTone.warm);
    expect(manual.copyWith(mode: ThemeMode.system).lightTone, FrostTone.cool);
  });

  test('six presets pass all matching-brightness surfaces', () {
    for (final brightness in Brightness.values) {
      for (final color in freepivFrostConfig.palettes.accentPresets) {
        final result = validateAccent(color, brightness, freepivFrostConfig.palettes);
        expect(result.severity, FrostAccentSeverity.allowed);
        expect(result.minimumContrast, greaterThanOrEqualTo(2));
      }
    }
  });

  test('HEX parsing and unsafe extremes reject before persistence', () {
    expect(parseAccentHex('#aBc123'), const Color(0xFFABC123));
    expect(accentHex(const Color(0xFFABC123)), 'ABC123');
    for (final bad in ['', 'fff', '#FFFFFFFF', 'QQ0101']) {
      expect(parseAccentHex(bad), isNull);
    }
    for (final light in ['FFFFFF', 'FFFFFE', 'F6F6F6']) {
      expect(validateAccent(parseAccentHex(light)!, Brightness.light, freepivFrostConfig.palettes).canApply, isFalse);
    }
    for (final dark in ['000000', '202124']) {
      expect(validateAccent(parseAccentHex(dark)!, Brightness.dark, freepivFrostConfig.palettes).canApply, isFalse);
    }
    // Pure black and white match the text colour, so they are never an accent.
    expect(validateAccent(const Color(0xFF000000), Brightness.light, freepivFrostConfig.palettes).canApply, isFalse);
    expect(validateAccent(const Color(0xFFFFFFFF), Brightness.dark, freepivFrostConfig.palettes).canApply, isFalse);
  });

  test('severity uses the raw minimum contrast on both sides of each threshold', () {
    for (final brightness in Brightness.values) {
      final results = [
        for (var value = 0; value <= 255; value++) validateAccent(Color.fromARGB(255, value, value, value), brightness, freepivFrostConfig.palettes),
      ];
      for (final threshold in [1.5, 2.0]) {
        final below = results.where((result) => result.minimumContrast < threshold).toList()..sort((a, b) => b.minimumContrast.compareTo(a.minimumContrast));
        final above = results.where((result) => result.minimumContrast >= threshold).toList()..sort((a, b) => a.minimumContrast.compareTo(b.minimumContrast));
        expect(below, isNotEmpty);
        expect(above, isNotEmpty);
        expect(below.first.minimumContrast, lessThan(threshold));
        expect(above.first.minimumContrast, greaterThanOrEqualTo(threshold));
        expect(below.first.severity, threshold == 1.5 ? FrostAccentSeverity.rejected : FrostAccentSeverity.warning);
        expect(above.first.severity, threshold == 1.5 ? FrostAccentSeverity.warning : FrostAccentSeverity.allowed);
      }
    }
  });

  test('appearance migrates old mode and repairs each corrupt field independently', () async {
    final store = MemorySettingsStore({'themeMode': 2, 'localeCode': 'ja-JP'});
    await AppSettings.initialize(store: store);
    expect(AppSettings.appearance.mode, ThemeMode.dark);
    expect(AppSettings.localeCode, 'ja-JP');

    store.values['appearance'] = {
      'version': 1,
      'mode': 'light',
      'lightTone': 'cool',
      'darkTone': 'warm',
      'lightAccent': 'FFFFFF',
      'darkAccent': '00A68C',
      'lightCustomAccent': 'NOTHEX',
      'darkCustomAccent': '000000',
    };
    await AppSettings.initialize(store: store);
    final loaded = AppSettings.appearance;
    expect(loaded.mode, ThemeMode.light);
    expect(loaded.lightTone, FrostTone.cool);
    expect(loaded.darkTone, FrostTone.warm);
    expect(loaded.lightAccent, FrostPalettes.pink.lightDefaultAccent);
    expect(loaded.darkAccent, const Color(0xFF00A68C));
    expect(loaded.lightCustomAccent, isNull);
    expect(loaded.darkCustomAccent, isNull);
    expect(AppSettings.localeCode, 'ja-JP');
  });

  test('the persistence boundary refuses unsafe accents without touching disk', () async {
    final store = MemorySettingsStore();
    await AppSettings.initialize(store: store);
    await expectLater(AppSettings.saveAppearance(FrostAppearance.initial(FrostPalettes.pink).copyWith(lightAccent: const Color(0xFFFFFFFF))), throwsArgumentError);
    expect(store.writes, isEmpty);
    expect(AppSettings.appearance.lightAccent, FrostPalettes.pink.lightDefaultAccent);
  });

  test('rapid immediate choices coalesce and last valid snapshot wins', () async {
    final store = MemorySettingsStore();
    final firstWrite = Completer<void>();
    var started = 0;
    store.onWrite = (key, value) async {
      started++;
      if (started == 1) await firstWrite.future;
    };
    await AppSettings.initialize(store: store);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appearanceProvider.notifier);
    notifier.setMode(ThemeMode.light);
    notifier.setTone(Brightness.light, FrostTone.cool);
    notifier.setPreset(Brightness.light, const Color(0xFF4C8DFF));
    firstWrite.complete();
    await notifier.retrySave();
    final saved = AppSettings.appearance;
    expect(saved.mode, ThemeMode.light);
    expect(saved.lightTone, FrostTone.cool);
    expect(saved.lightAccent, const Color(0xFF4C8DFF));
    expect(container.read(appearanceProvider).unsaved, isFalse);
    expect(store.writes.every((entry) => entry.key == 'appearance'), isTrue);
    expect(store.writes.length, lessThanOrEqualTo(2));
  });

  test('custom apply waits for write and failure leaves applied theme alone', () async {
    final store = MemorySettingsStore();
    await AppSettings.initialize(store: store);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appearanceProvider.notifier);
    store.onWrite = (_, _) async => throw StateError('disk unavailable');
    final failed = await notifier.applyCustom(Brightness.dark, const Color(0xFF00A68C));
    expect(failed, isFalse);
    expect(container.read(appearanceProvider).settings.darkAccent, FrostPalettes.pink.darkDefaultAccent);
    expect(AppSettings.appearance.darkAccent, FrostPalettes.pink.darkDefaultAccent);
    store.onWrite = null;
    expect(await notifier.applyCustom(Brightness.dark, const Color(0xFF00A68C)), isTrue);
    expect(container.read(appearanceProvider).settings.darkAccent, const Color(0xFF00A68C));
    expect(AppSettings.appearance.darkCustomAccent, const Color(0xFF00A68C));
  });
}
