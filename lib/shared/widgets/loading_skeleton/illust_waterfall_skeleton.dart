import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _ratios = <double>[1.32, 0.78, 1.08, 1.58, 0.92, 1.22, 1.44, 0.86, 1.16, 0.88, 1.42, 1.02, 1.26, 0.96, 1.52, 1.12, 0.82, 1.36, 1.06, 1.46];

class IllustWaterfallSkeleton extends StatelessWidget {
  const IllustWaterfallSkeleton({super.key, required this.physics, this.sliverHeader});

  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: FrostWaterfallGrid<double>(
        items: _skeletonRatios(size.width, size.height, FrostMetrics.gridExtent),
        physics: physics,
        sliverHeader: sliverHeader,
        itemBuilder: (context, ratio, index) {
          return IllustPreviewerSkeleton(aspectRatio: ratio);
        },
      ),
    );
  }
}

class SliverIllustWaterfallSkeleton extends StatelessWidget {
  const SliverIllustWaterfallSkeleton({
    this.padding,
    this.preferredTileWidth = FrostMetrics.gridExtent,
    this.crossAxisSpacing = FrostMetrics.gridGap,
    this.mainAxisSpacing = FrostMetrics.gridGap,
    super.key,
  });

  final EdgeInsets? padding;
  final double preferredTileWidth;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => FrostSliverWaterfallGrid<double>(
        items: _skeletonRatios(constraints.crossAxisExtent, constraints.viewportMainAxisExtent, preferredTileWidth),
        padding: padding,
        preferredTileWidth: preferredTileWidth,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        itemBuilder: (context, ratio, index) {
          return IllustPreviewerSkeleton(aspectRatio: ratio);
        },
      ),
    );
  }
}

/// Enough placeholder tiles to run past the bottom of the viewport at any
/// window size, so a maximized window never shows a short skeleton that then
/// grows when the real works arrive. Overestimates on purpose: tiles below
/// the viewport are never built.
List<double> _skeletonRatios(double width, double viewportHeight, double preferredTileWidth) {
  const footerHeight = 64.0;
  const widestRatio = 1.58;
  final columns = (width / preferredTileWidth).ceil() + 1;
  final shortestTile = width / columns / widestRatio + footerHeight;
  final rows = (viewportHeight / shortestTile).ceil() + 1;
  final count = (columns * rows).clamp(_ratios.length, 160);
  return [for (var index = 0; index < count; index++) _ratios[index % _ratios.length]];
}

class IllustPreviewerSkeleton extends StatelessWidget {
  const IllustPreviewerSkeleton({required this.aspectRatio, super.key});
  final double aspectRatio;
  @override
  Widget build(BuildContext context) => Skeletonizer.zone(
    child: FrostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: const Bone(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.vertical(top: Radius.circular(FrostMetrics.controlRadius)),
            ),
          ),
          const Padding(
            padding: PivMetrics.artworkFooterPadding,
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Bone.text(), SizedBox(height: 4), Bone.text(width: 96)]),
                ),
                SizedBox(width: 8),
                Bone.circle(size: FrostMetrics.controlHeight),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
