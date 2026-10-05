import 'package:freepiv/app/router/app_navigation.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/illust_waterfall_skeleton.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
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
  final _scrollKeys = List.generate(4, (_) => GlobalKey<NestedScrollViewState>());
  ValueListenable<({int index, int sequence})>? _primaryReselection;

  @override
  void initState() {
    super.initState();

    _homeTabController = TabController(
      length: _homeTypes.length,
      initialIndex: _homeTypeIndex(ref.read(homeProvider)),
      animationDuration: FrostMotion.navigation,
      vsync: this,
    );
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = FrostShellNavigationScope.maybeOf(context)?.primaryReselection;
    if (identical(next, _primaryReselection)) return;
    _primaryReselection?.removeListener(_handlePrimaryReselection);
    _primaryReselection = next;
    next?.addListener(_handlePrimaryReselection);
  }

  void _handlePrimaryReselection() {
    final signal = _primaryReselection?.value;
    if (signal == null || appRouteDestinations[signal.index].route != AppRoute.home || signal.sequence == 0) return;
    final scroll = _scrollKeys[_homeTabController.index].currentState?.innerController;
    if (scroll == null || !scroll.hasClients) return;
    final duration = FrostMotion.duration(context, FrostMotion.navigation);
    if (duration == Duration.zero) {
      scroll.jumpTo(0);
    } else {
      scroll.animateTo(0, duration: duration, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _primaryReselection?.removeListener(_handlePrimaryReselection);
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
        // The type tabs float over the feed; artwork scrolls beneath them.
        child: FrostPinnedChrome(
          extent: MediaQuery.paddingOf(context).top + kTextTabBarHeight,
          chrome: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: EdgeInsets.symmetric(horizontal: FrostMetrics.pageTabInset(constraints.maxWidth)),
                child: _HomeTypeSelector(controller: _homeTabController, onTypeChanged: (type) => ref.read(homeProvider.notifier).setType(type)),
              ),
            ),
          ),
          body: AnimatedBuilder(
            animation: Listenable.merge([illustSource, mangaSource, novelSource, userSource]),
            builder: (context, child) {
              return MouseDragScroll(
                child: TabBarView(
                  controller: _homeTabController,
                  children: [
                    _IllustHomeTab(
                      key: const PageStorageKey('home-illustrations'),
                      scrollKey: _scrollKeys[0],
                      source: illustSource,
                      homeType: HomeType.illustrations,
                    ),
                    _IllustHomeTab(key: const PageStorageKey('home-manga'), scrollKey: _scrollKeys[1], source: mangaSource, homeType: HomeType.manga),
                    _NovelHomeTab(key: const PageStorageKey('home-novels'), scrollKey: _scrollKeys[2], source: novelSource),
                    _UserHomeTab(key: const PageStorageKey('home-users'), scrollKey: _scrollKeys[3], source: userSource),
                  ],
                ),
              );
            },
          ),
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
  const _IllustHomeTab({super.key, required this.scrollKey, required this.source, required this.homeType});

  final GlobalKey<NestedScrollViewState> scrollKey;
  final HomeIllustListSource source;
  final HomeType homeType;

  @override
  State<_IllustHomeTab> createState() => _IllustHomeTabState();
}

