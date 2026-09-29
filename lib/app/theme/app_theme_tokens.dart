import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/accent_color_math.dart';
import 'package:freepiv/core/services/appearance_settings.dart';

@immutable
class FreepivThemeTokens extends ThemeExtension<FreepivThemeTokens> {
  const FreepivThemeTokens({
    required this.brightness,
    required this.tone,
    required this.accent,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceInset,
    required this.surfaceMuted,
    required this.surfaceTint,
    required this.textPrimary,
    required this.textSecondary,
    required this.disabledText,
    required this.line,
    required this.hoverSurface,
    required this.pressedSurface,
    required this.commentSeparator,
    required this.commentThreadLine,
    required this.shadow,
  });

  static const brandPink = Color(0xFFFC619D);
  final Brightness brightness;
  final AppearanceTone tone;
  final Color accent;
  Color get brand => accent;

  /// Solid action fill (primary buttons, Follow): exactly the chosen accent,
  /// never darkened toward a wine shade.
  Color get actionFill => accent;

  /// Its label: white where it reads (the default pink), else a deep (or pale)
  /// tone of the accent's own hue rather than
  /// generic black or white, see [solidLabelTone].
  Color get onAction => solidLabelTone(accent);

  /// Glyphs drawn directly on the raw accent (checkbox check, switch thumb,
  /// colorScheme.onPrimary).
  Color get onAccent => readableOnAccent(accent);

  /// Keyboard focus ring: shown only while navigating by keyboard, so it
  /// may be strong.
  Color get focus => textPrimary;

  /// Outline of a text field being typed in. The caret already shows where
  /// input goes, so the outline marks the active field in the accent at the
  /// 3:1 a focus indicator needs, not with the dark keyboard ring.
  Color get fieldFocus => keyGraphicOn(surfaceRaised);

  /// Edge of an opaque floating panel (reduce transparency). Its solid fill
  /// already separates it from the canvas, so the line sits halfway between
  /// the canvas and [line] and is felt rather than drawn.
  Color get panelEdge => Color.lerp(canvas, line, .5)!;
  final Color canvas, surface, surfaceRaised, surfaceInset, surfaceMuted, surfaceTint;
  final Color textPrimary, textSecondary, disabledText;
  final Color line, hoverSurface, pressedSurface, commentSeparator, commentThreadLine, shadow;
  bool get isDark => brightness == Brightness.dark;

  /// Accent tone for text and links on the palette's surfaces (4.5:1).
  Color get accentInk => readableAccentTone(accent, surface, 4.5);

  /// Translucent accent wash for persistent selection. It stays translucent
  /// so a selected item on glass still shows the material behind it.
  Color get selectionFill => accent.withValues(alpha: isDark ? .20 : .14);

  /// Opaque equivalent of [selectionFill] over a raised surface, for menus
  /// and reduced-transparency rendering.
  Color get selectionSurface => Color.alphaBlend(selectionFill, surfaceRaised);
  Color get selectionInk => readableAccentTone(accent, selectionSurface, 4.5);
  Color get selectionLine => keyGraphicOn(selectionSurface);

  /// Accent tone for key graphics such as indicators and icons (3:1).
  Color keyGraphicOn(Color background) => readableAccentTone(accent, background, 3);

