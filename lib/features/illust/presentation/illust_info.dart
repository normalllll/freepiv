import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/comments/presentation/comment_thread_item.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/logic/ugoira_playback.dart';
import 'package:freepiv/features/illust/presentation/artwork_actions.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/features/series/series_widgets.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/bookmark_options.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/loading_section.dart';
import 'package:freepiv/ui/compositions/pixiv_text.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:freepiv/ui/compositions/tag_menu.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// What the info column acts on: the work, its pages and the page on stage.
@immutable
class IllustInfoContext {
  const IllustInfoContext({required this.illust, required this.pages, required this.page, this.playback});

  final Illust illust;
  final List<ArtworkPageImage> pages;
  final int page;
  final UgoiraPlayback? playback;

  bool get ugoira => playback != null;
}

/// The heading of the info column: title, author line, the action bar and
/// the meta line.
class IllustInfoHeading extends StatelessWidget {
  const IllustInfoHeading({required this.info, super.key});

  final IllustInfoContext info;

  @override
  Widget build(BuildContext context) {
    final illust = info.illust;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.group,
      children: [
        FrostText(illust.title, content: true, role: FrostTextRole.title2, selectable: true),
        IllustAuthorLine(user: illust.user),
        IllustActionBar(info: info),
        IllustMetaLine(illust: illust),
        if (illust.series case Series(:final id?, :final title?)) AppSeriesLink(kind: AppSeriesKind.manga, seriesId: id, title: title),
      ],
    );
  }
}

/// Avatar, name (opening the author's page) and Follow.
class IllustAuthorLine extends StatelessWidget {
  const IllustAuthorLine({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    void open() => unawaited(GoRouter.of(context).push(AppLocations.user(user.id)));
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        spacing: FrostGap.related,
        children: [
          Semantics(
            button: true,
            label: user.name,
            excludeSemantics: true,
            child: FrostClickSurface(
              shape: const FrostClickShape.circle(),
              onTap: open,
              child: AppUserAvatar(user: user),
            ),
          ),
          Expanded(
            child: FrostClickSurface(
              onTap: open,
              child: FrostText(user.name, content: true, role: FrostTextRole.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          // At large text Follow takes at most half the line, never more.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
            child: AppFollowButton(user: user, prominent: false),
          ),
        ],
      ),
    );
  }
}

/// Bookmark, solid once the work is bookmarked, then download, copy link and
/// More.
class IllustActionBar extends ConsumerWidget {
  const IllustActionBar({required this.info, super.key});

  /// Narrower than this, Copy link would push the row onto a second line.
  static const _linkButtonMinWidth = 430.0;

  final IllustInfoContext info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final illust = info.illust;
    final page = info.pages[info.page.clamp(0, info.pages.length - 1)];
    return LayoutBuilder(
      builder: (context, constraints) {
        // On a phone the link moves into More, so the row stays one line.
        final roomForLink = constraints.maxWidth >= _linkButtonMinWidth;
        return Wrap(
          spacing: FrostGap.related,
          runSpacing: FrostGap.related,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppBookmarkBuilder(
              workId: illust.id,
              initiallyBookmarked: illust.isBookmarked,
              builder: (context, bookmarked, toggle) {
                final count = illust.totalBookmarks + (bookmarked && !illust.isBookmarked ? 1 : 0) - (!bookmarked && illust.isBookmarked ? 1 : 0);
                return AppDetailBookmarkButton(
                  bookmarked: bookmarked,
                  label: t.illustDetail.bookmarkCount(count: formatCount(count)),
                  tooltip: bookmarked ? t.illust.tooltip.removeBookmark : t.illust.tooltip.addBookmark,
                  onPressed: toggle,
                );
              },
            ),
            AppBookmarkOptionsButton(workId: illust.id, initiallyBookmarked: illust.isBookmarked),
            Builder(
              builder: (buttonContext) => FrostButton.icon(
                icon: PivIcons.download,
                label: info.ugoira ? t.illustDetail.downloadGif : t.illust.contextMenu.download,
                onPressed: () {
                  final origin = DownloadFlight.originOf(buttonContext);
                  if (info.playback case final playback?) {
                    unawaited(downloadUgoiraGif(playback, illust, page: page, origin: origin));
                  } else {
                    unawaited(downloadArtworkPage(illust, info.page, page, origin: origin));
                  }
                },
              ),
            ),
            if (roomForLink)
              FrostButton.icon(icon: PivIcons.link, label: t.illust.contextMenu.copyLink, onPressed: () => unawaited(copyArtworkLink(illust.id))),
            FrostMenuAnchor(
              entries: illustMoreMenu(context, info, copyLink: !roomForLink),
              builder: (context, focusNode, toggle) => FrostButton.icon(icon: PivIcons.more, label: FrostScope.labelsOf(context).more, onPressed: toggle),
            ),
          ],
        );
      },
    );
  }
}

