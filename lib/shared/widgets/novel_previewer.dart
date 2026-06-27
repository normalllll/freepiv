import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/energetic_card.dart';
import 'package:freepiv/shared/widgets/illust_bookmark_button.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

class NovelPreviewer extends StatelessWidget {
  const NovelPreviewer({required this.novel, this.onTap, this.maxWidth, super.key});

  final Novel novel;
  final VoidCallback? onTap;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final accent = _novelAccent(context);
    final card = EnergeticCard(
      accentColor: accent,
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NovelCoverImage(url: novel.imageUrls.medium, width: 82, height: 116),
          const SizedBox(width: 12),
          Expanded(child: _NovelPreviewBody(novel: novel)),
          const SizedBox(width: 8),
          IllustBookmarkButton(illustId: novel.id, initialIsBookmarked: novel.isBookmarked, isNovel: true),
        ],
      ),
    );

    final maxWidth = this.maxWidth;
    if (maxWidth == null) {
      return card;
    }

    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: card,
      ),
    );
  }
}

class NovelCoverImage extends StatelessWidget {
  const NovelCoverImage({
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    super.key,
  });

  final String url;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: tokens.surfaceMuted, borderRadius: borderRadius),
        child: PixivImage(url: url, fit: BoxFit.cover, borderRadius: borderRadius),
      ),
    );
  }
}

class NovelTagChips extends StatelessWidget {
  const NovelTagChips({required this.tags, this.maxTags = 5, this.compact = false, super.key});

  final List<Tag> tags;
  final int maxTags;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleTags = tags.take(maxTags).toList(growable: false);
    final hiddenCount = tags.length - visibleTags.length;

    return Wrap(
      spacing: compact ? 5 : 6,
      runSpacing: compact ? 5 : 6,
      children: [
        for (final tag in visibleTags) _NovelTagChip(label: _tagLabel(tag), compact: compact),
        if (hiddenCount > 0) _NovelTagChip(label: '+$hiddenCount', compact: compact),
      ],
    );
  }
}

class _NovelPreviewBody extends StatelessWidget {
  const _NovelPreviewBody({required this.novel});

  final Novel novel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = t;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(novel.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            novel.user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 7),
          _NovelPreviewTags(tags: novel.tags),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _MetaPill(text: translations.user.meta.novelChars(count: novel.textLength)),
              if (novel.pageCount > 1) _MetaPill(text: translations.user.meta.novelPages(count: novel.pageCount)),
              if (novel.xRestrict > 0) const _MetaPill(text: 'R-18'),
            ],
          ),
        ],
      ),
    );
  }
}

class _NovelPreviewTags extends StatelessWidget {
  const _NovelPreviewTags({required this.tags});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleTags = tags.take(4).toList(growable: false);
    final hiddenCount = tags.length - visibleTags.length;

    return SizedBox(
      height: 24,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: visibleTags.length + (hiddenCount > 0 ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(width: 5),
        itemBuilder: (context, index) {
          if (index >= visibleTags.length) {
            return _NovelTagChip(label: '+$hiddenCount', compact: true);
          }

          return _NovelTagChip(label: _tagLabel(visibleTags[index]), compact: true);
        },
      ),
    );
  }
}

class _NovelTagChip extends StatelessWidget {
  const _NovelTagChip({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = _tagAccent(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 112 : 180),
      child: EnergeticPill(
        accentColor: accent,
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: compact ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text});

  final String text;

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
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

String _tagLabel(Tag tag) {
  final translatedName = tag.translatedName;
  if (translatedName != null && translatedName.isNotEmpty) {
    return '#${tag.name} · $translatedName';
  }

  return '#${tag.name}';
}

Color _novelAccent(BuildContext context) {
  final tokens = FreepivThemeTokens.of(context);
  return tokens.brand;
}

Color _tagAccent(BuildContext context) {
  final tokens = FreepivThemeTokens.of(context);
  return tokens.brand;
}
