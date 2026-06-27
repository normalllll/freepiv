import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/core/utils/utils.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

class UserCollapsibleHeaderSliver extends StatelessWidget {
  const UserCollapsibleHeaderSliver({
    required this.detail,
    required this.overlapsContent,
    required this.includeTopPadding,
    required this.showBackButton,
    super.key,
  });

  final UserDetailResult detail;
  final bool overlapsContent;
  final bool includeTopPadding;
  final bool showBackButton;

  static double collapseExtentFor(double width, UserDetailResult detail) {
    return expandedHeightFor(width, detail) - collapsedHeightFor(width);
  }

  static double expandedHeightFor(double width, UserDetailResult detail) {
    final compact = width < 620;
    final baseExpandedHeight = compact ? 338.0 : 362.0;
    if (_hasComment(detail)) {
      return baseExpandedHeight;
    }

    return baseExpandedHeight - 42.0;
  }

  static double collapsedHeightFor(double width) {
    return width < 620 ? 64.0 : 70.0;
  }

  static bool _hasComment(UserDetailResult detail) {
    final comment = detail.user.comment?.trim();
    return comment != null && comment.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _UserHeaderDelegate(
        detail: detail,
        topPadding: includeTopPadding ? mediaQuery.padding.top : 0,
        expandedHeight: expandedHeightFor(width, detail),
        collapsedHeight: collapsedHeightFor(width),
        overlapsContent: overlapsContent,
        showBackButton: showBackButton,
      ),
    );
  }
}

class _UserHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _UserHeaderDelegate({
    required this.detail,
    required this.topPadding,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.overlapsContent,
    required this.showBackButton,
  });

  final UserDetailResult detail;
  final double topPadding;
  final double expandedHeight;
  final double collapsedHeight;
  final bool overlapsContent;
  final bool showBackButton;

  @override
  double get minExtent => topPadding + collapsedHeight;

  @override
  double get maxExtent => topPadding + expandedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 620;
    final expandedOpacity = (1 - progress * 1.7).clamp(0.0, 1.0);
    final collapsedOpacity = ((progress - 0.58) / 0.42).clamp(0.0, 1.0);

    return Material(
      color: colorScheme.surface,
      elevation: this.overlapsContent || overlapsContent ? 1 : 0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            top: topPadding,
            child: IgnorePointer(
              ignoring: expandedOpacity < 0.35,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: expandedHeight,
                  child: SizedBox(
                    height: expandedHeight,
                    child: Opacity(
                      opacity: expandedOpacity,
                      child: _ExpandedUserHeader(detail: detail, compact: compact, availableWidth: size.width),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: colorScheme.surface.withValues(alpha: progress * 0.96)),
            ),
          ),
          PositionedDirectional(
            top: topPadding,
            start: 0,
            end: 0,
            height: collapsedHeight,
            child: IgnorePointer(
              ignoring: collapsedOpacity < 0.35,
              child: Opacity(
                opacity: collapsedOpacity,
                child: _CollapsedUserHeader(detail: detail, compact: compact, showBackButton: showBackButton),
              ),
            ),
          ),
          if (showBackButton)
            PositionedDirectional(
              top: topPadding + 8,
              start: 8,
              child: SurfaceIconButton(icon: Icons.arrow_back, tooltip: t.common.back, onPressed: () => Navigator.of(context).maybePop()),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_UserHeaderDelegate oldDelegate) {
    return oldDelegate.detail != detail ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight ||
        oldDelegate.overlapsContent != overlapsContent ||
        oldDelegate.showBackButton != showBackButton;
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({required this.url, required this.hasBackground, required this.opacity});

  final String? url;
  final bool hasBackground;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!hasBackground) {
      return ColoredBox(color: colorScheme.surfaceContainerHighest);
    }

    return Opacity(
      opacity: opacity,
      child: PixivImage(url: url!, fit: BoxFit.cover),
    );
  }
}

class _ExpandedUserHeader extends StatelessWidget {
  const _ExpandedUserHeader({required this.detail, required this.compact, required this.availableWidth});

  final UserDetailResult detail;
  final bool compact;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contentWidth = math.min(availableWidth, 980.0);
    final horizontalPadding = math.max(16.0, (availableWidth - contentWidth) / 2 + (compact ? 16 : 20));
    final backgroundHeight = compact ? 148.0 : 172.0;
    final avatarSize = compact ? 84.0 : 98.0;
    final avatarTop = backgroundHeight - avatarSize / 2;
    final comment = detail.user.comment?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: backgroundHeight + 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                bottom: 58,
                child: _HeaderBackground(
                  url: detail.profile.backgroundImageUrl,
                  hasBackground: detail.profile.backgroundImageUrl?.isNotEmpty ?? false,
                  opacity: 1,
                ),
              ),
              PositionedDirectional(
                start: horizontalPadding,
                top: avatarTop,
                child: _HeaderAvatar(url: detail.user.profileImageUrls.medium, size: avatarSize),
              ),
              PositionedDirectional(
                top: backgroundHeight + 8,
                start: horizontalPadding + avatarSize + 14,
                end: horizontalPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ExpandedNameBlock(detail: detail)),
                    const SizedBox(width: 10),
                    UserFollowButton(userId: detail.user.id, initialIsFollowed: detail.user.isFollowed),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, compact ? 10 : 12, horizontalPadding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (comment != null && comment.isNotEmpty) ...[
                HtmlRichText(
                  comment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.25),
                ),
                const SizedBox(height: 12),
              ],
              _UserStatsRow(profile: detail.profile),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpandedNameBlock extends StatelessWidget {
  const _ExpandedNameBlock({required this.detail});

  final UserDetailResult detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          detail.user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w800, height: 1.08),
        ),
        const SizedBox(height: 3),
        Text(
          '@${detail.user.account}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.1),
        ),
      ],
    );
  }
}

class _CollapsedUserHeader extends StatelessWidget {
  const _CollapsedUserHeader({required this.detail, required this.compact, required this.showBackButton});

  final UserDetailResult detail;
  final bool compact;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarSize = 40.0;
    final start = showBackButton ? (compact ? 64.0 : 70.0) : (compact ? 16.0 : 20.0);

    return Row(
      children: [
        SizedBox(width: start),
        _HeaderAvatar(url: detail.user.profileImageUrls.medium, size: avatarSize),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w800, height: 1.08),
              ),
              const SizedBox(height: 2),
              Text(
                '@${detail.user.account}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.surface.withValues(alpha: 0.92), width: 3),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: ClipOval(
          child: PixivImage(url: url, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _UserStatsRow extends StatelessWidget {
  const _UserStatsRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _UserHeaderStat(value: profile.totalIllusts, label: translations.user.stats.illustrations),
          const SizedBox(width: 8),
          _UserHeaderStat(value: profile.totalManga, label: translations.user.stats.manga),
          const SizedBox(width: 8),
          _UserHeaderStat(value: profile.totalNovels, label: translations.user.stats.novels),
          const SizedBox(width: 8),
          _UserHeaderStat(value: profile.totalFollowUsers, label: translations.user.stats.following),
        ],
      ),
    );
  }
}

class _UserHeaderStat extends StatelessWidget {
  const _UserHeaderStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatCount(value), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 5),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
