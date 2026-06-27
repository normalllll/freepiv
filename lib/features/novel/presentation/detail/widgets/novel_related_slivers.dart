import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_detail_constraints.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NovelRelatedSlivers {
  const NovelRelatedSlivers._();

  static List<Widget> build({
    required BuildContext context,
    required NovelRelatedListSource source,
    required int currentNovelId,
    required ValueChanged<Novel> onNovelTap,
  }) {
    final titleSlivers = <Widget>[
      SliverToBoxAdapter(
        child: NovelDetailWidthLimiter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: IllustSectionTitle(title: t.illust.section.relatedWorks, icon: Icons.auto_awesome_mosaic_outlined),
          ),
        ),
      ),
    ];
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return [...titleSlivers, const SliverPadding(padding: EdgeInsets.fromLTRB(16, 0, 16, 24), sliver: NovelRelatedListSkeleton())];
    }

    if (!source.initialized && lastError != null) {
      return [
        ...titleSlivers,
        SliverToBoxAdapter(
          child: NovelDetailWidthLimiter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CompactMessage(
                icon: Icons.error_outline,
                message: formatPixivError(lastError),
                actionLabel: t.common.retry,
                onAction: () => source.refresh(true),
              ),
            ),
          ),
        ),
      ];
    }

    if (source.initialized && source.isEmpty) {
      return [
        ...titleSlivers,
        SliverToBoxAdapter(
          child: NovelDetailWidthLimiter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CompactMessage(icon: Icons.image_not_supported_outlined, message: t.illust.related.empty),
            ),
          ),
        ),
      ];
    }

    return [
      ...titleSlivers,
      SliverDataList<Novel>(
        source: source,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemBuilder: (context, novel, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NovelRelatedTile(novel: novel, onTap: () => onNovelTap(novel)),
          );
        },
      ),
    ];
  }
}

class NovelRelatedTile extends StatelessWidget {
  const NovelRelatedTile({required this.novel, required this.onTap, super.key});

  final Novel novel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _novelRelatedAccent(context);

    return NovelDetailWidthLimiter(
      child: EnergeticCard(
        accentColor: accent,
        onTap: onTap,
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 92,
              child: PixivImage(url: novel.imageUrls.squareMedium, fit: BoxFit.cover, borderRadius: BorderRadius.circular(6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(novel.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      novel.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        SmallNovelStatPill(icon: Icons.visibility_outlined, label: formatCount(novel.totalView)),
                        SmallNovelStatPill(icon: Icons.favorite_border, label: formatCount(novel.totalBookmarks)),
                        if (novel.pageCount > 1) SmallNovelStatPill(icon: Icons.collections_outlined, label: '${novel.pageCount}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmallNovelStatPill extends StatelessWidget {
  const SmallNovelStatPill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = FreepivThemeTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(tokens.brand.withValues(alpha: 0.060), colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

Color _novelRelatedAccent(BuildContext context) {
  final tokens = FreepivThemeTokens.of(context);
  return tokens.brand;
}

class NovelRelatedListSkeleton extends StatelessWidget {
  const NovelRelatedListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NovelDetailWidthLimiter(
            child: Skeletonizer.zone(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Bone(width: 92, height: 92, borderRadius: BorderRadius.circular(6)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone.text(width: double.infinity),
                            SizedBox(height: 10),
                            Bone.text(width: 150),
                            SizedBox(height: 22),
                            Bone.text(width: 180),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
