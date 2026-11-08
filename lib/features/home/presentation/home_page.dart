import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/work_actions.dart' show AppCardBookmarkButton;
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/destination_header.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/compositions/sectioned_page.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The home page: recommended illustrations, manga,
/// novels and users, each with its own feed, scroll position and refresh.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const types = [HomeType.illustrations, HomeType.manga, HomeType.novels, HomeType.users];

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: HomePage.types.length,
    initialIndex: HomePage.types.indexOf(ref.read(homeProvider)),
    animationDuration: FrostMotion.navigation,
    vsync: this,
  )..addListener(_tabChanged);
  final _scrolls = [for (final _ in HomePage.types) ScrollController()];
  ValueListenable<({int index, int sequence})>? _reselection;

  void _tabChanged() {
    if (_tabs.indexIsChanging) return;
    final type = HomePage.types[_tabs.index];
    if (ref.read(homeProvider) != type) ref.read(homeProvider.notifier).setType(type);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = FrostShellNavigationScope.maybeOf(context)?.primaryReselection;
    if (identical(next, _reselection)) return;
    _reselection?.removeListener(_reselected);
    _reselection = next?..addListener(_reselected);
  }

  /// Selecting Home again scrolls the current section back to its top.
  void _reselected() {
    final signal = _reselection?.value;
    if (signal == null || signal.sequence == 0 || appRouteDestinations[signal.index].route != AppRoute.home) return;
    final scroll = _scrolls[_tabs.index];
    if (!scroll.hasClients) return;
    final duration = FrostMotion.duration(context, FrostMotion.navigation);
    if (duration == Duration.zero) {
      scroll.jumpTo(0);
    } else {
      unawaited(scroll.animateTo(0, duration: duration, curve: Curves.easeOutCubic));
    }
  }

  @override
  void dispose() {
    _reselection?.removeListener(_reselected);
    _tabs.dispose();
    for (final scroll in _scrolls) {
      scroll.dispose();
    }
    super.dispose();
  }

  FrostListSource<Object?> _source(HomeType type) => switch (type) {
    HomeType.illustrations => ref.read(homeIllustSourceProvider),
    HomeType.manga => ref.read(homeMangaSourceProvider),
    HomeType.novels => ref.read(homeNovelSourceProvider),
    HomeType.users => ref.read(homeUserSourceProvider),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    ref.listen<HomeType>(homeProvider, (_, next) {
      final index = HomePage.types.indexOf(next);
      if (_tabs.index != index) _tabs.animateTo(index);
    });
    return AppSectionedPage(
      header: AppDestinationHeader(title: t.navigation.home),
      controller: _tabs,
      scrollControllers: _scrolls,
      tabs: [
        FrostTab(label: t.home.illustrations),
        FrostTab(label: t.home.manga),
        FrostTab(label: t.home.novels),
        FrostTab(label: t.home.users),
      ],
      onRefresh: (section) async => _source(HomePage.types[section]).refresh(false),
      slivers: (context, section) => switch (HomePage.types[section]) {
        HomeType.illustrations => _artworkSlivers(context, ref.watch(homeIllustSourceProvider), AppRankingKind.illust),
        HomeType.manga => _artworkSlivers(context, ref.watch(homeMangaSourceProvider), AppRankingKind.manga),
        HomeType.novels => _novelSlivers(context, ref.watch(homeNovelSourceProvider)),
        HomeType.users => _userSlivers(context, ref.watch(homeUserSourceProvider)),
      },
    );
  }
}

// The ranking shelf shows about six square works across a default window.
const _rankingTiles = 6;
const _rankingTileMin = 120.0;
const _rankingTileMax = 180.0;

// A ranked novel's cover against the cover in a row of the list.
const _novelTileScale = 1.5;

Widget _emptyFeed(BuildContext context) =>
    FrostEmptyState(icon: FrostIconSet.of(context).empty, title: context.t.home.emptyTitle, message: context.t.home.emptyMessage);

/// The ranking shelf of [kind] and the Recommended title above an artwork
/// feed, with bones for tiles while [ranking] is null.
Widget _artworkHead(BuildContext context, AppRankingKind kind, {List<Illust>? ranking}) {
  final t = context.t;
  return SliverMainAxisGroup(
    slivers: [
      SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final extent = FrostShelf.fillingExtent(width: constraints.maxWidth, count: _rankingTiles, min: _rankingTileMin, max: _rankingTileMax);
            return FrostShelf(
              title: t.home.rankings,
              action: FrostButton.quiet(
                label: t.home.seeMore,
                onPressed: () => GoRouter.of(context).push(AppLocations.ranking(kind: kind)),
              ),
              itemCount: ranking?.length ?? (constraints.maxWidth / extent).ceil(),
              itemExtent: extent,
              height: extent + AppArtworkCardFooter.extentOf(context),
              itemBuilder: (context, index) =>
                  ranking == null ? const AppArtworkCardSkeleton(aspectRatio: 1) : AppArtworkCard(illust: ranking[index], rank: index + 1, square: true),
            );
          },
        ),
      ),
      SliverToBoxAdapter(child: AppBrowseSectionHeader(title: t.home.recommended)),
    ],
  );
}

