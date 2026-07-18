import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';

class EnergeticCard extends StatelessWidget {
  const EnergeticCard({
    required this.child,
    this.onTap,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.accentColor,
    this.borderRadius = 8,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final Color? accentColor;
  final double borderRadius;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final radius = BorderRadius.circular(borderRadius);
    final accent = accentColor ?? tokens.brand;

    Widget content = child;
    final padding = this.padding;
    if (padding != null) {
      content = Padding(padding: padding, child: content);
    }

    final onTap = this.onTap;
    content = Material(
      type: MaterialType.transparency,
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: radius,
              onTap: onTap,
              splashColor: accent.withValues(alpha: 0.06),
              highlightColor: accent.withValues(alpha: 0.035),
              child: content,
            ),
    );

    content = ClipRRect(borderRadius: radius, clipBehavior: clipBehavior, child: content);

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              Color.alphaBlend(accent.withValues(alpha: 0.018), tokens.surfaceRaised),
              Color.alphaBlend(tokens.surfaceTint.withValues(alpha: 0.20), tokens.surfaceRaised),
              tokens.surfaceRaised,
            ],
            stops: const [0, 0.62, 1],
          ),
          borderRadius: radius,
          boxShadow: [BoxShadow(color: tokens.shadow, blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: content,
      ),
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
    final accent = accentColor ?? tokens.brand;
    final foreground = selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? accent : Color.alphaBlend(accent.withValues(alpha: 0.08), tokens.surfaceRaised),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? accent : Color.alphaBlend(accent.withValues(alpha: 0.18), tokens.line)),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w700),
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
