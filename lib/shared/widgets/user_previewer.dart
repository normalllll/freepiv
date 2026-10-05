import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/artwork_hero.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/shared/widgets/user_follow_button.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Narrowest a user card may be: room for the name, the follow button and
/// three thumbnails. The grid fits as many columns as allow this width and
/// drops to a single column on phones and narrow windows instead of
/// squeezing two cards side by side.
const _userCardMinWidth = 340.0;

/// Preview works shown per card at most. The strip always has the height of
/// this many square thumbnails, so every card has the same shape: fewer works
/// share the width, and a user without works shows a "no public works" note.
const _previewSlots = 3;

const _cardPadding = 10.0;
const _stripGap = 6.0;
const _sectionGap = 10.0;
const _avatarSize = 40.0;

/// Whether the follow action moves under the name: very narrow cards or large
/// text, so the name is never squeezed to a few characters.
bool _stackedFollow(BuildContext context, double innerWidth) => innerWidth < 300 || MediaQuery.textScalerOf(context).scale(14) >= 21;

double _lineHeight(BuildContext context, TextStyle? style) {
  final painter = TextPainter(
    text: TextSpan(text: 'Ag', style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final height = painter.height;
  painter.dispose();
  return height;
}

/// Height of a user card [width] wide, derived from the same metrics the card
/// lays out with, so a grid row of cards is exactly as tall as its content.
double userCardHeight(BuildContext context, double width) {
  final textTheme = Theme.of(context).textTheme;
  final inner = width - _cardPadding * 2;
  final strip = (inner - _stripGap * (_previewSlots - 1)) / _previewSlots;
  final identity = math.max(
    _avatarSize,
    _lineHeight(context, textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)) + _lineHeight(context, textTheme.bodySmall),
  );
  final follow = math.max(FrostMetrics.controlHeight, _lineHeight(context, textTheme.labelLarge) + 16);
  final row = _stackedFollow(context, inner) ? identity + 8 + follow : math.max(identity, follow);
  return (_cardPadding * 2 + strip + _sectionGap + row).ceilToDouble();
}

/// A user card: the user's latest works across the top, then avatar, name
/// and the follow action at the end of one row.
class UserPreviewer extends StatelessWidget {
  const UserPreviewer({required this.userPreview, super.key});

  final UserPreview userPreview;

  @override
  Widget build(BuildContext context) {
    final user = userPreview.user;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final works = userPreview.illusts.take(_previewSlots).toList(growable: false);
    return FrostCard(
      onTap: () => context.pushNamed(AppRoute.userDetail.name, pathParameters: {'id': '${user.id}'}),
      padding: const EdgeInsets.all(_cardPadding),
      child: _UserCardLayout(
        previews: [for (final illust in works) _PreviewThumb(illust: illust)],
        empty: const _NoWorksNote(),
        avatar: SizedBox.square(
          dimension: _avatarSize,
          child: PixivImage(url: user.profileImageUrls.medium, fit: BoxFit.cover, borderRadius: BorderRadius.circular(_avatarSize / 2)),
        ),
        identity: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              '@${user.account}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        follow: UserFollowButton(userId: user.id, initialIsFollowed: user.isFollowed),
      ),
    );
  }
}

class UserPreviewerSkeleton extends StatelessWidget {
  const UserPreviewerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FrostCard(
      padding: const EdgeInsets.all(_cardPadding),
      child: Skeletonizer.zone(
        child: _UserCardLayout(
          previews: [
            for (var index = 0; index < _previewSlots; index++)
              Bone(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(FrostMetrics.controlRadius)),
          ],
          empty: const SizedBox.shrink(),
          avatar: const Bone.circle(size: _avatarSize),
          identity: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _TextLineBone(width: 120, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              _TextLineBone(width: 80, style: textTheme.bodySmall),
            ],
          ),
          follow: const UserFollowButtonPlaceholder(),
        ),
      ),
    );
  }
}

/// A text line's bone: the line keeps the real text's height, and the bar only
/// covers the glyphs' body, so stacked lines keep the gap real text shows
/// instead of touching.
class _TextLineBone extends StatelessWidget {
  const _TextLineBone({required this.width, required this.style});