/// The novels' ranking shelf and the Recommended title above their list, with
/// bones for covers while [ranking] is null.
Widget _novelHead(BuildContext context, {List<Novel>? ranking}) {
  final t = context.t;
  const extent = AppNovelRow.coverWidth * _novelTileScale;
  return SliverMainAxisGroup(
    slivers: [
      SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) => FrostShelf(
            title: t.home.rankings,
            action: FrostButton.quiet(
              label: t.home.seeMore,
              onPressed: () => GoRouter.of(context).push(AppLocations.ranking(kind: AppRankingKind.novel)),
            ),
            itemCount: ranking?.length ?? (constraints.maxWidth / extent).ceil(),
            itemExtent: extent,
            height: extent / AppNovelRow.coverRatio + AppArtworkCardFooter.extentOf(context),
            itemBuilder: (context, index) =>
                ranking == null ? const AppArtworkCardSkeleton(aspectRatio: AppNovelRow.coverRatio) : _NovelCover(novel: ranking[index], rank: index + 1),
          ),
        ),
      ),
      SliverToBoxAdapter(child: AppBrowseSectionHeader(title: t.home.recommended)),
    ],
  );
}

List<Widget> _artworkSlivers(BuildContext context, HomeIllustListSource source, AppRankingKind kind) {
  return [
    StreamBuilder(
      stream: source.rebuild,
      builder: (context, _) => switch ((source.phase, source.rankingIllusts)) {
        (FrostLoadPhase.loading, _) => _artworkHead(context, kind),
        (FrostLoadPhase.content, final ranking) when ranking.isNotEmpty => _artworkHead(context, kind, ranking: ranking),
        _ => const SliverToBoxAdapter(),
      },
    ),
    FrostSliverDataWaterfallGrid<Illust>(
      source: source,
      firstLoadSkeleton: const AppArtworkWaterfallSkeleton(),
      empty: _emptyFeed(context),
      itemBuilder: (context, illust, index) => AppArtworkCard(illust: illust),
    ),
  ];
}

List<Widget> _novelSlivers(BuildContext context, HomeNovelListSource source) {
  return [
    StreamBuilder(
      stream: source.rebuild,
      builder: (context, _) => switch ((source.phase, source.rankingNovels)) {
        (FrostLoadPhase.loading, _) => _novelHead(context),
        (FrostLoadPhase.content, final ranking) when ranking.isNotEmpty => _novelHead(context, ranking: ranking),
        _ => const SliverToBoxAdapter(),
      },
    ),
    FrostSliverContentColumn(
      maxWidth: FrostMetrics.readingMaxWidth,
      sliver: FrostSliverDataList<Novel>(
        source: source,
        firstLoadSkeleton: const AppNovelRowsSkeleton(),
        empty: _emptyFeed(context),
        itemBuilder: (context, novel, index) => AppNovelRow(novel: novel),
      ),
    ),
  ];
}

List<Widget> _userSlivers(BuildContext context, HomeUserListSource source) => [
  FrostSliverContentColumn(
    maxWidth: FrostMetrics.readingMaxWidth,
    sliver: FrostSliverDataList<UserPreview>(
      source: source,
      firstLoadSkeleton: const AppUserRowsSkeleton(),
      empty: _emptyFeed(context),
      itemBuilder: (context, preview, index) => AppUserRow(preview: preview),
    ),
  ),
];

/// A ranked novel in the ranking shelf: its cover with the rank, then its
/// title and author with the bookmark button.
class _NovelCover extends StatelessWidget {
  const _NovelCover({required this.novel, required this.rank});

  final Novel novel;
  final int rank;

  @override
  Widget build(BuildContext context) => FrostMediaCard(
    media: AppPixivImage(url: novel.imageUrls.medium, aspectRatio: AppNovelRow.coverRatio, radius: 0),
    aspectRatio: AppNovelRow.coverRatio,
    topStart: FrostBadge(label: '$rank', tone: FrostBadgeTone.onMedia),
    footer: AppArtworkCardFooter(
      title: novel.title,
      author: novel.user.name,
      bookmark: AppCardBookmarkButton(workId: novel.id, initiallyBookmarked: novel.isBookmarked, novel: true),
    ),
    semanticLabel: context.t.artworkCard.semantics(title: novel.title, author: novel.user.name),
    onPressed: () => GoRouter.of(context).push(AppLocations.novel(novel.id), extra: novel),
  );
}
