import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/series/series_widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_ui/frost_ui.dart';

/// What follows the last line: "The end", the novel's bookmark and its
/// comments, and for a novel in a series the next episode, a button to watch
/// the series and a link back to the previous one.
///
/// It lies after the text and is not part of it: reading progress reaches
/// 100 % at the end of the text, before this card.
class ReaderEndCard extends StatelessWidget {
  const ReaderEndCard({
    required this.novelId,
    required this.bookmarked,
    required this.onComments,
    required this.onOpenNovel,
    this.seriesId,
    this.seriesTitle,
    this.seriesWatched = false,
    this.next,
    this.previous,
    super.key,
  });

  final int novelId;
  final bool bookmarked;
  final VoidCallback onComments;

  /// Replaces the reader with the reader of the novel with this id.
  final ValueChanged<int> onOpenNovel;

  /// The series the novel belongs to; null when it is in none.
  final int? seriesId;
  final String? seriesTitle;
  final bool seriesWatched;
  final NovelNavigationItem? next;
  final NovelNavigationItem? previous;

  @override
  Widget build(BuildContext context) {
    final t = context.t.novel.reader;
    final series = seriesId;
    return Column(
      key: const ValueKey('reader-end-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.group,
      children: [
        FrostText(t.theEnd, role: FrostTextRole.headline, textAlign: TextAlign.center),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: FrostGap.related,
          runSpacing: FrostGap.related,
          children: [
            AppBookmarkBuilder(
              workId: novelId,
              initiallyBookmarked: bookmarked,
              novel: true,
              builder: (context, bookmarked, toggle) => FrostButton.outlined(
                key: const ValueKey('reader-end-bookmark'),
                label: bookmarked ? context.t.novelDetail.bookmarked : context.t.novelDetail.bookmark,
                icon: bookmarked ? PivIcons.heartFilled : PivIcons.heart,
                onPressed: toggle,
              ),
            ),
            FrostButton.outlined(key: const ValueKey('reader-end-comments'), label: t.comments, icon: PivIcons.messageCircle, onPressed: onComments),
          ],
        ),
        if (series != null) ...[
          if (seriesTitle != null) AppSeriesLink(kind: AppSeriesKind.novel, seriesId: series, title: seriesTitle!),
          if (next != null) _NextNovel(item: next!, onOpen: onOpenNovel),
          Center(
            child: AppSeriesWatchButton(kind: AppSeriesKind.novel, seriesId: series, watched: seriesWatched),
          ),
          if (previous != null)
            Center(
              child: FrostButton.plain(
                key: const ValueKey('reader-end-previous'),
                label: t.seriesPrevious(title: previous!.title),
                onPressed: (previous!.viewable && int.tryParse(previous!.id) != null) ? () => onOpenNovel(int.parse(previous!.id)) : null,
              ),
            ),
        ],
      ],
    );
  }
}

/// The next novel of the series: cover, its place in the series and title; a
/// novel that cannot be read yet says why and cannot be opened.
class _NextNovel extends StatelessWidget {
  const _NextNovel({required this.item, required this.onOpen});

  final NovelNavigationItem item;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.t.novel.reader;
    final id = int.tryParse(item.id);
    final openable = item.viewable && id != null;
    final cover = item.coverUrl;
    final order = item.contentOrder;
    final body = FrostSurface(
      role: FrostSurfaceRole.module,
      borderRadius: BorderRadius.circular(FrostRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(FrostGap.related),
        child: Row(
          spacing: FrostGap.group,
          children: [
            SizedBox(
              width: 56,
              child: AspectRatio(
                aspectRatio: PivMetrics.novelCoverWidth / PivMetrics.novelCoverHeight,
                child: cover == null || cover.isEmpty || !openable
                    ? const SizedBox.expand()
                    : AppPixivImage(url: cover, aspectRatio: PivMetrics.novelCoverWidth / PivMetrics.novelCoverHeight, radius: FrostRadius.md),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FrostGap.inline,
                children: [
                  FrostText(
                    [t.seriesNext, if (order != null && order.isNotEmpty) '#$order'].join(' · '),
                    role: FrostTextRole.footnote,
                    tone: FrostTextTone.secondary,
                  ),
                  FrostText(item.title, content: true, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (!openable)
                    FrostText(
                      item.viewableMessage?.trim().isNotEmpty == true ? item.viewableMessage! : t.seriesNextUnavailable,
                      role: FrostTextRole.footnote,
                      tone: FrostTextTone.secondary,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (!openable) return Opacity(key: const ValueKey('reader-end-next'), opacity: .6, child: body);
    return FrostClickSurface(
      key: const ValueKey('reader-end-next'),
      shape: FrostClickShape.rounded(BorderRadius.circular(FrostRadius.lg)),
      onTap: () => onOpen(id),
      child: body,
    );
  }
}
