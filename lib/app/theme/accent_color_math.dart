import 'package:flutter/material.dart';

double colorContrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
}

Color readableOnAccent(Color accent) {
  const preferred = Color(0xFF171C24);
  if (_minimumPrimaryContrast(accent, preferred) >= 4.5) return preferred;
  const black = Colors.black;
  const white = Colors.white;
  if (_minimumPrimaryContrast(accent, black) >= 4.5) return black;
  if (_minimumPrimaryContrast(accent, white) >= 4.5) return white;
  // The feedback layer is suppressed if it would lower this contrast.
  return colorContrast(accent, black) >= colorContrast(accent, white) ? black : white;
}

double _minimumPrimaryContrast(Color accent, Color foreground) {
  final base = colorContrast(accent, foreground);
  final hover = colorContrast(Color.alphaBlend(Colors.white.withValues(alpha: .08), accent), foreground);
  final pressed = colorContrast(Color.alphaBlend(Colors.white.withValues(alpha: .04), accent), foreground);
  return [base, hover, pressed].reduce((a, b) => a < b ? a : b);
}

/// Returns [accent] or the nearest tone of the same hue and saturation that
/// reaches [minimum] contrast on [background]. Lightness moves away from the
/// background, so pink stays pink instead of being mixed with black or white.
Color readableAccentTone(Color accent, Color background, double minimum) {
  final key = (accent.toARGB32(), background.toARGB32(), minimum);
  if (_readableToneCache[key] case final cached?) return cached;
  if (_readableToneCache.length > 64) _readableToneCache.clear();
  return _readableToneCache[key] = _searchReadableTone(accent, background, minimum);
}

// Theme getters resolve these tones during build; palettes are few and fixed.
final _readableToneCache = <(int, int, double), Color>{};

Color _searchReadableTone(Color accent, Color background, double minimum) {
  if (colorContrast(accent, background) >= minimum) return accent;
  final hsl = HSLColor.fromColor(accent);
  final darken = background.computeLuminance() > .18;
  var low = darken ? 0.0 : hsl.lightness;
  var high = darken ? hsl.lightness : 1.0;
  // The extreme end (near black or near white) always passes on the neutral
  // palette surfaces; search the tone closest to the original that passes.
  for (var i = 0; i < 18; i++) {
    final middle = (low + high) / 2;
    final passes = colorContrast(hsl.withLightness(middle).toColor(), background) >= minimum;
    if (darken == passes) {
      low = middle;
    } else {
      high = middle;
    }
  }
  return hsl.withLightness(darken ? low : high).toColor().withValues(alpha: accent.a);
}

/// Label colour for a solid accent button. White wherever it reaches
/// [solidWhiteLabelContrast] on the fill, as on Pixiv's own blue buttons: a
/// dark tone on a saturated mid-tone fill such as the default pink reads as
/// dirty. Otherwise a clearly coloured tone of the fill's own hue — neither
/// generic black nor white — at the lightness closest to the fill that still
/// reaches [solidLabelContrast] on the fill and on its hover/press washes,
/// falling back to black or white only when no tone of the hue can.
Color solidLabelTone(Color fill) {
  final key = fill.toARGB32();
  if (_solidLabelCache[key] case final cached?) return cached;
  if (_solidLabelCache.length > 64) _solidLabelCache.clear();
  return _solidLabelCache[key] = _searchSolidLabel(fill);
}

/// Standard text contrast; aiming higher only pushes the label toward black.
const solidLabelContrast = 4.5;

/// The least contrast a white label may have on the fill: the large, bold
/// text of a button, a little under the 3:1 that large text asks for, where
/// the default pink lands.
const solidWhiteLabelContrast = 2.8;

/// Enough colour for the label to read as a hue, a little under the fill's
/// own so it does not compete with it.
const _solidLabelSaturation = .8;

final _solidLabelCache = <int, Color>{};

Color _searchSolidLabel(Color fill) {
  if (colorContrast(fill, Colors.white) >= solidWhiteLabelContrast) return Colors.white;
  final hsl = HSLColor.fromColor(fill);
  final ink = hsl.withSaturation(hsl.saturation.clamp(0.0, _solidLabelSaturation));
  final dark = fill.computeLuminance() > .18;
  final extreme = dark ? 0.0 : 1.0;
  bool passes(double lightness) => _minimumPrimaryContrast(fill, ink.withLightness(lightness).toColor()) >= solidLabelContrast;
  // Mid-tone accents such as pure blue reach the contrast with no tone of
  // their hue in every state; they fall through to black or white below.
  if (passes(extreme)) {
    // Binary search between the extreme (passes) and the fill's own
    // lightness (fails) for the passing tone nearest the fill.
    var good = extreme;
    var bad = hsl.lightness;
    for (var i = 0; i < 18; i++) {
      final middle = (good + bad) / 2;
      if (passes(middle)) {
        good = middle;
      } else {
        bad = middle;
      }
    }
    return ink.withLightness(good).toColor();
  }
  // The hover and press washes are then dropped where they would lower the
  // label below 4.5:1 (see [solidOverlayAlpha]).
  return colorContrast(fill, Colors.black) >= colorContrast(fill, Colors.white) ? Colors.black : Colors.white;
}

/// The hover/press wash of a solid button: darkening under a white label so
/// the label's contrast only rises, a lightening one otherwise.
Color solidWashColor(Color fill) => solidLabelTone(fill) == Colors.white ? Colors.black : Colors.white;

/// The [solidWashColor] alpha a solid button may show without dropping its
/// label below 4.5:1; 0 where it would. A dark wash under a white label
/// never lowers it.
double solidOverlayAlpha(Color fill, double requested) {
  if (solidLabelTone(fill) == Colors.white) return requested;
  final composite = Color.alphaBlend(Colors.white.withValues(alpha: requested), fill);
  return colorContrast(composite, solidLabelTone(fill)) >= 4.5 ? requested : 0;
}

/// Low-saturation accent used by ambient background washes.
Color ambientAccent(Color accent, {double saturationScale = .55}) {
  final hsl = HSLColor.fromColor(accent);
  return hsl.withSaturation((hsl.saturation * saturationScale).clamp(0.0, 1.0)).toColor();
}
