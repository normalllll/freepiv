import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_novel_list_tab.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/illust_waterfall_skeleton.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:go_router/go_router.dart';
import 'package:frost_data/frost_data.dart';

class NewestFeedView extends StatelessWidget {
  const NewestFeedView({required this.source, required this.filterSliver, super.key});

  final NewestListSource source;
  final Widget filterSliver;

  @override
  Widget build(BuildContext context) {
    return FrostRefreshView(
      onRefresh: () => source.refresh(source.items.isEmpty),
      builder: (context, physics, locators) {
        return NewestBody(source: source, physics: physics, locators: locators, filterSliver: filterSliver);
      },
    );
  }
}

class NewestBody extends StatelessWidget {
  const NewestBody({required this.source, required this.physics, required this.locators, required this.filterSliver, super.key});

  final NewestListSource source;
  final ScrollPhysics? physics;
  final FrostRefreshLocators locators;
  final Widget filterSliver;

  @override
  Widget build(BuildContext context) => FrostLoadStateSwitcher(phase: source.phase, child: _buildPhase(context));

  Widget _buildPhase(BuildContext context) {
    final lastError = source.lastError;

    if (source.phase == FrostLoadPhase.loading) {
      if (source.key.isNovel) {
        return NovelListSkeleton(physics: physics, sliverHeader: locators.sliverHeader, leadingSlivers: [filterSliver]);
      }

      return FrostLoadingScrollView(physics: physics, slivers: [filterSliver, ?locators.sliverHeader, const SliverIllustWaterfallSkeleton()]);
    }

    if (!source.initialized && lastError != null) {
      return SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        leadingSlivers: [filterSliver],
        child: FrostErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.items.isEmpty) {
      return SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        leadingSlivers: [filterSliver],
        child: FrostEmptyState(icon: FrostIconData.glyph(Icons.inbox_outlined), title: context.t.newest.emptyTitle),
      );
    }

    if (source.key.isNovel) {
      return NovelList(source: source, physics: physics, sliverHeader: locators.sliverHeader, leadingSlivers: [filterSliver]);
    }

    return FrostLoadingScrollView(
      physics: physics,
      slivers: [
        filterSliver,
        ?locators.sliverHeader,
        FrostSliverDataWaterfallGrid<NewestItem>(
          firstLoadSkeleton: const FullScreenLoadingSkeleton(),
          source: source,
          itemBuilder: (context, item, index) {
            return switch (item) {
              NewestIllust(:final illust) => IllustPreviewer(illust: illust, onOpen: (heroTag) => openIllustDetail(context, illust, heroTag)),
              NewestNovel() => const SizedBox.shrink(),
            };
          },
        ),
      ],
    );
  }
}

class NovelListSkeleton extends StatelessWidget {
  const NovelListSkeleton({required this.physics, this.sliverHeader, this.leadingSlivers = const [], super.key});

  final ScrollPhysics? physics;
  final Widget? sliverHeader;
  final List<Widget> leadingSlivers;

  @override
  Widget build(BuildContext context) {
    return FrostLoadingScrollView(
      physics: physics,
      slivers: [
        ...leadingSlivers,
        ?sliverHeader,
        const FrostSliverContentColumn(
          sliver: SliverPadding(padding: EdgeInsets.symmetric(vertical: 12), sliver: SliverListSkeleton(itemExtent: 140, itemCount: 8)),
        ),
      ],
    );
  }
}

class NovelList extends StatelessWidget {
  const NovelList({required this.source, required this.physics, this.sliverHeader, this.leadingSlivers = const [], super.key});

  final NewestListSource source;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;
  final List<Widget> leadingSlivers;

  @override
  Widget build(BuildContext context) {
    return FrostLoadingScrollView(
      physics: physics,
      slivers: [
        ...leadingSlivers,
        ?sliverHeader,
        FrostSliverDataList<NewestItem>(
          firstLoadSkeleton: const FullScreenLoadingSkeleton(),
          source: source,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemBuilder: (context, item, index) {
            return FrostContentColumn(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: switch (item) {
                  NewestNovel(:final novel) => NovelCard(novel: novel),
                  NewestIllust() => const SizedBox.shrink(),
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class NovelCard extends StatelessWidget {
  const NovelCard({required this.novel, super.key});

  final Novel novel;

  @override
  Widget build(BuildContext context) {
    return NovelPreviewer(
      novel: novel,
      onTap: () {
        context.pushNamed(AppRoute.novelDetail.name, pathParameters: {'id': '${novel.id}'}, extra: novel);
      },
    );
  }
}

class SliverFillBody extends StatelessWidget {
  const SliverFillBody({required this.child, required this.physics, this.sliverHeader, this.leadingSlivers = const [], super.key});

  final Widget child;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;
  final List<Widget> leadingSlivers;

  @override
  Widget build(BuildContext context) {
    return FrostSliverFillBody(physics: physics, sliverHeader: sliverHeader, leadingSlivers: leadingSlivers, child: child);
  }
}
