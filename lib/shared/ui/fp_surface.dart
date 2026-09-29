import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/theme/transparency_logic.dart';

enum FpSurfaceRole { chrome, panel, glassPanel, overlay, reading }

enum FpSurfaceEdge { material, none }

/// The side where a surface continues straight into a neighbouring one, the
/// two reading as one panel (a pinned header above its tab bar). That side
/// has square corners, no edge line and casts no shadow onto the other.
enum FpSurfaceJoin { none, above, below }

/// A bounded material layer. Blur is confined to this surface, never to an
/// entire scrolling list or an opaque page background.
class FpSurface extends ConsumerWidget {
  const FpSurface({
    required this.role,
    required this.child,
    this.borderRadius,
    this.edge = FpSurfaceEdge.material,
    this.elevated = true,
    this.join = FpSurfaceJoin.none,
    super.key,
  });

  final FpSurfaceRole role;
  final Widget child;
  final BorderRadiusGeometry? borderRadius;
  final FpSurfaceEdge edge;

  /// Chrome stacked directly above another chrome layer omits its shadow so
  /// the two read as one bar.
  final bool elevated;
  final FpSurfaceJoin join;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = FreepivThemeTokens.of(context);
    final highContrast = MediaQuery.highContrastOf(context);
    final solid = ref.watch(reduceTransparencyProvider) || highContrast;
    final radius = borderRadius ?? BorderRadius.circular(role == FpSurfaceRole.overlay ? AppMetrics.modalRadius : AppMetrics.groupRadius);
    final color = switch (role) {
      FpSurfaceRole.glassPanel || FpSurfaceRole.overlay => tokens.surfaceRaised,
      _ => tokens.surface,
    };
    final alpha = switch (role) {
      FpSurfaceRole.chrome => tokens.isDark ? .82 : .76,
      FpSurfaceRole.panel => tokens.isDark ? .96 : .94,
      FpSurfaceRole.glassPanel => tokens.isDark ? .78 : .80,
      FpSurfaceRole.overlay => tokens.isDark ? .92 : .88,
      FpSurfaceRole.reading => 1.0,
    };
    final sigma = solid
        ? 0.0
        : switch (role) {
            FpSurfaceRole.chrome => 18.0,
            FpSurfaceRole.glassPanel => 14.0,
            FpSurfaceRole.overlay => 24.0,
            _ => 0.0,
          };
    // A light glass panel over a pale canvas is almost the same colour, so it
    // keeps one neutral separating line. That line is functional, not the
    // decorative edge that [FpSurfaceEdge.none] removes from interactive groups.
    final separatesFromCanvas = role == FpSurfaceRole.glassPanel && !tokens.isDark && !solid;
    // With reduced transparency the opaque fill already sets a panel apart,
    // so its edge is a soft 1px line, not a full-strength one; only high
    // contrast keeps a strong 1.5px outline.
    final borderColor = highContrast
        ? tokens.textSecondary
        : separatesFromCanvas
        ? tokens.line.withValues(alpha: .7)
        : edge == FpSurfaceEdge.none
        ? null
        : switch (role) {
            FpSurfaceRole.chrome || FpSurfaceRole.glassPanel => solid ? tokens.panelEdge : null,
            FpSurfaceRole.overlay => solid ? tokens.line : tokens.line.withValues(alpha: .70),
            FpSurfaceRole.panel || FpSurfaceRole.reading => null,
          };
    // The upper piece of a joined panel would shade the lower one.
    final shadow = !elevated || join == FpSurfaceJoin.below
        ? const <BoxShadow>[]
        : switch (role) {
            FpSurfaceRole.chrome => [
              BoxShadow(
                color: Colors.black.withValues(alpha: tokens.isDark ? .18 : .06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            FpSurfaceRole.glassPanel => [
              BoxShadow(
                color: Colors.black.withValues(alpha: tokens.isDark ? .20 : .07),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
            FpSurfaceRole.overlay => [
              BoxShadow(
                color: Colors.black.withValues(alpha: tokens.isDark ? .36 : .14),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
            _ => const <BoxShadow>[],
          };
    final innerHighlightAlpha = switch ((tokens.isDark, role)) {
      // A hint of a lit edge on dark glass, not an outline.
      (true, _) => .07,
      (false, FpSurfaceRole.chrome) => .65,
      _ => .48,
    };

    final highlight = (role == FpSurfaceRole.chrome || role == FpSurfaceRole.glassPanel) && edge == FpSurfaceEdge.material && !solid && !separatesFromCanvas;
    final borderWidth = highContrast ? 1.5 : 1.0;
    final highlightColor = Colors.white.withValues(alpha: innerHighlightAlpha);
    final inner = Material(type: MaterialType.transparency, child: child);
    final fill = color.withValues(alpha: solid ? 1 : alpha);
    // A joined surface leaves its edge lines open on the joined side, which
    // a box border cannot do; other surfaces use plain borders.
    final Widget content = join == FpSurfaceJoin.none
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: borderColor == null ? null : Border.all(color: borderColor, width: borderWidth),
            ),
            child: highlight
                ? DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: highlightColor),
                    ),
                    child: inner,
                  )
                : inner,
          )
        : DecoratedBox(
            decoration: BoxDecoration(color: fill, borderRadius: radius),
            child: CustomPaint(
              foregroundPainter: _JoinedEdgePainter(
                radius: radius.resolve(Directionality.of(context)),
                join: join,
                strokes: [if (borderColor != null) (color: borderColor, width: borderWidth), if (highlight) (color: highlightColor, width: 1.0)],
              ),
              child: inner,
            ),
          );
    Widget layered = content;
    if (role == FpSurfaceRole.chrome || role == FpSurfaceRole.glassPanel || role == FpSurfaceRole.overlay) {
      layered = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        enabled: sigma > 0,
        child: content,
      );
    }
    Widget shaded = DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
      child: ClipRRect(borderRadius: radius, child: layered),
    );
    if (join == FpSurfaceJoin.above && shadow.isNotEmpty) {
      // Keep the lower piece's shadow off the piece it continues from.
      shaded = ClipRect(clipper: const _BelowTopEdge(), child: shaded);
    }
    return shaded;
  }
}

