import 'package:flutter/material.dart';

@immutable
class FreepivThemeTokens extends ThemeExtension<FreepivThemeTokens> {
  const FreepivThemeTokens({
    required this.brand,
    required this.accent,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceTint,
    required this.surfaceMuted,
    required this.line,
    required this.shadow,
  });

  static const brandPink = Color(0xFFFC619D);
  static const softBlue = Color(0xFF7BBDEB);

  final Color brand;
  final Color accent;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceTint;
  final Color surfaceMuted;
  final Color line;
  final Color shadow;

  static const light = FreepivThemeTokens(
    brand: brandPink,
    accent: softBlue,
    surface: Color(0xFFFFFBFD),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceTint: Color(0xFFFFF4F8),
    surfaceMuted: Color(0xFFF6F1F4),
    line: Color(0xFFEBDDE4),
    shadow: Color(0x10000000),
  );

  static const dark = FreepivThemeTokens(
    brand: Color(0xFFFF79AD),
    accent: Color(0xFF8FB8D8),
    surface: Color(0xFF121214),
    surfaceRaised: Color(0xFF1B1B1E),
    surfaceTint: Color(0xFF222226),
    surfaceMuted: Color(0xFF242428),
    line: Color(0xFF323238),
    shadow: Color(0x52000000),
  );

  static FreepivThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<FreepivThemeTokens>() ?? light;
  }

  @override
  FreepivThemeTokens copyWith({
    Color? brand,
    Color? accent,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceTint,
    Color? surfaceMuted,
    Color? line,
    Color? shadow,
  }) {
    return FreepivThemeTokens(
      brand: brand ?? this.brand,
      accent: accent ?? this.accent,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      line: line ?? this.line,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  FreepivThemeTokens lerp(ThemeExtension<FreepivThemeTokens>? other, double t) {
    if (other is! FreepivThemeTokens) {
      return this;
    }

    return FreepivThemeTokens(
      brand: Color.lerp(brand, other.brand, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      line: Color.lerp(line, other.line, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
