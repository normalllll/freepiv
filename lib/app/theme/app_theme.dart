import 'package:freepiv/app/theme/app_feedback.dart';
import 'package:freepiv/app/theme/accent_color_math.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/app/theme/app_system_fonts.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/core/services/appearance_settings.dart';
import 'package:freepiv/shared/ui/fp_page_transition.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light({
    required TargetPlatform platform,
    required Locale locale,
    AppearanceTone tone = AppearanceTone.neutral,
    Color accent = FreepivThemeTokens.brandPink,
  }) {
    return _build(tokens: FreepivThemeTokens.palette(Brightness.light, tone, accent), brightness: Brightness.light, platform: platform, locale: locale);
  }

  static ThemeData dark({
    required TargetPlatform platform,
    required Locale locale,
    AppearanceTone tone = AppearanceTone.neutral,
    Color accent = FreepivThemeTokens.brandPink,
  }) {
    return _build(tokens: FreepivThemeTokens.palette(Brightness.dark, tone, accent), brightness: Brightness.dark, platform: platform, locale: locale);
  }

  static ThemeData _build({required FreepivThemeTokens tokens, required Brightness brightness, required TargetPlatform platform, required Locale locale}) {
    final colorScheme = _colorScheme(tokens: tokens, brightness: brightness);
    final systemFonts = AppSystemFonts.resolve(platform: platform, locale: locale);
    final base = ThemeData(
      platform: platform,
      colorScheme: colorScheme,
      // Pages are transparent over the window's ambient backdrop.
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: PageTransitionsTheme(builders: {for (final platform in TargetPlatform.values) platform: const FpPageTransitionsBuilder()}),
      fontFamily: systemFonts.family,
      fontFamilyFallback: systemFonts.fallbacks,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [tokens],
    );

    return _applyTextTheme(base).copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: tokens.pressedSurface,
      hoverColor: tokens.hoverSurface,
      focusColor: tokens.hoverSurface,
      dividerColor: tokens.line,
      dividerTheme: DividerThemeData(color: tokens.line, thickness: 1, space: 1),
      appBarTheme: AppBarThemeData(
        // Headers sit on the ambient backdrop like the title bar above them.
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        // A transparent bar cannot infer icon brightness; use the palette's.
        systemOverlayStyle: appSystemOverlayStyle(tokens),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: tokens.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
      ),
      tabBarTheme: TabBarThemeData(
        overlayColor: WidgetStateProperty.resolveWith((states) => appShowsFocus(states) ? tokens.hoverSurface : appFeedbackSurface(tokens, states)),
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: tokens.keyGraphicOn(tokens.surface),
        // A short rounded bar under the label, in the readable accent tone.
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: tokens.keyGraphicOn(tokens.surface), width: AppMetrics.selectionIndicatorWidth),
          borderRadius: BorderRadius.circular(AppMetrics.selectionIndicatorWidth),
          insets: const EdgeInsets.symmetric(horizontal: 6),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        // Hover and press read as a rounded pill, like the navigation items,
        // rather than a square block that runs into the bar's corners.
        splashBorderRadius: BorderRadius.circular(AppMetrics.controlRadius),
        dividerColor: tokens.line,
        labelStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: base.textTheme.labelLarge,
        splashFactory: NoSplash.splashFactory,
      ),
      switchTheme: SwitchThemeData(
        mouseCursor: appClickCursor,
        overlayColor: WidgetStateProperty.resolveWith((states) => appButtonStateLayer(tokens, states, AppFeedbackRole.quiet)),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? tokens.disabledText
              : states.contains(WidgetState.selected)
              ? _switchThumb(tokens)
              : (tokens.isDark ? tokens.textSecondary : tokens.surfaceRaised),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? tokens.accent.withValues(alpha: states.contains(WidgetState.disabled) ? .38 : 1) : colorScheme.outline,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) => appShowsFocus(states) ? tokens.focus : Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        mouseCursor: appClickCursor,
        overlayColor: WidgetStateProperty.resolveWith((states) => appFeedbackSurface(tokens, states)),
        side: WidgetStateBorderSide.resolveWith(
          (states) => appFeedbackBorder(
            tokens,
            states,
            restingSide: BorderSide(
              color: states.contains(WidgetState.selected) ? tokens.keyGraphicOn(tokens.surface) : colorScheme.onSurfaceVariant,
              width: 2,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.badgeRadius)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.keyGraphicOn(tokens.surface).withValues(alpha: states.contains(WidgetState.disabled) ? .38 : 1)
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(tokens.keyGraphicOn(tokens.surface) == tokens.accent ? tokens.onAccent : tokens.surface),
      ),
      radioTheme: RadioThemeData(
        mouseCursor: appClickCursor,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => appFeedbackSurface(tokens, states, resting: appShowsFocus(states) ? tokens.hoverSurface : Colors.transparent),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colorScheme.outline
              : states.contains(WidgetState.selected)
              ? tokens.selectionInk
              : colorScheme.onSurfaceVariant,
        ),
      ),
      sliderTheme: SliderThemeData(
        mouseCursor: appClickCursor,
        activeTrackColor: tokens.keyGraphicOn(tokens.surface),
        thumbColor: tokens.keyGraphicOn(tokens.surface),
        inactiveTrackColor: tokens.line,
        overlayColor: tokens.hoverSurface,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: tokens.keyGraphicOn(tokens.surface), linearTrackColor: tokens.line),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: colorScheme.inverseSurface, borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
        textStyle: base.textTheme.bodySmall?.copyWith(color: colorScheme.onInverseSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: const Duration(milliseconds: 500),
      ),
      menuButtonTheme: MenuButtonThemeData(
        // The menu surface owns the outer corners; contiguous rows fill it.
        style: appFeedbackStyle(tokens).copyWith(shape: const WidgetStatePropertyAll(RoundedRectangleBorder())),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(tokens.surfaceRaised),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(4),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppMetrics.groupRadius),
              side: BorderSide(color: tokens.line),
            ),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style:
            IconButton.styleFrom(
              overlayColor: Colors.transparent,
              minimumSize: const Size.square(AppMetrics.controlHeight),
              iconSize: AppMetrics.iconSize,
              foregroundColor: colorScheme.onSurfaceVariant,
              disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              shape: const CircleBorder(),
            ).copyWith(
              mouseCursor: appClickCursor,
              backgroundBuilder: appButtonFeedbackBackground,
              backgroundColor: WidgetStateProperty.resolveWith((states) => appButtonRestingSurface(tokens, states, resting: Colors.transparent)),
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              side: appFeedbackStyle(tokens, restingSide: BorderSide.none).side,
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              overlayColor: Colors.transparent,
              foregroundColor: colorScheme.onSurface,
              disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
              textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
            ).copyWith(
              mouseCursor: appClickCursor,
              backgroundBuilder: appButtonFeedbackBackground,
              backgroundColor: WidgetStateProperty.resolveWith((states) => appButtonRestingSurface(tokens, states, resting: Colors.transparent)),
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              side: appFeedbackStyle(tokens, restingSide: BorderSide.none).side,
            ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: tokens.actionFill,
              overlayColor: Colors.transparent,
              foregroundColor: tokens.onAction,
              disabledBackgroundColor: tokens.surfaceInset,
              disabledForegroundColor: tokens.disabledText,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
            ).copyWith(
              mouseCursor: appClickCursor,
              backgroundBuilder: appPrimaryButtonFeedbackBackground,
              backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) ? tokens.surfaceInset : tokens.actionFill),
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              side: appFeedbackStyle(tokens).side,
            ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              overlayColor: Colors.transparent,
              backgroundColor: tokens.surfaceRaised,
              foregroundColor: colorScheme.onSurface,
              disabledBackgroundColor: tokens.surfaceMuted,
              disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.42),
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
            ).copyWith(
              mouseCursor: appClickCursor,
              backgroundBuilder: appSecondaryButtonFeedbackBackground,
              backgroundColor: WidgetStatePropertyAll(tokens.surfaceInset),
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              side: appFeedbackStyle(tokens).side,
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              overlayColor: Colors.transparent,
              foregroundColor: colorScheme.onSurface,
              disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
            ).copyWith(
              mouseCursor: appClickCursor,
              backgroundBuilder: appSecondaryButtonFeedbackBackground,
              backgroundColor: WidgetStatePropertyAll(tokens.surfaceInset),
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              side: appFeedbackStyle(tokens).side,
            ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(style: _segmentedButtonStyle(tokens, colorScheme, base.textTheme.labelLarge)),
      chipTheme: ChipThemeData(
        // Selected chips use the accent wash, a check and accent ink; resting
        // chips stay neutral and never carry a coloured outline.
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Color.alphaBlend(appButtonStateLayer(tokens, states, AppFeedbackRole.quiet), tokens.selectionSurface)
              : appFeedbackSurface(tokens, states, resting: states.contains(WidgetState.disabled) ? tokens.surfaceMuted : tokens.surfaceInset),
        ),
        backgroundColor: tokens.surfaceInset,
        selectedColor: tokens.selectionSurface,
        disabledColor: tokens.surfaceMuted,
        checkmarkColor: tokens.selectionInk,
        labelStyle: base.textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
        secondaryLabelStyle: base.textTheme.labelLarge?.copyWith(color: tokens.selectionInk, fontWeight: FontWeight.w600),
        side: WidgetStateBorderSide.resolveWith((states) => appFeedbackBorder(tokens, states)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        showCheckmark: true,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: tokens.surfaceInset,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: _inputBorder(tokens.line),
        enabledBorder: _inputBorder(tokens.line),
        focusedBorder: _inputBorder(tokens.fieldFocus, width: AppMetrics.fieldFocusWidth),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: AppMetrics.fieldFocusWidth),
        hintStyle: base.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        menuPadding: EdgeInsets.zero,
        color: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.modalRadius)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppMetrics.modalRadius))),
      ),
      listTileTheme: ListTileThemeData(
        mouseCursor: appClickCursor,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }

  static ThemeData _applyTextTheme(ThemeData theme) {
    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        displayLarge: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w600),
        displayMedium: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600),
        displaySmall: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w600),
        headlineLarge: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
        headlineMedium: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        headlineSmall: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        titleLarge: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
        bodyMedium: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
        bodySmall: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400),
        labelLarge: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        labelMedium: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        labelSmall: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  static ColorScheme _colorScheme({required FreepivThemeTokens tokens, required Brightness brightness}) {
    final base = ColorScheme.fromSeed(seedColor: tokens.accent, brightness: brightness);
    return base.copyWith(
      primary: tokens.brand,
      onPrimary: tokens.onAccent,
      primaryContainer: tokens.selectionSurface,
      onPrimaryContainer: tokens.selectionInk,
      secondary: tokens.accent,
      onSecondary: tokens.onAccent,
      secondaryContainer: tokens.selectionSurface,
      onSecondaryContainer: tokens.selectionInk,
      tertiary: tokens.accent,
      onTertiary: tokens.onAccent,
      tertiaryContainer: tokens.selectionSurface,
      onTertiaryContainer: tokens.selectionInk,
      error: tokens.textPrimary,
      onError: tokens.surface,
      errorContainer: tokens.surfaceMuted,
      onErrorContainer: tokens.textPrimary,
      surface: tokens.surface,
      surfaceTint: tokens.surfaceTint,
      onSurface: tokens.textPrimary,
      surfaceContainerLowest: tokens.canvas,
      surfaceContainerLow: tokens.surface,
      surfaceContainer: tokens.surfaceInset,
      surfaceContainerHigh: tokens.surfaceRaised,
      surfaceContainerHighest: tokens.surfaceMuted,
      onSurfaceVariant: tokens.textSecondary,
      inverseSurface: tokens.isDark ? FreepivThemeTokens.lightNeutral.surface : FreepivThemeTokens.darkNeutral.surface,
      onInverseSurface: tokens.isDark ? FreepivThemeTokens.lightNeutral.textPrimary : FreepivThemeTokens.darkNeutral.textPrimary,
      outline: tokens.line,
      outlineVariant: tokens.line,
      shadow: tokens.shadow,
      scrim: Colors.black.withValues(alpha: tokens.isDark ? .48 : .24),
    );
  }

  static Color _switchThumb(FreepivThemeTokens tokens) {
    final lightThumb = tokens.isDark ? tokens.textPrimary : tokens.surfaceRaised;
    // Keep the familiar light thumb on the default pink track. On an almost
    // white custom track, a dark thumb is needed to retain a visible handle.
    return colorContrast(tokens.accent, lightThumb) >= 2.3 ? lightThumb : tokens.onAccent;
  }

  static ButtonStyle _segmentedButtonStyle(FreepivThemeTokens tokens, ColorScheme colorScheme, TextStyle? labelStyle) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, AppMetrics.controlHeight)),
      textStyle: WidgetStatePropertyAll(labelStyle?.copyWith(fontWeight: FontWeight.w600)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.controlRadius))),
      side: WidgetStateProperty.resolveWith((states) {
        return appFeedbackBorder(tokens, states);
      }),
      mouseCursor: appClickCursor,
      backgroundBuilder: appButtonFeedbackBackground,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return tokens.isDark ? tokens.surfaceMuted : tokens.surfaceRaised;
        }

        return tokens.isDark ? tokens.surfaceRaised : tokens.surfaceInset;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurfaceVariant.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return tokens.selectionInk;
        }

        return colorScheme.onSurfaceVariant;
      }),
      iconColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) && !states.contains(WidgetState.disabled)
            ? tokens.keyGraphicOn(tokens.surfaceRaised)
            : colorScheme.onSurfaceVariant,
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppMetrics.controlRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Status and navigation bar styling over the transparent ambient backdrop.
SystemUiOverlayStyle appSystemOverlayStyle(FreepivThemeTokens tokens) => (tokens.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
  statusBarColor: Colors.transparent,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarContrastEnforced: false,
);
