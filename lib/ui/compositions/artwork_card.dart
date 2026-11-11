import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/illust/presentation/artwork_actions.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/bookmark_options.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// What the illustration route receives from a card: the work, and the tag
/// its image flies with.
typedef ArtworkRouteExtra = ({Illust illust, FrostMediaHeroTag heroTag});

/// Pushes the illustration page for [illust]. With the opening card's
/// [heroTag] the card's image flies into the stage and back.
void openArtwork(BuildContext context, Illust illust, [FrostMediaHeroTag? heroTag]) {
  unawaited(GoRouter.of(context).push(AppLocations.illust(illust.id), extra: heroTag == null ? illust : (illust: illust, heroTag: heroTag)));
}

/// The aspect ratio a work's preview is shown at.
double artworkAspectRatio(Illust illust) => illust.width > 0 && illust.height > 0 ? illust.width / illust.height : 1;

/// The corner marks of a work: R-18, R-18G and AI.
List<Widget> artworkRestrictionBadges(BuildContext context, Illust illust) =>
    workRestrictionBadges(context, xRestrict: illust.xRestrict, aiGenerated: illust.illustAiType == 2);

/// The corner marks of a work given by what they show.
List<Widget> workRestrictionBadges(BuildContext context, {required int xRestrict, required bool aiGenerated}) {
  final t = context.t;
  return [
    if (xRestrict == 1) const FrostBadge(label: 'R-18', tone: FrostBadgeTone.negative, style: FrostBadgeStyle.solid),
    if (xRestrict >= 2) const FrostBadge(label: 'R-18G', tone: FrostBadgeTone.negative, style: FrostBadgeStyle.solid),
    if (aiGenerated) FrostBadge(label: t.artworkCard.ai, tone: FrostBadgeTone.onMedia),
  ];
}

/// A work in a feed, a shelf or a grid: the image with its
/// corner marks, then the title and the author with the bookmark button at
/// the end of that text.
class AppArtworkCard extends ConsumerWidget {
  const AppArtworkCard({required this.illust, this.rank, this.square = false, super.key}) : tile = false;

  /// A small square of the work in a strip (a work's "Recent works"): the
  /// image with its corner marks, without the title, author and bookmark.
  const AppArtworkCard.tile({required this.illust, super.key}) : rank = null, square = true, tile = true;

  final Illust illust;

  /// A ranking number at the top-start corner.
  final int? rank;

  /// Square tiles (the ranking shelf) cut the same preview from its centre.
  final bool square;

  /// The image alone, see [AppArtworkCard.tile].
  final bool tile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final url = illustPreviewImageUrl(illust.imageUrls, ref.watch(previewImageQualityProvider));
    final ratio = square ? 1.0 : artworkAspectRatio(illust);
    final topStart = [if (rank case final rank?) FrostBadge(label: '$rank', tone: FrostBadgeTone.onMedia), ...artworkRestrictionBadges(context, illust)];
    final ugoira = illust.kind == 'ugoira';
    Widget card(FrostMediaHeroTag? tag) {
      final image = AppPixivImage(url: url, aspectRatio: ratio, radius: 0);
      return Builder(
        builder: (cardContext) => FrostMediaCard(
          media: tag == null ? image : FrostMediaHero(tag: tag, child: image),
          aspectRatio: ratio,
          topStart: topStart.isEmpty ? null : Wrap(spacing: FrostGap.inline, runSpacing: FrostGap.inline, children: topStart),
          topEnd: ugoira
              ? FrostBadge(label: t.artworkCard.ugoira, icon: PivIcons.play, tone: FrostBadgeTone.onMedia)
              : illust.pageCount > 1
              ? FrostBadge(label: '${illust.pageCount}', icon: PivIcons.images, tone: FrostBadgeTone.onMedia)
              : null,
          footer: tile
              ? null
              : AppArtworkCardFooter(
                  title: illust.title,
                  author: illust.user.name,
                  bookmark: AppCardBookmarkButton(workId: illust.id, initiallyBookmarked: illust.isBookmarked),
                ),
          semanticLabel: t.artworkCard.semantics(title: illust.title, author: illust.user.name),
          onPressed: () => openArtwork(cardContext, illust, tag),
          contextMenu: artworkMenu(cardContext, ref, illust),
        ),
      );
    }

    if (url.isEmpty) return card(null);
    return FrostMediaHeroSource(
      image: pixivImageProvider(ref, url),
      aspectRatio: artworkAspectRatio(illust),
      identity: illust.id,
      builder: (context, tag) => card(tag),
    );
  }
}

/// The text under a work's card: its title on one line and its author below
/// it, with [bookmark] at the end when there is one.
class AppArtworkCardFooter extends StatelessWidget {
  const AppArtworkCardFooter({required this.title, required this.author, this.bookmark, super.key});

  final String title;
  final String author;

