// Sample data for development: the sample entrypoint (tool/sample_main.dart),
// screenshots and widget tests. Nothing in the app's own entrypoint imports
// this file, so release builds leave it out.
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/features/downloads/presentation/download_entry.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
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
      imageUrls: const ImageUrls(squareMedium: '', medium: '', large: ''),
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
final sampleOverrides = [
  homeIllustSourceProvider.overrideWith((ref) {
    final source = SampleIllustSource(illustType: IllustType.illust);
    ref.onDispose(source.dispose);
    return source;
  }),
  homeMangaSourceProvider.overrideWith((ref) {
    final source = SampleIllustSource(illustType: IllustType.manga);
    ref.onDispose(source.dispose);
    return source;
  }),
  searchTrendingTagsProvider.overrideWith(_SampleTrendingTags.new),
  downloadTasksProvider.overrideWith((ref) => Stream.value(sampleDownloadTasks)),
  fanboxDownloadsProvider.overrideWithValue(const {}),
];
