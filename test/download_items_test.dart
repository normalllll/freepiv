import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/features/downloads/logic.dart';

const _work = ArtworkSource(illustId: 101, title: 'Summer sketches', subtitle: 'Mika');
const _article = PixivisionSource(articleId: 9, url: 'https://www.pixivision.net/en/a/9', title: 'Blue skies in illustration');
const _novel = NovelSource(novelId: 77, title: 'The lighthouse keeper', subtitle: 'Ren');
const _post = FanboxPostSource(postId: '500', title: 'March rewards', subtitle: 'Studio Kite');
const _creator = FanboxCreatorSource(creatorId: 'kite', title: 'Studio Kite');

var _clock = 0;

DownloadTaskSnapshot _task(
  DownloadSource source,
  String filename, {
  DownloadStatus status = DownloadStatus.downloaded,
  SaveState saveState = SaveState.saved,
  double progress = 1,
  DownloadPart? part,
  String? error,
}) {
  final created = DateTime(2026, 10, 5, 12, 0, _clock++);
  return DownloadTaskSnapshot(
    id: '${source.key}/$filename',
    origin: ContentFile(Uri.parse('https://example.com/$filename')),
    source: source,
    part: part,
    title: filename,
    filename: filename,
    status: status,
    saveState: saveState,
    receivedBytes: (progress * 2400000).round(),
    totalBytes: 2400000,
    progress: progress,
    localPath: saveState == SaveState.saved ? 'C:/Users/me/Downloads/freepiv/$filename' : null,
    error: error,
    log: null,
    createdAt: created,
    updatedAt: created,
  );
}

const _postA = DownloadPart(id: '1', title: 'January sketches');
const _postB = DownloadPart(id: '2', title: 'February commission');

/// A history with one item of each kind: a saved two-page work, a Pixivision
/// article still downloading, a novel image that failed, a FANBOX post, and
/// a creator still being collected.
List<DownloadTaskSnapshot> _history() {
  _clock = 0;
  return [
    _task(_work, '101_p0.png'),
    _task(_work, '101_p1.png'),
    _task(_article, 'sky_1.jpg'),
    _task(_article, 'sky_2.jpg', status: DownloadStatus.running, saveState: SaveState.none, progress: .4),
    _task(_article, 'sky_3.jpg', status: DownloadStatus.queued, saveState: SaveState.none, progress: 0),
    _task(_novel, 'cover.jpg', status: DownloadStatus.failed, saveState: SaveState.none, progress: 0, error: 'HTTP 403 · Forbidden'),
    for (var index = 0; index < 4; index++) _task(_post, '500_$index.png'),
    _task(_post, '500_files.zip', status: DownloadStatus.running, saveState: SaveState.none, progress: .7),
    _task(_creator, '1_a.png', part: _postA),
    _task(_creator, '1_b.png', part: _postA),
    _task(_creator, '2_a.png', part: _postB, status: DownloadStatus.failed, saveState: SaveState.none, progress: 0, error: 'Connection reset'),
    _task(_creator, '2_b.png', part: _postB, status: DownloadStatus.queued, saveState: SaveState.none, progress: 0),
  ];
}

void main() {
  group('download items', () {
    test('group tasks by source, newest first, keeping each part in order', () {
      final items = downloadItemsOf(_history());
      expect(items.map((item) => item.source), [_creator, _post, _novel, _article, _work]);
      final creator = items.first;
      expect(creator.parts.map((part) => part.$1), [_postA, _postB]);
      expect(creator.total, 4);
      expect(creator.completed, 2);
      expect(creator.failed, 1);
      expect(creator.state, DownloadItemState.active);
      expect(items.last.state, DownloadItemState.completed);
      expect(items.last.progress, 1);
    });

    test('a creator still collecting shows before its first file, with no progress yet', () {
      final items = downloadItemsOf(
        [_task(_work, '1_p0.png')],
        collecting: [(source: const FanboxCreatorSource(creatorId: 'new', title: 'New'), posts: 3)],
      );
      expect(items.first.source.key, 'fanboxCreator:new');
      expect(items.first.state, DownloadItemState.collecting);
      expect(items.first.collectedPosts, 3);
      expect(items.first.progress, isNull);
    });

    test('the panel puts items needing attention before finished ones', () {
      final ordered = panelOrder(downloadItemsOf(_history()));
      expect(ordered.map((item) => item.state).toList(), [
        DownloadItemState.active,
        DownloadItemState.active,
        DownloadItemState.failed,
        DownloadItemState.active,
        DownloadItemState.completed,
      ]);
    });
  });
}
