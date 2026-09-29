import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/shared/ui/spring_builder.dart';
import 'package:freepiv/shared/widgets/app_click_surface.dart';

/// Mutually exclusive mode switch: an inset track with one raised pill that
/// slides to the selected segment. Selection is carried by the pill, the
/// accent ink and the heavier weight, so it never depends on colour alone.
class AppSegmentedButton<T> extends StatelessWidget {
  const AppSegmentedButton({required this.segments, required this.selected, required this.onSelectionChanged, this.showSelectedIcon = false, super.key});
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Adds a check to the selected segment when the segments carry no icons.
  final bool showSelectedIcon;

  static const _trackPadding = 3.0;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final selectedIndex = math.max(0, segments.indexWhere((segment) => selected.contains(segment.value)));
    final height = AppMetrics.fieldHeight(context);
    final count = segments.length;
    final radius = BorderRadius.circular(AppMetrics.controlRadius);
    final innerRadius = BorderRadius.circular(AppMetrics.controlRadius - _trackPadding);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: tokens.surfaceInset, borderRadius: radius),
        child: Padding(
          padding: const EdgeInsets.all(_trackPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height - _trackPadding * 2),
            // Equal flex inside IntrinsicWidth sizes every segment to the
            // widest label; a tight parent width still stretches the track.
            // When the width is too small (large text, narrow phones) labels
            // wrap to a second line and IntrinsicHeight grows the track.
            child: IntrinsicWidth(
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    Positioned.fill(
                      // The pill slides on a spring: a quick second tap
                      // redirects it from where it is, at its speed.
                      child: SpringBuilder(
                        value: selectedIndex.toDouble(),
                        spring: AppMotion.snappy,
                        builder: (context, position, child) => Align(alignment: Alignment(count == 1 ? 0 : -1 + 2 * position / (count - 1), 0), child: child),
                        child: FractionallySizedBox(
                          widthFactor: 1 / count,
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: tokens.isDark ? tokens.surfaceMuted : tokens.surfaceRaised,
                              borderRadius: innerRadius,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: tokens.isDark ? .24 : .08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (index, segment) in segments.indexed)
                          Expanded(
                            child: _Segment(
                              segment: segment,
                              selected: index == selectedIndex,
                              showSelectedIcon: showSelectedIcon,
                              borderRadius: innerRadius,
                              onTap: segment.enabled && onSelectionChanged != null && index != selectedIndex
                                  ? () => onSelectionChanged!({segment.value})
                                  : null,
                              interactive: segment.enabled && onSelectionChanged != null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.showSelectedIcon,
    required this.borderRadius,
    required this.onTap,
    required this.interactive,
  });

  final ButtonSegment<T> segment;
  final bool selected;
  final bool showSelectedIcon;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final theme = Theme.of(context);
    final foreground = !interactive
        ? tokens.disabledText
        : selected
        ? tokens.selectionInk
        : tokens.textSecondary;
    final icon = segment.icon ?? (showSelectedIcon && selected ? const Icon(Icons.check_rounded) : null);
    final content = IconTheme.merge(
      data: IconThemeData(size: 18, color: foreground),
      child: DefaultTextStyle.merge(
        style: theme.textTheme.labelLarge?.copyWith(color: foreground, fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
        // Two lines before an ellipsis, so large text never hides a label.
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ?icon,
              if (icon != null && segment.label != null) const SizedBox(width: 6),
              if (segment.label case final label?) Flexible(child: label),
            ],
          ),
        ),
      ),
    );
    Widget result = Semantics(
      button: true,
      selected: selected,
      enabled: interactive,
      inMutuallyExclusiveGroup: true,
      child: AppClickSurface(
        // The selected segment keeps focus traversal but has nothing to do.
        onTap: onTap ?? (interactive ? () {} : null),
        feedback: selected ? AppClickFeedback.artwork : AppClickFeedback.quiet,
        borderRadius: borderRadius,
        child: Center(child: content),
      ),
    );
    if (segment.tooltip case final tooltip?) result = Tooltip(message: tooltip, child: result);
    return result;
  }
}

class ConstrainedSegmentedButton<T> extends StatelessWidget {
  const ConstrainedSegmentedButton({
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.maxWidth = 420,
    this.alignment = AlignmentDirectional.centerStart,
    super.key,
  });

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;
  final double? maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: double.infinity,
      child: AppSegmentedButton<T>(segments: segments, selected: selected, onSelectionChanged: onSelectionChanged),
    );
    final constrainedButton = maxWidth == null
        ? button
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: button,
          );

    return Align(alignment: alignment, child: constrainedButton);
  }
}
