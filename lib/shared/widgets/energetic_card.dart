import 'package:freepiv/shared/widgets/app_click_surface.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';

class EnergeticCard extends StatelessWidget {
  const EnergeticCard({
    required this.child,
    this.onTap,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.accentColor,
    this.borderRadius = AppMetrics.controlRadius,
    this.feedback = AppClickFeedback.surface,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final Color? accentColor;
  final double borderRadius;
  final AppClickFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    Widget content = child;
    final padding = this.padding;
    if (padding != null) {
      content = Padding(padding: padding, child: content);
    }

    final onTap = this.onTap;
    content = Material(
      type: MaterialType.transparency,
      child: onTap == null ? content : AppClickSurface(feedback: feedback, borderRadius: radius, onTap: onTap, child: content),
    );

    return Padding(
      padding: margin,
      child: FpSurface(role: FpSurfaceRole.panel, borderRadius: radius, child: content),
    );
  }
}

class EnergeticPill extends StatelessWidget {
  const EnergeticPill({
    required this.child,
    this.icon,
    this.selected = false,
    this.accentColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    super.key,
  });

  final Widget child;
  final IconData? icon;
  final bool selected;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? tokens.selectionInk : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? tokens.selectionSurface : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppMetrics.controlRadius),
        border: Border.all(color: tokens.line.withValues(alpha: .35)),
      ),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: foreground), const SizedBox(width: 4)],
            Flexible(
              fit: FlexFit.loose,
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
