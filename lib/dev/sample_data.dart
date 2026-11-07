// Sample data for development: the sample entrypoint (tool/sample_main.dart),
// screenshots and widget tests. Nothing in the app's own entrypoint imports
// this file, so release builds leave it out.
import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:freepiv/dev/sample_images.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/features/downloads/presentation/download_entry.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/logic/search_trending_tags_logic.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

/// Settings kept in memory, starting from [values].
class SampleSettingsStore implements AppSettingsStore {
  SampleSettingsStore([Map<String, dynamic> values = const {}]) : values = Map.of(values);

  final Map<String, dynamic> values;

  @override
  Map<String, dynamic> load() => Map.of(values);

  @override
  Future<void> write(String key, dynamic value) async => value == null ? values.remove(key) : values[key] = value;
}

/// A first run with some searches behind it.
const sampleSettings = <String, dynamic>{
  'searchHistory': ['初音ミク', 'landscape', 'オリジナル', 'cat', 'ブルーアーカイブ', 'scenery'],
};

const sampleAccount = UserAccountResult(
  accessToken: 'sample',
  expiresIn: 3600,
  tokenType: 'bearer',
  scope: '',
  refreshToken: 'sample',
  user: LocalUser(
    profileImageUrls: LocalUserProfileImageUrls(px16X16: '', px50X50: '', px170X170: ''),
    id: '1000',
    name: 'Sample user',
    account: 'sample_user',
    mailAddress: 'sample@example.test',
    isPremium: false,
    xRestrict: 0,
    isMailAuthorized: true,
    requirePolicyAgreement: false,
  ),
);

const _artist = User(
  id: 2000,
  name: 'Sample artist',
  account: 'sample_artist',
  profileImageUrls: ProfileImageUrls(medium: ''),
);

/// Works with no image addresses: their cards show the image placeholder.
List<Illust> sampleIllusts({int count = 24, String kind = 'illust'}) => [
  for (var index = 0; index < count; index++)
    Illust(
      id: 90000 + index,
      title: index.isEven ? 'Sample work ${index + 1}' : 'A longer sample work title that wraps ${index + 1}',
      kind: kind,
      imageUrls: ImageUrls(
        squareMedium: sampleImageUrl(index, width: 360, height: 360),
        medium: sampleImageUrl(index, width: 540, height: [540, 756, 405, 675][index % 4]),
        large: sampleImageUrl(index, width: 1000, height: [1000, 1400, 750, 1250][index % 4]),
      ),
      caption: '',
      restrict: 0,
      user: _artist,
      tags: const [
        Tag(name: 'オリジナル', translatedName: 'original'),
        Tag(name: 'landscape'),
      ],
      tools: const [],
      createDate: '2026-11-01T12:00:00+09:00',
      pageCount: index % 5 == 0 ? 3 : 1,
      width: 1000,
      height: [1000, 1400, 750, 1250][index % 4],
      sanityLevel: 2,
      xRestrict: 0,
      metaSinglePage: const MetaSinglePage(),
      metaPages: const [],
      totalView: 1200 + index * 37,
      totalBookmarks: 300 + index * 11,
      isBookmarked: index % 7 == 0,
      visible: true,
      isMuted: false,
      illustAiType: index % 9 == 0 ? 2 : 1,
    ),
];

/// A recommended feed that answers from [sampleIllusts].
class SampleIllustSource extends HomeIllustListSource {
  SampleIllustSource({required super.illustType});

  @override
  Future<IllustPageResult> loadFirstPage() async {
    final illusts = sampleIllusts(kind: illustType == IllustType.manga ? 'manga' : 'illust');
    return IllustPageResult(illusts: illusts, rankingIllusts: illusts.take(8).toList());
  }

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) async => const IllustPageResult(illusts: [], rankingIllusts: []);
}

class _SampleTrendingTags extends SearchTrendingTags {
  @override
  Future<List<TrendTag>> build() async {
    final illusts = sampleIllusts(count: 8);
    const names = ['初音ミク', 'オリジナル', '風景', '猫', '女の子', 'ブルーアーカイブ', '原神', '創作'];
    const translated = ['Hatsune Miku', 'original', 'scenery', 'cat', 'girl', 'Blue Archive', 'Genshin Impact', 'original work'];
    return [for (var index = 0; index < names.length; index++) TrendTag(tag: names[index], translatedName: translated[index], illust: illusts[index])];
  }
}

