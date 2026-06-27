import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _homePageStorageBucket = PageStorageBucket();

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  static const _homeTypes = [HomeType.illustrations, HomeType.manga, HomeType.novels, HomeType.users];

  late final TabController _homeTabController;

  @override
  void initState() {
    super.initState();

    _homeTabController = TabController(length: _homeTypes.length, initialIndex: _homeTypeIndex(ref.read(homeProvider)), vsync: this);
    _homeTabController.addListener(_handleHomeTabChanged);

    Future.microtask(() {
      ref.read(homeProvider.notifier).loadCurrentIfNeeded();
    });
  }

  void _handleHomeTabChanged() {
    if (_homeTabController.indexIsChanging) {
      return;
    }

    final type = _homeTypeForIndex(_homeTabController.index);
    if (ref.read(homeProvider) == type) {
      return;
    }

    ref.read(homeProvider.notifier).setType(type);
  }

  @override
  void dispose() {
    _homeTabController.removeListener(_handleHomeTabChanged);
    _homeTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final illustSource = ref.watch(homeIllustSourceProvider);
    final mangaSource = ref.watch(homeMangaSourceProvider);
    final novelSource = ref.watch(homeNovelSourceProvider);
    final userSource = ref.watch(homeUserSourceProvider);

    ref.listen<HomeType>(homeProvider, (previous, next) {
      final index = _homeTypeIndex(next);
      if (_homeTabController.index == index) {
        return;
      }

      _homeTabController.animateTo(index);
    });

    return Scaffold(
      body: PageStorage(
        bucket: _homePageStorageBucket,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _HomeTypeSelector(
                  controller: _homeTabController,
                  onTypeChanged: (type) {
                    ref.read(homeProvider.notifier).setType(type);
                  },
                ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([illustSource, mangaSource, novelSource, userSource]),
                builder: (context, child) {
                  return TabBarView(
                    controller: _homeTabController,
                    children: [
                      _IllustHomeTab(key: const PageStorageKey('home-illustrations'), source: illustSource, homeType: HomeType.illustrations),
                      _IllustHomeTab(key: const PageStorageKey('home-manga'), source: mangaSource, homeType: HomeType.manga),
                      _NovelHomeTab(key: const PageStorageKey('home-novels'), source: novelSource),
                      _UserHomeTab(key: const PageStorageKey('home-users'), source: userSource),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static HomeType _homeTypeForIndex(int index) => _homeTypes[index];

  static int _homeTypeIndex(HomeType type) => _homeTypes.indexOf(type);
}

abstract class _KeepAliveHomeTabState<T extends StatefulWidget> extends State<T> with AutomaticKeepAliveClientMixin<T> {
  @override
  bool get wantKeepAlive => true;
}

class _IllustHomeTab extends StatefulWidget {
  const _IllustHomeTab({super.key, required this.source, required this.homeType});

  final HomeIllustListSource source;
  final HomeType homeType;

  @override
  State<_IllustHomeTab> createState() => _IllustHomeTabState();
}

class _IllustHomeTabState extends _KeepAliveHomeTabState<_IllustHomeTab> {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return DataNestedRefreshView(
      onRefresh: () => widget.source.refresh(widget.source.isEmpty),
      builder: (context, refresh) {
        return NestedScrollView(
          key: PageStorageKey<String>('home-${widget.homeType.name}-nested-scroll'),
          controller: refresh.scrollController,
          physics: refresh.physics,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return const <Widget>[];
          },
          body: refresh.body(
            builder: (context, locators) {
              return _IllustHomeBody(source: widget.source, homeType: widget.homeType, physics: refresh.physics, locators: locators);
            },
          ),
        );
      },
    );
  }
}

class _NovelHomeTab extends StatefulWidget {
  const _NovelHomeTab({super.key, required this.source});

  final HomeNovelListSource source;

  @override
  State<_NovelHomeTab> createState() => _NovelHomeTabState();
}

class _NovelHomeTabState extends _KeepAliveHomeTabState<_NovelHomeTab> {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return DataNestedRefreshView(
      onRefresh: () => widget.source.refresh(widget.source.isEmpty),
      builder: (context, refresh) {
        return NestedScrollView(
          key: const PageStorageKey<String>('home-novels-nested-scroll'),
          controller: refresh.scrollController,
          physics: refresh.physics,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return const <Widget>[];
          },
          body: refresh.body(
            builder: (context, locators) {
              return _NovelHomeBody(source: widget.source, physics: refresh.physics, locators: locators);
            },
          ),
        );
      },
    );
  }
}

class _UserHomeTab extends StatefulWidget {
  const _UserHomeTab({super.key, required this.source});

  final HomeUserListSource source;

  @override
  State<_UserHomeTab> createState() => _UserHomeTabState();
}

class _UserHomeTabState extends _KeepAliveHomeTabState<_UserHomeTab> {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return DataNestedRefreshView(
      onRefresh: () => widget.source.refresh(widget.source.isEmpty),
      builder: (context, refresh) {
        return NestedScrollView(
          key: const PageStorageKey<String>('home-users-nested-scroll'),
          controller: refresh.scrollController,
          physics: refresh.physics,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return const <Widget>[];
          },
          body: refresh.body(
            builder: (context, locators) {
              return _UserHomeBody(source: widget.source, physics: refresh.physics, locators: locators);
            },
          ),
        );
      },
    );
  }
}

