import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/shared/layout/fp_pinned_chrome.dart';
import 'form_controls.dart';

double compactFilterHeight(BuildContext context) => math.max(48, appFieldHeight(context)) + 14;

class FloatingFilterSliver extends StatelessWidget {
  const FloatingFilterSliver({required this.height, required this.child, super.key});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) => SliverPersistentHeader(
      floating: true,
      delegate: _FilterDelegate(height: height, scrollOffset: constraints.scrollOffset, child: child),
    ),
  );
}

class _FilterDelegate extends SliverPersistentHeaderDelegate {
  const _FilterDelegate({required this.height, required this.scrollOffset, required this.child});
  final double height;
  final double scrollOffset;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  // No snap animation: wheel events finish before layout and must not replay
  // the header's previous offset when the next frame arrives.
  @override
  // Glass only while content is actually beneath the floating filters.
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Floating headers use an effective offset: on reverse scroll it differs
    // from the actual local sliver offset. Only the visible, overlapping part
    // reveals glass, so re-entering filters start at zero even far down a list.
    final overlap = math.min(scrollOffset - shrinkOffset, height - shrinkOffset);
    final coverage = overlapsContent ? (overlap / 24).clamp(0.0, 1.0) : 0.0;
    return SizedBox.expand(
      child: PinnedChromeGlass(opacity: coverage, animate: false, child: child),
    );
  }

  @override
  bool shouldRebuild(_FilterDelegate oldDelegate) => height != oldDelegate.height || scrollOffset != oldDelegate.scrollOffset || child != oldDelegate.child;
}
