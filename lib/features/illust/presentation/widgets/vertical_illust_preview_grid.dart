import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/shared/widgets/app_click_surface.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

const _previewSpacing = 8.0;

/// Tile size of a preview grid [width] wide: 2–4 square columns no narrower
/// than [minTileExtent]. Shared by the grid and its skeleton so loading
/// never changes the tile size.
double _previewTileExtent(double width, double minTileExtent) {
  final columnCount = (width / minTileExtent).ceil().clamp(2, 4);
  return (width - _previewSpacing * (columnCount - 1)) / columnCount;
}

class VerticalIllustPreviewGrid extends StatelessWidget {
  const VerticalIllustPreviewGrid({required this.illusts, required this.onIllustTap, this.minTileExtent = 112, super.key});

  final List<Illust> illusts;
  final IllustOpener onIllustTap;
  final double minTileExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : minTileExtent * 2;
        final itemExtent = _previewTileExtent(width, minTileExtent);

        return Wrap(
          spacing: _previewSpacing,
          runSpacing: _previewSpacing,
          children: [
            for (final illust in illusts)
              SizedBox.square(
                dimension: itemExtent,
                child: SquareIllustTile(illust: illust, onOpen: (heroTag) => onIllustTap(illust, heroTag)),
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
        final itemExtent = _previewTileExtent(width, minTileExtent);

        return Wrap(
          spacing: _previewSpacing,
          runSpacing: _previewSpacing,
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

class SquareIllustTile extends ConsumerWidget {
  const SquareIllustTile({required this.illust, required this.onOpen, super.key});

  final Illust illust;

  /// Opens the work with this tile's hero tag.
  final ValueChanged<ArtworkHeroTag> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewQuality = ref.watch(previewImageQualityProvider);
    final imageUrl = illustPreviewImageUrl(illust.imageUrls, previewQuality);
    final borderRadius = BorderRadius.circular(8);

    return ArtworkHeroSource(
      illust: illust,
      imageUrl: imageUrl,
      sourceRadius: borderRadius,
      builder: (context, heroTag) => Tooltip(
        message: illust.title,
        waitDuration: const Duration(milliseconds: 500),
        child: ArtworkHero(
          tag: heroTag,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: AppClickSurface(
              feedback: AppClickFeedback.artwork,
              onTap: () => onOpen(heroTag),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PixivImage(url: imageUrl, fit: BoxFit.cover),
                  if (illust.pageCount > 1)
                    PositionedDirectional(
                      top: 5,
                      end: 5,
                      child: _TileBadge(icon: Icons.collections_outlined, label: '${illust.pageCount}'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TileBadge extends StatelessWidget {
  const _TileBadge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;

    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.50), borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 11, color: Colors.white), const SizedBox(width: 3)],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}