DownloadTaskSnapshot _task(int index, DownloadStatus status, SaveState saveState, double progress) {
  final created = DateTime(2026, 11, 7, 10, index);
  return DownloadTaskSnapshot(
    id: 'illust_${90000 + index}_page_0',
    origin: ArtworkPage(illustId: 90000 + index, pageIndex: 0),
    source: ArtworkSource(illustId: 90000 + index, title: 'Sample work ${index + 1}', subtitle: _artist.name),
    title: 'Sample work ${index + 1}',
    filename: '${90000 + index}_p0.png',
    status: status,
    saveState: saveState,
    receivedBytes: (progress * 2400000).round(),
    totalBytes: 2400000,
    progress: progress,
    localPath: saveState == SaveState.saved ? 'C:/Users/sample/Downloads/freepiv/${90000 + index}_p0.png' : null,
    error: status == DownloadStatus.failed ? 'Connection reset' : null,
    log: null,
    createdAt: created,
    updatedAt: created,
  );
}

/// Two downloads going, one failed and some history.
final sampleDownloadTasks = [
  _task(0, DownloadStatus.running, SaveState.none, .45),
  _task(1, DownloadStatus.queued, SaveState.none, 0),
  _task(2, DownloadStatus.failed, SaveState.none, .2),
  _task(3, DownloadStatus.downloaded, SaveState.saved, 1),
  _task(4, DownloadStatus.downloaded, SaveState.saved, 1),
];

/// The providers the sample app answers from sample data instead of Pixiv.
///
/// Keyed by provider, so a test can replace one of them.
final sampleOverrideMap = <Object, Override>{
  homeIllustSourceProvider: homeIllustSourceProvider.overrideWith((ref) {
    final source = SampleIllustSource(illustType: IllustType.illust);
    ref.onDispose(source.dispose);
    return source;
  }),
  homeMangaSourceProvider: homeMangaSourceProvider.overrideWith((ref) {
    final source = SampleIllustSource(illustType: IllustType.manga);
    ref.onDispose(source.dispose);
    return source;
  }),
  homeNovelSourceProvider: homeNovelSourceProvider.overrideWith((ref) {
    final source = SampleNovelSource();
    ref.onDispose(source.dispose);
    return source;
  }),
  homeUserSourceProvider: homeUserSourceProvider.overrideWith((ref) {
    final source = SampleUserSource();
    ref.onDispose(source.dispose);
    return source;
  }),
  illustCommentsProvider: illustCommentsProvider.overrideWith2((_) => _SampleIllustComments()),
  illustUserWorksProvider: illustUserWorksProvider.overrideWith2((_) => _SampleUserWorks()),
  illustRelatedWorksProvider: illustRelatedWorksProvider.overrideWith2((_) => _SampleRelatedWorks()),
  userDetailProvider: userDetailProvider.overrideWith2((_) => _SampleUserDetail()),
  userIllustsProvider: userIllustsProvider.overrideWith2((_) => _SampleUserIllustsNotifier()),
  userNovelsProvider: userNovelsProvider.overrideWith2((_) => _SampleUserNovelsNotifier()),
  userFollowingUsersProvider: userFollowingUsersProvider.overrideWith2((_) => _SampleUserFollowingNotifier()),
  novelTextProvider: novelTextProvider.overrideWith2((_) => _SampleNovelText()),
  novelCommentsProvider: novelCommentsProvider.overrideWith2((_) => _SampleNovelComments()),
  novelUserWorksProvider: novelUserWorksProvider.overrideWith2((_) => _SampleNovelUserWorks()),
  novelRelatedWorksProvider: novelRelatedWorksProvider.overrideWith2((_) => _SampleNovelRelated()),
  workCommentsSourceProvider: workCommentsSourceProvider.overrideWith((ref, work) {
    final source = _SampleWorkComments(workType: work.$1, workId: work.$2);
    ref.onDispose(source.dispose);
    return source;
  }),
  searchIllustResultSourceProvider: searchIllustResultSourceProvider.overrideWith((ref, request) {
    sampleSearchRequests.add(request);
    final source = SampleSearchIllusts(request: request);
    ref.onDispose(source.dispose);
    return source;
  }),
  searchNovelResultSourceProvider: searchNovelResultSourceProvider.overrideWith((ref, request) {
    sampleSearchRequests.add(request);
    final source = _SampleSearchNovels(request: request);
    ref.onDispose(source.dispose);
    return source;
  }),
  searchUserResultSourceProvider: searchUserResultSourceProvider.overrideWith((ref, keyword) {
    final source = _SampleSearchUsers(keyword: keyword);
    ref.onDispose(source.dispose);
    return source;
  }),
  searchTrendingTagsProvider: searchTrendingTagsProvider.overrideWith(_SampleTrendingTags.new),
  downloadTasksProvider: downloadTasksProvider.overrideWith((ref) => Stream.value(sampleDownloadTasks)),
  fanboxDownloadsProvider: fanboxDownloadsProvider.overrideWithValue(const {}),
};

