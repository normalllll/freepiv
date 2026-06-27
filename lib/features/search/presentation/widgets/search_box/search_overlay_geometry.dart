import 'dart:math' as math;

import 'package:flutter/material.dart';

({Offset offset, double maxHeight}) suggestionOverlayGeometry(BuildContext context, RenderBox? renderBox) {
  final media = MediaQuery.of(context);
  final size = renderBox?.size ?? const Size(0, 44);
  final origin = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  final viewportBottom = media.size.height - media.viewInsets.bottom;
  final below = viewportBottom - origin.dy - size.height - 12;
  final above = origin.dy - media.padding.top - 12;
  final preferredCap = media.size.width < 600 ? 320.0 : 420.0;

  if (below >= 120 || below >= above) {
    return (offset: const Offset(0, 8), maxHeight: math.max(0.0, math.min(preferredCap, below)));
  }

  final maxHeight = math.max(0.0, math.min(preferredCap, above));
  return (offset: Offset(0, -maxHeight - 8), maxHeight: maxHeight);
}
