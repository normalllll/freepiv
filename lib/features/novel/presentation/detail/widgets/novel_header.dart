import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

class NovelHeader extends StatelessWidget {
  const NovelHeader({required this.novel, required this.webviewNovel, super.key});

  final Novel novel;
  final WebviewNovel webviewNovel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 720;
            final cover = LargeNovelCoverImage(url: novelCoverUrl(novel, webviewNovel), desktop: desktop);
            final info = NovelHeaderInfo(novel: novel, webviewNovel: webviewNovel);

            return Padding(
              padding: EdgeInsets.fromLTRB(desktop ? 28 : 16, 16, desktop ? 28 : 16, 18),
              child: desktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        cover,
                        const SizedBox(width: 24),
                        Expanded(child: info),
                      ],
                    )
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [cover, const SizedBox(height: 16), info]),
            );
          },
        ),
      ),
    );
  }
}

class LargeNovelCoverImage extends StatelessWidget {
  const LargeNovelCoverImage({required this.url, required this.desktop, super.key});

  final String url;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = desktop ? 260.0 : double.infinity;
    final height = desktop ? 360.0 : math.min(360.0, math.max(240.0, MediaQuery.sizeOf(context).width * 0.78));
    final borderRadius = BorderRadius.circular(8);

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: borderRadius),
        child: PixivImage(url: url, fit: BoxFit.contain, borderRadius: borderRadius),
      ),
    );
  }
}

class NovelHeaderInfo extends StatelessWidget {
  const NovelHeaderInfo({required this.novel, required this.webviewNovel, super.key});

  final Novel novel;
  final WebviewNovel webviewNovel;

  @override
  Widget build(BuildContext context) {
    final translations = t;
    final caption = webviewNovel.caption.trim().isNotEmpty ? webviewNovel.caption : novel.caption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(novel.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(novel.user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 14),
        NovelStatsStrip(novel: novel, webviewNovel: webviewNovel),
        const SizedBox(height: 12),
        NovelRestrictionBadges(novel: novel, webviewNovel: webviewNovel),
        if (novel.tags.isNotEmpty) ...[
          const SizedBox(height: 14),
          IllustSectionTitle(title: translations.illust.section.tags, icon: Icons.tag_outlined),
          const SizedBox(height: 7),
          NovelTagChips(tags: novel.tags, maxTags: 12),
        ],
        if (caption.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          IllustSectionTitle(title: translations.illust.section.caption, icon: Icons.notes_outlined),
          const SizedBox(height: 7),
          NovelCaptionBox(caption: caption),
        ],
        const SizedBox(height: 14),
        IllustSectionTitle(title: translations.illust.section.details, icon: Icons.info_outline),
        const SizedBox(height: 4),
        NovelMetadataRow(label: translations.common.id, value: novel.id.toString()),
        if ((novel.series.title ?? '').isNotEmpty) NovelMetadataRow(label: translations.novel.detail.series, value: novel.series.title!),
        if (novel.createDate.isNotEmpty) NovelMetadataRow(label: translations.illust.metadata.created, value: formatPixivDate(novel.createDate)),
      ],
    );
  }
}

class NovelStatsStrip extends StatelessWidget {
  const NovelStatsStrip({required this.novel, required this.webviewNovel, super.key});

  final Novel novel;
  final WebviewNovel webviewNovel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: NovelStatPill(
            icon: Icons.text_fields,
            label: t.user.meta.novelChars(count: novel.textLength),
            value: formatCount(novel.textLength),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: NovelStatPill(
            icon: Icons.visibility_outlined,
            label: t.illust.stats.views,
            value: formatCount(math.max(novel.totalView, webviewNovel.rating.view)),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: NovelStatPill(icon: Icons.favorite_border, label: t.illust.stats.bookmarks, value: formatCount(novel.totalBookmarks)),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: NovelStatPill(
            icon: Icons.menu_book_outlined,
            label: t.user.meta.novelPages(count: novel.pageCount),
            value: '${novel.pageCount}',
          ),
        ),
      ],
    );
  }
}

class NovelStatPill extends StatelessWidget {
  const NovelStatPill({required this.icon, required this.label, required this.value, super.key});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, height: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NovelRestrictionBadges extends StatelessWidget {
  const NovelRestrictionBadges({required this.novel, required this.webviewNovel, super.key});

  final Novel novel;
  final WebviewNovel webviewNovel;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (novel.novelAiType != 0 || webviewNovel.aiType > 0) NovelInfoBadge(label: context.t.illust.badge.aiArtwork, icon: Icons.auto_awesome_outlined),
      if (novel.xRestrict > 0 || novel.isXRestricted) const NovelInfoBadge(label: 'R-18', icon: Icons.explicit_outlined),
      if (novel.isOriginal || webviewNovel.isOriginal) NovelInfoBadge(label: context.t.illust.badge.original, icon: Icons.edit_note_outlined),
    ];

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 6, runSpacing: 6, children: badges);
  }
}

class NovelInfoBadge extends StatelessWidget {
  const NovelInfoBadge({required this.label, required this.icon, super.key});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(7)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class NovelCaptionBox extends StatelessWidget {
  const NovelCaptionBox({required this.caption, super.key});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: HtmlRichText(caption, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface, height: 1.35)),
      ),
    );
  }
}

class NovelMetadataRow extends StatelessWidget {
  const NovelMetadataRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
