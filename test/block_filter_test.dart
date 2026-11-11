import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/block/block_filter.dart';
import 'package:freepiv/core/block/block_list.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
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

    await AppSettings.initialize(store: store);
    AppSettings.blockList = const BlockList().withTag('tag');
    AppSettings.blockList = const BlockList();
    await pumpEventQueue();
    expect(store.values.containsKey('blockList'), isFalse, reason: 'an empty list stores nothing');
  });
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
