import 'package:flutter/material.dart';

class ConstrainedSegmentedButton<T> extends StatelessWidget {
  const ConstrainedSegmentedButton({
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.maxWidth = 420,
    this.alignment = AlignmentDirectional.centerStart,
    this.style,
    super.key,
  });

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;
  final double? maxWidth;
  final AlignmentGeometry alignment;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(segments: segments, selected: selected, onSelectionChanged: onSelectionChanged, style: style),
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