/// More: download every page, copy the picture (desktop), open on Pixiv,
/// copy the ID; for an animation, the GIF instead of the pages. [copyLink]
/// adds the link for a row with no room for its own button.
List<FrostMenuEntry> illustMoreMenu(BuildContext context, IllustInfoContext info, {bool copyLink = false}) {
  final t = context.t;
  final illust = info.illust;
  final page = info.pages[info.page.clamp(0, info.pages.length - 1)];
  return [
    if (info.playback case final playback?) ...[
      FrostMenuAction(
        t.illustDetail.downloadGif,
        leading: const FrostGlyph.icon(PivIcons.download),
        onSelected: () => unawaited(downloadUgoiraGif(playback, illust, page: page, origin: DownloadFlight.originOf(context))),
      ),
      if (isDesktopPlatform)
        FrostMenuAction(t.illustDetail.copyGif, leading: const FrostGlyph.icon(PivIcons.copy), onSelected: () => unawaited(copyUgoiraGif(playback))),
    ] else ...[
      if (info.pages.length > 1)
        FrostMenuAction(
          t.illust.contextMenu.downloadAll,
          leading: const FrostGlyph.icon(PivIcons.images),
          onSelected: () => unawaited(downloadArtworkPages(illust, info.pages, origin: DownloadFlight.originOf(context))),
        ),
      if (isDesktopPlatform)
        FrostMenuAction(t.illust.contextMenu.copyImage, leading: const FrostGlyph.icon(PivIcons.copy), onSelected: () => unawaited(copyArtworkImage(page))),
    ],
    if (copyLink)
      FrostMenuAction(t.illust.contextMenu.copyLink, leading: const FrostGlyph.icon(PivIcons.link), onSelected: () => unawaited(copyArtworkLink(illust.id))),
    FrostMenuAction(
      t.illust.contextMenu.openOriginal,
      leading: const FrostGlyph.icon(PivIcons.externalLink),
      onSelected: () => unawaited(openArtworkOnPixiv(illust.id)),
    ),
    FrostMenuAction(t.illustDetail.copyId, leading: const FrostGlyph.icon(PivIcons.copy), onSelected: () => unawaited(copyArtworkId(illust.id))),
  ];
}

/// Views · date · size · pages, and the AI / R-18 marks.
class IllustMetaLine extends StatelessWidget {
  const IllustMetaLine({required this.illust, super.key});

  final Illust illust;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final badges = [
      if (illust.illustAiType == 2) FrostBadge(label: t.illust.badge.aiArtwork, tone: FrostBadgeTone.info),
      if (illust.xRestrict == 1) const FrostBadge(label: 'R-18', tone: FrostBadgeTone.negative),
      if (illust.xRestrict >= 2) const FrostBadge(label: 'R-18G', tone: FrostBadgeTone.negative),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FrostGap.related,
      children: [
        FrostMetaLine(
          items: [
            t.illustDetail.views(count: formatCount(illust.totalView)),
            formatPixivDate(illust.createDate),
            '${illust.width} × ${illust.height}',
            if (illust.pageCount > 1) t.illustDetail.pages(count: illust.pageCount),
          ],
        ),
        if (badges.isNotEmpty) Wrap(spacing: FrostGap.inline, children: badges),
      ],
    );
  }
}

/// The caption, tags and the work's details.
class IllustAbout extends StatefulWidget {
  const IllustAbout({required this.illust, super.key});

  final Illust illust;

  /// Tags shown before the rest are expanded.
  static const shownTags = 5;

  @override
  State<IllustAbout> createState() => _IllustAboutState();
}

