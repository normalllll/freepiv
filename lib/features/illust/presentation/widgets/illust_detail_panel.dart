import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_comments_section.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_image_viewer.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_related_section.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_user_preview_section.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

class IllustDetailPanel extends StatelessWidget {
  const IllustDetailPanel({
    required this.illust,
    required this.onIllustTap,
    this.onShowRelatedWorks,
    this.showRelatedPreview = true,
    this.scrollable = true,
    required this.actions,
    super.key,
  });

  final Illust illust;
  final IllustOpener onIllustTap;
  final VoidCallback? onShowRelatedWorks;
  final bool showRelatedPreview;
  final bool scrollable;
  final IllustPageActions actions;

  @override
  Widget build(BuildContext context) {
    final translations = t;
    // Wide and narrow share one order: title, quiet stats, creator, then the
    // single action row. Stats sit with the title so they read as the work's.
    final content = [
      SelectableText(
        illust.title,
        style: frostContentTextStyle(context, illust.title, Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 6),
      _StatsStrip(illust: illust),
      const SizedBox(height: FrostGap.group),
      IllustUserPreviewSection(illust: illust, onIllustTap: onIllustTap, showRecentWorks: false),
      const SizedBox(height: FrostGap.group),
      _ActionRow(illust: illust, actions: actions),
      if (illust.illustAiType == 2 || illust.xRestrict > 0) ...[const SizedBox(height: FrostGap.related), _RestrictionBadges(illust: illust)],
      if (illust.caption.trim().isNotEmpty) ...[
        const SizedBox(height: FrostGap.group),
        IllustSectionTitle(title: translations.illust.section.caption),
        const SizedBox(height: FrostGap.inline),
        _CaptionBox(caption: illust.caption),
      ],
      const SizedBox(height: FrostGap.group),
      IllustSectionTitle(title: translations.illust.section.tags),
      const SizedBox(height: FrostGap.inline),
      _TagWrap(tags: illust.tags),
      const SizedBox(height: FrostGap.group),
      ExpansionTile(
        key: PageStorageKey<String>('illust-metadata-${illust.id}'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(translations.illust.section.details, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        children: [
          _MetadataRow(label: translations.common.id, value: illust.id.toString(), copyable: true),
          if (illust.kind.isNotEmpty) _MetadataRow(label: translations.illust.metadata.type, value: _kindLabel(illust.kind, translations)),
          if (illust.width > 0 && illust.height > 0) _MetadataRow(label: translations.illust.stats.size, value: '${illust.width} × ${illust.height}'),
          if (illust.createDate.isNotEmpty) _MetadataRow(label: translations.illust.metadata.created, value: formatPixivDate(illust.createDate)),
        ],
      ),
      const SizedBox(height: 8),
      IllustCommentsSection(illustId: illust.id, totalComments: illust.totalComments),
      const SizedBox(height: FrostGap.group),
      // The creator's recent works follow the work's own content.
      IllustUserPreviewSection(illust: illust, onIllustTap: onIllustTap, showHeader: false),
      const SizedBox(height: FrostGap.group),
      if (showRelatedPreview && onShowRelatedWorks != null)
        IllustRelatedSection(illustId: illust.id, onIllustTap: onIllustTap, onShowMore: onShowRelatedWorks!),
    ];

    return scrollable
        ? ListView(key: PageStorageKey<String>('illust-detail-panel-${illust.id}'), padding: const EdgeInsets.all(20), children: content)
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content),
          );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.illust, required this.actions});

  final Illust illust;
  final IllustPageActions actions;

  @override
  Widget build(BuildContext context) {
    final tokens = FrostThemeTokens.of(context);
    final translations = t;
    final tonal = IconButton.styleFrom(backgroundColor: tokens.surfaceInset, fixedSize: Size.square(FrostDensity.of(context).controlHeight));
    return Wrap(
      spacing: FrostGap.related,
      runSpacing: FrostGap.related,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: tokens.surfaceInset, shape: BoxShape.circle),
          child: IllustBookmarkButton(illustId: illust.id, initialIsBookmarked: illust.isBookmarked),
        ),
        if (actions.canDownload)
          Builder(
            builder: (buttonContext) => IconButton(
              style: tonal,
              tooltip: translations.illust.contextMenu.download,
              onPressed: () => unawaited(actions.download(origin: DownloadFlight.originOf(buttonContext))),
              icon: const Icon(Icons.download_outlined),
            ),
          ),
        IconButton(
          style: tonal,
          tooltip: translations.illust.contextMenu.copyLink,
          onPressed: () => unawaited(actions.copyLink()),
          icon: const Icon(Icons.link_rounded),
        ),
        Builder(
          builder: (buttonContext) => IconButton(
            style: tonal,
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onPressed: () => unawaited(actions.showMore(buttonContext)),
            icon: const Icon(Icons.more_horiz),
          ),
        ),
      ],
    );
  }
}

