import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/accent_color_math.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/core/services/appearance_settings.dart';

enum AccentSeverity { allowed, warning, rejected }

class AccentValidation {
  const AccentValidation(this.severity, this.minimumContrast);
  final AccentSeverity severity;
  final double minimumContrast;
  bool get canApply => severity != AccentSeverity.rejected;
}

Color? parseAccentHex(String input) {
  final value = input.trim().replaceFirst(RegExp(r'^#'), '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return null;
  return Color(0xFF000000 | int.parse(value, radix: 16));
}

String accentHex(Color color) => color.toARGB32().toRadixString(16).substring(2).toUpperCase();

const accentPresets = <Color>[FreepivThemeTokens.brandPink, Color(0xFF4C8DFF), Color(0xFF00A68C), Color(0xFF9B7AF6), Color(0xFFC58A15), Color(0xFFE97640)];

AccentValidation validateAccent(Color candidate, Brightness brightness) {
  if (candidate.a < 1) return const AccentValidation(AccentSeverity.rejected, 0);
  var minimum = double.infinity;
  for (final tone in AppearanceTone.values) {
    final palette = FreepivThemeTokens.palette(brightness, tone, candidate);
    for (final surface in [
      palette.canvas,
      palette.surface,
      palette.surfaceRaised,
      palette.surfaceInset,
      palette.surfaceMuted,
      palette.hoverSurface,
      palette.pressedSurface,
    ]) {
      final contrast = colorContrast(candidate, surface);
      if (contrast < minimum) minimum = contrast;
    }
  }
  if (minimum < 1.5) return AccentValidation(AccentSeverity.rejected, minimum);
  // Filled controls resolve their own foreground from the exact accent. The
  // paired black/white alternatives guarantee at least 4.5 on an opaque fill.
  if (colorContrast(candidate, readableOnAccent(candidate)) < 4.5) {
    return AccentValidation(AccentSeverity.rejected, minimum);
  }
  return AccentValidation(minimum < 2 ? AccentSeverity.warning : AccentSeverity.allowed, minimum);
}
