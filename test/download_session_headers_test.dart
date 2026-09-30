import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/downloads/default_download_manager.dart';
import 'package:freepiv/core/downloads/download_database.dart' show DownloadDatabase;
import 'package:freepiv/core/downloads/download_engine.dart';
import 'package:freepiv/core/downloads/download_manager_configuration.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/downloads/download_permission_guard.dart';
import 'package:freepiv/core/downloads/download_store.dart';
import 'package:freepiv/core/downloads/media_saver.dart';

/// Records the jobs it is asked to start and never finishes them.
class _RecordingEngine implements DownloadEngine {
  final started = <DownloadJob>[];

  @override
  DownloadEngineType get type => DownloadEngineType.desktopRust;

  @override
  Stream<DownloadEngineEvent> get events => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start(List<DownloadJob> jobs) async => started.addAll(jobs);

  @override
  Future<List<DownloadEngineSnapshot>> syncActiveTasks() async => [];

  @override
  Future<void> acknowledge(Set<String> jobIds) async {}

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Ready implements DownloadPermissionGuard {
  @override
  Future<void> ensureReadyForDownload() async {}
}

const _post = FanboxPostSource(postId: '42', title: 'Post');

DownloadJob _fanboxJob(String url) => DownloadJob.create(
  origin: ContentFile.of(Uri.parse(url)),
  source: _post,
  url: Uri.parse(url),
  filename: '42_1.png',
  saveTarget: const SaveTarget.downloadsFolder(),
  networkOptions: const DownloadNetworkOptions(headers: {'Referer': 'https://www.fanbox.cc/'}),
);

void main() {
  late DriftDownloadStore store;
  late _RecordingEngine engine;

  DefaultDownloadManager managerWith(DownloadSessionHeaders sessionHeaders) {
    store = DriftDownloadStore(DownloadDatabase.withExecutor(NativeDatabase.memory()));
    engine = _RecordingEngine();
    return DefaultDownloadManager(
      configuration: DownloadManagerConfiguration(maxConcurrentDownloads: () => 4, sessionHeaders: sessionHeaders),
      store: store,
      engine: engine,
      mediaSaver: const UnsupportedMediaSaver(),
      permissionGuard: _Ready(),
    );
  }

  test('session headers reach the engine but never the stored job', () async {
    final manager = managerWith((job) async => {'Cookie': 'FANBOXSESSID=secret'});
    addTearDown(manager.dispose);
    addTearDown(() => store.close());

    final job = _fanboxJob('https://downloads.fanbox.cc/images/post/42/1.png');
    await manager.enqueue([job]);

    expect(engine.started.single.networkOptions.headers, {'referer': 'https://www.fanbox.cc/', 'cookie': 'FANBOXSESSID=secret'});
    final stored = await store.getJob(job.id);
    expect(stored?.networkOptions.headers, {'referer': 'https://www.fanbox.cc/'});
    expect(stored?.source, _post);
  });

  test('a download whose session is missing fails with the reason instead of starting', () async {
    final manager = managerWith((job) async => throw const DownloadException('Sign in again'));
    addTearDown(manager.dispose);
    addTearDown(() => store.close());

    final job = _fanboxJob('https://downloads.fanbox.cc/images/post/42/2.png');
    await manager.enqueue([job]);

    expect(engine.started, isEmpty);
    final task = await store.getTask(job.id);
    expect(task?.status, DownloadStatus.failed);
    expect(task?.error, 'Sign in again');
    expect(task?.log, isNot(contains('secret')));
  });

  test('asking again for files already queued reports that nothing was added', () async {
    final manager = managerWith((job) async => const {});
    addTearDown(manager.dispose);
    addTearDown(() => store.close());

    final job = _fanboxJob('https://downloads.fanbox.cc/images/post/42/3.png');
    await manager.enqueue([job]);
    await expectLater(manager.enqueue([job]), throwsA(isA<DownloadAlreadyQueued>()));
  });

  test('FANBOX files keep to their own folder', () {
    expect(_fanboxJob('https://downloads.fanbox.cc/files/post/42/a.zip').folder, 'fanbox');
    expect(_fanboxJob('https://downloads.fanbox.cc/files/post/42/a.zip').toPlatformJson()['folder'], 'fanbox');
    final work = DownloadJob.create(
      origin: const ArtworkPage(illustId: 1, pageIndex: 0),
      source: const ArtworkSource(illustId: 1, title: 'Work'),
      url: Uri.parse('https://i.pximg.net/img-original/img/1_p0.png'),
      saveTarget: const SaveTarget.downloadsFolder(),
    );
    expect(work.folder, isNull);
  });
}
