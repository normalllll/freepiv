import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/accent_color_math.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/theme/app_metrics.dart';

enum AppFeedbackRole { primary, secondary, quiet }

/// Mouse feedback and keyboard focus are independent of the page layout.
bool appShowsFocus(Set<WidgetState> states) => states.contains(WidgetState.focused) && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

final appClickCursor = WidgetStateProperty.resolveWith<MouseCursor>(
  (states) => states.contains(WidgetState.disabled) ? SystemMouseCursors.basic : SystemMouseCursors.click,
);

Color appFeedbackSurface(FreepivThemeTokens tokens, Set<WidgetState> states, {Color resting = Colors.transparent}) {
  // Transparent black interpolates through dark RGB values before compositing.
  // Preserve the surface's RGB at zero alpha so entry/exit only changes opacity.
  final idle = resting.a == 0 ? tokens.hoverSurface.withValues(alpha: 0) : resting;
  if (states.contains(WidgetState.disabled)) return idle;
  if (states.contains(WidgetState.pressed)) return tokens.pressedSurface;
  if (states.contains(WidgetState.hovered)) return tokens.hoverSurface;
  return idle;
}

/// Material does not animate its background color. Keep its base stable and
/// animate a separate, clipped layer beneath button content instead.
Color appButtonRestingSurface(FreepivThemeTokens tokens, Set<WidgetState> states, {Color resting = Colors.transparent}) => resting;

Color appButtonStateLayer(FreepivThemeTokens tokens, Set<WidgetState> states, AppFeedbackRole role) {
  final disabled = states.contains(WidgetState.disabled);
  final pressed = states.contains(WidgetState.pressed);
  final hovered = states.contains(WidgetState.hovered);
  return switch (role) {
    // A dark wash under a white label, a light one under a dark label
    // (dropped for the rare accent where it would lower that below 4.5:1).
    AppFeedbackRole.primary => solidWashColor(tokens.actionFill).withValues(
      alpha: disabled
          ? 0
          : solidOverlayAlpha(
              tokens.actionFill,
              pressed
                  ? .04
                  : hovered
                  ? .08
                  : 0,
            ),
    ),
    AppFeedbackRole.secondary => (pressed ? tokens.pressedSurface : tokens.hoverSurface).withValues(alpha: disabled || (!pressed && !hovered) ? 0 : 1),
    AppFeedbackRole.quiet => (tokens.isDark ? Colors.white : Colors.black).withValues(
      alpha: disabled
          ? 0
          : pressed
          ? (tokens.isDark ? .10 : .07)
          : hovered
          ? (tokens.isDark ? .06 : .04)
          : 0,
    ),
  };
}

Widget appButtonFeedbackBackground(BuildContext context, Set<WidgetState> states, Widget? child) =>
    _appButtonFeedbackBackground(context, states, child, AppFeedbackRole.quiet);

Widget appPrimaryButtonFeedbackBackground(BuildContext context, Set<WidgetState> states, Widget? child) =>
    _appButtonFeedbackBackground(context, states, child, AppFeedbackRole.primary);

Widget appSecondaryButtonFeedbackBackground(BuildContext context, Set<WidgetState> states, Widget? child) =>
    _appButtonFeedbackBackground(context, states, child, AppFeedbackRole.secondary);

Widget _appButtonFeedbackBackground(BuildContext context, Set<WidgetState> states, Widget? child, AppFeedbackRole role) {
  return Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: Builder(
            builder: (context) {
              // This context is inside the button's resolved Material, so
              // local shapes (including segmented edges and caption buttons)
              // take precedence over the global theme.
              final material = context.findAncestorWidgetOfExactType<Material>();
              final shape = material?.shape ?? RoundedRectangleBorder(borderRadius: material?.borderRadius ?? BorderRadius.zero);
              return ClipPath(
                clipper: ShapeBorderClipper(shape: shape),
                child: AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.hover),
                  curve: AppMotion.hoverCurve,
                  color: appButtonStateLayer(FreepivThemeTokens.of(context), states, role),
                ),
              );
            },
          ),
        ),
      ),
      child ?? const SizedBox.shrink(),
    ],
  );
}

ButtonStyle appFeedbackStyle(FreepivThemeTokens tokens, {BorderSide restingSide = BorderSide.none}) => ButtonStyle(
  mouseCursor: appClickCursor,
  backgroundBuilder: appButtonFeedbackBackground,
  splashFactory: NoSplash.splashFactory,
  overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  backgroundColor: WidgetStateProperty.resolveWith((states) => appButtonRestingSurface(tokens, states)),
  side: WidgetStateProperty.resolveWith((states) => appFeedbackBorder(tokens, states, restingSide: restingSide)),
);

ButtonStyle appSecondaryButtonStyle(FreepivThemeTokens tokens) => ButtonStyle(
  mouseCursor: appClickCursor,
  backgroundBuilder: appSecondaryButtonFeedbackBackground,
  backgroundColor: WidgetStatePropertyAll(tokens.surfaceInset),
  overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  side: WidgetStateProperty.resolveWith((states) => appFeedbackBorder(tokens, states)),
);

BorderSide appFeedbackBorder(FreepivThemeTokens tokens, Set<WidgetState> states, {BorderSide restingSide = BorderSide.none}) {
  if (states.contains(WidgetState.disabled)) return restingSide;
  if (appShowsFocus(states)) return BorderSide(color: tokens.focus, width: AppMetrics.focusBorderWidth);
  return restingSide;
}
