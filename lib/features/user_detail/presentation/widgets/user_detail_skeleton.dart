import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_collapsible_header.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_tab_scaffold.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/illust_waterfall_skeleton.dart';
import 'package:freepiv/shared/widgets/user_follow_button.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UserDetailLoadingSkeleton extends StatelessWidget {
  const UserDetailLoadingSkeleton({required this.useHorizontalLayout, super.key});

  final bool useHorizontalLayout;

  @override
  Widget build(BuildContext context) {
    return FrostContentViewport(child: Builder(builder: _buildContent));
  }

  Widget _buildContent(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final layout = UserCollapsibleHeaderLayout.forWidth(width, textScale: MediaQuery.textScalerOf(context).scale(14) / 14);
    final topPadding = mediaQuery.padding.top;
    final expandedHeaderHeight = UserCollapsibleHeaderSliver.skeletonExpandedHeightFor(context, width);
    final collapsedHeaderHeight = UserCollapsibleHeaderSliver.collapsedHeightFor(width, context);

    return Scaffold(
      body: ExcludeSemantics(
        child: Skeletonizer.zone(
          child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _SkeletonHeaderDelegate(
                  topPadding: topPadding,
                  expandedHeight: expandedHeaderHeight,
                  collapsedHeight: collapsedHeaderHeight,
                  layout: layout,
                  showBackButton: !useHorizontalLayout && !(FrostShellNavigationScope.maybeOf(context)?.ownsBackControl ?? false),
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
    required this.layout,
    required this.showBackButton,
  });

  final double topPadding;
  final double expandedHeight;
  final double collapsedHeight;
  final UserCollapsibleHeaderLayout layout;
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

    // Transparent at rest like the loaded header.
    return Material(
      type: MaterialType.transparency,
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
                      child: _ExpandedSkeletonHeader(layout: layout),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: FrostPinnedChromeGlass(opacity: math.max(progress, overlapsContent ? 1.0 : 0.0), animate: false, corners: FrostPinnedChromeCorners.top),
          ),
          PositionedDirectional(
            top: topPadding,
            start: 0,
            end: 0,
            height: collapsedHeight,
            child: IgnorePointer(
              child: Opacity(
                opacity: collapsedOpacity,
                child: _CollapsedSkeletonHeader(layout: layout, showBackButton: showBackButton),
              ),
            ),
          ),
          if (showBackButton)
            PositionedDirectional(
              top: topPadding + 8,
              start: 8,
              child: FrostSurfaceIconButton(
                icon: FrostIconData.glyph(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: null,
              ),
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
        oldDelegate.layout != layout ||
        oldDelegate.showBackButton != showBackButton;
  }
}

class _ExpandedSkeletonHeader extends StatelessWidget {
  const _ExpandedSkeletonHeader({required this.layout});

  final UserCollapsibleHeaderLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: layout.stackedHeaderHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                bottom: UserCollapsibleHeaderLayout.stackedHeaderExtraHeight,
                child: ColoredBox(color: colorScheme.surfaceContainerHighest),
              ),
              PositionedDirectional(
                start: layout.horizontalPadding,
                top: layout.avatarTop,
                child: Bone.circle(size: layout.avatarSize),
              ),
              PositionedDirectional(
                top: layout.backgroundHeight + UserCollapsibleHeaderLayout.expandedNameTopOffset - UserCollapsibleHeaderLayout.followLift,
                start: layout.horizontalPadding + layout.avatarSize + UserCollapsibleHeaderLayout.expandedNameStartGap,
                end: layout.horizontalPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: UserCollapsibleHeaderLayout.followLift),
                        child: _NameBlockSkeleton(height: layout.compact ? 36 : 42, width: layout.compact ? 168 : 210),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Bone(width: 82, height: FollowToggleButton.denseHeight, borderRadius: BorderRadius.circular(8)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(layout.horizontalPadding, layout.bodyTopPadding, layout.horizontalPadding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone(
                width: math.min(layout.bodyContentWidth, 520),
                height: UserCollapsibleHeaderSliver.placeholderCommentHeightFor(context, layout.availableWidth),
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: UserCollapsibleHeaderLayout.commentStatsGap),
              // One block as tall as the (possibly wrapped) stats, so the
              // header does not change height when the content arrives.
              Bone(
                width: math.min(layout.bodyContentWidth, 104 + 92 * 3 + 24),
                height: UserCollapsibleHeaderSliver.statsHeightFor(context, layout.availableWidth),
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollapsedSkeletonHeader extends StatelessWidget {
  const _CollapsedSkeletonHeader({required this.layout, required this.showBackButton});

  final UserCollapsibleHeaderLayout layout;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final start = layout.collapsedLeadingPadding(showBackButton: showBackButton);

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
  double get minExtent => UserDetailTabBar.height;

  @override
  double get maxExtent => UserDetailTabBar.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: SizedBox(
          height: UserDetailTabBar.height,
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
