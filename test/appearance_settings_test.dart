import 'dart:async';

import 'package:flutter/material.dart';
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

  test('all six palettes feed neutral ThemeData surfaces and readable text', () {
    const expectedCanvas = {
      (Brightness.light, FrostTone.neutral): Color(0xFFF6F6F6),
      (Brightness.light, FrostTone.cool): Color(0xFFF4F7FA),
      (Brightness.light, FrostTone.warm): Color(0xFFF7F7F4),
      (Brightness.dark, FrostTone.neutral): Color(0xFF202124),
      (Brightness.dark, FrostTone.cool): Color(0xFF1B2026),
      (Brightness.dark, FrostTone.warm): Color(0xFF20201E),
    };
    for (final brightness in Brightness.values) {
      for (final tone in FrostTone.values) {
        final theme = brightness == Brightness.light
            ? AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en'), tone: tone)
            : AppTheme.dark(platform: TargetPlatform.android, locale: const Locale('en'), tone: tone);
        final tokens = theme.extension<FrostThemeTokens>()!;
        expect(tokens.canvas, expectedCanvas[(brightness, tone)]);
        // Pages are transparent; the window ambient backdrop paints the canvas.
        expect(theme.scaffoldBackgroundColor, Colors.transparent);
        expect(theme.colorScheme.surfaceContainerLowest, tokens.canvas);
        expect(theme.colorScheme.surfaceContainer, tokens.surfaceInset);
        for (final surface in [
          tokens.canvas,
          tokens.surface,
          tokens.surfaceRaised,
          tokens.surfaceInset,
          tokens.surfaceMuted,
          tokens.hoverSurface,
          tokens.pressedSurface,
        ]) {
          expect(colorContrast(tokens.textPrimary, surface), greaterThanOrEqualTo(4.5));
          expect(colorContrast(tokens.textSecondary, surface), greaterThanOrEqualTo(4.5));
        }
      }
    }
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
    expect(validateAccent(Colors.black, Brightness.light, freepivFrostConfig.palettes).canApply, isFalse);
    expect(validateAccent(Colors.white, Brightness.dark, freepivFrostConfig.palettes).canApply, isFalse);
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

  test('filled actions and critical glyphs stay readable for allowed samples', () {
    for (final brightness in Brightness.values) {
      for (var red = 0; red <= 255; red += 51) {
        for (var green = 0; green <= 255; green += 51) {
          for (var blue = 0; blue <= 255; blue += 51) {
            final candidate = Color.fromARGB(255, red, green, blue);
            if (!validateAccent(candidate, brightness, freepivFrostConfig.palettes).canApply) continue;
            final palette = FrostPalettes.pink.palette(brightness, FrostTone.neutral, candidate);
            // Glyphs on the raw accent keep full text contrast.
            expect(colorContrast(candidate, palette.onAccent), greaterThanOrEqualTo(4.5));
            // Solid buttons keep the exact accent (never a darkened wine
            // shade). A white label needs its button-text minimum and only
            // ever gets a darkening wash; any other label is a tone of the
            // accent's own hue with full text contrast, including under the
            // hover and press washes.
            expect(palette.actionFill, candidate);
            final whiteLabel = palette.onAction == Colors.white;
            for (final opacity in [0.0, .04, .08]) {
              final wash = solidOverlayAlpha(palette.actionFill, opacity);
              final composite = Color.alphaBlend(solidWashColor(palette.actionFill).withValues(alpha: wash), palette.actionFill);
              expect(
                colorContrast(composite, palette.onAction),
                greaterThanOrEqualTo(whiteLabel ? solidWhiteLabelContrast : 4.5),
                reason: '$candidate $opacity',
              );
            }
            final label = HSLColor.fromColor(palette.onAction);
            // Deep or pale 8-bit tones only approximate the hue.
            if (!whiteLabel && label.saturation > .1 && label.lightness > .08 && label.lightness < .92) {
              final drift = (label.hue - HSLColor.fromColor(candidate).hue).abs() % 360;
              expect(drift < 180 ? drift : 360 - drift, lessThan(10), reason: '$candidate');
            }
            for (final surface in [palette.canvas, palette.surface, palette.surfaceInset, palette.surfaceRaised]) {
              expect(colorContrast(palette.keyGraphicOn(surface), surface), greaterThanOrEqualTo(3));
            }
          }
        }
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
    expect(loaded.lightAccent, const Color(0xFFFC619D));
    expect(loaded.darkAccent, const Color(0xFF00A68C));
    expect(loaded.lightCustomAccent, isNull);
    expect(loaded.darkCustomAccent, isNull);
    expect(AppSettings.localeCode, 'ja-JP');
  });

  test('the persistence boundary refuses unsafe accents without touching disk', () async {
    final store = MemorySettingsStore();
    await AppSettings.initialize(store: store);
    await expectLater(AppSettings.saveAppearance(FrostAppearance.initial(FrostPalettes.pink).copyWith(lightAccent: Colors.white)), throwsArgumentError);
    expect(store.writes, isEmpty);
    expect(AppSettings.appearance.lightAccent, const Color(0xFFFC619D));
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
    expect(container.read(appearanceProvider).settings.darkAccent, const Color(0xFFFC619D));
    expect(AppSettings.appearance.darkAccent, const Color(0xFFFC619D));
    store.onWrite = null;
    expect(await notifier.applyCustom(Brightness.dark, const Color(0xFF00A68C)), isTrue);
    expect(container.read(appearanceProvider).settings.darkAccent, const Color(0xFF00A68C));
    expect(AppSettings.appearance.darkCustomAccent, const Color(0xFF00A68C));
  });
}