  /// The button at the end of the text; none for a card that cannot bookmark.
  final Widget? bookmark;

  /// How much a card's footer adds below its image, for rows of cards that
  /// need a fixed height (shelves).
  static double extentOf(BuildContext context) =>
      // Frost puts eight pixels between the image and the footer.
      8 + _height(context);

  /// One line of [role] at the current text scale. Fixed line boxes keep
  /// every card the same height whatever a font rounds its metrics to.
  static double _line(BuildContext context, FrostTextRole role) {
    final style = FrostTypography.of(context).style(role);
    return MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
  }

  static double _height(BuildContext context) =>
      math.max(_line(context, FrostTextRole.subheadline) + _gap + _line(context, FrostTextRole.footnote), FrostControlSize.compact.height(context));

  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _height(context),
    child: Row(
      spacing: FrostGap.inline,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: _gap,
            children: [
              SizedBox(
                height: _line(context, FrostTextRole.subheadline),
                child: FrostText(title, role: FrostTextRole.subheadline, content: true, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                height: _line(context, FrostTextRole.footnote),
                child: FrostText(
                  author,
                  role: FrostTextRole.footnote,
                  tone: FrostTextTone.secondary,
                  content: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        ?bookmark,
      ],
    ),
  );
}

/// The right-click / long-press menu of a work's card: its title and author
/// as the header, then the author, download, copy link and open on Pixiv.
List<FrostMenuEntry> artworkMenu(BuildContext context, WidgetRef ref, Illust illust) {
  final t = context.t;
  return [
    FrostMenuSection(
      header: t.artworkCard.menuHeader(title: illust.title, author: illust.user.name),
      entries: [
        FrostMenuAction(
          t.artworkCard.openAuthor,
          leading: const FrostGlyph.icon(PivIcons.user),
          onSelected: () => unawaited(GoRouter.of(context).push(AppLocations.user(illust.user.id))),
        ),
        if (illust.kind != 'ugoira')
          FrostMenuAction(
            t.illust.contextMenu.download,
            leading: const FrostGlyph.icon(PivIcons.download),
            onSelected: () => unawaited(
              downloadArtwork(
                illust,
                quality: ref.read(viewerImageQualityProvider),
                previewQuality: ref.read(previewImageQualityProvider),
                origin: context.mounted ? DownloadFlight.originOf(context) : null,
              ),
            ),
          ),
        ...bookmarkOptionsMenuEntries(context, workId: illust.id, initiallyBookmarked: illust.isBookmarked),
        FrostMenuAction(t.illust.contextMenu.copyLink, leading: const FrostGlyph.icon(PivIcons.link), onSelected: () => unawaited(copyArtworkLink(illust.id))),
        FrostMenuAction(
          t.illust.contextMenu.openOriginal,
          leading: const FrostGlyph.icon(PivIcons.externalLink),
          onSelected: () => unawaited(openArtworkOnPixiv(illust.id)),
        ),
      ],
    ),
  ];
}

/// A work's card while it loads, the height and shape of the loaded one: the
/// frame of its image, then its title, author and bookmark as bones.
class AppArtworkCardSkeleton extends StatelessWidget {
  const AppArtworkCardSkeleton({required this.aspectRatio, super.key});

  final double aspectRatio;

  @override
  Widget build(BuildContext context) => Semantics(
    label: FrostScope.labelsOf(context).loading,
    excludeSemantics: true,
    child: IgnorePointer(
      child: FrostMediaCard(
        aspectRatio: aspectRatio,
        // Frost records the shading inside the media clip this way.
        media: FrostMediaFrame.skeleton(aspectRatio: null),
        footer: AppArtworkCardFooter(
          title: 'A work title',
          author: 'Sample artist',
          bookmark: FrostButton.icon(icon: PivIcons.heart, label: context.t.illust.tooltip.addBookmark, size: FrostControlSize.compact, onPressed: () {}),
        ).frostSkeleton(true),
      ),
    ),
  );
}

/// First-load placeholders the size of a feed's cards.
class AppArtworkWaterfallSkeleton extends StatelessWidget {
  const AppArtworkWaterfallSkeleton({this.count, this.padding, super.key});

  /// Null fills the window; a number is for a short fixed preview.
  final int? count;

  /// The padding of the grid it stands for; null keeps the grid's own.
  final EdgeInsetsGeometry? padding;

  static const _ratios = [.75, 1.0, .66, 1.33, .8, 1.0];
  static const _widest = 1.33;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => FrostWaterfallGrid<int>(
      items: List.generate(
        count ?? appWaterfallSkeletonCount(context, width: constraints.maxWidth, widestRatio: _widest, footerExtent: AppArtworkCardFooter.extentOf(context)),
        (index) => index,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemBuilder: (context, _, index) => AppArtworkCardSkeleton(aspectRatio: _ratios[index % _ratios.length]),
    ),
  );
}