  static const light = lightNeutral;
  static const dark = darkNeutral;
  static const lightNeutral = FreepivThemeTokens(
    brightness: Brightness.light,
    tone: AppearanceTone.neutral,
    accent: brandPink,
    canvas: Color(0xFFF6F6F6),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceInset: Color(0xFFECECEC),
    surfaceMuted: Color(0xFFF1F1F1),
    surfaceTint: Color(0xFFF6F6F6),
    textPrimary: Color(0xFF242424),
    textSecondary: Color(0xFF606060),
    disabledText: Color(0xFF777777),
    line: Color(0xFFD6D6D6),
    hoverSurface: Color(0xFFE7E7E7),
    pressedSurface: Color(0xFFDBDBDB),
    commentSeparator: Color(0xFFD0D0D0),
    commentThreadLine: Color(0xFFBABABA),
    shadow: Color(0x10000000),
  );
  static const lightCool = FreepivThemeTokens(
    brightness: Brightness.light,
    tone: AppearanceTone.cool,
    accent: brandPink,
    canvas: Color(0xFFF4F7FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceInset: Color(0xFFEBF0F5),
    surfaceMuted: Color(0xFFF0F4F8),
    surfaceTint: Color(0xFFF4F7FA),
    textPrimary: Color(0xFF202832),
    textSecondary: Color(0xFF52606D),
    disabledText: Color(0xFF697582),
    line: Color(0xFFD6DEE7),
    hoverSurface: Color(0xFFE9EEF4),
    pressedSurface: Color(0xFFDDE5EE),
    commentSeparator: Color(0xFFCCD5DF),
    commentThreadLine: Color(0xFFAEBBC9),
    shadow: Color(0x10000000),
  );
  static const lightWarm = FreepivThemeTokens(
    brightness: Brightness.light,
    tone: AppearanceTone.warm,
    accent: brandPink,
    canvas: Color(0xFFF7F7F4),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceInset: Color(0xFFEEEEEA),
    surfaceMuted: Color(0xFFF2F2EE),
    surfaceTint: Color(0xFFF7F7F4),
    textPrimary: Color(0xFF242421),
    textSecondary: Color(0xFF61615B),
    disabledText: Color(0xFF787870),
    line: Color(0xFFD6D6CF),
    hoverSurface: Color(0xFFE8E8E3),
    pressedSurface: Color(0xFFDDDDD6),
    commentSeparator: Color(0xFFD0D0C8),
    commentThreadLine: Color(0xFFBCBCB3),
    shadow: Color(0x10000000),
  );
  static const darkNeutral = FreepivThemeTokens(
    brightness: Brightness.dark,
    tone: AppearanceTone.neutral,
    accent: brandPink,
    canvas: Color(0xFF202124),
    surface: Color(0xFF292A2D),
    surfaceRaised: Color(0xFF303134),
    surfaceInset: Color(0xFF252629),
    surfaceMuted: Color(0xFF36373A),
    surfaceTint: Color(0xFF303134),
    textPrimary: Color(0xFFE8EAED),
    textSecondary: Color(0xFFB9BDC4),
    disabledText: Color(0xFF858991),
    line: Color(0xFF4A4D51),
    hoverSurface: Color(0xFF3A3B3F),
    pressedSurface: Color(0xFF45464B),
    commentSeparator: Color(0xFF565A60),
    commentThreadLine: Color(0xFF747A82),
    shadow: Color(0x52000000),
  );
  static const darkCool = FreepivThemeTokens(
    brightness: Brightness.dark,
    tone: AppearanceTone.cool,
    accent: brandPink,
    canvas: Color(0xFF1B2026),
    surface: Color(0xFF232A32),
    surfaceRaised: Color(0xFF2C3540),
    surfaceInset: Color(0xFF1F262E),
    surfaceMuted: Color(0xFF333F4B),
    surfaceTint: Color(0xFF2C3540),
    textPrimary: Color(0xFFECF1F7),
    textSecondary: Color(0xFFBECBD9),
    disabledText: Color(0xFF8A98A8),
    line: Color(0xFF465464),
    hoverSurface: Color(0xFF354351),
    pressedSurface: Color(0xFF414F5F),
    commentSeparator: Color(0xFF536477),
    commentThreadLine: Color(0xFF70859B),
    shadow: Color(0x52000000),
  );
  static const darkWarm = FreepivThemeTokens(
    brightness: Brightness.dark,
    tone: AppearanceTone.warm,
    accent: brandPink,
    canvas: Color(0xFF20201E),
    surface: Color(0xFF292927),
    surfaceRaised: Color(0xFF33332F),
    surfaceInset: Color(0xFF252523),
    surfaceMuted: Color(0xFF393934),
    surfaceTint: Color(0xFF33332F),
    textPrimary: Color(0xFFF5F4F1),
    textSecondary: Color(0xFFC3C1BA),
    disabledText: Color(0xFF929087),
    line: Color(0xFF4F4F46),
    hoverSurface: Color(0xFF3D3D37),
    pressedSurface: Color(0xFF484840),
    commentSeparator: Color(0xFF5C5C52),
    commentThreadLine: Color(0xFF7B7B6D),
    shadow: Color(0x52000000),
  );

  static FreepivThemeTokens palette(Brightness brightness, AppearanceTone tone, Color accent) {
    final base = switch ((brightness, tone)) {
      (Brightness.light, AppearanceTone.neutral) => lightNeutral,
      (Brightness.light, AppearanceTone.cool) => lightCool,
      (Brightness.light, AppearanceTone.warm) => lightWarm,
      (Brightness.dark, AppearanceTone.neutral) => darkNeutral,
      (Brightness.dark, AppearanceTone.cool) => darkCool,
      (Brightness.dark, AppearanceTone.warm) => darkWarm,
    };
    return base.copyWith(accent: accent);
  }

  static FreepivThemeTokens of(BuildContext context) => Theme.of(context).extension<FreepivThemeTokens>() ?? light;

  @override
  FreepivThemeTokens copyWith({
    Brightness? brightness,
    AppearanceTone? tone,
    Color? brand,
    Color? accent,
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceInset,
    Color? surfaceMuted,
    Color? surfaceTint,
    Color? textPrimary,
    Color? textSecondary,
    Color? disabledText,
    Color? line,
    Color? hoverSurface,
    Color? pressedSurface,
    Color? commentSeparator,
    Color? commentThreadLine,
    Color? shadow,
  }) => FreepivThemeTokens(
    brightness: brightness ?? this.brightness,
    tone: tone ?? this.tone,
    accent: accent ?? brand ?? this.accent,
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceInset: surfaceInset ?? this.surfaceInset,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    surfaceTint: surfaceTint ?? this.surfaceTint,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    disabledText: disabledText ?? this.disabledText,
    line: line ?? this.line,
    hoverSurface: hoverSurface ?? this.hoverSurface,
    pressedSurface: pressedSurface ?? this.pressedSurface,
    commentSeparator: commentSeparator ?? this.commentSeparator,
    commentThreadLine: commentThreadLine ?? this.commentThreadLine,
    shadow: shadow ?? this.shadow,
  );

  @override
  FreepivThemeTokens lerp(ThemeExtension<FreepivThemeTokens>? other, double t) {
    if (other is! FreepivThemeTokens) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return FreepivThemeTokens(
      brightness: t < .5 ? brightness : other.brightness,
      tone: t < .5 ? tone : other.tone,
      accent: mix(accent, other.accent),
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      surfaceInset: mix(surfaceInset, other.surfaceInset),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      surfaceTint: mix(surfaceTint, other.surfaceTint),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      disabledText: mix(disabledText, other.disabledText),
      line: mix(line, other.line),
      hoverSurface: mix(hoverSurface, other.hoverSurface),
      pressedSurface: mix(pressedSurface, other.pressedSurface),
      commentSeparator: mix(commentSeparator, other.commentSeparator),
      commentThreadLine: mix(commentThreadLine, other.commentThreadLine),
      shadow: mix(shadow, other.shadow),
    );
  }
}

abstract final class WindowCaptionColors {
  static const closeHover = Color(0xFFE81123);
  static const closePressed = Color(0xFFC50F1F);
  static const onClose = Colors.white;
}
