import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/work_actions.dart' show AppCardBookmarkButton;
import 'package:freepiv/ui/compositions/content_rows.dart';
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
      header: const _HomeHeader(),
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

/// The page header: the page title in the title-bar layout; the way to Me
/// and to search where the title row holds no search.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    if (FrostShell.titleContentInCaptionOf(context)) return FrostPageHeader(title: FrostText(t.navigation.home));
    final account = pixivAccountNotifier.value?.user;
    final avatarUrl = account?.profileImageUrls.px170X170 ?? '';
    return FrostPageHeader(
      leading: [
        if (account != null)
          Semantics(
            button: true,
            label: t.navigation.me,
            excludeSemantics: true,
            child: FrostClickSurface(
              shape: const FrostClickShape.circle(),
              onTap: () => GoRouter.of(context).go(AppRoute.me.path),
              child: FrostAvatar.person(
                name: account.name,
                colorKey: account.id,
                size: FrostAvatarSize.small,
                image: avatarUrl.isEmpty ? null : pixivImageProvider(ref, avatarUrl),
              ),
            ),
          ),
      ],
      middle: FrostSearchEntry(
        key: const ValueKey('home-search-entry'),
        placeholder: t.appSearch.placeholder,
        onPressed: () => openAppSearch(ref, GoRouter.of(context)),
      ),
    );
  }
}

// The ranking shelf shows about six square works across a default window.
const _rankingTiles = 6;
const _rankingTileMin = 120.0;
const _rankingTileMax = 180.0;

Widget _emptyFeed(BuildContext context) =>
    FrostEmptyState(icon: FrostIconSet.of(context).empty, title: context.t.home.emptyTitle, message: context.t.home.emptyMessage);

List<Widget> _artworkSlivers(BuildContext context, HomeIllustListSource source, AppRankingKind kind) {
  final t = context.t;
  return [
    StreamBuilder(
      stream: source.rebuild,
      builder: (context, _) {
        final ranking = source.rankingIllusts;
        if (source.phase != FrostLoadPhase.content || ranking.isEmpty) return const SliverToBoxAdapter();
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
                    itemCount: ranking.length,
                    itemExtent: extent,
                    height: extent + AppArtworkCardFooter.extentOf(context),
                    itemBuilder: (context, index) => AppArtworkCard(illust: ranking[index], rank: index + 1, square: true),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(child: AppBrowseSectionHeader(title: t.home.recommended)),
          ],
        );
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
  final t = context.t;
  return [
    StreamBuilder(
      stream: source.rebuild,
      builder: (context, _) {
        final ranking = source.rankingNovels;
        if (source.phase != FrostLoadPhase.content || ranking.isEmpty) return const SliverToBoxAdapter();
        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: FrostShelf(
                title: t.home.rankings,
                action: FrostButton.quiet(
                  label: t.home.seeMore,
                  onPressed: () => GoRouter.of(context).push(AppLocations.ranking(kind: AppRankingKind.novel)),
                ),
                itemCount: ranking.length,
                itemExtent: AppNovelRow.coverWidth * 1.5,
                height: AppNovelRow.coverWidth * 1.5 * 1.414 + AppArtworkCardFooter.extentOf(context),
                itemBuilder: (context, index) => _NovelCover(novel: ranking[index], rank: index + 1),
              ),
            ),
            SliverToBoxAdapter(child: AppBrowseSectionHeader(title: t.home.recommended)),
          ],
        );
      },
    ),
    FrostSliverContentColumn(
      maxWidth: FrostMetrics.readingMaxWidth,
      sliver: FrostSliverDataList<Novel>(
        source: source,
        firstLoadSkeleton: const AppRowsSkeleton(),
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
      firstLoadSkeleton: const AppRowsSkeleton(),
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
    media: AppPixivImage(url: novel.imageUrls.medium, aspectRatio: 1 / 1.414, radius: 0),
    aspectRatio: 1 / 1.414,
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
