import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/shared/widgets/energetic_card.dart';
import 'package:freepiv/shared/widgets/illust_bookmark_button.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

class IllustPreviewer extends ConsumerWidget {
  const IllustPreviewer({required this.illust, required this.onTap, this.fit = BoxFit.cover, this.square = false, super.key});

  final Illust illust;
  final BoxFit fit;
  final VoidCallback? onTap;
  final bool square;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _illustAccent(context);

    return EnergeticCard(
      accentColor: accent,
      onTap: onTap,
      child: square
          ? _IllustPreviewImage(illust: illust, fit: fit, square: true, showBadges: false)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IllustPreviewImage(illust: illust, fit: fit),
                _IllustPreviewFooter(illust: illust, accentColor: accent),
              ],
            ),
    );
  }
}

class _IllustPreviewImage extends ConsumerWidget {
  const _IllustPreviewImage({required this.illust, required this.fit, this.square = false, this.showBadges = true});

  final Illust illust;
  final BoxFit fit;
  final bool square;
  final bool showBadges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewQuality = ref.watch(previewImageQualityProvider);
    final imageAspectRatio = illust.width > 0 && illust.height > 0 ? illust.width / illust.height : 1.0;
    final imageUrl = square ? illust.imageUrls.squareMedium : illustPreviewImageUrl(illust.imageUrls, previewQuality);

    return AspectRatio(
      aspectRatio: square ? 1.0 : imageAspectRatio.clamp(0.6, 1.6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: PixivImage(url: imageUrl, fit: fit),
          ),
          if (showBadges && _isUgoiraIllust(illust))
            const PositionedDirectional(
              top: 8,
              start: 8,
              child: _LabelBadge(label: 'GIF', backgroundColor: Color(0xFF111827)),
            ),
          if (showBadges && illust.xRestrict > 0)
            const PositionedDirectional(
              top: 8,
              end: 8,
              child: _LabelBadge(label: 'R-18', backgroundColor: Color(0xFFE53935)),
            ),
          if (showBadges && illust.illustAiType == 2)
            const PositionedDirectional(
              start: 8,
              bottom: 8,
              child: _LabelBadge(label: 'AI', backgroundColor: Color(0xFF2563EB)),
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
  const _IllustPreviewFooter({required this.illust, required this.accentColor});

  final Illust illust;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(illust.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                      child: const SizedBox.square(dimension: 6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        illust.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
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
  final tokens = FreepivThemeTokens.of(context);
  return tokens.brand;
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1),
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
                fontWeight: FontWeight.w800,
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
