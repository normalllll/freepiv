import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'form_controls.dart';

double compactFilterHeight(BuildContext context) => math.max(48, appFieldHeight(context)) + 14;

class FloatingFilterSliver extends StatelessWidget {
  const FloatingFilterSliver({required this.height, required this.child, super.key});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SliverPersistentHeader(
    floating: true,
    delegate: _FilterDelegate(height: height, child: child),
  );
}

class _FilterDelegate extends SliverPersistentHeaderDelegate {
  const _FilterDelegate({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  // No snap animation: wheel events finish before layout and must not replay
  // the header's previous offset when the next frame arrives.
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_FilterDelegate oldDelegate) => height != oldDelegate.height || child != oldDelegate.child;
}
