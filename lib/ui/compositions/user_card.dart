import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// Narrowest a user card may be: room for the name, Follow and three works.
const _minTileWidth = 340.0;

/// Works across the top of a card at most. The strip always has the height
/// of this many square works; fewer share its width.
const _slots = 3;

const _padding = FrostGap.related;
const _stripGap = FrostGap.inline;
const _sectionGap = FrostGap.related;
const _identityGap = FrostGap.related;
const _lineGap = 2.0;

/// The size a card's avatar is drawn at, and its height in the row.
const _avatarSize = FrostAvatarSize.large;
const _avatarExtent = 40.0;

/// The tallest target Frost gives a button, on touch.
const _followExtent = 44.0;

/// Follow moves under the name on a card narrower than this inside, or at
/// [_stackedTextScale] and above, so the name is never squeezed.
const _stackedBelowWidth = 300.0;
const _stackedTextScale = 1.5;

bool _stacked(BuildContext context, double inner) => inner < _stackedBelowWidth || MediaQuery.textScalerOf(context).scale(1) >= _stackedTextScale;

double _line(BuildContext context, FrostTextRole role) {
  final style = FrostTypography.of(context).style(role);
  return MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
}

double _stripExtent(double inner) => (inner - _stripGap * (_slots - 1)) / _slots;

double _identityExtent(BuildContext context) =>
    math.max(_avatarExtent, _line(context, FrostTextRole.headline) + _lineGap + _line(context, FrostTextRole.footnote));

/// How tall a card [width] wide is, from the metrics it lays out with, so
/// every card in a grid row has its height whatever works its user has.
double appUserCardHeight(BuildContext context, double width) {
  final inner = width - _padding * 2;
  final identity = _identityExtent(context);
  final details = _stacked(context, inner) ? identity + _identityGap + _followExtent : math.max(identity, _followExtent);
  return (_padding * 2 + _stripExtent(inner) + _sectionGap + details).ceilToDouble();
}

/// A user in a grid: their latest works across the top,
/// then avatar, name and @account with Follow at the end, under them when
/// the card is narrow. The card opens the user, a work opens that work.
class AppUserCard extends StatelessWidget {
  const AppUserCard({required this.preview, super.key});

  final UserPreview preview;

  @override
  Widget build(BuildContext context) {
    final user = preview.user;
    final radius = BorderRadius.circular(FrostRadius.lg);
    return FrostSurface(
      role: FrostSurfaceRole.module,
      edge: FrostSurfaceEdge.none,
      elevated: false,
      borderRadius: radius,
      child: FrostClickSurface(
        shape: FrostClickShape.rounded(radius),
        onTap: () => unawaited(GoRouter.of(context).push(AppLocations.user(user.id))),
        child: Padding(
          padding: const EdgeInsets.all(_padding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final inner = constraints.maxWidth;
              final stacked = _stacked(context, inner);
              final identity = SizedBox(
                height: _identityExtent(context),
                child: Row(
                  spacing: _identityGap,
                  children: [
                    AppUserAvatar(user: user, size: _avatarSize),
                    Expanded(child: _Names(user: user)),
                    if (!stacked) AppFollowButton(user: user, prominent: false),
                  ],
                ),
              );
              final details = Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: _identityGap,
                children: [
                  identity,
                  if (stacked)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppFollowButton(user: user, prominent: false),
                    ),
                ],
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: _sectionGap,
                children: [
                  SizedBox(
                    height: _stripExtent(inner),
                    child: _Works(works: preview.illusts.take(_slots).toList(growable: false), width: inner, height: _stripExtent(inner)),
                  ),
                  // In a grid the height comes from [appUserCardHeight].
                  if (constraints.hasBoundedHeight) Expanded(child: details) else details,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Names extends StatelessWidget {
  const _Names({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: _lineGap,
    children: [
      SizedBox(
        height: _line(context, FrostTextRole.headline),
        child: FrostText(user.name, content: true, role: FrostTextRole.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      SizedBox(
        height: _line(context, FrostTextRole.footnote),
        child: FrostText('@${user.account}', role: FrostTextRole.footnote, tone: FrostTextTone.secondary, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

/// The strip of works: each fills its share of the width at the strip's
/// height, or a quiet note where the user has none.
class _Works extends StatelessWidget {
  const _Works({required this.works, required this.width, required this.height});

  final List<Illust> works;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    if (works.isEmpty) {
      return Center(
        child: FrostText(
          context.t.user.noPublicWorks,
          role: FrostTextRole.footnote,
          tone: FrostTextTone.secondary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    final slot = (width - _stripGap * (works.length - 1)) / works.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: _stripGap,
      children: [
        for (final illust in works)
          Expanded(
            child: AppArtworkCard.tile(illust: illust, tileRatio: slot / height),
          ),
      ],
    );
  }
}

/// Users as a responsive grid of equal cards, with its skeleton.
class AppSliverUserGrid extends StatelessWidget {
  const AppSliverUserGrid({required this.source, this.empty, super.key});

  final FrostListSource<UserPreview> source;
  final Widget? empty;

  @override
  Widget build(BuildContext context) => FrostSliverDataGrid<UserPreview>(
    source: source,
    firstLoadSkeleton: const AppUserCardsSkeleton(),
    empty: empty,
    minTileWidth: _minTileWidth,
    tileHeight: appUserCardHeight,
    itemBuilder: (context, preview, index) => AppUserCard(preview: preview),
  );
}

/// [AppSliverUserGrid] while it loads: real cards painted as bones in the
/// same columns, running past the bottom of the window.
class AppUserCardsSkeleton extends StatelessWidget {
  const AppUserCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = FrostSliverDataGrid.geometry(context, constraints.maxWidth, minTileWidth: _minTileWidth);
      final height = appUserCardHeight(context, layout.tileWidth);
      final rows = appSkeletonCount(context, shortestExtent: height);
      final preview = userPreviewPlaceholder();
      return Padding(
        padding: layout.padding,
        child: appBones(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostGap.grid,
            children: [
              for (var row = 0; row < rows; row++)
                SizedBox(
                  height: height,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: FrostGap.grid,
                    children: [for (var column = 0; column < layout.columns; column++) Expanded(child: AppUserCard(preview: preview))],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
