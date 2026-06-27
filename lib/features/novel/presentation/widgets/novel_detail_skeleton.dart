import 'package:flutter/material.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NovelDetailSkeletonPage extends StatelessWidget {
  const NovelDetailSkeletonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: !shouldUseDesktopShell,
                  leading: shouldUseDesktopShell ? const SizedBox.shrink() : null,
                  leadingWidth: shouldUseDesktopShell ? 64 : null,
                  title: const _TitleSkeleton(),
                ),
                const SliverToBoxAdapter(child: _HeaderSkeleton()),
                const SliverToBoxAdapter(child: _ReaderSkeleton()),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 720;

            final cover = Skeletonizer.zone(
              child: Bone(width: desktop ? 260 : double.infinity, height: desktop ? 360 : 320, borderRadius: BorderRadius.circular(8)),
            );
            final info = const _InfoSkeleton();

            return Padding(
              padding: EdgeInsets.fromLTRB(desktop ? 28 : 16, 16, desktop ? 28 : 16, 18),
              child: desktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        cover,
                        const SizedBox(width: 24),
                        const Expanded(child: _InfoSkeleton()),
                      ],
                    )
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [cover, const SizedBox(height: 16), info]),
            );
          },
        ),
      ),
    );
  }
}

class _InfoSkeleton extends StatelessWidget {
  const _InfoSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Bone.text(width: double.infinity, fontSize: 24),
          const SizedBox(height: 10),
          const Bone.text(width: 180),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var index = 0; index < 4; index++) ...[
                Expanded(child: Bone(height: 52, borderRadius: BorderRadius.circular(8))),
                if (index != 3) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final width in const [80.0, 126.0, 94.0, 150.0, 108.0]) Bone(width: width, height: 28, borderRadius: BorderRadius.circular(999)),
            ],
          ),
          const SizedBox(height: 16),
          Bone(height: 86, borderRadius: BorderRadius.circular(8)),
        ],
      ),
    );
  }
}

class _ReaderSkeleton extends StatelessWidget {
  const _ReaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Skeletonizer.zone(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Bone.text(width: 132, fontSize: 18),
                const SizedBox(height: 18),
                for (var index = 0; index < 10; index++) ...[Bone.text(width: index.isEven ? double.infinity : 620), const SizedBox(height: 12)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSkeleton extends StatelessWidget {
  const _BottomSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
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
                        Bone(width: 68, height: 96, borderRadius: BorderRadius.circular(6)),
                        if (index != 3) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Bone.text(width: 150),
                const SizedBox(height: 12),
                const CommentsLoadingSkeleton(itemCount: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
