import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
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

/// A user in a list, the same row on the home page,
/// search results, an author's following and the following list: avatar,
/// name, @account, up to three works where there is room, and Follow, which
/// never opens the row.
class AppUserRow extends StatelessWidget {
  const AppUserRow({required this.preview, super.key});

  final UserPreview preview;

  /// Narrower rows leave the works out.
  static const worksFrom = 520.0;

  @override
  Widget build(BuildContext context) {
    final user = preview.user;
    return LayoutBuilder(
      builder: (context, constraints) {
        final works = constraints.maxWidth >= worksFrom ? preview.illusts.take(3).toList() : const <Illust>[];
        return FrostListRow(
          title: user.name,
          contentTitle: true,
          subtitle: FrostRowSubtitle('@${user.account}'),
          leading: FrostLeading.custom(AppUserAvatar(user: user)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: FrostGap.related,
            children: [
              for (final illust in works) AppArtworkThumbnail(illust: illust),
              AppFollowButton(user: user, prominent: false),
            ],
          ),
          onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.user(user.id))),
        );
      },
    );
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
  Widget build(BuildContext context) {
    final t = context.t;
    final caption = plainTextFromHtml(novel.caption).trim();
    final title = rank == null ? novel.title : '$rank. ${novel.title}';
    return FrostClickSurface(
      onTap: () => unawaited(GoRouter.of(context).push(AppLocations.novel(novel.id), extra: novel)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
        child: Row(
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
                    FrostText(
                      caption,
                      content: true,
                      role: FrostTextRole.footnote,
                      tone: FrostTextTone.secondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
        ),
      ),
    );
  }
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

/// First-load placeholders for a list of users: [AppUserRow].
class AppUserRowsSkeleton extends StatelessWidget {
  const AppUserRowsSkeleton({this.count, super.key});

  /// Null fills the window; a number is for a short fixed preview.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final preview = userPreviewPlaceholder();
    final rows = count ?? appSkeletonCount(context, shortestExtent: FrostControlSize.regular.height(context));
    return appBones(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var index = 0; index < rows; index++) AppUserRow(preview: preview)],
      ),
    );
  }
}
