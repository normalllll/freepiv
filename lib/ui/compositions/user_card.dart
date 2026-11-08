import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// Narrowest a user card may be: room for the name, Follow and three works.
const _minTileWidth = 380.0;

/// Columns of user cards at most, however wide the window.
const _maxColumns = 5;

/// Works across the top of a card at most; slots without a work stay empty.
const _slots = 3;

const _padding = FrostGap.related;
const _stripGap = FrostGap.inline;
const _sectionGap = FrostGap.related;
const _identityGap = FrostGap.related;
const _lineGap = 2.0;

/// The size a card's avatar is drawn at, and its height in the row.
const _avatarSize = FrostAvatarSize.large;
const _avatarExtent = 40.0;

/// Follow moves under the name on a card narrower than this inside, or at
/// [_stackedTextScale] and above, so the name is never squeezed.
const _stackedBelowWidth = 300.0;
const _stackedTextScale = 1.5;

bool _stacked(BuildContext context, double inner) => inner < _stackedBelowWidth || MediaQuery.textScalerOf(context).scale(1) >= _stackedTextScale;

double _line(BuildContext context, FrostTextRole role) {
  final style = FrostTypography.of(context).style(role);
  return MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
}

double _identityExtent(BuildContext context) =>
    math.max(_avatarExtent, _line(context, FrostTextRole.headline) + _lineGap + _line(context, FrostTextRole.footnote));

/// Columns of user cards across [crossAxisExtent]: as many as keep a card
/// [_minTileWidth] wide, one on a phone, [_maxColumns] at most.
int _columns(BuildContext context, double crossAxisExtent) =>
    math.min(_maxColumns, FrostSliverDataGrid.geometry(context, crossAxisExtent, minTileWidth: _minTileWidth).columns);

/// A user in a waterfall, as tall as what they have to
/// show: up to three square works across the top, faint empty tiles where
/// there are fewer and no strip at all without works, then avatar, name and
/// @account with Follow at the end, under them when the card is narrow. The
/// card opens the user, a work opens that work.
class AppUserCard extends StatelessWidget {
  const AppUserCard({required this.preview, super.key});

  final UserPreview preview;

  @override
  Widget build(BuildContext context) {
    final user = preview.user;
    final radius = BorderRadius.circular(FrostRadius.lg);
    final works = preview.illusts.take(_slots).toList(growable: false);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: _sectionGap,
            children: [
              if (works.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: _stripGap,
                  children: [
                    for (var slot = 0; slot < _slots; slot++)
                      Expanded(
                        child: slot < works.length ? AppArtworkCard.tile(illust: works[slot]) : FrostMediaFrame(aspectRatio: 1, child: const SizedBox.expand()),
                      ),
                  ],
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = _stacked(context, constraints.maxWidth);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: _identityGap,
                    children: [
                      Row(
                        spacing: _identityGap,
                        children: [
                          AppUserAvatar(user: user, size: _avatarSize),
                          Expanded(child: _Names(user: user)),
                          if (!stacked) AppFollowButton(user: user, prominent: false),
                        ],
                      ),
                      if (stacked)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: AppFollowButton(user: user, prominent: false),
                        ),
                    ],
                  );
                },
              ),
            ],
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
    mainAxisSize: MainAxisSize.min,
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

/// Users as a waterfall of cards, with its skeleton.
class AppSliverUserGrid extends StatelessWidget {
  const AppSliverUserGrid({required this.source, this.empty, super.key});

  final FrostListSource<UserPreview> source;
  final Widget? empty;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) => FrostSliverDataWaterfallGrid<UserPreview>(
      source: source,
      firstLoadSkeleton: const AppUserCardsSkeleton(),
      empty: empty,
      preferredTileWidth: _minTileWidth,
      columns: _columns(context, constraints.crossAxisExtent),
      maxColumns: _maxColumns,
      itemBuilder: (context, preview, index) => AppUserCard(preview: preview),
    ),
  );
}

/// [AppSliverUserGrid] while it loads: real cards painted as bones in the same
/// columns, tall and short together, running past the bottom of the window.
class AppUserCardsSkeleton extends StatelessWidget {
  const AppUserCardsSkeleton({super.key});

  /// Works on each placeholder card in turn.
  static const _works = [3, 3, 0, 3, 1, 3, 0, 2];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = _columns(context, constraints.maxWidth);
      final previews = {for (final works in _works) works: userPreviewPlaceholder(works: works)};
      final shortest = _identityExtent(context) + _padding * 2 + FrostGap.grid;
      return appBones(
        FrostWaterfallGrid<int>(
          items: List.generate(appSkeletonCount(context, shortestExtent: shortest, perRow: columns), (index) => index),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          preferredTileWidth: _minTileWidth,
          columns: columns,
          maxColumns: _maxColumns,
          itemBuilder: (context, _, index) => AppUserCard(preview: previews[_works[index % _works.length]]!),
        ),
      );
    },
  );
}
