import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/block/block_filter.dart';
import 'package:freepiv/core/block/block_list.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/ranking/logic/ranking_logic.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_data/frost_data.dart';

import 'support/work_fakes.dart';

/// Pages of illustrations, each naming the next until the last. [onRequest]
/// can hold a page back; every request is counted.
class _Pages extends FrostCursorListSource<Illust, IllustPageResult> with BlockFilteredCursorList<Illust, IllustPageResult> {
  _Pages(this.pages, {this.onRequest});

  final List<List<Illust>> pages;
  final Future<void> Function(int index)? onRequest;
  var requests = 0;

  @override
  bool isBlocked(BlockList blocks, Illust item) => blocks.hidesIllust(item);

  Future<IllustPageResult> _page(int index) async {
    requests++;
    await onRequest?.call(index);
    return IllustPageResult(illusts: pages[index], rankingIllusts: const [], nextUrl: index + 1 < pages.length ? '${index + 1}' : null);
  }

  @override
  Future<IllustPageResult> loadFirstPage() => _page(0);

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) => _page(int.parse(nextUrl));

  @override
  String? nextUrlFromPage(IllustPageResult page) => page.nextUrl;

  @override
  List<Illust> itemsFromPage(IllustPageResult page) => page.illusts;
}

List<int> _ids(FrostListSource<Illust> source) => [for (final illust in source.items) illust.id];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AppSettings.initialize(store: SampleSettingsStore());
  });

  test('a source leaves out works by a blocked user and works with a blocked tag', () async {
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven')).withTag('blocked tag');
    final source = _Pages([
      [
        fakeIllust(1),
        fakeIllust(2, by: 7),
        fakeIllust(3, tags: ['fine', 'blocked tag']),
        fakeIllust(4, tags: ['blocked']),
      ],
    ]);
    addTearDown(source.dispose);

    await source.refresh(true);

    expect(_ids(source), [1, 4], reason: 'a tag matches its name exactly, not a part of it');
  });

  test('a page that is blocked whole is followed by the next one in the same load', () async {
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven'));
    final source = _Pages([
      [fakeIllust(1, by: 7), fakeIllust(2, by: 7)],
      [fakeIllust(3, by: 7)],
      [fakeIllust(4), fakeIllust(5, by: 7)],
      [fakeIllust(6)],
    ]);
    addTearDown(source.dispose);

    await source.refresh(true);

    expect(_ids(source), [4]);
    expect(source.requests, 3);
    expect(source.hasNextPage, isTrue, reason: 'the page after is left for the list to ask for');

    await source.loadMore();

    expect(_ids(source), [4, 6]);
  });

  test('a load reads at most $blockBackfillPages pages and then answers with an empty page', () async {
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven'));
    final source = _Pages([
      for (var page = 0; page < 8; page++) [fakeIllust(page, by: 7)],
      [fakeIllust(100)],
    ]);
    addTearDown(source.dispose);

    await source.refresh(true);

    expect(source.requests, blockBackfillPages);
    expect(source.items, isEmpty);
    expect(source.hasMore, isTrue, reason: 'pages remain, so the empty list is not the end');
    expect(source.phase, FrostLoadPhase.content, reason: 'not the empty state while there is more');

    await source.loadMore();

    expect(source.requests, blockBackfillPages + 4, reason: 'the next load reads on from where this one stopped');
    expect(_ids(source), [100]);
  });

  test('a source disposed while a page is on its way asks for no more', () async {
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven'));
    final held = Completer<void>();
    final source = _Pages([
      [fakeIllust(1, by: 7)],
      [fakeIllust(2)],
    ], onRequest: (index) => index == 0 ? held.future : Future.value());

    final loading = source.refresh(true);
    await pumpEventQueue();
    expect(source.requests, 1);
    source.dispose();
    held.complete();
    await loading;
    await pumpEventQueue();

    expect(source.requests, 1);
  });

  test('a refresh that supersedes a load keeps the older one from reading on', () async {
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven'));
    final held = Completer<void>();
    var firstLoad = true;
    final source = _Pages(
      [
        [fakeIllust(1, by: 7)],
        [fakeIllust(2, by: 7)],
        [fakeIllust(3)],
      ],
      onRequest: (index) async {
        if (index == 0 && firstLoad) {
          firstLoad = false;
          await held.future;
        }
      },
    );
    addTearDown(source.dispose);

    final older = source.refresh(true);
    await pumpEventQueue();
    source.clearData();
    held.complete();
    await older;
    await pumpEventQueue();

    expect(source.requests, 1, reason: 'the older load stopped after its first page');
  });

  test('a user blocked later takes their works out of the loaded list at once and keeps the rest and the paging', () async {
    final source = _Pages([
      [
        fakeIllust(1),
        fakeIllust(2, by: 7),
        fakeIllust(3),
        fakeIllust(4, tags: ['tagged']),
      ],
      [fakeIllust(5, by: 7), fakeIllust(6)],
    ]);
    addTearDown(source.dispose);
    await source.refresh(true);
    var notified = 0;
    source.addListener(() => notified++);

    AppSettings.blockList = AppSettings.blockList.withUser(const BlockedUser(id: 7, name: 'Seven'));

    expect(_ids(source), [1, 3, 4], reason: 'the others keep their order');
    expect(notified, 1);
    expect(source.hasNextPage, isTrue);
    expect(source.hasMore, isTrue);
    expect(source.phase, FrostLoadPhase.content);

    AppSettings.blockList = AppSettings.blockList.withTag('tagged');
    expect(_ids(source), [1, 3]);

    await source.loadMore();
    expect(_ids(source), [1, 3, 6], reason: 'the next page is filtered by the new list');
  });

  test('unblocking leaves the loaded list as it is', () async {
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven'));
    final source = _Pages([
      [fakeIllust(1), fakeIllust(2, by: 7)],
    ]);
    addTearDown(source.dispose);
    await source.refresh(true);

    AppSettings.blockList = const BlockList();

    expect(_ids(source), [1]);
  });

  test('a disposed source no longer listens to the block list', () async {
    final source = _Pages([
      [fakeIllust(1), fakeIllust(2, by: 7)],
    ]);
    await source.refresh(true);
    source.dispose();

    AppSettings.blockList = AppSettings.blockList.withUser(const BlockedUser(id: 7, name: 'Seven'));

    // ignore: invalid_use_of_protected_member
    expect(AppSettings.blockListListenable.hasListeners, isFalse);
  });

  test('an entry that cannot be read is skipped and the others stay', () async {
    await AppSettings.initialize(
      store: SampleSettingsStore({
        'blockList': {
          'tags': ['good', '', 3, 'good', 'other'],
          'users': [
            {'id': 7, 'name': 'Seven'},
            {'id': 'eight', 'name': 'Eight'},
            {'name': 'No ID'},
            {'id': 9},
            'nine',
            {'id': 10, 'name': 'Ten'},
          ],
        },
      }),
    );

    expect(AppSettings.blockList.tags, ['good', 'other']);
    expect(AppSettings.blockList.users, const [BlockedUser(id: 7, name: 'Seven'), BlockedUser(id: 10, name: 'Ten')]);
  });

  test('a tag is stored without spaces around it and without a leading #, and what is left of nothing is not a tag', () {
    final blocks = const BlockList().withTag('  #猫 ').withTag('##landscape').withTag('a # b');

    expect(blocks.tags, ['猫', 'landscape', 'a # b']);
    expect(blocks.withTag('猫').withTag('# 猫').tags, blocks.tags, reason: 'already blocked, however it is typed');
    expect(blocks.withTag('#').withTag('   ').withTag('').tags, blocks.tags);
    expect(blocks.blocksTag('猫'), isTrue);
    expect(BlockList.normalizeTag(' #猫 '), '猫');
    expect(blocks.withoutTag('猫').blocksTag('猫'), isFalse);
  });

  test('the home ranking shelf stays when a blocked first page is followed by a page without one', () async {
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven'));
    final source = _TwoHomePages(
      IllustPageResult(illusts: [fakeIllust(1, by: 7)], rankingIllusts: [fakeIllust(10), fakeIllust(11, by: 7)], nextUrl: 'next'),
      IllustPageResult(illusts: [fakeIllust(2)], rankingIllusts: const []),
    );
    addTearDown(source.dispose);

    await source.refresh(true);

    expect(_ids(source), [2], reason: 'the first page was blocked whole, so the second one was read in the same load');
    expect([for (final illust in source.rankingIllusts) illust.id], [10], reason: 'the shelf of the first page, filtered, not replaced by the empty one');
  });

  test('the home ranking shelf of novels stays as well, and a refresh sets it again', () async {
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven'));
    var shelf = [fakeNovel(10)];
    final source = _TwoHomeNovelPages(
      () => NovelPageResult(novels: [fakeNovel(1, by: 7)], rankingNovels: shelf, nextUrl: 'next'),
      const NovelPageResult(novels: [], rankingNovels: []),
    );
    addTearDown(source.dispose);

    await source.refresh(true);
    expect([for (final novel in source.rankingNovels) novel.id], [10]);

    shelf = [fakeNovel(20)];
    await source.refresh(true);
    expect([for (final novel in source.rankingNovels) novel.id], [20]);
  });

  _wiringTests();

  test('the home ranking shelf leaves out what the block list hides, and follows it', () async {
    final source = _HomeFeed(
      IllustPageResult(
        illusts: [fakeIllust(1), fakeIllust(2, by: 7)],
        rankingIllusts: [
          fakeIllust(10, by: 7),
          fakeIllust(11),
          fakeIllust(12, tags: ['tagged']),
        ],
      ),
    );
    addTearDown(source.dispose);
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven'));

    await source.refresh(true);

    expect([for (final illust in source.rankingIllusts) illust.id], [11, 12]);
    expect(_ids(source), [1]);

    var notified = 0;
    source.addListener(() => notified++);
    AppSettings.blockList = AppSettings.blockList.withTag('tagged');

    expect(notified, greaterThan(0), reason: 'the shelf is told');
    expect([for (final illust in source.rankingIllusts) illust.id], [11]);

    AppSettings.blockList = const BlockList();
    expect([for (final illust in source.rankingIllusts) illust.id], [11], reason: 'unblocking does not bring entries back');
  });

  test('the home users and the novels are filtered as well', () async {
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven')).withTag('tagged');
    final users = _HomeUsers([fakePreview(1), fakePreview(7), fakePreview(2)]);
    final novels = _HomeNovels(
      NovelPageResult(
        novels: [
          fakeNovel(1),
          fakeNovel(2, by: 7),
          fakeNovel(3, tags: ['tagged']),
        ],
        rankingNovels: [
          fakeNovel(4, tags: ['tagged']),
          fakeNovel(5),
        ],
      ),
    );
    addTearDown(users.dispose);
    addTearDown(novels.dispose);

    await users.refresh(true);
    await novels.refresh(true);

    expect([for (final preview in users.items) preview.user.id], [1, 2]);
    expect([for (final novel in novels.items) novel.id], [1]);
    expect([for (final novel in novels.rankingNovels) novel.id], [5]);
  });

  test('related users are filtered, and a blocked page is followed by the next', () async {
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven')).withUser(const BlockedUser(id: 8, name: 'Eight'));
    final source = _RelatedUsers([
      [fakePreview(7), fakePreview(8)],
      [fakePreview(1), fakePreview(8)],
      [],
    ]);
    addTearDown(source.dispose);

    await source.refresh(true);

    expect([for (final preview in source.items) preview.user.id], [1], reason: 'the first page was blocked whole, so the second one was read too');
    expect(source.offsets, [0, 2]);
    expect(source.hasMore, isTrue);

    AppSettings.blockList = AppSettings.blockList.withUser(const BlockedUser(id: 1, name: 'One'));
    expect(source.items, isEmpty, reason: 'loaded users go at once');

    await source.loadMore();
    expect(source.hasMore, isFalse, reason: 'an empty page still ends the list');
  });

  test('the block list is stored, read back and an unreadable one is dropped', () async {
    final store = SampleSettingsStore();
    await AppSettings.initialize(store: store);
    AppSettings.blockList = const BlockList().withTag('tag').withUser(const BlockedUser(id: 7, name: 'Seven'));
    await pumpEventQueue();

    await AppSettings.initialize(store: SampleSettingsStore(store.values));
    expect(AppSettings.blockList.tags, ['tag']);
    expect(AppSettings.blockList.users, const [BlockedUser(id: 7, name: 'Seven')]);

    await AppSettings.initialize(
      store: SampleSettingsStore({
        'blockList': {'tags': 'not a list', 'users': []},
      }),
    );
    expect(AppSettings.blockList.isEmpty, isTrue);

    await AppSettings.initialize(store: SampleSettingsStore({'blockList': 'not a map'}));
    expect(AppSettings.blockList.isEmpty, isTrue);

    await AppSettings.initialize(store: store);
    AppSettings.blockList = const BlockList().withTag('tag');
    AppSettings.blockList = const BlockList();
    await pumpEventQueue();
    expect(store.values.containsKey('blockList'), isFalse, reason: 'an empty list stores nothing');
  });
}

