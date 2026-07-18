import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_system_fonts.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/core/services/app_settings.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final savedThemeMode = AppSettings.themeMode;
    if (savedThemeMode == null || savedThemeMode >= ThemeMode.values.length) {
      return ThemeMode.system;
    }
    return ThemeMode.values[savedThemeMode];
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    AppSettings.themeMode = mode.index;
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light({required TargetPlatform platform, required Locale locale}) {
    return _build(tokens: FreepivThemeTokens.light, brightness: Brightness.light, platform: platform, locale: locale);
  }

  static ThemeData dark({required TargetPlatform platform, required Locale locale}) {
    return _build(tokens: FreepivThemeTokens.dark, brightness: Brightness.dark, platform: platform, locale: locale);
  }

  static ThemeData _build({required FreepivThemeTokens tokens, required Brightness brightness, required TargetPlatform platform, required Locale locale}) {
    final colorScheme = _colorScheme(tokens: tokens, brightness: brightness);
    final systemFonts = AppSystemFonts.resolve(platform: platform, locale: locale);
    final base = ThemeData(
      platform: platform,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.surface,
      fontFamily: systemFonts.family,
      fontFamilyFallback: systemFonts.fallbacks,
      useMaterial3: true,
      extensions: [tokens],
    );

    return _applyTextTheme(base).copyWith(
      splashColor: tokens.brand.withValues(alpha: 0.10),
      highlightColor: tokens.brand.withValues(alpha: 0.06),
      hoverColor: tokens.brand.withValues(alpha: 0.05),
      focusColor: tokens.brand.withValues(alpha: 0.10),
      dividerColor: tokens.line.withValues(alpha: brightness == Brightness.light ? 0.55 : 0.45),
      dividerTheme: DividerThemeData(color: tokens.line.withValues(alpha: brightness == Brightness.light ? 0.55 : 0.45), thickness: 1, space: 1),
      appBarTheme: AppBarThemeData(
        backgroundColor: tokens.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w700),
        shape: Border(bottom: BorderSide(color: tokens.line.withValues(alpha: 0.42))),
      ),
      cardTheme: CardThemeData(
        color: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: tokens.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
          highlightColor: tokens.brand.withValues(alpha: 0.08),
          hoverColor: tokens.brand.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.brand,
          disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
          textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: tokens.brand.withValues(alpha: 0.36),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.68),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.surfaceRaised,
          foregroundColor: tokens.brand,
          disabledBackgroundColor: tokens.surfaceMuted,
          disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.42),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.brand,
          disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
          side: BorderSide(color: tokens.line),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(style: _segmentedButtonStyle(tokens, colorScheme)),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceRaised,
        selectedColor: tokens.brand.withValues(alpha: brightness == Brightness.light ? 0.15 : 0.25),
        disabledColor: tokens.surfaceMuted,
        labelStyle: base.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
        secondaryLabelStyle: base.textTheme.labelMedium?.copyWith(color: tokens.brand, fontWeight: FontWeight.w700),
        side: BorderSide(color: tokens.line.withValues(alpha: 0.42)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: tokens.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: _inputBorder(tokens.line),
        enabledBorder: _inputBorder(tokens.line),
        focusedBorder: _inputBorder(tokens.brand, width: 1.4),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 1.4),
        hintStyle: base.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.brand,
        textColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }

  static ThemeData _applyTextTheme(ThemeData theme) {
    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        displayLarge: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700),
        displayMedium: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700),
        displaySmall: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        headlineLarge: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        headlineMedium: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        headlineSmall: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
        bodyMedium: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
        bodySmall: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400),
        labelLarge: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        labelMedium: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        labelSmall: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  static ColorScheme _colorScheme({required FreepivThemeTokens tokens, required Brightness brightness}) {
    final base = ColorScheme.fromSeed(seedColor: FreepivThemeTokens.brandPink, brightness: brightness);

    if (brightness == Brightness.light) {
      return base.copyWith(
        primary: tokens.brand,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFFFD8E8),
        onPrimaryContainer: const Color(0xFF4E102E),
        secondary: tokens.accent,
        onSecondary: const Color(0xFF082B42),
        secondaryContainer: const Color(0xFFE3F3FF),
        onSecondaryContainer: const Color(0xFF12344D),
        tertiary: tokens.accent,
        onTertiary: const Color(0xFF052A3D),
        tertiaryContainer: const Color(0xFFE3F3FF),
        onTertiaryContainer: const Color(0xFF092B3E),
        error: const Color(0xFFFF4F68),
        onError: Colors.white,
        surface: tokens.surface,
        onSurface: const Color(0xFF251821),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: const Color(0xFFFFF7FA),
        surfaceContainer: const Color(0xFFFFF3F7),
        surfaceContainerHigh: const Color(0xFFF9EEF3),
        surfaceContainerHighest: const Color(0xFFF3E8EE),
        onSurfaceVariant: const Color(0xFF6B5261),
        outline: const Color(0xFFD9C4CF),
        outlineVariant: tokens.line,
        shadow: tokens.shadow,
        scrim: Colors.black,
      );
    }

    return base.copyWith(
      primary: tokens.brand,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF5A263D),
      onPrimaryContainer: const Color(0xFFFFD8E8),
      secondary: tokens.accent,
      onSecondary: const Color(0xFF102A3C),
      secondaryContainer: const Color(0xFF283D4E),
      onSecondaryContainer: const Color(0xFFE3F3FF),
      tertiary: tokens.accent,
      onTertiary: const Color(0xFF062B40),
      tertiaryContainer: const Color(0xFF283D4E),
      onTertiaryContainer: const Color(0xFFE3F3FF),
      error: const Color(0xFFFF8A9A),
      onError: const Color(0xFF3A0710),
      surface: tokens.surface,
      onSurface: const Color(0xFFF1EEF0),
      surfaceContainerLowest: const Color(0xFF0E0E10),
      surfaceContainerLow: const Color(0xFF171719),
      surfaceContainer: const Color(0xFF1C1C1F),
      surfaceContainerHigh: const Color(0xFF232327),
      surfaceContainerHighest: const Color(0xFF2B2B30),
      onSurfaceVariant: const Color(0xFFC9C3C8),
      outline: const Color(0xFF6B666D),
      outlineVariant: tokens.line,
      shadow: tokens.shadow,
      scrim: Colors.black,
    );
  }

  static ButtonStyle _segmentedButtonStyle(FreepivThemeTokens tokens, ColorScheme colorScheme) {
    return ButtonStyle(
      visualDensity: VisualDensity.compact,
      textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      side: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return BorderSide(color: selected ? tokens.brand.withValues(alpha: 0.72) : tokens.line.withValues(alpha: 0.38), width: selected ? 1.1 : 1);
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return tokens.brand.withValues(alpha: colorScheme.brightness == Brightness.light ? 0.15 : 0.24);
        }

        return tokens.surfaceRaised;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurfaceVariant.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return tokens.brand;
        }

        return colorScheme.onSurfaceVariant;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? tokens.brand : colorScheme.onSurfaceVariant),
      overlayColor: WidgetStatePropertyAll(tokens.brand.withValues(alpha: 0.06)),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
