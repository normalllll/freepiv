import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/ranking/logic/ranking_logic.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_novel_list_tab.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/illust_waterfall_skeleton.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:go_router/go_router.dart';

const _rankingTabBarHeight = 48.0;

class RankingIllustPage extends ConsumerStatefulWidget {
  const RankingIllustPage({super.key});

  @override
  ConsumerState<RankingIllustPage> createState() => _RankingIllustPageState();
}

class _RankingIllustPageState extends ConsumerState<RankingIllustPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: IllustRankingMode.values.length,
      initialIndex: _illustRankingModeIndex(ref.read(rankingProvider).illustMode),
      vsync: this,
    );
    _tabController.addListener(_handleTabChanged);

    Future.microtask(() {
      ref.read(rankingProvider.notifier).loadIllustCurrentIfNeeded();
    });
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    final mode = _illustRankingModeForIndex(_tabController.index);
    if (ref.read(rankingProvider).illustMode == mode) {
      return;
    }

    ref.read(rankingProvider.notifier).setIllustMode(mode);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rankingProvider);

    ref.listen<RankingState>(rankingProvider, (previous, next) {
      final index = _illustRankingModeIndex(next.illustMode);
      if (_tabController.index == index) {
        return;
      }

      _tabController.animateTo(index);
    });

    return _RankingPageScaffold(
      child: Column(
        children: [
          _RankingHeader(
            child: _IllustRankingTabBar(
              controller: _tabController,
              onModeChanged: (mode) {
                ref.read(rankingProvider.notifier).setIllustMode(mode);
              },
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge(state.illustSources.values.toList()),
              builder: (context, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    for (final mode in IllustRankingMode.values)
                      _IllustRankingTab(key: PageStorageKey('ranking-illust-$mode'), source: state.illustSourceFor(mode)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RankingMangaPage extends ConsumerStatefulWidget {
  const RankingMangaPage({super.key});

  @override
  ConsumerState<RankingMangaPage> createState() => _RankingMangaPageState();
}

class _RankingMangaPageState extends ConsumerState<RankingMangaPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: MangaRankingMode.values.length,
      initialIndex: _mangaRankingModeIndex(ref.read(rankingProvider).mangaMode),
      vsync: this,
    );
    _tabController.addListener(_handleTabChanged);

    Future.microtask(() {
      ref.read(rankingProvider.notifier).loadMangaCurrentIfNeeded();
    });
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    final mode = _mangaRankingModeForIndex(_tabController.index);
    if (ref.read(rankingProvider).mangaMode == mode) {
      return;
    }

    ref.read(rankingProvider.notifier).setMangaMode(mode);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rankingProvider);

    ref.listen<RankingState>(rankingProvider, (previous, next) {
      final index = _mangaRankingModeIndex(next.mangaMode);
      if (_tabController.index == index) {
        return;
      }

      _tabController.animateTo(index);
    });

    return _RankingPageScaffold(
      child: Column(
        children: [
          _RankingHeader(
            child: _MangaRankingTabBar(
              controller: _tabController,
              onModeChanged: (mode) {
                ref.read(rankingProvider.notifier).setMangaMode(mode);
              },
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge(state.mangaSources.values.toList()),
              builder: (context, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    for (final mode in MangaRankingMode.values)
                      _MangaRankingTab(key: PageStorageKey('ranking-manga-$mode'), source: state.mangaSourceFor(mode)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RankingNovelPage extends ConsumerStatefulWidget {
  const RankingNovelPage({super.key});

  @override
  ConsumerState<RankingNovelPage> createState() => _RankingNovelPageState();
}

class _RankingNovelPageState extends ConsumerState<RankingNovelPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: NovelRankingMode.values.length,
      initialIndex: _novelRankingModeIndex(ref.read(rankingProvider).novelMode),
      vsync: this,
    );
    _tabController.addListener(_handleTabChanged);

    Future.microtask(() {
      ref.read(rankingProvider.notifier).loadNovelCurrentIfNeeded();
    });
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    final mode = _novelRankingModeForIndex(_tabController.index);
    if (ref.read(rankingProvider).novelMode == mode) {
      return;
    }

    ref.read(rankingProvider.notifier).setNovelMode(mode);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rankingProvider);

    ref.listen<RankingState>(rankingProvider, (previous, next) {
      final index = _novelRankingModeIndex(next.novelMode);
      if (_tabController.index == index) {
        return;
      }

      _tabController.animateTo(index);
    });

    return _RankingPageScaffold(
      child: Column(
        children: [
          _RankingHeader(
            child: _NovelRankingTabBar(
              controller: _tabController,
              onModeChanged: (mode) {
                ref.read(rankingProvider.notifier).setNovelMode(mode);
              },
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge(state.novelSources.values.toList()),
              builder: (context, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    for (final mode in NovelRankingMode.values)
                      _NovelRankingTab(key: PageStorageKey('ranking-novel-$mode'), source: state.novelSourceFor(mode)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingPageScaffold extends StatelessWidget {
  const _RankingPageScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        return Scaffold(
          appBar: shouldUseDesktopShell ? null : AppBar(title: Text(context.t.navigation.ranking)),
          body: child,
        );
      },
    );
  }
}

class _RankingHeader extends StatelessWidget {
  const _RankingHeader({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.42))),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(height: _rankingTabBarHeight, child: child),
        ),
      ),
    );
  }
}

class _IllustRankingTabBar extends StatelessWidget {
  const _IllustRankingTabBar({required this.controller, required this.onModeChanged});

  final TabController controller;
  final ValueChanged<IllustRankingMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
      onTap: (index) {
        onModeChanged(_illustRankingModeForIndex(index));
      },
      tabs: [for (final mode in IllustRankingMode.values) Tab(text: _rankingModeNameLabel(mode.name, translations))],
    );
  }
}

class _MangaRankingTabBar extends StatelessWidget {
  const _MangaRankingTabBar({required this.controller, required this.onModeChanged});

  final TabController controller;
  final ValueChanged<MangaRankingMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
      onTap: (index) {
        onModeChanged(_mangaRankingModeForIndex(index));
      },
      tabs: [for (final mode in MangaRankingMode.values) Tab(text: _rankingModeNameLabel(mode.name, translations))],
    );
  }
}

class _NovelRankingTabBar extends StatelessWidget {
  const _NovelRankingTabBar({required this.controller, required this.onModeChanged});

  final TabController controller;
  final ValueChanged<NovelRankingMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
      onTap: (index) {
        onModeChanged(_novelRankingModeForIndex(index));
      },
      tabs: [for (final mode in NovelRankingMode.values) Tab(text: _rankingModeNameLabel(mode.name, translations))],
    );
  }
}

class _IllustRankingTab extends StatelessWidget {
  const _IllustRankingTab({required this.source, super.key});

  final RankingIllustListSource source;

  @override
  Widget build(BuildContext context) {
    return _ImageRankingTab(source: source);
  }
}

class _MangaRankingTab extends StatelessWidget {
  const _MangaRankingTab({required this.source, super.key});

  final RankingMangaListSource source;

  @override
  Widget build(BuildContext context) {
    return _ImageRankingTab(source: source);
  }
}

class _ImageRankingTab extends StatelessWidget {
  const _ImageRankingTab({required this.source});

  final DataListSource<Illust> source;

  @override
  Widget build(BuildContext context) {
    return DataNestedRefreshView(
      onRefresh: () => source.refresh(source.isEmpty),
      builder: (context, refresh) {
        return NestedScrollView(
          controller: refresh.scrollController,
          physics: refresh.physics,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return const <Widget>[];
          },
          body: refresh.body(
            builder: (context, locators) {
              return _ImageRankingBody(source: source, physics: refresh.physics, locators: locators);
            },
          ),
        );
      },
    );
  }
}

class _NovelRankingTab extends StatelessWidget {
  const _NovelRankingTab({required this.source, super.key});

  final RankingNovelListSource source;

  @override
  Widget build(BuildContext context) {
    return DataNestedRefreshView(
      onRefresh: () => source.refresh(source.isEmpty),
      builder: (context, refresh) {
        return NestedScrollView(
          controller: refresh.scrollController,
          physics: refresh.physics,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return const <Widget>[];
          },
          body: refresh.body(
            builder: (context, locators) {
              return _NovelRankingBody(source: source, physics: refresh.physics, locators: locators);
            },
          ),
        );
      },
    );
  }
}

class _ImageRankingBody extends StatelessWidget {
  const _ImageRankingBody({required this.source, required this.physics, required this.locators});

  final DataListSource<Illust> source;
  final ScrollPhysics? physics;
  final DataRefreshLocators locators;

  @override
  Widget build(BuildContext context) {
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return IllustWaterfallSkeleton(physics: physics, sliverHeader: locators.sliverHeader);
    }

    if (!source.initialized && lastError != null) {
      return DataSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: ErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return DataSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: EmptyContent(icon: Icons.emoji_events_outlined, title: context.t.ranking.emptyTitle, message: context.t.ranking.emptyMessage),
      );
    }

    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?locators.sliverHeader,
        SliverDataWaterfallGrid<Illust>(
          source: source,
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

class _NovelRankingBody extends StatelessWidget {
  const _NovelRankingBody({required this.source, required this.physics, required this.locators});

  final RankingNovelListSource source;
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
          const SliverPadding(padding: EdgeInsets.all(12), sliver: SliverListSkeleton(itemExtent: 140, itemCount: 8)),
        ],
      );
    }

    if (!source.initialized && lastError != null) {
      return DataSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: ErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return DataSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: EmptyContent(icon: Icons.menu_book_outlined, title: context.t.ranking.emptyTitle, message: context.t.ranking.emptyMessage),
      );
    }

    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?locators.sliverHeader,
        SliverDataList<Novel>(
          source: source,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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

int _illustRankingModeIndex(IllustRankingMode mode) {
  return IllustRankingMode.values.indexOf(mode);
}

IllustRankingMode _illustRankingModeForIndex(int index) {
  final values = IllustRankingMode.values;

  if (index <= 0) {
    return values.first;
  }

  if (index >= values.length - 1) {
    return values.last;
  }

  return values[index];
}

int _mangaRankingModeIndex(MangaRankingMode mode) {
  return MangaRankingMode.values.indexOf(mode);
}

MangaRankingMode _mangaRankingModeForIndex(int index) {
  final values = MangaRankingMode.values;

  if (index <= 0) {
    return values.first;
  }

  if (index >= values.length - 1) {
    return values.last;
  }

  return values[index];
}

int _novelRankingModeIndex(NovelRankingMode mode) {
  return NovelRankingMode.values.indexOf(mode);
}

NovelRankingMode _novelRankingModeForIndex(int index) {
  final values = NovelRankingMode.values;

  if (index <= 0) {
    return values.first;
  }

  if (index >= values.length - 1) {
    return values.last;
  }

  return values[index];
}

String _rankingModeNameLabel(String name, Translations translations) {
  return switch (name) {
    'day' => translations.ranking.modes.day,
    'dayR18' => translations.ranking.modes.dayR18,
    'dayMale' => translations.ranking.modes.dayMale,
    'dayMaleR18' => translations.ranking.modes.dayMaleR18,
    'dayFemale' => translations.ranking.modes.dayFemale,
    'dayFemaleR18' => translations.ranking.modes.dayFemaleR18,
    'dayAi' => translations.ranking.modes.dayAi,
    'dayR18Ai' => translations.ranking.modes.dayR18Ai,
    'week' => translations.ranking.modes.week,
    'weekR18' => translations.ranking.modes.weekR18,
    'weekOriginal' => translations.ranking.modes.weekOriginal,
    'weekRookie' => translations.ranking.modes.weekRookie,
    'month' => translations.ranking.modes.month,
    _ => name,
  };
}
