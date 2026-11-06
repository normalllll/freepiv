import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FullScreenLoadingSkeleton extends StatelessWidget {
  const FullScreenLoadingSkeleton({this.padding = const EdgeInsets.all(12), this.itemPadding = const EdgeInsets.all(8), super.key});

  final EdgeInsets padding;
  final EdgeInsets itemPadding;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;

    final useGrid = width >= 560;

    final columns = math.max(1, (width - padding.horizontal) ~/ 220);
    final itemCount = useGrid ? ((height / 257).ceil() + 1) * columns : (height / 156).ceil() + 1;

    return Skeletonizer.zone(
      effect: frostSkeletonEffect(context),
      child: Padding(
        padding: padding,
        child: useGrid
            ? _SkeletonGrid(itemCount: itemCount, maxWidth: width - padding.horizontal, itemPadding: itemPadding)
            : _SkeletonList(itemCount: itemCount, itemPadding: itemPadding),
      ),
    );
  }
}

/// Mirrors PixivCommentTile's geometry (avatar slot, row padding, name and
/// date row, body lines, actions) and the 1px separators between comments,
/// so the loaded list replaces the skeleton without a jump.
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid({required this.itemCount, required this.maxWidth, required this.itemPadding});

  final int itemCount;
  final double maxWidth;
  final EdgeInsets itemPadding;

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;

    final availableWidth = math.max(160.0, maxWidth);
    final columnCount = math.max(1, availableWidth ~/ 220);
    final itemWidth = (availableWidth - spacing * (columnCount - 1)) / columnCount;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (var index = 0; index < itemCount; index++)
          SizedBox(
            width: itemWidth,
            height: 245,
            child: _WorkCardSkeleton(itemPadding: itemPadding),
          ),
      ],
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList({required this.itemCount, required this.itemPadding});

  final int itemCount;
  final EdgeInsets itemPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < itemCount; index++) ...[
          SizedBox(height: 144, child: _WorkCardSkeleton(itemPadding: itemPadding)),
          if (index != itemCount - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _WorkCardSkeleton extends StatelessWidget {
  const _WorkCardSkeleton({this.itemPadding = const EdgeInsets.all(8)});

  final EdgeInsets itemPadding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(FrostRadius.lg)),
      child: Padding(
        padding: itemPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Bone(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(FrostRadius.lg)),
            ),
            const SizedBox(height: 10),
            const Bone.text(width: double.infinity),
            const SizedBox(height: 7),
            const Bone.text(width: 120),
          ],
        ),
      ),
    );
  }
}
