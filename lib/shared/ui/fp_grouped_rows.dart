import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';

/// Contiguous rows share one surface and only its outer corners are rounded.
class FpGroupedRows extends StatelessWidget {
  const FpGroupedRows({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FpSurface(
      role: FpSurfaceRole.glassPanel,
      edge: FpSurfaceEdge.none,
      borderRadius: BorderRadius.circular(AppMetrics.groupRadius),
      child: ListTileTheme.merge(
        shape: const RoundedRectangleBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < children.length; index++)
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(AppMetrics.groupRadius) : Radius.zero,
                  bottom: index == children.length - 1 ? const Radius.circular(AppMetrics.groupRadius) : Radius.zero,
                ),
                child: children[index],
              ),
          ],
        ),
      ),
    );
  }
}