class _TwoHomePages extends HomeIllustListSource {
  _TwoHomePages(this.first, this.next) : super(illustType: IllustType.illust);

  final IllustPageResult first, next;

  @override
  Future<IllustPageResult> loadFirstPage() async => first;

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) async => next;
}

class _TwoHomeNovelPages extends HomeNovelListSource {
  _TwoHomeNovelPages(this.first, this.next);

  final NovelPageResult Function() first;
  final NovelPageResult next;

  @override
  Future<NovelPageResult> loadFirstPage() async => first();

  @override
  Future<NovelPageResult> loadNextPage(String nextUrl) async => next;
}

// Each source the block list applies to, as its own class: a class that lost
// its mixin, or tests the wrong thing in isBlocked, fails here.

List<Illust> _illustPage() => [
  fakeIllust(1),
  fakeIllust(2, by: 7),
  fakeIllust(3, tags: ['blocked tag']),
];

List<Novel> _novelPage() => [
  fakeNovel(1),
  fakeNovel(2, by: 7),
  fakeNovel(3, tags: ['blocked tag']),
];

IllustPageResult _illusts() => IllustPageResult(illusts: _illustPage(), rankingIllusts: const []);

NovelPageResult _novels() => NovelPageResult(novels: _novelPage(), rankingNovels: const []);

