import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/shared/widgets/legacy_frost.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/shared/widgets/artwork_hero.dart';
import 'package:freepiv/shared/widgets/illust_bookmark_button.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

class IllustPreviewer extends ConsumerWidget {
  const IllustPreviewer({required this.illust, required this.onOpen, this.fit = BoxFit.cover, this.square = false, this.rank, this.leadingBadge, super.key});

  final Illust illust;
  final BoxFit fit;

  /// Opens the work with this card's own hero tag, so its image flies into
  /// the detail stage and back (see [openIllustDetail]).
  final ValueChanged<ArtworkHeroTag> onOpen;
  final bool square;
  final int? rank;

  /// A badge over the image's top-start corner (a ranking number). It is
  /// part of the image, so it flies with it rather than staying behind.
  final Widget? leadingBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _illustAccent(context);
    // Square tiles show the same uncropped preview as the feeds, cut to the
    // square from its centre, so the work opens with its image already
    // cached rather than loading apart from a separate square crop.
    final previewUrl = illustPreviewImageUrl(illust.imageUrls, ref.watch(previewImageQualityProvider));
    return ArtworkHeroSource(
      illust: illust,
      imageUrl: previewUrl,
      sourceRadius: square ? BorderRadius.circular(FrostRadius.lg) : const BorderRadius.vertical(top: Radius.circular(FrostRadius.lg)),
      builder: (context, heroTag) {
        final image = ArtworkHero(
          tag: heroTag,
          child: _IllustPreviewImage(illust: illust, imageUrl: previewUrl, fit: fit, square: square, showBadges: !square, leadingBadge: leadingBadge),
        );
        return PivCard(
          feedback: square ? FrostClickFeedback.media : FrostClickFeedback.surface,
          accentColor: accent,
          onTap: () => onOpen(heroTag),
          child: square
              ? image
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    image,
                    _IllustPreviewFooter(illust: illust, accentColor: accent, rank: rank),
                  ],
                ),
        );
      },
    );
  }
}

class _IllustPreviewImage extends StatelessWidget {
  const _IllustPreviewImage({
    required this.illust,
    required this.imageUrl,
    required this.fit,
    required this.square,
    required this.showBadges,
    this.leadingBadge,
  });

  final Illust illust;
  final String imageUrl;
  final BoxFit fit;
  final bool square;
  final bool showBadges;
  final Widget? leadingBadge;

  @override
  Widget build(BuildContext context) {
    final imageAspectRatio = illust.width > 0 && illust.height > 0 ? illust.width / illust.height : 1.0;

    return AspectRatio(
      aspectRatio: square ? 1.0 : imageAspectRatio.clamp(0.6, 1.6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // With a pointer over the card the picture leans in slightly,
          // cropped by its own frame; the badges stay put.
          Positioned.fill(
            child: ClipRect(
              child: FrostSpringBuilder(
                value: FrostClickSurface.hoveredOf(context) ? FrostMetrics.mediaHoverZoom : 1,
                spring: FrostMotion.standard,
                builder: (context, zoom, child) => Transform.scale(scale: zoom, child: child),
                child: PixivImage(url: imageUrl, fit: fit),
              ),
            ),
          ),
          if (leadingBadge case final badge?) PositionedDirectional(start: 8, top: 8, child: badge),
          if (showBadges && _isUgoiraIllust(illust))
            const PositionedDirectional(
              top: 8,
              start: 8,
              child: _LabelBadge(label: 'GIF', backgroundColor: Color(0xCC242428)),
            ),
          if (showBadges && illust.xRestrict > 0)
            const PositionedDirectional(
              top: 8,
              end: 8,
              child: _LabelBadge(label: 'R-18', backgroundColor: Color(0xCC242428)),
            ),
          if (showBadges && illust.illustAiType == 2)
            const PositionedDirectional(
              start: 8,
              bottom: 8,
              child: _LabelBadge(label: 'AI', backgroundColor: Color(0xCC242428)),
            ),
          if (showBadges && illust.pageCount > 1) PositionedDirectional(end: 8, bottom: 8, child: _PageCountBadge(pageCount: illust.pageCount)),
        ],
      ),
    );
  }
}

bool _isUgoiraIllust(Illust illust) {
  return illust.kind.toLowerCase() == 'ugoira';
}

class _IllustPreviewFooter extends StatelessWidget {
  const _IllustPreviewFooter({required this.illust, required this.accentColor, this.rank});

  final int? rank;

  final Illust illust;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: PivMetrics.artworkFooterPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank == null ? illust.title : '#$rank  ${illust.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: frostContentTextStyle(context, illust.title, Theme.of(context).textTheme.titleSmall),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        illust.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IllustBookmarkButton(illustId: illust.id, initialIsBookmarked: illust.isBookmarked),
        ],
      ),
    );
  }
}

Color _illustAccent(BuildContext context) {
  final tokens = FrostThemeTokens.of(context);
  return tokens.accent;
}

class _LabelBadge extends StatelessWidget {
  const _LabelBadge({required this.label, required this.backgroundColor});

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 1))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w400, height: 1),
        ),
      ),
    );
  }
}

class _PageCountBadge extends StatelessWidget {
  const _PageCountBadge({required this.pageCount});

  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 8, offset: Offset(0, 1))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.collections_outlined,
              size: 13,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
            const SizedBox(width: 3),
            Text(
              '$pageCount',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                height: 1,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
