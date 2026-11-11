import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// Opens the work [entry] remembers; its page loads the work itself.
void openHistoryEntry(BuildContext context, HistoryEntry entry) {
  unawaited(GoRouter.of(context).push(entry.kind.isNovel ? AppLocations.novel(entry.workId) : AppLocations.illust(entry.workId)));
}

/// What the menu of an entry of the browsing history offers: opening the work
/// and removing the entry.
List<FrostMenuEntry> historyEntryMenu(BuildContext context, HistoryEntry entry, VoidCallback onRemove) {
  final t = context.t.history;
  return [
    FrostMenuSection(
      header: entry.title,
      entries: [
        FrostMenuAction(t.open, leading: const FrostGlyph.icon(PivIcons.eye), onSelected: () => openHistoryEntry(context, entry)),
        FrostMenuAction(t.remove, leading: const FrostGlyph.icon(PivIcons.trash), onSelected: onRemove),
      ],
    ),
  ];
}

/// An illustration, manga or animation of the browsing history, as it was when
/// last viewed: the card of a work in a feed without the bookmark button,
/// whose state would be out of date.
class AppHistoryCard extends StatelessWidget {
  const AppHistoryCard({required this.entry, required this.onRemove, super.key});

  final HistoryEntry entry;

  /// Removes the entry from the history.
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final ratio = entry.aspectRatio;
    final badges = workRestrictionBadges(context, xRestrict: entry.xRestrict, aiGenerated: entry.aiGenerated);
    final pages = entry.pageCount ?? 1;
    return FrostMediaCard(
      media: AppPixivImage(url: entry.thumbnailUrl, aspectRatio: ratio, radius: 0),
      aspectRatio: ratio,
      topStart: badges.isEmpty ? null : Wrap(spacing: FrostGap.inline, runSpacing: FrostGap.inline, children: badges),
      topEnd: entry.kind == HistoryWorkKind.ugoira
          ? FrostBadge(label: t.artworkCard.ugoira, icon: PivIcons.play, tone: FrostBadgeTone.onMedia)
          : pages > 1
          ? FrostBadge(label: '$pages', icon: PivIcons.images, tone: FrostBadgeTone.onMedia)
          : null,
      footer: AppArtworkCardFooter(title: entry.title, author: entry.authorName),
      semanticLabel: t.artworkCard.semantics(title: entry.title, author: entry.authorName),
      onPressed: () => openHistoryEntry(context, entry),
      contextMenu: historyEntryMenu(context, entry, onRemove),
    );
  }
}

/// A novel of the browsing history, as it was when last viewed: its cover,
/// title, author and length, without the bookmark button.
class AppHistoryNovelRow extends StatelessWidget {
  const AppHistoryNovelRow({required this.entry, required this.onRemove, super.key});

  final HistoryEntry entry;

  /// Removes the entry from the history.
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final length = entry.textLength;
    final badges = workRestrictionBadges(context, xRestrict: entry.xRestrict, aiGenerated: entry.aiGenerated);
    return FrostContextMenuRegion(
      entries: historyEntryMenu(context, entry, onRemove),
      child: FrostClickSurface(
        onTap: () => openHistoryEntry(context, entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FrostGap.group,
            children: [
              SizedBox(
                width: AppNovelRow.coverWidth,
                child: AppPixivImage(url: entry.thumbnailUrl, aspectRatio: AppNovelRow.coverRatio, radius: FrostRadius.md),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostGap.inline,
                  children: [
                    FrostText(entry.title, content: true, role: FrostTextRole.headline, maxLines: 2, overflow: TextOverflow.ellipsis),
                    FrostText(
                      entry.authorName,
                      content: true,
                      role: FrostTextRole.footnote,
                      tone: FrostTextTone.secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (length != null) FrostMetaLine(items: [t.user.meta.novelChars(count: length)]),
                    if (badges.isNotEmpty) Wrap(spacing: FrostGap.inline, runSpacing: FrostGap.inline, children: badges),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