List<UserPreview> _previews() => [fakePreview(1), fakePreview(7)];

void _wiringTests() {
  Future<void> expectKept<T>(FrostListSource<T> source, List<int> Function(List<T> items) ids) async {
    addTearDown(source.dispose);
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 7, name: 'Seven')).withTag('blocked tag');
    await source.refresh(true);
    expect(ids(source.items), [1], reason: '${source.runtimeType} drops the work by a blocked user and the one with a blocked tag');
  }

  List<int> illustIds(List<Illust> items) => [for (final illust in items) illust.id];
  List<int> novelIds(List<Novel> items) => [for (final novel in items) novel.id];
  List<int> userIds(List<UserPreview> items) => [for (final preview in items) preview.user.id];

  test('home illustrations, novels and users', () async {
    await expectKept(_HomeFeed(_illusts()), illustIds);
    await expectKept(_HomeNovels(_novels()), novelIds);
    await expectKept(_HomeUsers(_previews()), userIds);
  });

  test('the newest feed, of illustrations and of novels', () async {
    List<int> ids(List<NewestItem> items) => [
      for (final item in items)
        switch (item) {
          NewestIllust(:final illust) => illust.id,
          NewestNovel(:final novel) => novel.id,
        },
    ];
    await expectKept(_Newest(const NewestFeedKey(audience: NewestAudience.everyone, workType: NewestWorkType.illust), _illusts()), ids);
    await expectKept(_Newest(const NewestFeedKey(audience: NewestAudience.everyone, workType: NewestWorkType.novel), _novels()), ids);
  });

  test('the rankings of illustrations, manga and novels', () async {
    await expectKept(_RankingIllusts(_illusts()), illustIds);
    await expectKept(_RankingManga(_illusts()), illustIds);
    await expectKept(_RankingNovels(_novels()), novelIds);
  });

  test('the searches for illustrations, novels and users', () async {
    const request = SearchResultRequest(keyword: 'word', filter: SearchFilterState());
    await expectKept(_SearchIllusts(request, SearchIllustPageResult(illusts: _illustPage(), searchSpanLimit: 0)), illustIds);
    await expectKept(_SearchNovels(request, SearchNovelPageResult(novels: _novelPage(), searchSpanLimit: 0)), novelIds);
    await expectKept(_SearchUsers('word', _previews()), userIds);
  });

  test('the works related to an illustration and to a novel', () async {
    await expectKept(_RelatedIllusts(_illusts()), illustIds);
    await expectKept(_RelatedNovels(_novels()), novelIds);
  });
}

