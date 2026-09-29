import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/accent_validation.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';

enum AppearanceTone { neutral, cool, warm }

@immutable
class AppearanceSettings {
  const AppearanceSettings({
    this.mode = ThemeMode.system,
    this.lightTone = AppearanceTone.neutral,
    this.darkTone = AppearanceTone.neutral,
    this.lightAccent = FreepivThemeTokens.brandPink,
    this.darkAccent = FreepivThemeTokens.brandPink,
    this.lightCustomAccent,
    this.darkCustomAccent,
  });

  final ThemeMode mode;
  final AppearanceTone lightTone, darkTone;
  final Color lightAccent, darkAccent;
  final Color? lightCustomAccent, darkCustomAccent;

  @override
  bool operator ==(Object other) =>
      other is AppearanceSettings &&
      other.mode == mode &&
      other.lightTone == lightTone &&
      other.darkTone == darkTone &&
      other.lightAccent == lightAccent &&
      other.darkAccent == darkAccent &&
      other.lightCustomAccent == lightCustomAccent &&
      other.darkCustomAccent == darkCustomAccent;

  @override
  int get hashCode => Object.hash(mode, lightTone, darkTone, lightAccent, darkAccent, lightCustomAccent, darkCustomAccent);

  AppearanceTone toneFor(Brightness brightness) => brightness == Brightness.light ? lightTone : darkTone;
  AppearanceTone effectiveToneFor(Brightness brightness) => mode == ThemeMode.system ? AppearanceTone.neutral : toneFor(brightness);
  Color accentFor(Brightness brightness) => brightness == Brightness.light ? lightAccent : darkAccent;
  Color? customAccentFor(Brightness brightness) => brightness == Brightness.light ? lightCustomAccent : darkCustomAccent;

  AppearanceSettings copyWith({
    ThemeMode? mode,
    AppearanceTone? lightTone,
    AppearanceTone? darkTone,
    Color? lightAccent,
    Color? darkAccent,
    Color? lightCustomAccent,
    Color? darkCustomAccent,
  }) => AppearanceSettings(
    mode: mode ?? this.mode,
    lightTone: lightTone ?? this.lightTone,
    darkTone: darkTone ?? this.darkTone,
    lightAccent: lightAccent ?? this.lightAccent,
    darkAccent: darkAccent ?? this.darkAccent,
    lightCustomAccent: lightCustomAccent ?? this.lightCustomAccent,
    darkCustomAccent: darkCustomAccent ?? this.darkCustomAccent,
  );

  Map<String, Object?> toRecord() => {
    'version': 1,
    'mode': mode.name,
    'lightTone': lightTone.name,
    'darkTone': darkTone.name,
    'lightAccent': accentHex(lightAccent),
    'darkAccent': accentHex(darkAccent),
    'lightCustomAccent': lightCustomAccent == null ? null : accentHex(lightCustomAccent!),
    'darkCustomAccent': darkCustomAccent == null ? null : accentHex(darkCustomAccent!),
  };

  static AppearanceSettings fromRecord(Object? input, {int? legacyThemeMode}) {
    final legacyMode = legacyThemeMode != null && legacyThemeMode >= 0 && legacyThemeMode < ThemeMode.values.length
        ? ThemeMode.values[legacyThemeMode]
        : ThemeMode.system;
    if (input is! Map || input['version'] != 1) return AppearanceSettings(mode: legacyMode);
    T pickEnum<T extends Enum>(Object? value, List<T> values, T fallback) {
      for (final item in values) {
        if (item.name == value) return item;
      }
      return fallback;
    }

    Color? safeColor(Object? value, Brightness brightness) {
      final color = value is String ? parseAccentHex(value) : null;
      return color != null && validateAccent(color, brightness).canApply ? color : null;
    }

    return AppearanceSettings(
      mode: pickEnum(input['mode'], ThemeMode.values, ThemeMode.system),
      lightTone: pickEnum(input['lightTone'], AppearanceTone.values, AppearanceTone.neutral),
      darkTone: pickEnum(input['darkTone'], AppearanceTone.values, AppearanceTone.neutral),
      lightAccent: safeColor(input['lightAccent'], Brightness.light) ?? FreepivThemeTokens.brandPink,
      darkAccent: safeColor(input['darkAccent'], Brightness.dark) ?? FreepivThemeTokens.brandPink,
      lightCustomAccent: safeColor(input['lightCustomAccent'], Brightness.light),
      darkCustomAccent: safeColor(input['darkCustomAccent'], Brightness.dark),
    );
  }
}