class _IllustHomeBody extends StatelessWidget {
  const _IllustHomeBody({required this.source, required this.homeType, required this.physics, required this.locators});

  final HomeIllustListSource source;
  final HomeType homeType;
  final ScrollPhysics? physics;
  final DataRefreshLocators locators;

  @override
  Widget build(BuildContext context) {
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return DataLoadingCustomScrollView(
        physics: physics,
        slivers: [
          ?locators.sliverHeader,
          const _IllustRankingPreviewSkeleton(),
          const _HomeSectionHeaderSkeleton(),
          const _SliverHomeIllustPreviewerSkeletonWaterfall(),
        ],
      );
    }

    if (!source.initialized && lastError != null) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: ErrorContent(message: formatPixivError(lastError), onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: EmptyContent(icon: Icons.image_not_supported_outlined, title: context.t.home.emptyTitle, message: context.t.home.emptyMessage),
      );
    }

    return DataLoadingCustomScrollView(
      key: PageStorageKey<String>('home-${homeType.name}-body-scroll'),
      physics: physics,
      slivers: [
        ?locators.sliverHeader,
        _IllustRankingPreviewSection(items: source.rankingIllusts, homeType: homeType),
        const _HomeSectionHeader(),
        SliverDataWaterfallGrid<Illust>(
          source: source,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          itemBuilder: (context, illust, index) {
            return IllustPreviewer(
              illust: illust,
              onTap: () {
                context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': '${illust.id}'}, extra: illust);
              },
            );
          },
        ),
      ],
    );
  }
}

class _NovelHomeBody extends StatelessWidget {
  const _NovelHomeBody({required this.source, required this.physics, required this.locators});

  final HomeNovelListSource source;
  final ScrollPhysics? physics;
  final DataRefreshLocators locators;

  @override
  Widget build(BuildContext context) {
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return DataLoadingCustomScrollView(
        physics: physics,
        slivers: [?locators.sliverHeader, const _NovelRankingPreviewSkeleton(), const _HomeSectionHeaderSkeleton(), const _SliverNovelPreviewerSkeletonList()],
      );
    }