class _IllustHomeTabState extends _KeepAliveHomeTabState<_IllustHomeTab> {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FrostNestedRefreshView(
      onRefresh: () => widget.source.refresh(widget.source.isEmpty),
      builder: (context, refresh) {
        return NestedScrollView(
          key: widget.scrollKey,
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
  const _NovelHomeTab({super.key, required this.scrollKey, required this.source});

  final GlobalKey<NestedScrollViewState> scrollKey;
  final HomeNovelListSource source;

  @override
  State<_NovelHomeTab> createState() => _NovelHomeTabState();
}

class _NovelHomeTabState extends _KeepAliveHomeTabState<_NovelHomeTab> {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FrostNestedRefreshView(
      onRefresh: () => widget.source.refresh(widget.source.isEmpty),
      builder: (context, refresh) {
        return NestedScrollView(
          key: widget.scrollKey,
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
  const _UserHomeTab({super.key, required this.scrollKey, required this.source});

  final GlobalKey<NestedScrollViewState> scrollKey;
  final HomeUserListSource source;

  @override
  State<_UserHomeTab> createState() => _UserHomeTabState();
}

class _UserHomeTabState extends _KeepAliveHomeTabState<_UserHomeTab> {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FrostNestedRefreshView(
      onRefresh: () => widget.source.refresh(widget.source.isEmpty),
      builder: (context, refresh) {
        return NestedScrollView(
          key: widget.scrollKey,
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
  final FrostRefreshLocators locators;

  @override
  Widget build(BuildContext context) => FrostLoadStateSwitcher(phase: source.phase, child: _buildPhase(context));

  Widget _buildPhase(BuildContext context) {
    final lastError = source.lastError;

    if (source.phase == FrostLoadPhase.loading) {
      return FrostLoadingScrollView(
        physics: physics,
        slivers: [
          const FrostChromeSpacer(),
          ?locators.sliverHeader,
          const _IllustRankingPreviewSkeleton(),
          const _HomeSectionHeader(skeleton: true),
          const SliverIllustWaterfallSkeleton(),
        ],
      );
    }

    if (!source.initialized && lastError != null) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: FrostErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: FrostEmptyContent(
          icon: FrostIconData.glyph(Icons.image_not_supported_outlined),
          title: context.t.home.emptyTitle,
          message: context.t.home.emptyMessage,
        ),
      );
    }

    return FrostLoadingScrollView(
      key: PageStorageKey<String>('home-${homeType.name}-body-scroll'),
      physics: physics,
      slivers: [
        const FrostChromeSpacer(),
        ?locators.sliverHeader,
        _IllustRankingPreviewSection(items: source.rankingIllusts, homeType: homeType),
        const _HomeSectionHeader(),
        FrostSliverDataWaterfallGrid<Illust>(
          firstLoadSkeleton: const FullScreenLoadingSkeleton(),
          source: source,
          itemBuilder: (context, illust, index) {
            return IllustPreviewer(illust: illust, onOpen: (heroTag) => openIllustDetail(context, illust, heroTag));
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
  final FrostRefreshLocators locators;

  @override
  Widget build(BuildContext context) => FrostLoadStateSwitcher(phase: source.phase, child: _buildPhase(context));

  Widget _buildPhase(BuildContext context) {
    final lastError = source.lastError;

    if (source.phase == FrostLoadPhase.loading) {
      return FrostLoadingScrollView(
        physics: physics,
        slivers: [
          const FrostChromeSpacer(),
          ?locators.sliverHeader,
          const _NovelRankingPreviewSkeleton(),
          const _HomeSectionHeader(alignToNovelList: true, skeleton: true),
          const _SliverNovelPreviewerSkeletonList(),
        ],
      );
    }

    if (!source.initialized && lastError != null) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: FrostErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: FrostEmptyContent(icon: FrostIconData.glyph(Icons.menu_book_outlined), title: context.t.home.emptyTitle, message: context.t.home.emptyMessage),
      );
    }

    return FrostLoadingScrollView(
      key: const PageStorageKey<String>('home-novels-body-scroll'),
      physics: physics,
      slivers: [
        const FrostChromeSpacer(),
        ?locators.sliverHeader,
        _NovelRankingPreviewSection(items: source.rankingNovels),
        const _HomeSectionHeader(alignToNovelList: true),
        FrostSliverDataList<Novel>(
          firstLoadSkeleton: const FullScreenLoadingSkeleton(),
          source: source,
          padding: _homeListPadding(context),
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
  final FrostRefreshLocators locators;

  @override
  Widget build(BuildContext context) => FrostLoadStateSwitcher(phase: source.phase, child: _buildPhase(context));

  Widget _buildPhase(BuildContext context) {
    final lastError = source.lastError;

    if (source.phase == FrostLoadPhase.loading) {
      return FrostLoadingScrollView(physics: physics, slivers: [const FrostChromeSpacer(), ?locators.sliverHeader, const SliverUserPreviewerSkeletonGrid()]);
    }

    if (!source.initialized && lastError != null) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: FrostErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return _SliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: FrostEmptyContent(icon: FrostIconData.glyph(Icons.people_outline), title: context.t.home.emptyTitle, message: context.t.home.emptyMessage),
      );
    }

    return FrostLoadingScrollView(
      key: const PageStorageKey<String>('home-users-body-scroll'),
      physics: physics,
      slivers: [
        const FrostChromeSpacer(),
        ?locators.sliverHeader,
        SliverUserPreviewGrid(source: source),
      ],
    );
  }
}

/// Square ranking tiles that fill the row with whole items at any width.
double _rankingTileExtent(double width) {
  final inset = FrostMetrics.browseInset(width);
  final available = width - inset * 2;
  final count = math.max(1, ((available + FrostMetrics.itemGap) / (190 + FrostMetrics.itemGap)).floor());
  return FrostShelf.fillingExtent(width: available, count: count, min: 150, max: 220);
}

class _IllustRankingPreviewSection extends StatelessWidget {
  const _IllustRankingPreviewSection({required this.items, required this.homeType});

  final List<Illust> items;
  final HomeType homeType;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final translations = context.t;
    final extent = _rankingTileExtent(MediaQuery.sizeOf(context).width);

    return SliverToBoxAdapter(
      child: FrostShelf(
        title: translations.home.rankings,
        itemCount: items.length,
        itemExtent: extent,
        height: extent,
        action: TextButton(onPressed: () => context.push(_rankingRoutePath(homeType)), child: Text(translations.home.seeMore)),
        itemBuilder: (context, index) {
          final illust = items[index];
          return IllustPreviewer(
            illust: illust,
            square: true,
            leadingBadge: _RankBadge(rank: index + 1),
            onOpen: (heroTag) => openIllustDetail(context, illust, heroTag),
          );
        },
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .6), borderRadius: BorderRadius.circular(FrostMetrics.badgeRadius)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Text(
            '$rank',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _IllustRankingPreviewSkeleton extends StatelessWidget {
  const _IllustRankingPreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final extent = _rankingTileExtent(width);
    final inset = FrostMetrics.browseInset(width);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FrostShelfHeader(title: context.t.home.rankings, inset: inset, skeleton: true),
          SizedBox(
            height: extent,
            child: Skeletonizer.zone(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: inset),
                itemCount: 8,
                separatorBuilder: (context, index) => const SizedBox(width: FrostMetrics.itemGap),
                itemBuilder: (context, index) => SizedBox.square(dimension: extent, child: const _IllustRankingCardSkeleton()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustRankingCardSkeleton extends StatelessWidget {
  const _IllustRankingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return FrostCard(
      child: Bone(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(FrostMetrics.controlRadius)),
    );
  }
}

/// The novel tab is a centred reading column; its shelf, title and list all
/// share that column instead of the shelf spanning the window.
class _NovelColumn extends StatelessWidget {
  const _NovelColumn({required this.child});

  final Widget child;

  static double inset(BuildContext context) => FrostMetrics.browseInset(MediaQuery.sizeOf(context).width);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FrostMetrics.contentMaxWidth),
        child: child,
      ),
    );
  }
}

double _novelShelfCardWidth(BuildContext context) => (MediaQuery.sizeOf(context).width * 0.86).clamp(0.0, 420.0);

class _NovelRankingPreviewSection extends StatelessWidget {
  const _NovelRankingPreviewSection({required this.items});

  final List<Novel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final translations = context.t;
    final width = _novelShelfCardWidth(context);

    return SliverToBoxAdapter(
      child: _NovelColumn(
        child: FrostShelf(
          title: translations.home.rankings,
          inset: _NovelColumn.inset(context),
          itemCount: items.length,
          itemExtent: width,
          height: NovelPreviewer.contentHeight(context) + 24,
          action: TextButton(onPressed: () => context.push(_rankingRoutePath(HomeType.novels)), child: Text(translations.home.seeMore)),
          itemBuilder: (context, index) {
            final novel = items[index];
            return NovelPreviewer(
              novel: novel,
              maxWidth: width,
              onTap: () {
                context.pushNamed(AppRoute.novelDetail.name, pathParameters: {'id': '${novel.id}'}, extra: novel);
              },
            );
          },
        ),
      ),
    );
  }
}

class _NovelRankingPreviewSkeleton extends StatelessWidget {
  const _NovelRankingPreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = _novelShelfCardWidth(context);
    final inset = _NovelColumn.inset(context);

    return SliverToBoxAdapter(
      child: _NovelColumn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FrostShelfHeader(title: context.t.home.rankings, inset: inset, skeleton: true),
            SizedBox(
              height: NovelPreviewer.contentHeight(context) + 24,
              child: Skeletonizer.zone(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: inset),
                  itemCount: 4,
                  separatorBuilder: (context, index) => const SizedBox(width: FrostMetrics.itemGap),
                  itemBuilder: (context, index) => SizedBox(
                    width: width,
                    child: _NovelPreviewerSkeleton(maxWidth: width),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({this.alignToNovelList = false, this.skeleton = false});

  final bool alignToNovelList;
  final bool skeleton;

  @override
  Widget build(BuildContext context) {
    final header = FrostShelfHeader(title: context.t.home.recommended, inset: FrostMetrics.browseInset(MediaQuery.sizeOf(context).width), skeleton: skeleton);
    return SliverToBoxAdapter(child: alignToNovelList ? _NovelColumn(child: header) : header);
  }
}

/// The novel list and its skeleton on the shared content column.
EdgeInsets _homeListPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return FrostMetrics.columnPadding(width).copyWith(top: 4, bottom: FrostMetrics.browseInset(width));
}

class _SliverNovelPreviewerSkeletonList extends StatelessWidget {
  const _SliverNovelPreviewerSkeletonList();

  static const itemCount = 8;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: _homeListPadding(context),
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
    const card = NovelPreviewerSkeleton();

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
    return FrostSliverFillBody(physics: physics, sliverHeader: sliverHeader, leadingSlivers: const [FrostChromeSpacer()], child: child);
  }
}

class _HomeTypeSelector extends StatelessWidget {
  const _HomeTypeSelector({required this.controller, required this.onTypeChanged});

  final TabController controller;
  final ValueChanged<HomeType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return MouseDragScroll(
      child: FrostTabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.symmetric(horizontal: FrostMetrics.tabLabelPadding(MediaQuery.sizeOf(context).width)),
        tabs: [
          Tab(text: translations.home.illustrations),
          Tab(text: translations.home.manga),
          Tab(text: translations.home.novels),
          Tab(text: translations.home.users),
        ],
        onTap: (index) => onTypeChanged(_HomePageState._homeTypeForIndex(index)),
      ),
    );
  }
}
