import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_detail_constraints.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _novelStripSpacing = 8.0;
const _novelStripVisibleItems = 3;
const _novelStripMinWidth = 96.0;
const _novelStripMaxWidth = 140.0;
const _novelCoverAspectRatio = 82 / 116;

class NovelCreatorSection extends ConsumerWidget {
  const NovelCreatorSection({required this.novel, required this.onNovelTap, super.key});

  final Novel novel;
  final ValueChanged<Novel> onNovelTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userWorks = ref.watch(novelUserWorksProvider(novel.user.id));

    return NovelDetailWidthLimiter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IllustSectionTitle(title: t.illust.section.creator, icon: Icons.person_outline),
            const SizedBox(height: 8),
            NovelCreatorHeader(user: novel.user),
            const SizedBox(height: 12),
            Text(t.illust.section.recentWorks, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            userWorks.when(
              loading: () => const HorizontalNovelStripSkeleton(),
              error: (error, stackTrace) => CompactMessage(
                icon: Icons.error_outline,
                message: t.illust.works.failed,
                actionLabel: t.common.retry,
                onAction: () {
                  ref.read(novelUserWorksProvider(novel.user.id).notifier).reload();
                },
              ),
              data: (result) => UserNovelStrip(result: result, currentNovelId: novel.id, onNovelTap: onNovelTap),
            ),
          ],
        ),
      ),
    );
  }
}

class NovelCreatorHeader extends StatelessWidget {
  const NovelCreatorHeader({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          context.pushNamed(AppRoute.userDetail.name, pathParameters: {'id': '${user.id}'});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 44,
                child: PixivImage(url: user.profileImageUrls.medium, fit: BoxFit.cover, borderRadius: BorderRadius.circular(22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.account}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              UserFollowButton(userId: user.id, initialIsFollowed: user.isFollowed),
            ],
          ),
        ),
      ),
    );
  }
}

class UserNovelStrip extends StatelessWidget {
  const UserNovelStrip({required this.result, required this.currentNovelId, required this.onNovelTap, super.key});

  final NovelPageResult result;
  final int currentNovelId;
  final ValueChanged<Novel> onNovelTap;

  @override
  Widget build(BuildContext context) {
    final works = result.novels.where((novel) => novel.id != currentNovelId).take(12).toList(growable: false);

    if (works.isEmpty) {
      return CompactMessage(icon: Icons.menu_book_outlined, message: t.user.empty.novels);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = _novelStripTileWidth(constraints.maxWidth);
        final tileHeight = tileWidth / _novelCoverAspectRatio;

        return SizedBox(
          height: tileHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: works.length,
            separatorBuilder: (context, index) => const SizedBox(width: _novelStripSpacing),
            itemBuilder: (context, index) {
              final work = works[index];

              return NovelCoverTile(width: tileWidth, height: tileHeight, novel: work, onTap: () => onNovelTap(work));
            },
          ),
        );
      },
    );
  }
}

class NovelCoverTile extends StatelessWidget {
  const NovelCoverTile({required this.width, required this.height, required this.novel, required this.onTap, super.key});

  final double width;
  final double height;
  final Novel novel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(6);

    return Tooltip(
      message: novel.title,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PixivImage(url: novel.imageUrls.medium, fit: BoxFit.cover),
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.48)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                      child: Text(
                        novel.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, height: 1.1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HorizontalNovelStripSkeleton extends StatelessWidget {
  const HorizontalNovelStripSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = _novelStripTileWidth(constraints.maxWidth);
        final tileHeight = tileWidth / _novelCoverAspectRatio;

        return SizedBox(
          height: tileHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (context, index) => const SizedBox(width: _novelStripSpacing),
            itemBuilder: (context, index) {
              return Skeletonizer.zone(
                child: Bone(width: tileWidth, height: tileHeight, borderRadius: BorderRadius.circular(6)),
              );
            },
          ),
        );
      },
    );
  }
}

double _novelStripTileWidth(double availableWidth) {
  if (!availableWidth.isFinite || availableWidth <= 0) {
    return 116;
  }

  final usableWidth = availableWidth - _novelStripSpacing * (_novelStripVisibleItems - 1);
  return (usableWidth / _novelStripVisibleItems).clamp(_novelStripMinWidth, _novelStripMaxWidth).toDouble();
}