class _Newest extends NewestListSource {
  _Newest(NewestFeedKey key, this.page) : super(key: key);

  final Object page;

  @override
  Future<Object> loadFirstPage() async => page;
}

class _RankingIllusts extends RankingIllustListSource {
  _RankingIllusts(this.page) : super(mode: IllustRankingMode.day);

  final IllustPageResult page;

  @override
  Future<IllustPageResult> loadFirstPage() async => page;
}

class _RankingManga extends RankingMangaListSource {
  _RankingManga(this.page) : super(mode: MangaRankingMode.day);

  final IllustPageResult page;

  @override
  Future<IllustPageResult> loadFirstPage() async => page;
}

class _RankingNovels extends RankingNovelListSource {
  _RankingNovels(this.page) : super(mode: NovelRankingMode.day);

  final NovelPageResult page;

  @override
  Future<NovelPageResult> loadFirstPage() async => page;
}

class _SearchIllusts extends SearchIllustListSource {
  _SearchIllusts(SearchResultRequest request, this.page) : super(request: request);

  final SearchIllustPageResult page;

  @override
  Future<SearchIllustPageResult> loadFirstPage() async => page;
}

class _SearchNovels extends SearchNovelListSource {
  _SearchNovels(SearchResultRequest request, this.page) : super(request: request);

