import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/features/comments/presentation/comment_thread_item.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/logic/ugoira_playback.dart';
import 'package:freepiv/features/illust/presentation/artwork_actions.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/loading_section.dart';
import 'package:freepiv/ui/compositions/pixiv_text.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/social.dart' show FrostThread;
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

  final IllustInfoContext info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final illust = info.illust;
    final page = info.pages[info.page.clamp(0, info.pages.length - 1)];
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
        FrostButton.icon(icon: PivIcons.link, label: t.illust.contextMenu.copyLink, onPressed: () => unawaited(copyArtworkLink(illust.id))),
        FrostMenuAnchor(
          entries: illustMoreMenu(context, info),
          builder: (context, focusNode, toggle) => FrostButton.icon(icon: PivIcons.more, label: FrostScope.labelsOf(context).more, onPressed: toggle),
        ),
      ],
    );
  }
}

/// More: download every page, copy the picture (desktop), open on Pixiv,
/// copy the ID; for an animation, the GIF instead of the pages.
List<FrostMenuEntry> illustMoreMenu(BuildContext context, IllustInfoContext info) {
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
                  contextMenu: [
                    FrostMenuAction(
                      t.illustDetail.copyTag,
                      leading: const FrostGlyph.icon(PivIcons.copy),
                      onSelected: () => unawaited(_copy(t.illust.tags.tag, tag.name)),
                    ),
                  ],
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

  Future<void> _copy(String label, String value) async {
    try {
      await copyTextToClipboard(value);
      FrostToast.copied(t.illust.toast.copiedValue(label: label, value: value));
    } catch (error) {
      toastErrorWithCause(t.illust.toast.copyFailed(label: label), error);
    }
  }
}

/// The first comments and the way to all of them.
class IllustCommentsPreview extends ConsumerWidget {
  const IllustCommentsPreview({required this.illust, super.key});

  final Illust illust;

  /// Comments the preview shows.
  static const shown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = illustCommentsProvider(illust.id);
    final total = illust.totalComments;
    final value = ref.watch(provider);
    if (value.isLoading && !value.hasValue) return IllustCommentsLoading(total: total);
    return AppCommentsPreview(
      value: value,
      total: total,
      onRetry: () => unawaited(ref.read(provider.notifier).reload()),
      location: AppLocations.illustComments(illust.id),
    );
  }
}

/// The author's other works on a shelf, with the way to their page.
class IllustAuthorWorks extends ConsumerWidget {
  const IllustAuthorWorks({required this.illust, super.key});

  final Illust illust;

  static const tileExtent = 120.0;

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
            return FrostShelf(
              title: t.illust.section.recentWorks,
              inset: 0,
              action: FrostButton.quiet(label: t.home.seeMore, onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.user(illust.user.id)))),
              itemCount: works.length,
              itemExtent: tileExtent,
              height: tileExtent,
              itemBuilder: (context, index) => AppArtworkCard.tile(illust: works[index]),
            );
          },
          loading: () => const IllustAuthorWorksLoading(),
          error: (error, _) => AppLoadingSection(
            title: t.illust.section.recentWorks,
            value: AsyncError<void>(error, StackTrace.empty),
            onRetry: () => unawaited(ref.read(provider.notifier).reload()),
            failed: t.illust.works.failed,
            builder: (_) => const SizedBox(),
          ),
        );
  }
}

/// Eight related works and the way to all of them.
class IllustRelatedPreview extends ConsumerStatefulWidget {
  const IllustRelatedPreview({required this.illust, super.key});

  final Illust illust;

  static const shown = 8;

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
        final Widget body = switch (source.phase) {
          _ when works.isNotEmpty => FrostWaterfallGrid<Illust>(
            items: works,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemBuilder: (context, work, index) => AppArtworkCard(illust: work),
          ),
          _ when source.lastError != null => Row(
            children: [
              Expanded(
                child: FrostText(t.illust.related.failed, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
              ),
              FrostButton.quiet(label: t.common.retry, onPressed: () => unawaited(source.refresh(true))),
            ],
          ),
          _ when source.initialized => FrostText(t.illust.related.empty, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
          _ => const AppArtworkWaterfallSkeleton(count: 4, padding: EdgeInsets.zero),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FrostGap.related,
          children: [
            FrostSectionHeader(
              title: t.illust.section.relatedWorks,
              actionLabel: works.isEmpty ? null : t.illustDetail.moreRelated,
              onAction: works.isEmpty ? null : () => unawaited(GoRouter.of(context).push(AppLocations.illustRelated(widget.illust.id), extra: widget.illust)),
            ),
            body,
          ],
        );
      },
    );
  }
}