class _IllustAboutState extends State<IllustAbout> {
  bool _allTags = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final illust = widget.illust;
    final caption = plainTextFromHtml(illust.caption).trim();
    final tags = _allTags ? illust.tags : illust.tags.take(IllustAbout.shownTags).toList();
    final hidden = illust.tags.length - IllustAbout.shownTags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.group,
      children: [
        if (caption.isNotEmpty) AppPixivText(illust.caption),
        if (illust.tags.isNotEmpty)
          FrostWrap(
            children: [
              for (final tag in tags)
                FrostTag(
                  label: '#${tag.name}',
                  detail: tag.translatedName,
                  style: FrostTagStyle.topic,
                  onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.tagSearch(tag.name))),
                  contextMenu: workTagMenu(context, tag.name),
                ),
              if (hidden > 0)
                FrostButton.quiet(
                  label: _allTags ? t.illust.tags.showLess : t.illust.tags.showMore(count: hidden),
                  edgeAlignment: FrostButtonEdgeAlignment.start,
                  onPressed: () => setState(() => _allTags = !_allTags),
                ),
            ],
          ),
        FrostDisclosure(
          title: t.illust.section.details,
          child: FrostKeyValueList(
            entries: [
              FrostKeyValue.copyable(label: t.common.id, value: '${illust.id}'),
              FrostKeyValue(label: t.illust.metadata.type, value: illust.kind),
              FrostKeyValue(label: t.illust.stats.size, value: '${illust.width} × ${illust.height}'),
              FrostKeyValue(label: t.illust.metadata.created, value: formatPixivDate(illust.createDate)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The comments behind one row, as the work's details are: the row's height
/// is known before they load, so loading them moves nothing on the page.
/// Opened, the first few and the way to all of them.
class IllustCommentsPanel extends ConsumerWidget {
  const IllustCommentsPanel({required this.illust, super.key});

  final Illust illust;

  /// Comments shown when open.
  static const shown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final provider = illustCommentsProvider(illust.id);
    // Only the number in the row's text arrives late; the row keeps its height.
    final total = illust.totalComments ?? ref.watch(illustCommentTotalProvider(illust.id)).asData?.value;
    return FrostDisclosure(
      title: total == null ? t.illust.section.comments : t.illust.section.commentsWithCount(count: total),
      child: AppCommentsPreview(
        value: ref.watch(provider),
        total: total,
        onRetry: () => unawaited(ref.read(provider.notifier).reload()),
        location: AppLocations.illustComments(illust.id),
        titled: false,
        shown: shown,
        skeletonRows: total == null ? shown : math.min(shown, total),
      ),
    );
  }
}

/// The author's other works on a shelf, with the way to their page.
class IllustAuthorWorks extends ConsumerWidget {
  const IllustAuthorWorks({required this.illust, super.key});

  final Illust illust;

  static const tileExtent = 120.0;

  /// The space above the shelf, part of it so that an author with no other
  /// works leaves no gap behind.
  static const gapAbove = EdgeInsets.only(top: FrostGap.section);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final provider = illustUserWorksProvider(illust.user.id);
    return ref
        .watch(provider)
        .when(
          data: (page) {
            final works = page.illusts.where((work) => work.id != illust.id).toList();
            if (works.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: gapAbove,
              child: FrostShelf(
                title: t.illust.section.recentWorks,
                inset: 0,
                action: FrostButton.quiet(label: t.home.seeMore, onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.user(illust.user.id)))),
                itemCount: works.length,
                itemExtent: tileExtent,
                height: tileExtent,
                itemBuilder: (context, index) => AppArtworkCard.tile(illust: works[index]),
              ),
            );
          },
          loading: () => const IllustAuthorWorksLoading(),
          error: (error, _) => Padding(
            padding: gapAbove,
            child: AppLoadingSection(
              title: t.illust.section.recentWorks,
              value: AsyncError<void>(error, StackTrace.empty),
              onRetry: () => unawaited(ref.read(provider.notifier).reload()),
              failed: t.illust.works.failed,
              builder: (_) => const SizedBox(),
            ),
          ),
        );
  }
}

/// Eight related works and the way to all of them.
class IllustRelatedPreview extends ConsumerStatefulWidget {
  const IllustRelatedPreview({required this.illust, super.key});

  final Illust illust;

  static const shown = 8;

  /// Equal squares, so the block's height is known before the works load.
  static const tileMinWidth = 140.0;

  @override
  ConsumerState<IllustRelatedPreview> createState() => _IllustRelatedPreviewState();
}