  final SearchNovelPageResult page;

  @override
  Future<SearchNovelPageResult> loadFirstPage() async => page;
}

class _SearchUsers extends SearchUserListSource {
  _SearchUsers(String keyword, this.users) : super(keyword: keyword);

  final List<UserPreview> users;

  @override
  Future<UserPageResult> loadFirstPage() async => UserPageResult(userPreviews: users);
}

class _RelatedIllusts extends IllustRelatedListSource {
  _RelatedIllusts(this.page) : super(illustId: 99);

  final IllustPageResult page;

  @override
  Future<IllustPageResult> loadFirstPage() async => page;
}

class _RelatedNovels extends NovelRelatedListSource {
  _RelatedNovels(this.page) : super(novelId: 99);

  final NovelPageResult page;

  @override
  Future<NovelPageResult> loadFirstPage() async => page;
}

class _HomeFeed extends HomeIllustListSource {
  _HomeFeed(this.page) : super(illustType: IllustType.illust);

  final IllustPageResult page;

  @override
  Future<IllustPageResult> loadFirstPage() async => page;
}

class _HomeUsers extends HomeUserListSource {
  _HomeUsers(this.users);

  final List<UserPreview> users;

  @override
  Future<UserPageResult> loadFirstPage() async => UserPageResult(userPreviews: users);
}

class _HomeNovels extends HomeNovelListSource {
  _HomeNovels(this.page);

  final NovelPageResult page;

  @override
  Future<NovelPageResult> loadFirstPage() async => page;
}

/// Related users by offset: page [n] is `pages[n]`, and each is asked for at
/// the number of users read before it.
class _RelatedUsers extends UserRelatedListSource {
  _RelatedUsers(this.pages) : super(userId: 1);

  final List<List<UserPreview>> pages;
  final offsets = <int>[];

  @override
  Future<UserPageResult> loadOffsetPage(int offset) async {
    offsets.add(offset);
    var read = 0;
    for (final page in pages) {
      if (read == offset) return UserPageResult(userPreviews: page);
      read += page.length;
    }
    return const UserPageResult(userPreviews: []);
  }
}