final sampleOverrides = [...sampleOverrideMap.values];

/// Novels by sample authors, some long-titled and in a series.
List<Novel> sampleNovels({int count = 12}) => [
  for (var index = 0; index < count; index++)
    Novel(
      id: 70000 + index,
      title: index.isEven ? 'Sample novel ${index + 1}' : 'A rather long sample novel title that needs two lines ${index + 1}',
      caption: 'The opening of a story about the sea, the town on its shore and the people who wait there for the boats to come back.',
      restrict: 0,
      xRestrict: 0,
      isOriginal: true,
      imageUrls: ImageUrls(
        squareMedium: sampleImageUrl(40 + index, width: 240, height: 240),
        medium: sampleImageUrl(40 + index, width: 240, height: 340),
        large: '',
      ),
      createDate: '2026-11-01T12:00:00+09:00',
      tags: const [
        Tag(name: 'オリジナル', translatedName: 'original'),
        Tag(name: '恋愛'),
        Tag(name: 'ファンタジー'),
      ],
      pageCount: 3,
      textLength: 12000 + index * 830,
      user: _artist,
      series: Series(id: index % 3 == 0 ? 500 : null, title: index % 3 == 0 ? 'The shore stories' : null),
      totalBookmarks: 120 + index,
      isBookmarked: index % 4 == 0,
      totalView: 2000 + index * 50,
      visible: true,
      totalComments: 3,
      isMuted: false,
      isMypixivOnly: false,
      isXRestricted: false,
      novelAiType: 1,
    ),
];

/// Recommended users, each with three works.
List<UserPreview> sampleUserPreviews({int count = 10}) {
  final works = sampleIllusts(count: 3);
  return [
    for (var index = 0; index < count; index++)
      UserPreview(
        user: User(
          id: 3000 + index,
          name: index.isEven ? 'Sample creator ${index + 1}' : 'サンプルの作者 ${index + 1}',
          account: 'sample_creator_${index + 1}',
          profileImageUrls: ProfileImageUrls(medium: sampleImageUrl(60 + index, width: 170, height: 170)),
          isFollowed: index % 3 == 0,
        ),
        illusts: works,
        isMuted: false,
      ),
  ];
}

class SampleNovelSource extends HomeNovelListSource {
  @override
  Future<NovelPageResult> loadFirstPage() async {
    final novels = sampleNovels();
    return NovelPageResult(novels: novels, rankingNovels: novels.take(6).toList());
  }

  @override
  Future<NovelPageResult> loadNextPage(String nextUrl) async => const NovelPageResult(novels: [], rankingNovels: []);
}

class SampleUserSource extends HomeUserListSource {
  @override
  Future<UserPageResult> loadFirstPage() async => UserPageResult(userPreviews: sampleUserPreviews());

  @override
  Future<UserPageResult> loadNextPage(String nextUrl) async => const UserPageResult(userPreviews: []);
}

/// Comments on a sample work: text with emoji, a stamp and a reply thread.
List<Comment> sampleComments({int count = 6}) => [
  for (var index = 0; index < count; index++)
    Comment(
      id: 80000 + index,
      comment: index == 2
          ? ''
          : ['Beautiful colours (heart)', 'I love the light in this one', '', 'The composition is so calm. Thank you for sharing!'][index % 4],
      date: '2026-11-0${1 + index % 6}T1$index:30:00+09:00',
      user: sampleUserPreviews(count: count)[index].user,
      hasReplies: false,
      stamp: index == 2 ? const Stamp(stampId: 301, stampUrl: '') : null,
    ),
];