class _IllustRelatedPreviewState extends ConsumerState<IllustRelatedPreview> {
  @override
  void initState() {
    super.initState();
    final source = ref.read(illustRelatedWorksProvider(widget.illust.id));
    if (!source.initialized && !source.busy) unawaited(source.refresh(true));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final source = ref.watch(illustRelatedWorksProvider(widget.illust.id));
    return StreamBuilder(
      stream: source.rebuild,
      builder: (context, _) {
        final works = source.items.take(IllustRelatedPreview.shown).toList();
        final loading = works.isEmpty && source.lastError == null && !source.initialized;
        final Widget body = switch (source.phase) {
          _ when works.isNotEmpty => _RelatedTiles(children: [for (final work in works) AppArtworkCard.tile(illust: work)]),
          _ when source.lastError != null => Row(
            children: [
              Expanded(
                child: FrostText(t.illust.related.failed, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
              ),
              FrostButton.quiet(label: t.common.retry, onPressed: () => unawaited(source.refresh(true))),
            ],
          ),
          _ when source.initialized => FrostText(t.illust.related.empty, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
          _ => const _RelatedTilesSkeleton(),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FrostGap.related,
          children: [
            FrostSectionHeader(
              title: t.illust.section.relatedWorks,
              actionLabel: works.isEmpty ? null : t.illustDetail.moreRelated,
              onAction: works.isEmpty ? null : () => unawaited(GoRouter.of(context).push(AppLocations.illustRelated(widget.illust.id), extra: widget.illust)),
              trailing: loading ? const [_RelatedMoreBone()] : const [],
            ),
            body,
          ],
        );
      },
    );
  }
}

/// The heading (title, author line, actions, meta line) of a work not yet
/// loaded, laid out as [IllustInfoHeading] lays out the loaded one.
class IllustInfoHeadingSkeleton extends ConsumerWidget {
  const IllustInfoHeadingSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final illust = illustPlaceholder();
    final pages = artworkPages(illust, ref.watch(viewerImageQualityProvider), ref.watch(previewImageQualityProvider));
    return appBones(
      IllustInfoHeading(
        info: IllustInfoContext(illust: illust, pages: pages, page: 0),
      ),
    );
  }
}

/// The tags and the Details row of a work not yet loaded.
class IllustAboutSkeleton extends StatelessWidget {
  const IllustAboutSkeleton({super.key});

  @override
  Widget build(BuildContext context) => appBones(IllustAbout(illust: illustPlaceholder()));
}

/// The comments row of a work not yet loaded.
class IllustCommentsPanelSkeleton extends StatelessWidget {
  const IllustCommentsPanelSkeleton({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: appBones(FrostDisclosure(title: context.t.illust.section.commentsWithCount(count: 0), child: const SizedBox.shrink())),
  );
}

/// The author's works while they load: the same shelf of square tiles.
class IllustAuthorWorksLoading extends StatelessWidget {
  const IllustAuthorWorksLoading({super.key});

  static const tiles = 6;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: IllustAuthorWorks.gapAbove,
      child: IgnorePointer(
        child: FrostShelf(
          title: t.illust.section.recentWorks,
          inset: 0,
          action: appBones(FrostButton.quiet(label: t.home.seeMore, onPressed: () {})),
          itemCount: tiles,
          itemExtent: IllustAuthorWorks.tileExtent,
          height: IllustAuthorWorks.tileExtent,
          itemBuilder: (context, index) => FrostMediaCard.skeleton(aspectRatio: 1, footer: null),
        ),
      ),
    );
  }
}

/// Holds the place of "more" while the works load, so that the title's row
/// does not grow when it arrives.
class _RelatedMoreBone extends StatelessWidget {
  const _RelatedMoreBone();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: appBones(FrostButton.quiet(label: context.t.illustDetail.moreRelated, size: FrostControlSize.compact, onPressed: () {})),
  );
}

class _RelatedTilesSkeleton extends StatelessWidget {
  const _RelatedTilesSkeleton();

  @override
  Widget build(BuildContext context) =>
      _RelatedTiles(children: [for (var index = 0; index < IllustRelatedPreview.shown; index++) FrostMediaCard.skeleton(aspectRatio: 1, footer: null)]);
}

/// Equal squares in as many columns as fit the width it is given. FrostGrid
/// sets aside the sidebar's width for the page's own column, which would leave
/// one column in the info column beside the picture.
class _RelatedTiles extends StatelessWidget {
  const _RelatedTiles({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final gap = FrostGap.of(context).grid;
    final minimum = IllustRelatedPreview.tileMinWidth * math.max(1.0, MediaQuery.textScalerOf(context).scale(14) / 14);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(1, ((constraints.maxWidth + gap) / (minimum + gap)).floor());
        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          rows.add(
            Row(
              spacing: gap,
              children: [
                for (var index = start; index < start + columns; index++)
                  Expanded(child: AspectRatio(aspectRatio: 1, child: index < children.length ? children[index] : null)),
              ],
            ),
          );
        }
        return Column(spacing: gap, children: rows);
      },
    );
  }
}

/// The related works while they load.
class IllustRelatedLoading extends StatelessWidget {
  const IllustRelatedLoading({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FrostGap.related,
    children: [
      FrostSectionHeader(title: context.t.illust.section.relatedWorks, trailing: const [_RelatedMoreBone()]),
      const _RelatedTilesSkeleton(),
    ],
  );
}
