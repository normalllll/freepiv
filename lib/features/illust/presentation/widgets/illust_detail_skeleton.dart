import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:skeletonizer/skeletonizer.dart';

class IllustDetailSkeletonPage extends StatelessWidget {
  const IllustDetailSkeletonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        if (shouldUseDesktopShell) {
          return const _DesktopIllustDetailSkeleton();
        }

        return const _MobileIllustDetailSkeleton();
      },
    );
  }
}

class _DesktopIllustDetailSkeleton extends StatelessWidget {
  const _DesktopIllustDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final panelWidth = math.min(460.0, math.max(380.0, MediaQuery.sizeOf(context).width * 0.32));

    return ColoredBox(
      color: colorScheme.surface,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Skeletonizer.zone(
                child: Stack(
                  children: [
                    const Positioned.fill(child: _ImageAreaSkeleton()),
                    PositionedDirectional(top: 16, end: 16, child: Bone.iconButton(size: 46, borderRadius: BorderRadius.circular(999))),
                  ],
                ),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),
            SizedBox(width: panelWidth, child: const _DetailPanelSkeleton(scrollable: true)),
          ],
        ),
      ),
    );
  }
}

class _MobileIllustDetailSkeleton extends StatelessWidget {
  const _MobileIllustDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final imageHeight = math.min(size.height * 0.68, math.max(360.0, size.width * 1.15));

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(pinned: true, title: Skeletonizer.zone(child: const Bone.text(width: 180))),
        SliverToBoxAdapter(
          child: SizedBox(
            height: imageHeight,
            child: Skeletonizer.zone(child: const _ImageAreaSkeleton()),
          ),
        ),
        const SliverToBoxAdapter(child: _DetailPanelSkeleton(scrollable: false)),
        const SliverPadding(padding: EdgeInsets.fromLTRB(14, 0, 14, 24), sliver: _RelatedGridSkeleton()),
      ],
    );
  }
}

class _ImageAreaSkeleton extends StatelessWidget {
  const _ImageAreaSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.72,
          heightFactor: 0.74,
          child: Bone(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _DetailPanelSkeleton extends StatelessWidget {
  const _DetailPanelSkeleton({required this.scrollable});

  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final child = Skeletonizer.zone(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Bone.text(width: 260, fontSize: 22),
            SizedBox(height: 8),
            _StatsStripSkeleton(),
            SizedBox(height: 14),
            _SectionHeaderSkeleton(width: 96),
            SizedBox(height: 8),
            _TagWrapSkeleton(),
            SizedBox(height: 14),
            _SectionHeaderSkeleton(width: 118),
            SizedBox(height: 8),
            _CaptionSkeleton(),
            SizedBox(height: 14),
            _UserPreviewSkeleton(),
            SizedBox(height: 14),
            _SectionHeaderSkeleton(width: 92),
            SizedBox(height: 6),
            _MetadataSkeleton(),
            SizedBox(height: 14),
            _CommentsSkeleton(),
            SizedBox(height: 14),
            _RelatedPreviewSkeleton(),
          ],
        ),
      ),
    );

    if (!scrollable) {
      return child;
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(padding: EdgeInsets.zero, children: [child]),
    );
  }
}

class _StatsStripSkeleton extends StatelessWidget {
  const _StatsStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < 4; index++) ...[
          Expanded(child: Bone(height: 48, borderRadius: BorderRadius.circular(8))),
          if (index != 3) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _SectionHeaderSkeleton extends StatelessWidget {
  const _SectionHeaderSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Bone.icon(size: 18),
        const SizedBox(width: 6),
        Bone.text(width: width),
      ],
    );
  }
}

class _TagWrapSkeleton extends StatelessWidget {
  const _TagWrapSkeleton();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final width in const [84.0, 126.0, 72.0, 156.0, 98.0, 112.0]) Bone(width: width, height: 28, borderRadius: BorderRadius.circular(999)),
      ],
    );
  }
}

class _CaptionSkeleton extends StatelessWidget {
  const _CaptionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Bone(height: 86, borderRadius: BorderRadius.circular(8));
  }
}

class _UserPreviewSkeleton extends StatelessWidget {
  const _UserPreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Bone.circle(size: 46),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Bone.text(width: 150), SizedBox(height: 7), Bone.text(width: 104)]),
        ),
        Bone.button(width: 88, height: 34, borderRadius: BorderRadius.circular(999)),
      ],
    );
  }
}

class _MetadataSkeleton extends StatelessWidget {
  const _MetadataSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final width in const [116.0, 88.0, 156.0])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                const Bone.text(width: 76),
                const SizedBox(width: 20),
                Bone.text(width: width),
              ],
            ),
          ),
      ],
    );
  }
}

class _CommentsSkeleton extends StatelessWidget {
  const _CommentsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [_SectionHeaderSkeleton(width: 110), SizedBox(height: 10), _CommentRowSkeleton(), SizedBox(height: 10), _CommentRowSkeleton()],
    );
  }
}

class _CommentRowSkeleton extends StatelessWidget {
  const _CommentRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Bone.circle(size: 30),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone.text(width: 116),
              SizedBox(height: 6),
              Bone.text(width: double.infinity),
            ],
          ),
        ),
      ],
    );
  }
}

class _RelatedPreviewSkeleton extends StatelessWidget {
  const _RelatedPreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionHeaderSkeleton(width: 130),
        SizedBox(height: 10),
        SizedBox(height: 110, child: _RelatedPreviewRowSkeleton()),
      ],
    );
  }
}

class _RelatedPreviewRowSkeleton extends StatelessWidget {
  const _RelatedPreviewRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < 3; index++) ...[
          Expanded(
            child: Bone(height: double.infinity, borderRadius: BorderRadius.circular(8)),
          ),
          if (index != 2) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _RelatedGridSkeleton extends StatelessWidget {
  const _RelatedGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.78),
      itemBuilder: (context, index) {
        return Skeletonizer.zone(
          child: Bone(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(8)),
        );
      },
    );
  }
}