/// A work of usual size standing in while the real one loads. Only its
/// geometry is ever seen: everything built from it is painted as bones.
Illust illustPlaceholder({int id = 0}) => Illust(
  id: id,
  title: 'A work title',
  kind: 'illust',
  imageUrls: const ImageUrls(squareMedium: '', medium: '', large: ''),
  caption: '',
  restrict: 0,
  user: _placeholderUser,
  tags: const [
    Tag(name: 'original'),
    Tag(name: 'landscape'),
  ],
  tools: const [],
  createDate: '2026-01-01T00:00:00+09:00',
  pageCount: 1,
  width: 1000,
  height: 1000,
  sanityLevel: 2,
  xRestrict: 0,
  metaSinglePage: const MetaSinglePage(),
  metaPages: const [],
  totalView: 1000,
  totalBookmarks: 100,
  isBookmarked: false,
  visible: true,
  isMuted: false,
  illustAiType: 1,
);

const _placeholderUser = User(
  id: 0,
  name: 'Sample artist',
  account: 'sample',
  profileImageUrls: ProfileImageUrls(medium: ''),
);

/// [child], a real layout, painted as bones: nothing in it can be pressed,
/// focused or read.
Widget _bones(Widget child) => ExcludeSemantics(
  child: IgnorePointer(child: ExcludeFocus(child: child.frostSkeleton(true))),
);

/// The heading (title, author line, actions, meta line) of a work not yet
/// loaded, laid out as [IllustInfoHeading] lays out the loaded one.
class IllustInfoHeadingSkeleton extends ConsumerWidget {
  const IllustInfoHeadingSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final illust = illustPlaceholder();
    final pages = artworkPages(illust, ref.watch(viewerImageQualityProvider), ref.watch(previewImageQualityProvider));
    return _bones(
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
  Widget build(BuildContext context) => _bones(IllustAbout(illust: illustPlaceholder()));
}

/// The comments section while its comments load: the same header, comment
/// rows as bones and the way to the comments page.
class IllustCommentsLoading extends StatelessWidget {
  const IllustCommentsLoading({this.total, super.key});

  final int? total;

  static final _comment = Comment(id: 0, comment: 'A comment of usual length', date: '2026-01-01T12:00:00+09:00', user: _placeholderUser, hasReplies: false);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final total = this.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.related,
      children: [
        AppLoadingSection<void>(
          title: total == null ? t.illust.section.comments : t.illust.section.commentsWithCount(count: total),
          value: const AsyncLoading(),
          onRetry: () {},
          failed: '',
          builder: (_) => const SizedBox.shrink(),
          skeleton: _bones(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < AppCommentsPreview.shown; index++)
                  FrostThread(item: appCommentItem(context, _comment, assets: PixivCommentAssets.empty)),
              ],
            ),
          ),
        ),
        _bones(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FrostButton.quiet(label: AppCommentsPreview.entryLabel(t, total), edgeAlignment: FrostButtonEdgeAlignment.start, onPressed: () {}),
          ),
        ),
      ],
    );
  }
}

/// The author's works while they load: the same shelf of square tiles.
class IllustAuthorWorksLoading extends StatelessWidget {
  const IllustAuthorWorksLoading({super.key});

  static const tiles = 6;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return IgnorePointer(
      child: FrostShelf(
        title: t.illust.section.recentWorks,
        inset: 0,
        action: _bones(FrostButton.quiet(label: t.home.seeMore, onPressed: () {})),
        itemCount: tiles,
        itemExtent: IllustAuthorWorks.tileExtent,
        height: IllustAuthorWorks.tileExtent,
        itemBuilder: (context, index) => FrostMediaCard.skeleton(aspectRatio: 1, footer: null),
      ),
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
      FrostSectionHeader(title: context.t.illust.section.relatedWorks),
      const AppArtworkWaterfallSkeleton(count: 4, padding: EdgeInsets.zero),
    ],
  );
}