  final double width;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final lineHeight = painter.height;
    painter.dispose();
    final glyphs = scaler.scale(style?.fontSize ?? 14) * .72;
    return SizedBox(
      height: lineHeight,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Bone(width: width, height: glyphs, borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

/// Loaded users as a grid of equal cards in aligned rows.
class SliverUserPreviewGrid extends StatelessWidget {
  const SliverUserPreviewGrid({required this.source, super.key});

  final FrostListSource<UserPreview> source;

  @override
  Widget build(BuildContext context) {
    return FrostSliverDataGrid<UserPreview>(
      firstLoadSkeleton: const FullScreenLoadingSkeleton(),
      source: source,
      minTileWidth: _userCardMinWidth,
      tileHeight: userCardHeight,
      itemBuilder: (context, userPreview, index) => UserPreviewer(userPreview: userPreview),
    );
  }
}

/// The loading state of [SliverUserPreviewGrid]: the same columns and card
/// height, and enough rows to run past the bottom of the viewport.
class SliverUserPreviewerSkeletonGrid extends StatelessWidget {
  const SliverUserPreviewerSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final layout = FrostSliverDataGrid.geometry(context, constraints.crossAxisExtent, minTileWidth: _userCardMinWidth);
        final height = userCardHeight(context, layout.tileWidth);
        final rows = (constraints.viewportMainAxisExtent / height).ceil() + 1;
        return SliverPadding(
          padding: layout.padding,
          sliver: SliverGrid.builder(
            itemCount: layout.columns * rows,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: layout.columns,
              crossAxisSpacing: FrostMetrics.gridGap,
              mainAxisSpacing: FrostMetrics.gridGap,
              mainAxisExtent: height,
            ),
            itemBuilder: (context, index) => const UserPreviewerSkeleton(),
          ),
        );
      },
    );
  }
}

class _UserCardLayout extends StatelessWidget {
  const _UserCardLayout({required this.previews, required this.empty, required this.avatar, required this.identity, required this.follow});

  final List<Widget> previews;

  /// Shown in the strip when there are no previews.
  final Widget empty;
  final Widget avatar;
  final Widget identity;
  final Widget follow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = _stackedFollow(context, constraints.maxWidth);
        final stripHeight = (constraints.maxWidth - _stripGap * (_previewSlots - 1)) / _previewSlots;
        final identityRow = Row(
          children: [
            avatar,
            const SizedBox(width: 10),
            Expanded(child: identity),
            if (!stacked) ...[const SizedBox(width: 8), follow],
          ],
        );
        final details = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            identityRow,
            if (stacked) ...[const SizedBox(height: 8), Align(alignment: AlignmentDirectional.centerEnd, child: follow)],
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: stripHeight,
              child: previews.isEmpty
                  ? empty
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (index, preview) in previews.indexed) ...[if (index > 0) const SizedBox(width: _stripGap), Expanded(child: preview)],
                      ],
                    ),
            ),
            const SizedBox(height: _sectionGap),
            // In the grid the card's height comes from [userCardHeight]; the
            // details are centred in what is left. Outside a grid the card
            // simply sizes to its content.
            if (constraints.hasBoundedHeight) Expanded(child: details) else details,
          ],
        );
      },
    );
  }
}

class _PreviewThumb extends ConsumerWidget {
  const _PreviewThumb({required this.illust});

  final Illust illust;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(FrostMetrics.controlRadius);
    // The same uncropped preview the feeds and the detail page use, cut to
    // the slot from its centre: opening the work shows the cached image at
    // once, and it flies into the stage.
    final imageUrl = illustPreviewImageUrl(illust.imageUrls, ref.watch(previewImageQualityProvider));
    return ArtworkHeroSource(
      illust: illust,
      imageUrl: imageUrl,
      sourceRadius: radius,
      builder: (context, heroTag) => ArtworkHero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: FrostClickSurface(
            feedback: FrostClickFeedback.media,
            borderRadius: radius,
            onTap: () => openIllustDetail(context, illust, heroTag),
            child: PixivImage(url: imageUrl, fit: BoxFit.cover, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}

/// The strip of a user without public works: a quiet note in the same band,
/// so the card keeps its shape in the grid.
class _NoWorksNote extends StatelessWidget {
  const _NoWorksNote();

  @override
  Widget build(BuildContext context) {
    final tokens = FrostThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.surfaceInset, borderRadius: BorderRadius.circular(FrostMetrics.controlRadius)),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 18, color: tokens.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t.user.noPublicWorks,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