class _RestrictionBadges extends StatelessWidget {
  const _RestrictionBadges({required this.illust});

  final Illust illust;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (illust.illustAiType == 2) _InfoBadge(label: context.t.illust.badge.aiArtwork, icon: Icons.auto_awesome_outlined),
      if (illust.xRestrict > 0) const _InfoBadge(label: 'R-18', icon: Icons.explicit_outlined),
    ];

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 6, runSpacing: 6, children: badges);
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(FrostRadius.lg)),
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

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.illust});

  final Illust illust;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _StatPill(icon: Icons.visibility_outlined, label: translations.illust.stats.views, value: formatCount(illust.totalView)),
        _StatPill(icon: Icons.favorite_border, label: translations.illust.stats.bookmarks, value: formatCount(illust.totalBookmarks)),
        if (illust.pageCount > 1) _StatPill(icon: Icons.collections_outlined, label: translations.illust.stats.pages, value: '${illust.pageCount}'),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: context.t.common.labelValue(label: label, value: value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(value, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _TagWrap extends StatefulWidget {
  const _TagWrap({required this.tags});

  final List<Tag> tags;

  @override
  State<_TagWrap> createState() => _TagWrapState();
}

class _TagWrapState extends State<_TagWrap> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.tags.isEmpty) {
      return Text(context.t.illust.tags.none, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    final tags = widget.tags;
    final visibleTags = _expanded ? tags : tags.take(5);
    final tokens = FrostThemeTokens.of(context);

    return AnimatedSize(
      duration: FrostMotion.duration(context, FrostMotion.expand),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: FrostGap.related,
            runSpacing: FrostGap.related,
            children: [for (final tag in visibleTags) _TagChip(tag: tag)],
          ),
          if (tags.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: FrostGap.related),
              child: TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  foregroundColor: tokens.textPrimary,
                  backgroundColor: tokens.surfaceInset,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FrostRadius.lg)),
                ),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
                label: Text(_expanded ? context.t.illust.tags.showLess : context.t.illust.tags.showMore(count: tags.length - 5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = FrostThemeTokens.of(context);
    final borderRadius = BorderRadius.circular(FrostRadius.lg);

    return Tooltip(
      message: context.t.common.copy(label: tag.name),
      child: TextButton(
        onPressed: () => unawaited(_copyTextValue(context.t.illust.tags.tag, tag.name)),
        style: TextButton.styleFrom(
          overlayColor: Colors.transparent,
          foregroundColor: colorScheme.onSurfaceVariant,
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ).copyWith(backgroundColor: WidgetStateProperty.resolveWith((states) => frostButtonRestingSurface(tokens, states, resting: tokens.surfaceMuted))),
        child: Text(_tagLabel(tag), style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class _CaptionBox extends StatelessWidget {
  const _CaptionBox({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final textStyle = theme.brightness == Brightness.dark ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium;
    final tokens = FrostThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.surfaceMuted, borderRadius: BorderRadius.circular(FrostRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: HtmlRichText(caption, style: textStyle?.copyWith(color: colorScheme.onSurface, height: 1.5)),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value, this.copyable = false});

  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                ),
                if (copyable) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: context.t.common.copy(label: label),
                    visualDensity: VisualDensity.compact,
                    constraints: BoxConstraints.tightFor(width: FrostDensity.of(context).controlHeight, height: FrostDensity.of(context).controlHeight),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.content_copy_outlined, size: 16),
                    onPressed: () => unawaited(_copyTextValue(label, value)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _copyTextValue(String label, String value) async {
  try {
    await copyTextToClipboard(value);
    FrostToast.copied(t.illust.toast.copiedValue(label: label, value: value));
  } catch (error) {
    toastErrorWithCause(t.illust.toast.copyFailed(label: label), error);
  }
}

String _tagLabel(Tag tag) {
  final translatedName = tag.translatedName;
  if (translatedName != null && translatedName.isNotEmpty) {
    return '#${tag.name} · $translatedName';
  }

  return '#${tag.name}';
}

String _kindLabel(String kind, Translations translations) => switch (kind) {
  'manga' => translations.home.manga,
  _ => translations.home.illustrations,
};
