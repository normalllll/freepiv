import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/shared/logic/bookmark_options_logic.dart';
import 'package:freepiv/shared/logic/bookmark_tags.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Answers the bookmark reads and records what they asked.
class _Api implements PixivApi {
  /// The tag pages by their URL; the first page has the key ''.
  final tagPages = <String, BookmarkTagPageResult>{};
  final asked = <String>[];
  final bookmarkOptions = <BookmarkPageOptions>[];

  @override
  Future<BookmarkTagPageResult> getBookmarkTagPage({required int userId, required BookmarkTagOptions options}) async {
    asked.add('tags ${options.restrict.name} ${options.isNovel ? 'novel' : 'illust'}');
    return tagPages['']!;
  }

  @override
  Future<BookmarkTagPageResult> getNextBookmarkTagPage({required String url}) async {
    asked.add('next $url');
    return tagPages[url]!;
  }

  @override
  Future<IllustPageResult> getUserIllustBookmarkPage({required int userId, required Restrict restrict}) async {
    asked.add('illusts ${restrict.name}');
    return const IllustPageResult(illusts: [], rankingIllusts: []);
  }

  @override
  Future<IllustPageResult> getUserIllustBookmarkPageWithOptions({required int userId, required BookmarkPageOptions options}) async {
    bookmarkOptions.add(options);
    return const IllustPageResult(illusts: [], rankingIllusts: []);
  }

  @override
  Future<NovelPageResult> getUserNovelBookmarkPageWithOptions({required int userId, required BookmarkPageOptions options}) async {
    bookmarkOptions.add(options);
    return const NovelPageResult(novels: [], rankingNovels: []);
  }

  @override
  Future<WorkBookmarkDetailResult> getIllustBookmarkDetail({required int illustId}) async => WorkBookmarkDetailResult(
    bookmarkDetail: WorkBookmarkDetail(isBookmarked: false, tags: const [], restrict: Restrict.public),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Api api;
  setUp(() => pixivApi = api = _Api());

  group('every page of the tags is read', () {
    test('by following each next URL to the last page', () async {
      api.tagPages['x'] = const BookmarkTagPageResult(
        bookmarkTags: [BookmarkTag(name: 'b', count: 2)],
        nextUrl: 'y',
      );
      api.tagPages[''] = const BookmarkTagPageResult(
        bookmarkTags: [BookmarkTag(name: 'a', count: 1)],
        nextUrl: 'x',
      );
      api.tagPages['y'] = const BookmarkTagPageResult(bookmarkTags: [BookmarkTag(name: 'c', count: 3)]);
      final tags = await readBookmarkTags(userId: 1, restrict: Restrict.private, novel: true);
      expect([for (final tag in tags) tag.name], ['a', 'b', 'c']);
      expect(api.asked, ['tags private novel', 'next x', 'next y']);
    });

    test('and a URL that repeats ends the read instead of looping', () async {
      api.tagPages[''] = const BookmarkTagPageResult(
        bookmarkTags: [BookmarkTag(name: 'a', count: 1)],
        nextUrl: 'x',
      );
      api.tagPages['x'] = const BookmarkTagPageResult(
        bookmarkTags: [BookmarkTag(name: 'b', count: 1)],
        nextUrl: 'x',
      );
      final tags = await readBookmarkTags(userId: 1, restrict: Restrict.public, novel: false);
      expect(tags, hasLength(2));
    });

    test('and the bookmark options offer the tags of the later pages too, public and private', () async {
      api.tagPages[''] = const BookmarkTagPageResult(
        bookmarkTags: [BookmarkTag(name: 'first', count: 1)],
        nextUrl: 'x',
      );
      api.tagPages['x'] = const BookmarkTagPageResult(bookmarkTags: [BookmarkTag(name: 'second', count: 1)]);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final options = await container.read(workBookmarkOptionsProvider((accountId: '1', workId: 7, novel: false)).future);
      expect(options.tags, ['first', 'second']);
      expect(api.asked.where((call) => call == 'next x'), hasLength(2), reason: 'a second page for each of public and private');
    });

    test('and the bookmark options keep working when the tags cannot be read', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final options = await container.read(workBookmarkOptionsProvider((accountId: '1', workId: 7, novel: false)).future);
      expect(options.tags, isEmpty, reason: 'the read failed and was left out');
    });
  });

  group('the bookmark lists by tag', () {
    test('without a tag the plain bookmark request is made', () async {
      await UserIllustBookmarkListSource(userId: 1, restrict: Restrict.private).refresh(true);
      expect(api.asked, ['illusts private']);
      expect(api.bookmarkOptions, isEmpty);
    });

    test('a tag is sent with the restrict, for illustrations and novels', () async {
      await UserIllustBookmarkListSource(userId: 1, tag: const BookmarkTagFilter.named('girl')).refresh(true);
      await UserNovelBookmarkListSource(userId: 1, restrict: Restrict.private, tag: const BookmarkTagFilter.named('sea')).refresh(true);
      expect([for (final options in api.bookmarkOptions) (options.restrict, options.tag)], [(Restrict.public, 'girl'), (Restrict.private, 'sea')]);
    });

    test('the bookmarks without a tag are asked for as 未分類', () async {
      await UserIllustBookmarkListSource(userId: 1, tag: const BookmarkTagFilter.uncategorized()).refresh(true);
      expect(api.bookmarkOptions.single.tag, '未分類');
      expect(const BookmarkTagFilter.uncategorized().apiTag, '未分類');
      expect(const BookmarkTagFilter.all().apiTag, isNull);
      expect(const BookmarkTagFilter.named('x').apiTag, 'x');
    });

    test('filters compare by what they stand for', () {
      expect(const BookmarkTagFilter.named('a'), const BookmarkTagFilter.named('a'));
      expect(const BookmarkTagFilter.named('a'), isNot(const BookmarkTagFilter.named('b')));
      expect(const BookmarkTagFilter.all(), isNot(const BookmarkTagFilter.uncategorized()));
      expect(BookmarkTagFilter.ofTag('未分類'), const BookmarkTagFilter.uncategorized());
      expect(sampleBookmarkTags(), isNotEmpty);
    });
  });
}
