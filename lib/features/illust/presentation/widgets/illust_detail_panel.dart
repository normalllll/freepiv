import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_comments_section.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_related_section.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_user_preview_section.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

class IllustDetailPanel extends StatelessWidget {
  const IllustDetailPanel({
    required this.illust,
    required this.onIllustTap,
    this.onShowRelatedWorks,
    this.showRelatedPreview = true,
    this.scrollable = true,
    super.key,
  });

  final Illust illust;
  final ValueChanged<Illust> onIllustTap;
  final VoidCallback? onShowRelatedWorks;
  final bool showRelatedPreview;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = t;
    final content = [
      Text(illust.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      _StatsStrip(illust: illust),
      const SizedBox(height: 10),
      _RestrictionBadges(illust: illust),
      const SizedBox(height: 14),
      IllustSectionTitle(title: translations.illust.section.tags, icon: Icons.tag_outlined),
      const SizedBox(height: 6),
      _TagWrap(tags: illust.tags),
      if (illust.caption.trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        IllustSectionTitle(title: translations.illust.section.caption, icon: Icons.notes_outlined),
        const SizedBox(height: 6),
        _CaptionBox(caption: illust.caption),
      ],
      const SizedBox(height: 14),
      IllustUserPreviewSection(illust: illust, onIllustTap: onIllustTap),
      const SizedBox(height: 14),
      IllustSectionTitle(title: translations.illust.section.details, icon: Icons.info_outline),
      const SizedBox(height: 4),
      _MetadataRow(label: translations.common.id, value: illust.id.toString(), copyable: true),
      if (illust.kind.isNotEmpty) _MetadataRow(label: translations.illust.metadata.type, value: illust.kind),
      if (illust.createDate.isNotEmpty) _MetadataRow(label: translations.illust.metadata.created, value: formatPixivDate(illust.createDate)),
      const SizedBox(height: 14),

      IllustCommentsSection(illustId: illust.id, totalComments: illust.totalComments),
      const SizedBox(height: 14),
      if (showRelatedPreview && onShowRelatedWorks != null)
        IllustRelatedSection(illustId: illust.id, onIllustTap: onIllustTap, onShowMore: onShowRelatedWorks!),
    ];

    return ColoredBox(
      color: colorScheme.surface,
      child: scrollable
          ? ExcludeSemantics(
              child: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 22), children: content),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content),
            ),
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

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.illust});

  final Illust illust;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return Row(
      children: [
        Expanded(
          child: _StatPill(icon: Icons.aspect_ratio_outlined, label: translations.illust.stats.size, value: '${illust.width} x ${illust.height}'),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatPill(icon: Icons.visibility_outlined, label: translations.illust.stats.views, value: formatCount(illust.totalView)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatPill(icon: Icons.favorite_border, label: translations.illust.stats.bookmarks, value: formatCount(illust.totalBookmarks)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatPill(icon: Icons.collections_outlined, label: translations.illust.stats.pages, value: '${illust.pageCount}'),
        ),
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, height: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.tags});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return Text(context.t.illust.tags.none, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    final sortedTags = [...tags]
      ..sort((a, b) {
        return _tagLabel(a).length.compareTo(_tagLabel(b).length);
      });

    return Wrap(spacing: 6, runSpacing: 6, children: [for (final tag in sortedTags) _TagChip(tag: tag)]);
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(999);

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => unawaited(_copyTextValue(context.t.illust.tags.tag, tag.name)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Text(_tagLabel(tag), style: Theme.of(context).textTheme.labelSmall),
          ),
        ),
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

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value, this.copyable = false});

  final String label;
  final String value;
  final bool copyable;

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
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
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
    AppToast.success(t.illust.toast.copiedValue(label: label, value: value));
  } catch (error) {
    AppToast.errorWithCause(t.illust.toast.copyFailed(label: label), error);
  }
}

String _tagLabel(Tag tag) {
  final translatedName = tag.translatedName;
  if (translatedName != null && translatedName.isNotEmpty) {
    return '#${tag.name} · $translatedName';
  }

  return '#${tag.name}';
}
