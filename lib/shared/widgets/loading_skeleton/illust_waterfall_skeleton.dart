import 'package:flutter/material.dart';
import 'package:freepiv/shared/widgets/waterfall_grid.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _ratios = <double>[1.32, 0.78, 1.08, 1.58, 0.92, 1.22, 1.44, 0.86, 1.16, 0.88, 1.42, 1.02, 1.26, 0.96, 1.52, 1.12, 0.82, 1.36, 1.06, 1.46];

class IllustWaterfallSkeleton extends StatelessWidget {
  const IllustWaterfallSkeleton({super.key, required this.physics, this.sliverHeader});

  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: WaterfallGrid<double>(
        items: _ratios,
        physics: physics,
        sliverHeader: sliverHeader,
        itemBuilder: (context, ratio, index) {
          return _IllustWaterfallSkeletonCard(aspectRatio: ratio);
        },
      ),
    );
  }
}

class SliverIllustWaterfallSkeleton extends StatelessWidget {
  const SliverIllustWaterfallSkeleton({
    this.padding = const EdgeInsets.all(12),
    this.maxCrossAxisExtent = 240,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    super.key,
  });

  final EdgeInsets padding;
  final double maxCrossAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return SliverWaterfallGrid<double>(
      items: _ratios,
      padding: padding,
      maxCrossAxisExtent: maxCrossAxisExtent,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      itemBuilder: (context, ratio, index) {
        return _IllustWaterfallSkeletonCard(aspectRatio: ratio);
      },
    );
  }
}

class _IllustWaterfallSkeletonCard extends StatelessWidget {
  const _IllustWaterfallSkeletonCard({required this.aspectRatio});

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Bone(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(6)),
              ),
              const SizedBox(height: 10),
              const Bone.text(width: double.infinity),
              const SizedBox(height: 7),
              const Bone.text(width: 96),
            ],
          ),
        ),
      ),
    );
  }
}