class _SampleIllustComments extends IllustComments {
  @override
  Future<CommentPageResult> build(int illustId) async => CommentPageResult(comments: sampleComments());
}

class _SampleUserWorks extends IllustUserWorks {
  @override
  Future<IllustPageResult> build(int userId) async => IllustPageResult(illusts: sampleIllusts(count: 10), rankingIllusts: const []);
}

class _SampleRelatedSource extends IllustRelatedListSource {
  _SampleRelatedSource({required super.illustId});

  @override
  Future<IllustPageResult> loadFirstPage() async => IllustPageResult(illusts: sampleIllusts(count: 20).reversed.toList(), rankingIllusts: const []);

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) async => const IllustPageResult(illusts: [], rankingIllusts: []);
}

class _SampleRelatedWorks extends IllustRelatedWorks {
  @override
  IllustRelatedListSource build(int illustId) {
    final source = _SampleRelatedSource(illustId: illustId);
    ref.onDispose(source.dispose);
    return source;
  }
}

/// The sample artist's page.
final sampleUserDetail = UserDetailResult(
  user: UserInfo(
    id: 2000,
    name: 'Sample artist',
    account: 'sample_artist',
    profileImageUrls: ProfileImageUrls(medium: sampleImageUrl(77, width: 170, height: 170)),
    comment: 'I draw quiet towns, the sea and the light between them.\nCommissions are closed for now; thank you for looking.',
    isFollowed: false,
  ),
  profile: const UserProfile(
    webpage: 'https://example.com',
    gender: '',
    birth: '',
    birthDay: '04-12',
    birthYear: 0,
    region: 'Kanagawa',
    addressId: 0,
    countryCode: '',
    job: 'Illustrator',
    jobId: 0,
    totalFollowUsers: 128,
    totalMypixivUsers: 0,
    totalIllusts: 240,
    totalManga: 12,
    totalNovels: 3,
    totalIllustBookmarksPublic: 50,
    totalIllustSeries: 0,
    totalNovelSeries: 1,
    twitterUrl: 'https://twitter.com/sample_artist',
    isPremium: false,
    isUsingCustomProfileImage: true,
  ),
  profilePublicity: const UserProfilePublicity(gender: '', region: '', birthDay: '', birthYear: '', job: '', pawoo: false),
  workspace: const UserWorkspace(
    pc: '',
    monitor: '',
    tool: '',
    scanner: '',
    tablet: '',
    mouse: '',
    printer: '',
    desktop: '',
    music: '',
    desk: '',
    chair: '',
    comment: '',
  ),
);

class _SampleUserDetail extends UserDetail {
  @override
  FutureOr<UserDetailResult> build(UserDetailArgs args) => args.userDetail ?? sampleUserDetail;
}

class _SampleUserIllusts extends UserIllustListSource {
  _SampleUserIllusts({required super.userId, required super.illustType});

  @override
  Future<IllustPageResult> loadFirstPage() async => IllustPageResult(
    illusts: sampleIllusts(kind: illustType == IllustType.manga ? 'manga' : 'illust'),
    rankingIllusts: const [],
  );

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) async => const IllustPageResult(illusts: [], rankingIllusts: []);
}

class _SampleUserNovels extends UserNovelListSource {
  _SampleUserNovels({required super.userId});

  @override
  Future<NovelPageResult> loadFirstPage() async => NovelPageResult(novels: sampleNovels(count: 6), rankingNovels: const []);

  @override
  Future<NovelPageResult> loadNextPage(String nextUrl) async => const NovelPageResult(novels: [], rankingNovels: []);
}

class _SampleUserFollowing extends UserFollowingListSource {
  _SampleUserFollowing({required super.userId});

  @override
  Future<UserPageResult> loadFirstPage() async => UserPageResult(userPreviews: sampleUserPreviews());

  @override
  Future<UserPageResult> loadNextPage(String nextUrl) async => const UserPageResult(userPreviews: []);
}

