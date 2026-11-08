import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// A Pixiv user's avatar, with their initial while there is no picture.
class AppUserAvatar extends ConsumerWidget {
  const AppUserAvatar({required this.user, this.size = FrostAvatarSize.regular, super.key});

  final User user;
  final FrostAvatarSize size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = user.profileImageUrls.medium;
    return FrostAvatar.person(name: user.name, colorKey: '${user.id}', size: size, image: url.isEmpty ? null : pixivImageProvider(ref, url));
  }
}

/// A novel in a reading-column list: cover, title,
/// author, two lines of its caption, its length, a few tags and bookmark.
class AppNovelRow extends StatelessWidget {
  const AppNovelRow({required this.novel, this.rank, this.showAuthor = true, super.key});

  final Novel novel;

  /// A ranking number before the title.
  final int? rank;
  final bool showAuthor;

  static const coverWidth = 72.0;

  /// The width of a cover to its height.
  static const coverRatio = 1 / 1.414;
  static const _shownTags = 3;

  @override
  Widget build(BuildContext context) => FrostClickSurface(
    onTap: () => unawaited(GoRouter.of(context).push(AppLocations.novel(novel.id), extra: novel)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
      child: _content(context),
    ),
  );

  /// What a novel shows, in a row of a list or a card.
  Widget _content(BuildContext context) {
    final t = context.t;
    final caption = plainTextFromHtml(novel.caption).trim();
    final title = rank == null ? novel.title : '$rank. ${novel.title}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FrostGap.group,
      children: [
        SizedBox(
          width: coverWidth,
          child: AppPixivImage(url: novel.imageUrls.medium, aspectRatio: coverRatio, radius: FrostRadius.md),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FrostGap.inline,
            children: [
              FrostText(title, content: true, role: FrostTextRole.headline, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (showAuthor)
                FrostText(
                  novel.user.name,
                  content: true,
                  role: FrostTextRole.footnote,
                  tone: FrostTextTone.secondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (caption.isNotEmpty)
                FrostText(caption, content: true, role: FrostTextRole.footnote, tone: FrostTextTone.secondary, maxLines: 2, overflow: TextOverflow.ellipsis),
              FrostMetaLine(
                items: [
                  t.user.meta.novelChars(count: novel.textLength),
                  ?novel.series.title,
                ],
              ),
              if (novel.tags.isNotEmpty)
                FrostWrap(
                  children: [
                    for (final tag in novel.tags.take(_shownTags))
                      FrostTag(
                        label: '#${tag.name}',
                        style: FrostTagStyle.topic,
                        onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.tagSearch(tag.name, kind: AppSearchKind.novel))),
                      ),
                  ],
                ),
            ],
          ),
        ),
        AppRowBookmarkButton(workId: novel.id, initiallyBookmarked: novel.isBookmarked, novel: true),
      ],
    );
  }
}

/// Narrowest a novel card may be: room for the cover and two lines of caption.
const _novelCardMinWidth = 480.0;

/// Columns of novel cards at most, however wide the window.
const _novelCardMaxColumns = 3;

const _novelCardPadding = FrostGap.group;

/// Columns of novel cards across [crossAxisExtent]: as many as keep a card
/// [_novelCardMinWidth] wide, one at the least, [_novelCardMaxColumns] at most.
int _novelCardColumns(BuildContext context, double crossAxisExtent) =>
    math.min(_novelCardMaxColumns, FrostSliverDataGrid.geometry(context, crossAxisExtent, minTileWidth: _novelCardMinWidth).columns);

/// A novel as a card in a waterfall, showing what [AppNovelRow] shows.
class AppNovelCard extends StatelessWidget {
  const AppNovelCard({required this.novel, super.key});

  final Novel novel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FrostRadius.lg);
    return FrostSurface(
      role: FrostSurfaceRole.module,
      edge: FrostSurfaceEdge.none,
      elevated: false,
      borderRadius: radius,
      child: FrostClickSurface(
        shape: FrostClickShape.rounded(radius),
        onTap: () => unawaited(GoRouter.of(context).push(AppLocations.novel(novel.id), extra: novel)),
        child: Padding(
          padding: const EdgeInsets.all(_novelCardPadding),
          child: AppNovelRow(novel: novel)._content(context),
        ),
      ),
    );
  }
}

/// Novels as a waterfall of cards across the full content width.
class AppSliverNovelGrid extends StatelessWidget {
  const AppSliverNovelGrid({required this.source, this.empty, super.key});

  final FrostListSource<Novel> source;
  final Widget? empty;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) => FrostSliverDataWaterfallGrid<Novel>(
      source: source,
      firstLoadSkeleton: const AppNovelCardsSkeleton(),
      empty: empty,
      preferredTileWidth: _novelCardMinWidth,
      columns: _novelCardColumns(context, constraints.crossAxisExtent),
      maxColumns: _novelCardMaxColumns,
      itemBuilder: (context, novel, index) => AppNovelCard(novel: novel),
    ),
  );
}

/// [AppSliverNovelGrid] while it loads: real cards painted as bones in the same
/// columns, running past the bottom of the window.
class AppNovelCardsSkeleton extends StatelessWidget {
  const AppNovelCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = _novelCardColumns(context, constraints.maxWidth);
      final novel = novelPlaceholder();
      final shortest = AppNovelRow.coverWidth / AppNovelRow.coverRatio + _novelCardPadding * 2 + FrostGap.grid;
      return appBones(
        FrostWaterfallGrid<int>(
          items: List.generate(appSkeletonCount(context, shortestExtent: shortest, perRow: columns), (index) => index),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          preferredTileWidth: _novelCardMinWidth,
          columns: columns,
          maxColumns: _novelCardMaxColumns,
          itemBuilder: (context, _, index) => AppNovelCard(novel: novel),
        ),
      );
    },
  );
}

/// First-load placeholders for a list of rows.
class AppRowsSkeleton extends StatelessWidget {
  const AppRowsSkeleton({this.count, this.subtitle = true, super.key});

  /// Null fills the window; a number is for a short fixed preview.
  final int? count;
  final bool subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < (count ?? appSkeletonCount(context, shortestExtent: FrostControlSize.regular.height(context))); index++)
        FrostListRow.skeleton(title: 'Sample user name', icon: true, subtitle: subtitle ? '@sample_account' : null, value: null),
    ],
  );
}

/// First-load placeholders for a list of novels: [AppNovelRow] with its cover.
class AppNovelRowsSkeleton extends StatelessWidget {
  const AppNovelRowsSkeleton({this.count, this.showAuthor = true, super.key});

  /// Null fills the window; a number is for a short fixed preview.
  final int? count;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final novel = novelPlaceholder();
    final rows = count ?? appSkeletonCount(context, shortestExtent: AppNovelRow.coverWidth / AppNovelRow.coverRatio);
    return appBones(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var index = 0; index < rows; index++) AppNovelRow(novel: novel, showAuthor: showAuthor)],
      ),
    );
  }
}
