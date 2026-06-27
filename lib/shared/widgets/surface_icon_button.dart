import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';

class SurfaceIconButton extends StatelessWidget {
  const SurfaceIconButton({required this.icon, required this.tooltip, required this.onPressed, this.iconSize, super.key});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = FreepivThemeTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: tokens.shadow, blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: IconButton(tooltip: tooltip, onPressed: onPressed, iconSize: iconSize, color: colorScheme.onSurfaceVariant, icon: Icon(icon)),
    );
  }
}
