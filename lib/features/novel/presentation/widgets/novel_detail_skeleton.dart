import 'package:flutter/material.dart';
import 'package:freepiv/features/comments/presentation/widgets/comments_skeleton.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NovelDetailSkeletonPage extends StatelessWidget {
  const NovelDetailSkeletonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FrostAutoScaffold(
      builder: (BuildContext context, FrostSizeLayout layout, Orientation orientation, bool useHorizontalLayout) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                if (!useHorizontalLayout)
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    flexibleSpace: const FrostPinnedChromeGlass(opacity: 1),
                    automaticallyImplyLeading: false,
                    leading: FrostPageHeader.leadingFor(context),
                    leadingWidth: 44.0,
                    titleSpacing: 8.0,
                    title: const _TitleSkeleton(),
                  ),
                const SliverToBoxAdapter(child: _HeaderSkeleton()),
                const SliverToBoxAdapter(child: _BottomSkeleton()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TitleSkeleton extends StatelessWidget {
  const _TitleSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(child: const Bone.text(width: 180));
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return FrostContentColumn(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = FrostAutoScaffold.usesHorizontalLayoutOf(context) && constraints.maxWidth >= 720;

          final cover = Skeletonizer.zone(
            child: Bone(width: desktop ? 220 : 96, height: desktop ? 308 : 136, borderRadius: BorderRadius.circular(FrostRadius.lg)),
          );
          final info = const _InfoSkeleton(includeSupporting: false);

          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 18),
            child: desktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cover,
                      const SizedBox(width: 24),
                      const Expanded(child: _InfoSkeleton(includeSupporting: true)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          cover,
                          const SizedBox(width: 12),
                          Expanded(child: info),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Skeletonizer.zone(
                        child: Bone(width: 180, height: FrostDensity.of(context).controlHeight, borderRadius: BorderRadius.circular(FrostRadius.lg)),
                      ),
                      const SizedBox(height: 14),
                      const _SupportingSkeleton(),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _InfoSkeleton extends StatelessWidget {
  const _InfoSkeleton({required this.includeSupporting});

  final bool includeSupporting;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Bone.text(width: double.infinity, fontSize: 24),
          const SizedBox(height: 10),
          const Bone.text(width: 180),
          if (includeSupporting) ...[
            const SizedBox(height: 14),
            Bone(width: 180, height: FrostDensity.of(context).controlHeight, borderRadius: BorderRadius.circular(FrostRadius.lg)),
            const SizedBox(height: 14),
            const _SupportingSkeleton(),
          ],
        ],
      ),
    );
  }
}

class _SupportingSkeleton extends StatelessWidget {
  const _SupportingSkeleton();

  @override
  Widget build(BuildContext context) => Skeletonizer.zone(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Bone.text(width: 240),
        const SizedBox(height: 8),
        const Bone.text(width: double.infinity),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            for (final width in [80.0, 100.0, 76.0]) Bone(width: width, height: 24, borderRadius: BorderRadius.circular(FrostRadius.lg)),
          ],
        ),
        const SizedBox(height: 14),
        const Bone.text(width: 280),
      ],
    ),
  );
}

class _BottomSkeleton extends StatelessWidget {
  const _BottomSkeleton();

  @override
  Widget build(BuildContext context) {
    return FrostContentColumn(
      child: Skeletonizer.zone(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Bone.circle(size: 44),
                  SizedBox(width: 12),
                  Expanded(child: Bone.text(width: 160)),
                  UserFollowButtonPlaceholder(),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 96,
                child: Row(
                  children: [
                    for (var index = 0; index < 4; index++) ...[
                      Bone(width: 68, height: 96, borderRadius: BorderRadius.circular(FrostRadius.lg)),
                      if (index != 3) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Bone.text(width: 150),
              const SizedBox(height: 12),
              const CommentsLoadingSkeleton(itemCount: 2, preview: true),
            ],
          ),
        ),
      ),
    );
  }
}
