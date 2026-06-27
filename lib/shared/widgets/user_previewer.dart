import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/core/platform/platform_info.dart';
import 'package:freepiv/shared/widgets/energetic_card.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/shared/widgets/user_follow_button.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UserPreviewer extends StatelessWidget {
  const UserPreviewer({required this.userPreview, this.scrollIllustPreviews = true, super.key});

  static const desktopMaxWidth = 768.0;

  final UserPreview userPreview;
  final bool scrollIllustPreviews;

  @override
  Widget build(BuildContext context) {
    final user = userPreview.user;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _userAccent(context);

    final card = EnergeticCard(
      accentColor: accent,
      onTap: () {
        context.pushNamed(AppRoute.userDetail.name, pathParameters: {'id': '${user.id}'});
      },
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _UserAvatar(url: user.profileImageUrls.medium, accentColor: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.account}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              UserFollowButton(userId: user.id, initialIsFollowed: user.isFollowed),
            ],
          ),
          if (userPreview.illusts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _UserPreviewIllustList(illusts: userPreview.illusts, scrollable: scrollIllustPreviews),
          ],
        ],
      ),
    );

    return _UserPreviewWidthLimiter(child: card);
  }
}

class SliverUserPreviewerSkeletonList extends StatelessWidget {
  const SliverUserPreviewerSkeletonList({this.itemCount = 8, this.scrollIllustPreviews = true, super.key});

  final int itemCount;
  final bool scrollIllustPreviews;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: UserPreviewerSkeleton(scrollIllustPreviews: scrollIllustPreviews),
        );
      },
    );
  }
}

class UserPreviewerSkeleton extends StatelessWidget {
  const UserPreviewerSkeleton({this.scrollIllustPreviews = true, super.key});

  final bool scrollIllustPreviews;

  @override
  Widget build(BuildContext context) {
    final card = EnergeticCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Skeletonizer.zone(child: Bone.circle(size: 46)),
              const SizedBox(width: 12),
              const Expanded(
                child: Skeletonizer.zone(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.text(width: double.infinity),
                      SizedBox(height: 8),
                      Bone.text(width: 120),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const UserFollowButtonPlaceholder(),
            ],
          ),
          const SizedBox(height: 12),
          _UserPreviewIllustSkeletonList(scrollable: scrollIllustPreviews),
        ],
      ),
    );

    return _UserPreviewWidthLimiter(child: card);
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.url, required this.accentColor});

  final String url;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withValues(alpha: 0.56), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: SizedBox.square(
          dimension: 42,
          child: PixivImage(url: url, fit: BoxFit.cover, borderRadius: BorderRadius.circular(21)),
        ),
      ),
    );
  }
}

class _UserPreviewWidthLimiter extends StatelessWidget {
  const _UserPreviewWidthLimiter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform) {
      return child;
    }

    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: UserPreviewer.desktopMaxWidth),
        child: child,
      ),
    );
  }
}

class _UserPreviewIllustList extends StatelessWidget {
  const _UserPreviewIllustList({required this.illusts, required this.scrollable});

  static const _thumbSize = 86.0;
  static const _spacing = 8.0;
  static const _maxItemCount = 3;

  final List<Illust> illusts;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final previewIllusts = illusts.take(_maxItemCount).toList();

    if (scrollable) {
      return SizedBox(
        height: _thumbSize,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: previewIllusts.length,
          separatorBuilder: (context, index) => const SizedBox(width: _spacing),
          itemBuilder: (context, index) {
            return _UserPreviewIllustThumb(illust: previewIllusts[index]);
          },
        ),
      );
    }

    return SizedBox(
      height: _thumbSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final visibleCount = availableWidth.isFinite
              ? ((availableWidth + _spacing) / (_thumbSize + _spacing)).floor().clamp(1, previewIllusts.length)
              : previewIllusts.length;
          final visibleIllusts = previewIllusts.take(visibleCount).toList();

          return Row(
            children: [
              for (var index = 0; index < visibleIllusts.length; index++) ...[
                _UserPreviewIllustThumb(illust: visibleIllusts[index]),
                if (index != visibleIllusts.length - 1) const SizedBox(width: _spacing),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _UserPreviewIllustSkeletonList extends StatelessWidget {
  const _UserPreviewIllustSkeletonList({required this.scrollable});

  static const _thumbSize = 86.0;
  static const _spacing = 8.0;
  static const _itemCount = 3;

  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SizedBox(
        height: _thumbSize,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _itemCount,
          separatorBuilder: (context, index) => const SizedBox(width: _spacing),
          itemBuilder: (context, index) => const _UserPreviewIllustBone(),
        ),
      );
    }

    return SizedBox(
      height: _thumbSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final visibleCount = availableWidth.isFinite ? ((availableWidth + _spacing) / (_thumbSize + _spacing)).floor().clamp(1, _itemCount) : _itemCount;

          return Row(
            children: [
              for (var index = 0; index < visibleCount; index++) ...[
                const _UserPreviewIllustBone(),
                if (index != visibleCount - 1) const SizedBox(width: _spacing),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _UserPreviewIllustBone extends StatelessWidget {
  const _UserPreviewIllustBone();

  @override
  Widget build(BuildContext context) {
    return Bone(width: 86, height: 86, borderRadius: BorderRadius.circular(6));
  }
}

class _UserPreviewIllustThumb extends StatelessWidget {
  const _UserPreviewIllustThumb({required this.illust});

  final Illust illust;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': '${illust.id}'}, extra: illust);
            },
            child: PixivImage(url: illust.imageUrls.squareMedium, fit: BoxFit.cover, borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ),
    );
  }
}

Color _userAccent(BuildContext context) {
  final tokens = FreepivThemeTokens.of(context);
  return tokens.brand;
}