    if (!source.initialized && lastError != null) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: ErrorContent(message: formatPixivError(lastError), onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: EmptyContent(icon: Icons.menu_book_outlined, title: context.t.home.emptyTitle, message: context.t.home.emptyMessage),
      );
    }

    return DataLoadingCustomScrollView(
      key: const PageStorageKey<String>('home-novels-body-scroll'),
      physics: physics,
      slivers: [
        ?locators.sliverHeader,
        _NovelRankingPreviewSection(items: source.rankingNovels),
        const _HomeSectionHeader(),
        SliverDataList<Novel>(
          source: source,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          itemBuilder: (context, novel, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NovelPreviewer(
                novel: novel,
                onTap: () {
                  context.pushNamed(AppRoute.novelDetail.name, pathParameters: {'id': '${novel.id}'}, extra: novel);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _UserHomeBody extends StatelessWidget {
  const _UserHomeBody({required this.source, required this.physics, required this.locators});

  final HomeUserListSource source;
  final ScrollPhysics? physics;
  final DataRefreshLocators locators;

  @override
  Widget build(BuildContext context) {
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return DataLoadingCustomScrollView(
        physics: physics,
        slivers: [
          ?locators.sliverHeader,
          const SliverPadding(padding: EdgeInsets.fromLTRB(12, 0, 12, 12), sliver: SliverUserPreviewerSkeletonList()),
        ],
      );
    }

    if (!source.initialized && lastError != null) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: ErrorContent(message: formatPixivError(lastError), onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: EmptyContent(icon: Icons.people_outline, title: context.t.home.emptyTitle, message: context.t.home.emptyMessage),
      );
    }

    return DataLoadingCustomScrollView(
      key: const PageStorageKey<String>('home-users-body-scroll'),
      physics: physics,
      slivers: [
        ?locators.sliverHeader,
        SliverDataList<UserPreview>(
          source: source,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          itemBuilder: (context, userPreview, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: UserPreviewer(userPreview: userPreview),
            );
          },
        ),
      ],
    );
  }
}

class _IllustRankingPreviewSection extends StatelessWidget {
  const _IllustRankingPreviewSection({required this.items, required this.homeType});

  final List<Illust> items;
  final HomeType homeType;
  static const itemSize = 178.0;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final translations = context.t;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Row(
                children: [
                  Expanded(child: Text(translations.home.rankings, style: Theme.of(context).textTheme.titleMedium)),
                  TextButton(
                    onPressed: () {
                      context.push(_rankingRoutePath(homeType));
                    },
                    child: Text(translations.home.seeMore),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: itemSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.only(end: 16),
                itemCount: items.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 12);
                },
                itemBuilder: (context, index) {
                  final illust = items[index];

                  return SizedBox.square(
                    dimension: itemSize,
                    child: IllustPreviewer(
                      illust: illust,
                      square: true,
                      onTap: () {
                        context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': '${illust.id}'}, extra: illust);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustRankingPreviewSkeleton extends StatelessWidget {
  const _IllustRankingPreviewSkeleton();

  static const itemSize = _IllustRankingPreviewSection.itemSize;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
        child: Skeletonizer.zone(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HomeSectionTitleRowSkeleton(),
              SizedBox(
                height: itemSize,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  itemCount: 6,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => const SizedBox.square(dimension: itemSize, child: _IllustRankingCardSkeleton()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IllustRankingCardSkeleton extends StatelessWidget {
  const _IllustRankingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Bone(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(8)),
    );
  }
}

const _homeIllustSkeletonRatios = <double>[1.32, 0.78, 1.08, 1.58, 0.92, 1.22, 1.44, 0.86, 1.16, 0.88, 1.42, 1.02];

class _SliverHomeIllustPreviewerSkeletonWaterfall extends StatelessWidget {
  const _SliverHomeIllustPreviewerSkeletonWaterfall();

  @override
  Widget build(BuildContext context) {
    return SliverWaterfallGrid<double>(
      items: _homeIllustSkeletonRatios,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      itemBuilder: (context, ratio, index) => _HomeIllustPreviewerSkeleton(aspectRatio: ratio),
    );
  }
}

class _HomeIllustPreviewerSkeleton extends StatelessWidget {
  const _HomeIllustPreviewerSkeleton({required this.aspectRatio});

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: const Bone(width: double.infinity, height: double.infinity),
            ),
            const Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(width: double.infinity),
                        SizedBox(height: 7),
                        Bone.text(width: 96),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Bone.circle(size: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovelRankingPreviewSection extends StatelessWidget {
  const _NovelRankingPreviewSection({required this.items});

  final List<Novel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final translations = context.t;
    final width = isDesktopPlatform ? 420.0 : MediaQuery.sizeOf(context).width * 0.86;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Row(
                children: [
                  Expanded(child: Text(translations.home.rankings, style: Theme.of(context).textTheme.titleMedium)),
                  TextButton(
                    onPressed: () {
                      context.push(_rankingRoutePath(HomeType.novels));
                    },
                    child: Text(translations.home.seeMore),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.only(end: 16),
                itemCount: items.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 12);
                },
                itemBuilder: (context, index) {
                  final novel = items[index];

                  return SizedBox(
                    width: width,
                    child: NovelPreviewer(
                      novel: novel,
                      maxWidth: width,
                      onTap: () {
                        context.pushNamed(AppRoute.novelDetail.name, pathParameters: {'id': '${novel.id}'}, extra: novel);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovelRankingPreviewSkeleton extends StatelessWidget {
  const _NovelRankingPreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = isDesktopPlatform ? 420.0 : MediaQuery.sizeOf(context).width * 0.86;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
        child: Skeletonizer.zone(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HomeSectionTitleRowSkeleton(),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  itemCount: 4,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: width,
                      child: _NovelPreviewerSkeleton(maxWidth: width),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Text(context.t.home.recommended, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _HomeSectionHeaderSkeleton extends StatelessWidget {
  const _HomeSectionHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Skeletonizer.zone(child: Text(context.t.home.recommended, style: Theme.of(context).textTheme.titleMedium)),
      ),
    );
  }
}

class _HomeSectionTitleRowSkeleton extends StatelessWidget {
  const _HomeSectionTitleRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return Skeletonizer.zone(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: Row(
          children: [
            Expanded(child: Text(translations.home.rankings, style: Theme.of(context).textTheme.titleMedium)),
            TextButton(onPressed: () {}, child: Text(translations.home.seeMore)),
          ],
        ),
      ),
    );
  }
}

class _SliverNovelPreviewerSkeletonList extends StatelessWidget {
  const _SliverNovelPreviewerSkeletonList();

  static const itemCount = 8;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      sliver: SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const Padding(padding: EdgeInsets.only(bottom: 8), child: _NovelPreviewerSkeleton());
        },
      ),
    );
  }
}

class _NovelPreviewerSkeleton extends StatelessWidget {
  const _NovelPreviewerSkeleton({this.maxWidth});

  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final card = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth.isFinite && constraints.maxWidth < 300;
        final coverWidth = compact ? 68.0 : 82.0;
        final coverHeight = compact ? 96.0 : 116.0;
        final bookmarkSize = compact ? 34.0 : 40.0;
        final coverGap = compact ? 8.0 : 12.0;
        final bookmarkGap = compact ? 6.0 : 8.0;

        return Skeletonizer.zone(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone(width: coverWidth, height: coverHeight, borderRadius: BorderRadius.circular(6)),
                  SizedBox(width: coverGap),
                  Expanded(child: _NovelPreviewBodySkeleton(height: coverHeight)),
                  SizedBox(width: bookmarkGap),
                  Bone.circle(size: bookmarkSize),
                ],
              ),
            ),
          ),
        );
      },
    );

    final maxWidth = this.maxWidth;
    if (maxWidth == null) {
      return card;
    }

    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: card,
      ),
    );
  }
}

class _NovelPreviewBodySkeleton extends StatelessWidget {
  const _NovelPreviewBodySkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Bone.text(width: double.infinity),
          const SizedBox(height: 7),
          const FractionallySizedBox(widthFactor: 0.62, child: Bone.text(width: double.infinity)),
          const SizedBox(height: 12),
          const Row(
            children: [
              Flexible(
                flex: 4,
                child: Bone(width: double.infinity, height: 24, borderRadius: BorderRadius.all(Radius.circular(999))),
              ),
              SizedBox(width: 5),
              Flexible(
                flex: 5,
                child: Bone(width: double.infinity, height: 24, borderRadius: BorderRadius.all(Radius.circular(999))),
              ),
            ],
          ),
          const Spacer(),
          const Row(
            children: [
              Flexible(
                flex: 5,
                child: Bone(width: double.infinity, height: 22, borderRadius: BorderRadius.all(Radius.circular(6))),
              ),
              SizedBox(width: 6),
              Flexible(
                flex: 4,
                child: Bone(width: double.infinity, height: 22, borderRadius: BorderRadius.all(Radius.circular(6))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _rankingRoutePath(HomeType type) {
  return switch (type) {
    HomeType.illustrations => AppRoute.rankingIllust.path,
    HomeType.manga => AppRoute.rankingManga.path,
    HomeType.novels => AppRoute.rankingNovel.path,
    HomeType.users => AppRoute.rankingIllust.path,
  };
}

class _SliverFillBody extends StatelessWidget {
  const _SliverFillBody({required this.child, required this.physics, this.sliverHeader});

  final Widget child;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  Widget build(BuildContext context) {
    return DataSliverFillBody(physics: physics, sliverHeader: sliverHeader, child: child);
  }
}

class _HomeTypeSelector extends StatelessWidget {
  const _HomeTypeSelector({required this.controller, required this.onTypeChanged});

  final TabController controller;
  final ValueChanged<HomeType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = isDesktopPlatform && constraints.maxWidth > 560 ? 560.0 : constraints.maxWidth;

        return Align(
          alignment: isDesktopPlatform ? AlignmentDirectional.center : AlignmentDirectional.centerStart,
          child: SizedBox(
            width: width,
            height: 44,
            child: TabBar(
              controller: controller,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: [
                Tab(child: Text(translations.home.illustrations)),
                Tab(child: Text(translations.home.manga)),
                Tab(child: Text(translations.home.novels)),
                Tab(child: Text(translations.home.users)),
              ],
              onTap: (index) {
                onTypeChanged(_HomePageState._homeTypeForIndex(index));
              },
            ),
          ),
        );
      },
    );
  }
}