/// A joined surface's edge lines, drawn just inside its outline and left
/// open on the joined side, so two pieces meet without a line between them.
class _JoinedEdgePainter extends CustomPainter {
  const _JoinedEdgePainter({required this.radius, required this.strokes, required this.join});

  final BorderRadius radius;
  final List<({Color color, double width})> strokes;
  final FpSurfaceJoin join;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final inset = stroke.width / 2;
      final outline = radius.toRRect(Offset.zero & size).deflate(inset);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width
        ..color = stroke.color;
      canvas.drawPath(_openPath(outline), paint);
    }
  }

  Path _openPath(RRect outline) {
    // Joined sides have square corners, so the open side is a straight edge
    // between the two side lines.
    final (from, to) = join == FpSurfaceJoin.below ? (outline.bottom, outline.top) : (outline.top, outline.bottom);
    final corner = join == FpSurfaceJoin.below ? outline.tlRadiusY : outline.blRadiusY;
    final towards = to > from ? 1.0 : -1.0;
    return Path()
      ..moveTo(outline.left, from)
      ..lineTo(outline.left, to - towards * corner)
      ..arcToPoint(Offset(outline.left + corner, to), radius: Radius.circular(corner), clockwise: towards < 0)
      ..lineTo(outline.right - corner, to)
      ..arcToPoint(Offset(outline.right, to - towards * corner), radius: Radius.circular(corner), clockwise: towards < 0)
      ..lineTo(outline.right, from);
  }

  @override
  bool shouldRepaint(_JoinedEdgePainter oldDelegate) => radius != oldDelegate.radius || strokes != oldDelegate.strokes || join != oldDelegate.join;
}

class _BelowTopEdge extends CustomClipper<Rect> {
  const _BelowTopEdge();

  // Generous room for the shadow's blur on the other three sides.
  static const _shadowRoom = 64.0;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(-_shadowRoom, 0, size.width + _shadowRoom, size.height + _shadowRoom);

  @override
  bool shouldReclip(_BelowTopEdge oldClipper) => false;
}
