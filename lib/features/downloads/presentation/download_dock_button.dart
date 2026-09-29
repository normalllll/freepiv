import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/shared/ui/rolling_text.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/app_click_surface.dart';

/// The count is about work needing attention, never retained history.
int downloadBadgeCount(DownloadSummary summary) {
  final failures = summary.failed + summary.saveFailed;
  return failures > 0 ? failures : summary.queued + summary.running + summary.savePending;
}

String downloadBadgeText(int count) => count > 999 ? '999+' : '$count';

({Size footprint, double badgeHeight}) downloadDockButtonGeometry(BuildContext context, {double size = 52}) {
  final badgeStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700);
  final painter = TextPainter(
    text: TextSpan(text: '999+', style: badgeStyle),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final maxBadgeWidth = math.max(20.0, painter.width + 12);
  final badgeHeight = math.max(20.0, painter.height + 4);
  painter.dispose();
  return (footprint: Size(math.max(size + 8, size / 2 + maxBadgeWidth), size + math.max(8.0, badgeHeight / 2)), badgeHeight: badgeHeight);
}

class DownloadDockButton extends StatelessWidget {
  const DownloadDockButton({
    required this.summary,
    required this.onPressed,
    this.onDragDelta,
    this.focusNode,
    this.expanded = false,
    this.size = 52,
    super.key,
  });

  final DownloadSummary summary;
  final VoidCallback onPressed;
  final ValueChanged<Offset>? onDragDelta;
  final FocusNode? focusNode;
  final bool expanded;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = FreepivThemeTokens.of(context);
    final failures = summary.failed + summary.saveFailed;
    final active = summary.queued + summary.running + summary.savePending;
    final count = downloadBadgeCount(summary);
    final label = failures > 0 ? context.t.settings.downloads.badgeFailures(count: failures) : context.t.settings.downloads.badgeActive(count: active);
    final badgeStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.w700);
    // Reserve the widest count at the current text scale so 9 -> 10 -> 999+
    // never moves the button or its neighboring controls.
    final geometry = downloadDockButtonGeometry(context, size: size);
    final footprint = geometry.footprint;
    final badgeHeight = geometry.badgeHeight;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.groupRadius));

    Widget button = SizedBox(
      width: footprint.width,
      height: footprint.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            width: size,
            height: size,
            // Open state uses the shared selection wash; the glyph never
            // rotates, since an upside-down download arrow reads as upload.
            child: Material(
              color: expanded ? tokens.selectionSurface : tokens.surfaceRaised,
              shape: shape,
              elevation: 2,
              shadowColor: tokens.shadow,
              child: AppClickSurface(
                focusNode: focusNode,
                customBorder: shape,
                onTap: onPressed,
                child: Center(child: Icon(Icons.downloading_outlined, color: expanded ? tokens.selectionInk : colors.onSurfaceVariant)),
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: onPressed,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(999)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 20, minHeight: badgeHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        // The count rolls as tasks start and finish.
                        child: Center(child: RollingText(downloadBadgeText(count), style: badgeStyle)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (onDragDelta case final drag?) {
      button = GestureDetector(behavior: HitTestBehavior.translucent, onPanUpdate: (details) => drag(details.delta), child: button);
    }
    return Tooltip(
      excludeFromSemantics: true,
      message: count > 0 ? '${context.t.settings.downloads.tasksTitle} · $label' : context.t.settings.downloads.tasksTitle,
      child: Semantics(
        container: true,
        label: count > 0 ? '${context.t.settings.downloads.tasksTitle} · $label' : context.t.settings.downloads.tasksTitle,
        button: true,
        onTap: onPressed,
        child: ExcludeSemantics(child: button),
      ),
    );
  }
}
