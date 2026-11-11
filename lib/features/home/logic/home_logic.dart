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

  /// The ranking shelf, without what the block list hid when it was read or
  /// changed.
  List<Illust> get rankingIllusts => _rankingIllusts;

  @override
  bool isBlocked(BlockList blocks, Illust item) => blocks.hidesIllust(item);

  @override
  void didChangeBlockList(BlockList blocks) {
    _rankingIllusts = _unblocked(_rankingIllusts, blocks);
    notifyDataChanged();
  }

  static List<Illust> _unblocked(List<Illust> illusts, BlockList blocks) => [
    for (final illust in illusts)
      if (!blocks.hidesIllust(illust)) illust,
  ];

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

  /// Whether the next page applied is the first of a load: Pixiv gives the
  /// ranking shelf with the first page only, so only that page sets it.
  var _firstPage = false;

  @override
  Future<List<Illust>> initList() {
    _firstPage = true;
    return super.initList();
  }

  @override
  void didApplyPage(IllustPageResult page) {
    if (!_firstPage) return;
    _firstPage = false;
    _rankingIllusts = _unblocked(page.rankingIllusts, AppSettings.blockList);
  }

  @override
  void clearData() {
    _rankingIllusts = const [];
    super.clearData();
  }
}

class HomeNovelListSource extends FrostCursorListSource<Novel, NovelPageResult> with BlockFilteredCursorList<Novel, NovelPageResult> {
  List<Novel> _rankingNovels = const [];

  /// The ranking shelf, without what the block list hid when it was read or
  /// changed.
  List<Novel> get rankingNovels => _rankingNovels;

  @override
  bool isBlocked(BlockList blocks, Novel item) => blocks.hidesNovel(item);

  @override
  void didChangeBlockList(BlockList blocks) {
    _rankingNovels = _unblocked(_rankingNovels, blocks);
    notifyDataChanged();
  }

  static List<Novel> _unblocked(List<Novel> novels, BlockList blocks) => [
    for (final novel in novels)
      if (!blocks.hidesNovel(novel)) novel,
  ];

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

  /// Whether the next page applied is the first of a load: Pixiv gives the
  /// ranking shelf with the first page only, so only that page sets it.
  var _firstPage = false;

  @override
  Future<List<Novel>> initList() {
    _firstPage = true;
    return super.initList();
  }

  @override
  void didApplyPage(NovelPageResult page) {
    if (!_firstPage) return;
    _firstPage = false;
    _rankingNovels = _unblocked(page.rankingNovels, AppSettings.blockList);
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
