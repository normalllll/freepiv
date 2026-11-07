import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/illust/presentation/artwork_actions.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
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
List<Widget> artworkRestrictionBadges(BuildContext context, Illust illust) {
  final t = context.t;
  return [
    if (illust.xRestrict == 1) const FrostBadge(label: 'R-18', tone: FrostBadgeTone.negative, style: FrostBadgeStyle.solid),
    if (illust.xRestrict >= 2) const FrostBadge(label: 'R-18G', tone: FrostBadgeTone.negative, style: FrostBadgeStyle.solid),
    if (illust.illustAiType == 2) FrostBadge(label: t.artworkCard.ai, tone: FrostBadgeTone.onMedia),
  ];
}

/// A work in a feed, a shelf or a grid: only the image,
/// its corner marks and the always-shown bookmark button. The title and the
/// author live in the card's menu and on the detail page.
class AppArtworkCard extends ConsumerWidget {
  const AppArtworkCard({required this.illust, this.rank, this.square = false, super.key});

  final Illust illust;

  /// A ranking number at the top-start corner.
  final int? rank;

  /// Square tiles (the ranking shelf) cut the same preview from its centre.
  final bool square;

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
          bottomEnd: AppCardBookmarkButton(workId: illust.id, initiallyBookmarked: illust.isBookmarked),
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

/// A work as a small square in a row (a user's works): the feeds' preview
/// cut from its centre, so opening it shows the cached image at once and
/// it flies into the stage.
class AppArtworkThumbnail extends ConsumerWidget {
  const AppArtworkThumbnail({required this.illust, super.key});

  final Illust illust;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = illustPreviewImageUrl(illust.imageUrls, ref.watch(previewImageQualityProvider));
    Widget thumbnail(FrostMediaHeroTag? tag) {
      final image = AppPixivImage(url: url, aspectRatio: 1, radius: 0);
      return Builder(
        builder: (thumbnailContext) => FrostThumbnail(
          size: FrostThumbnailSize.small,
          semanticLabel: illust.title,
          image: tag == null ? image : FrostMediaHero(tag: tag, child: image),
          onPressed: () => openArtwork(thumbnailContext, illust, tag),
        ),
      );
    }

    if (url.isEmpty) return thumbnail(null);
    return FrostMediaHeroSource(
      image: pixivImageProvider(ref, url),
      aspectRatio: artworkAspectRatio(illust),
      identity: illust.id,
      builder: (context, tag) => thumbnail(tag),
    );
  }
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

/// First-load placeholders the size of a feed's cards.
class AppArtworkWaterfallSkeleton extends StatelessWidget {
  const AppArtworkWaterfallSkeleton({this.count = 12, super.key});

  final int count;

  static const _ratios = [.75, 1.0, .66, 1.33, .8, 1.0];

  @override
  Widget build(BuildContext context) => FrostWaterfallGrid<int>(
    items: List.generate(count, (index) => index),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (context, _, index) => FrostMediaCard.skeleton(aspectRatio: _ratios[index % _ratios.length], footer: null),
  );
}