class _SampleUserIllustsNotifier extends UserIllusts {
  @override
  UserIllustListSource build({required int userId, required IllustType illustType}) {
    final source = _SampleUserIllusts(userId: userId, illustType: illustType);
    ref.onDispose(source.dispose);
    return source;
  }
}

class _SampleUserNovelsNotifier extends UserNovels {
  @override
  UserNovelListSource build({required int userId}) {
    final source = _SampleUserNovels(userId: userId);
    ref.onDispose(source.dispose);
    return source;
  }
}

class _SampleUserFollowingNotifier extends UserFollowingUsers {
  @override
  UserFollowingListSource build({required int userId}) {
    final source = _SampleUserFollowing(userId: userId);
    ref.onDispose(source.dispose);
    return source;
  }
}

WebviewNovel sampleNovelText(int novelId) => WebviewNovel(
  id: '$novelId',
  title: 'Sample novel',
  userId: '2000',
  coverUrl: '',
  tags: const [],
  caption: '',
  cdate: '',
  rating: const NovelRating(like: 0, bookmark: 120, view: 2000),
  text: List.filled(40, 'The boats came back at dusk, one by one, and the town lit its lamps along the shore.').join('\n\n'),
  illusts: const [],
  images: const [],
  glossaryItems: const [],
  replaceableItemIds: const [],
  aiType: 0,
  isOriginal: true,
);

class _SampleNovelText extends NovelText {
  @override
  FutureOr<WebviewNovel> build(int novelId) => sampleNovelText(novelId);
}

class _SampleNovelComments extends NovelComments {
  @override
  Future<CommentPageResult> build(int novelId) async => CommentPageResult(comments: sampleComments(count: 4));
}

class _SampleNovelUserWorks extends NovelUserWorks {
  @override
  Future<NovelPageResult> build(int userId) async => NovelPageResult(novels: sampleNovels(count: 5), rankingNovels: const []);
}

class _SampleNovelRelatedSource extends NovelRelatedListSource {
  _SampleNovelRelatedSource({required super.novelId});

  @override
  Future<NovelPageResult> loadFirstPage() async => NovelPageResult(novels: sampleNovels(count: 6).reversed.toList(), rankingNovels: const []);

  @override
  Future<NovelPageResult> loadNextPage(String nextUrl) async => const NovelPageResult(novels: [], rankingNovels: []);
}

class _SampleNovelRelated extends NovelRelatedWorks {
  @override
  NovelRelatedListSource build(int novelId) {
    final source = _SampleNovelRelatedSource(novelId: novelId);
    ref.onDispose(source.dispose);
    return source;
  }
}

class _SampleWorkComments extends WorkCommentsListSource {
  _SampleWorkComments({required super.workType, required super.workId});

  @override
  Future<CommentPageResult> loadFirstPage() async => CommentPageResult(comments: sampleComments(count: 10));

  @override
  Future<CommentPageResult> loadNextPage(String nextUrl) async => const CommentPageResult(comments: []);
}

/// Every search request the sample app is asked for, newest last.
final sampleSearchRequests = <SearchResultRequest>[];

class SampleSearchIllusts extends SearchIllustListSource {
  SampleSearchIllusts({required super.request});

  @override
  Future<SearchIllustPageResult> loadFirstPage() async => SearchIllustPageResult(illusts: sampleIllusts(count: 18), searchSpanLimit: 0);

  @override
  Future<SearchIllustPageResult> loadNextPage(String nextUrl) async => const SearchIllustPageResult(illusts: [], searchSpanLimit: 0);
}

class _SampleSearchNovels extends SearchNovelListSource {
  _SampleSearchNovels({required super.request});

  @override
  Future<SearchNovelPageResult> loadFirstPage() async => SearchNovelPageResult(novels: sampleNovels(count: 8), searchSpanLimit: 0);

  @override
  Future<SearchNovelPageResult> loadNextPage(String nextUrl) async => const SearchNovelPageResult(novels: [], searchSpanLimit: 0);
}

class _SampleSearchUsers extends SearchUserListSource {
  _SampleSearchUsers({required super.keyword});

  @override
  Future<UserPageResult> loadFirstPage() async => UserPageResult(userPreviews: sampleUserPreviews(count: 6));

  @override
  Future<UserPageResult> loadNextPage(String nextUrl) async => const UserPageResult(userPreviews: []);
}
