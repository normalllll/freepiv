import 'package:freepiv/core/block/block_filter.dart';
import 'package:freepiv/core/block/block_list.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frost_data/frost_data.dart';

part 'home_logic.g.dart';

enum HomeType { illustrations, manga, novels, users }

class HomeIllustListSource extends FrostCursorListSource<Illust, IllustPageResult> with BlockFilteredCursorList<Illust, IllustPageResult> {
  HomeIllustListSource({required this.illustType});

  final IllustType illustType;

  List<Illust> _rankingIllusts = const [];

  /// The ranking shelf, without what the block list hides.
  List<Illust> get rankingIllusts => [
    for (final illust in _rankingIllusts)
      if (!AppSettings.blockList.hidesIllust(illust)) illust,
  ];

  @override
  bool isBlocked(BlockList blocks, Illust item) => blocks.hidesIllust(item);

  @override
  void didChangeBlockList(BlockList blocks) => notifyDataChanged();

  @override
  Future<IllustPageResult> loadFirstPage() {
    return pixivApi.getRecommendedIllustPage(illustType: illustType);
  }

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextIllustPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(IllustPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Illust> itemsFromPage(IllustPageResult page) {
    return page.illusts;
  }

  @override
  void didApplyPage(IllustPageResult page) {
    _rankingIllusts = page.rankingIllusts;
  }

  @override
  void clearData() {
    _rankingIllusts = const [];
    super.clearData();
  }
}

class HomeNovelListSource extends FrostCursorListSource<Novel, NovelPageResult> with BlockFilteredCursorList<Novel, NovelPageResult> {
  List<Novel> _rankingNovels = const [];

  /// The ranking shelf, without what the block list hides.
  List<Novel> get rankingNovels => [
    for (final novel in _rankingNovels)
      if (!AppSettings.blockList.hidesNovel(novel)) novel,
  ];

  @override
  bool isBlocked(BlockList blocks, Novel item) => blocks.hidesNovel(item);

  @override
  void didChangeBlockList(BlockList blocks) => notifyDataChanged();

  @override
  Future<NovelPageResult> loadFirstPage() {
    return pixivApi.getRecommendedNovelPage();
  }

  @override
  Future<NovelPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextNovelPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(NovelPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Novel> itemsFromPage(NovelPageResult page) {
    return page.novels;
  }

  @override
  void didApplyPage(NovelPageResult page) {
    _rankingNovels = page.rankingNovels;
  }

  @override
  void clearData() {
    _rankingNovels = const [];
    super.clearData();
  }
}

class HomeUserListSource extends FrostCursorListSource<UserPreview, UserPageResult> with BlockFilteredCursorList<UserPreview, UserPageResult> {
  @override
  bool isBlocked(BlockList blocks, UserPreview item) => blocks.hidesPreview(item);

  @override
  Future<UserPageResult> loadFirstPage() {
    return pixivApi.getRecommendedUserPage();
  }

  @override
  Future<UserPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextUserPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(UserPageResult page) {
    return page.nextUrl;
  }

  @override
  List<UserPreview> itemsFromPage(UserPageResult page) {
    return page.userPreviews;
  }
}

@Riverpod(keepAlive: true)
HomeIllustListSource homeIllustSource(Ref ref) {
  final source = HomeIllustListSource(illustType: IllustType.illust);
  ref.onDispose(source.dispose);
  return source;
}

@Riverpod(keepAlive: true)
HomeIllustListSource homeMangaSource(Ref ref) {
  final source = HomeIllustListSource(illustType: IllustType.manga);
  ref.onDispose(source.dispose);
  return source;
}

@Riverpod(keepAlive: true)
HomeNovelListSource homeNovelSource(Ref ref) {
  final source = HomeNovelListSource();
  ref.onDispose(source.dispose);
  return source;
}

@Riverpod(keepAlive: true)
HomeUserListSource homeUserSource(Ref ref) {
  final source = HomeUserListSource();
  ref.onDispose(source.dispose);
  return source;
}

@Riverpod(keepAlive: true)
class Home extends _$Home {
  @override
  HomeType build() {
    return HomeType.illustrations;
  }

  void setType(HomeType type) {
    if (state == type) {
      return;
    }

    state = type;
    loadCurrentIfNeeded();
  }

  void loadCurrentIfNeeded() {
    switch (state) {
      case HomeType.illustrations:
        _loadIllustSourceIfNeeded(ref.read(homeIllustSourceProvider));
      case HomeType.manga:
        _loadIllustSourceIfNeeded(ref.read(homeMangaSourceProvider));
      case HomeType.novels:
        _loadNovelSourceIfNeeded(ref.read(homeNovelSourceProvider));
      case HomeType.users:
        _loadUserSourceIfNeeded(ref.read(homeUserSourceProvider));
    }
  }

  void _loadIllustSourceIfNeeded(HomeIllustListSource source) {
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }

  void _loadNovelSourceIfNeeded(HomeNovelListSource source) {
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }

  void _loadUserSourceIfNeeded(HomeUserListSource source) {
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }
}
