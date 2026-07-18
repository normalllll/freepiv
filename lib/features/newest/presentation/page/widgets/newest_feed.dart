import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_novel_list_tab.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/illust_waterfall_skeleton.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:go_router/go_router.dart';

class NewestFeedView extends StatelessWidget {
  const NewestFeedView({required this.source, required this.filterSliver, super.key});

  final NewestListSource source;
  final Widget filterSliver;

  @override
  Widget build(BuildContext context) {
    return DataRefreshView(
      onRefresh: () => source.refresh(source.isEmpty),
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
  final DataRefreshLocators locators;
  final Widget filterSliver;

  @override
  Widget build(BuildContext context) {
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      if (source.key.isNovel) {
        return NovelListSkeleton(physics: physics, sliverHeader: locators.sliverHeader, leadingSlivers: [filterSliver]);
      }

      return DataLoadingCustomScrollView(physics: physics, slivers: [?locators.sliverHeader, filterSliver, const SliverIllustWaterfallSkeleton()]);
    }

    if (!source.initialized && lastError != null) {
      return SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        leadingSlivers: [filterSliver],
        child: ErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        leadingSlivers: [filterSliver],
        child: EmptyContent(icon: Icons.dynamic_feed_outlined, title: context.t.newest.emptyTitle),
      );
    }

    if (source.key.isNovel) {
      return NovelList(source: source, physics: physics, sliverHeader: locators.sliverHeader, leadingSlivers: [filterSliver]);
    }

    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?locators.sliverHeader,
        filterSliver,
        SliverDataWaterfallGrid<NewestItem>(
          source: source,
          padding: const EdgeInsets.all(12),
          maxCrossAxisExtent: 240,
          itemBuilder: (context, item, index) {
            return switch (item) {
              NewestIllust(:final illust) => IllustPreviewer(
                illust: illust,
                onTap: () {
                  context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': '${illust.id}'}, extra: illust);
                },
              ),
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
    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?sliverHeader,
        ...leadingSlivers,
        const SliverPadding(padding: EdgeInsets.all(12), sliver: SliverListSkeleton(itemExtent: 140, itemCount: 8)),
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
    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?sliverHeader,
        ...leadingSlivers,
        SliverDataList<NewestItem>(
          source: source,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, item, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: switch (item) {
                NewestNovel(:final novel) => NovelCard(novel: novel),
                NewestIllust() => const SizedBox.shrink(),
              },
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
    return DataSliverFillBody(physics: physics, sliverHeader: sliverHeader, leadingSlivers: leadingSlivers, child: child);
  }
}
