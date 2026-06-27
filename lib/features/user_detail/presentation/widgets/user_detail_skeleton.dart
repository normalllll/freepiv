import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_collapsible_header.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_tab_scaffold.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/illust_waterfall_skeleton.dart';
import 'package:freepiv/shared/widgets/surface_icon_button.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UserDetailLoadingSkeleton extends StatelessWidget {
  const UserDetailLoadingSkeleton({required this.shouldUseDesktopShell, super.key});

  final bool shouldUseDesktopShell;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final compact = width < 620;
    final topPadding = mediaQuery.padding.top;
    final expandedHeaderHeight = compact ? 338.0 : 362.0;
    final collapsedHeaderHeight = UserCollapsibleHeaderSliver.collapsedHeightFor(width);

    return Scaffold(
      body: ExcludeSemantics(
        child: Skeletonizer.zone(
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _SkeletonHeaderDelegate(
                  topPadding: topPadding,
                  expandedHeight: expandedHeaderHeight,
                  collapsedHeight: collapsedHeaderHeight,
                  compact: compact,
                  showBackButton: !shouldUseDesktopShell,
                ),
              ),
              const SliverPersistentHeader(pinned: true, delegate: _SkeletonTabBarDelegate()),
              const SliverIllustWaterfallSkeleton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SkeletonHeaderDelegate({
    required this.topPadding,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.compact,
    required this.showBackButton,
  });

  final double topPadding;
  final double expandedHeight;
  final double collapsedHeight;
  final bool compact;
  final bool showBackButton;

  @override
  double get minExtent => topPadding + collapsedHeight;

  @override
  double get maxExtent => topPadding + expandedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final expandedOpacity = (1 - progress * 1.7).clamp(0.0, 1.0);
    final collapsedOpacity = ((progress - 0.58) / 0.42).clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: overlapsContent ? 1 : 0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            top: topPadding,
            child: IgnorePointer(
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: expandedHeight,
                  child: SizedBox(
                    height: expandedHeight,
                    child: Opacity(
                      opacity: expandedOpacity,
                      child: _ExpandedSkeletonHeader(compact: compact, availableWidth: MediaQuery.sizeOf(context).width),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: colorScheme.surface.withValues(alpha: progress * 0.96)),
          ),
          PositionedDirectional(
            top: topPadding,
            start: 0,
            end: 0,
            height: collapsedHeight,
            child: IgnorePointer(
              child: Opacity(
                opacity: collapsedOpacity,
                child: _CollapsedSkeletonHeader(compact: compact, showBackButton: showBackButton),
              ),
            ),
          ),
          if (showBackButton)
            PositionedDirectional(
              top: topPadding + 8,
              start: 8,
              child: SurfaceIconButton(icon: Icons.arrow_back, tooltip: MaterialLocalizations.of(context).backButtonTooltip, onPressed: null),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SkeletonHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight ||
        oldDelegate.compact != compact ||
        oldDelegate.showBackButton != showBackButton;
  }
}

class _ExpandedSkeletonHeader extends StatelessWidget {
  const _ExpandedSkeletonHeader({required this.compact, required this.availableWidth});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: backgroundHeight + 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(bottom: 58, child: ColoredBox(color: colorScheme.surfaceContainerHighest)),
              PositionedDirectional(
                start: horizontalPadding,
                top: avatarTop,
                child: Bone.circle(size: avatarSize),
              ),
              PositionedDirectional(
                top: backgroundHeight + 8,
                start: horizontalPadding + avatarSize + 14,
                end: horizontalPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _NameBlockSkeleton(height: compact ? 36 : 42, width: compact ? 168 : 210),
                    ),
                    const SizedBox(width: 10),
                    Bone(width: 82, height: 34, borderRadius: BorderRadius.circular(8)),
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
              Bone(width: math.min(availableWidth - horizontalPadding * 2, 520), height: 34, borderRadius: BorderRadius.circular(8)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < 4; index++) ...[
                      Bone(width: index == 0 ? 104 : 92, height: 32, borderRadius: BorderRadius.circular(8)),
                      if (index != 3) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollapsedSkeletonHeader extends StatelessWidget {
  const _CollapsedSkeletonHeader({required this.compact, required this.showBackButton});

  final bool compact;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final start = showBackButton ? (compact ? 64.0 : 70.0) : (compact ? 16.0 : 20.0);

    return Row(
      children: [
        SizedBox(width: start),
        const Bone.circle(size: 40),
        const SizedBox(width: 10),
        const Expanded(child: _NameBlockSkeleton(height: 32, width: 148, center: true)),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _NameBlockSkeleton extends StatelessWidget {
  const _NameBlockSkeleton({required this.height, required this.width, this.center = false});

  final double height;
  final double width;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final bone = Bone(width: width, height: height, borderRadius: BorderRadius.circular(8));

    if (!center) {
      return bone;
    }

    return Align(alignment: AlignmentDirectional.centerStart, child: bone);
  }
}

class _SkeletonTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _SkeletonTabBarDelegate();

  @override
  double get minExtent => UserDetailTabBarSliver.height;

  @override
  double get maxExtent => UserDetailTabBarSliver.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: overlapsContent ? 1 : 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.42))),
        ),
        child: SizedBox(
          height: UserDetailTabBarSliver.height,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const _SkeletonTab(width: 104),
                const SizedBox(width: 18),
                const _SkeletonTab(width: 74),
                const SizedBox(width: 18),
                const _SkeletonTab(width: 82),
                const SizedBox(width: 18),
                const _SkeletonTab(width: 72),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SkeletonTabBarDelegate oldDelegate) => false;
}

class _SkeletonTab extends StatelessWidget {
  const _SkeletonTab({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Bone(width: width, height: 24, borderRadius: BorderRadius.circular(8)),
    );
  }
}
