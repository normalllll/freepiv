import 'package:flutter/material.dart';
import 'package:freepiv/features/illust/presentation/widgets/horizontal_illust_strip.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

class VerticalIllustPreviewGrid extends StatelessWidget {
  const VerticalIllustPreviewGrid({required this.illusts, required this.onIllustTap, this.minTileExtent = 112, super.key});

  final List<Illust> illusts;
  final ValueChanged<Illust> onIllustTap;
  final double minTileExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : minTileExtent * 2;
        const spacing = 8.0;
        final columnCount = (width / minTileExtent).ceil().clamp(2, 4);
        final itemExtent = (width - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final illust in illusts)
              SizedBox.square(
                dimension: itemExtent,
                child: SquareIllustTile(illust: illust, onTap: () => onIllustTap(illust)),
              ),
          ],
        );
      },
    );
  }
}

class RelatedPreviewGridSkeleton extends StatelessWidget {
  const RelatedPreviewGridSkeleton({this.itemCount = 6, this.minTileExtent = 112, super.key});

  final int itemCount;
  final double minTileExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : minTileExtent * 2;
        const spacing = 8.0;
        final columnCount = (width / minTileExtent).ceil().clamp(2, 4);
        final itemExtent = (width - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < itemCount; index++)
              SizedBox.square(
                dimension: itemExtent,
                child: const ImageLoadingSkeleton(borderRadius: BorderRadius.all(Radius.circular(8))),
              ),
          ],
        );
      },
    );
  }
}
