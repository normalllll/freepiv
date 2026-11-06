import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'login_logic.dart';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:freepiv/core/downloads/download_file_system.dart';
import 'package:freepiv/core/downloads/download_manager.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';

part 'logic.g.dart';

@Riverpod(keepAlive: true)
Future<Box<String>> fanboxStore(Ref ref) => Hive.openBox<String>('fanbox');

class FanboxSignedOut implements Exception {}

@riverpod
class FanboxOperation extends _$FanboxOperation {
  @override
  Future<void> build(String scope) async {}
  Future<bool> run(Future<void> Function() operation) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await operation();
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
class FanboxSession extends _$FanboxSession {
  int _revision = 0;

  @override
  Future<String?> build() async => (await ref.watch(fanboxStoreProvider.future)).get('session');

  Future<bool> signIn(String input, {bool Function()? canCommit}) async {
    final revision = ++_revision;
    var session = input.trim();
    if (session.startsWith('{')) {
      final json = jsonDecode(session) as Map<String, Object?>;
      session = (json['session_id'] ?? json['session']) as String? ?? '';
    }
    if (session.startsWith('FANBOXSESSID=')) session = session.substring('FANBOXSESSID='.length);
    final api = _createApi(session, ref.read(proxySettingsProvider));
    try {
      await api.validateSession();
      final store = await ref.read(fanboxStoreProvider.future);
      if (!ref.mounted || revision != _revision || canCommit?.call() == false) return false;
      await store.put('session', session);
      if (ref.mounted && revision == _revision) state = AsyncData(session);
      return ref.mounted && revision == _revision;
    } finally {
      api.dispose();
    }
  }

  Future<void> signOut() async {
    ++_revision;
    await ref.read(fanboxWebLoginProvider.notifier).clearBrowser(() async {
      final store = await ref.read(fanboxStoreProvider.future);
      await store.delete('session');
      if (ref.mounted) state = const AsyncData(null);
    });
  }
}

FanboxApi _createApi(String session, AppProxySettings proxy) =>
    FanboxApi(session: session, proxy: proxy.activeUrl, language: LocaleSettings.currentLocale.languageTag, acceptInvalidCerts: false);

@riverpod
Future<FanboxApi> fanboxApi(Ref ref) async {
  final proxy = ref.watch(proxySettingsProvider);
  final session = await ref.watch(fanboxSessionProvider.future);
  if (session == null || !ref.mounted) throw FanboxSignedOut();
  final api = _createApi(session, proxy);
  ref.onDispose(api.dispose);
  return api;
}

enum FanboxSection {
  home,
  supporting,
  following,
  recommended,
  pixiv,
  plans,
  searchCreators,
  searchTags,
  tag,
  creatorPosts,
  creatorPlans,
  notices,
  messages,
  bookmarks,
}

typedef FanboxLocation = ({FanboxSection section, String creatorId, String query});

sealed class FanboxEntry {
  const FanboxEntry();
}

class FanboxPostEntry extends FanboxEntry {
  const FanboxPostEntry(this.post);
  final FanboxPost post;
}

/// A post saved in the local bookmarks, loaded on its own when shown.
class FanboxBookmarkEntry extends FanboxEntry {
  const FanboxBookmarkEntry(this.postId);
  final String postId;
}

class FanboxCreatorEntry extends FanboxEntry {
  const FanboxCreatorEntry(this.creator);
  final FanboxCreator creator;
}

class FanboxPlanEntry extends FanboxEntry {
  const FanboxPlanEntry(this.plan);
  final FanboxPlan plan;
}

class FanboxTagEntry extends FanboxEntry {
  const FanboxTagEntry(this.tag);
  final FanboxTag tag;
}

class FanboxNoticeEntry extends FanboxEntry {
  const FanboxNoticeEntry(this.notice);
  final FanboxNotice notice;
}

class FanboxCollection {
  const FanboxCollection(this.entries, {this.nextUrl, this.nextPage, this.loadingMore = false, this.error});
  final List<FanboxEntry> entries;
  final String? nextUrl;
  final int? nextPage;
  final bool loadingMore;
  final Object? error;
  bool get hasMore => nextUrl != null || nextPage != null;
}

@Riverpod(keepAlive: true)
class FanboxBrowseSelection extends _$FanboxBrowseSelection {
  @override
  FanboxLocation build() => (section: FanboxSection.home, creatorId: '', query: '');
  void select(FanboxLocation location) => state = location;
}

@riverpod
class FanboxBrowse extends _$FanboxBrowse {
  int _revision = 0;
  @override
  Future<FanboxCollection> build(FanboxLocation location) async {
    final retention = ref.keepAlive();
    Timer? expiry;
    ref.onCancel(() => expiry = Timer(const Duration(minutes: 10), retention.close));
    ref.onResume(() => expiry?.cancel());
    ref.onDispose(() => expiry?.cancel());

    ++_revision;
    if (location.section == FanboxSection.bookmarks) {
      // Each bookmark loads in its own row (fanboxPostProvider), so a slow or
      // removed post holds up or fails only that row.
      final ids = await ref.watch(fanboxBookmarksProvider.future);
      return FanboxCollection(List.unmodifiable([for (final id in ids) FanboxBookmarkEntry(id)]));
    }
    final api = await ref.watch(fanboxApiProvider.future);
    return _fetch(api, location, null, 1);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    final revision = _revision;
    state = AsyncData(FanboxCollection(current.entries, nextUrl: current.nextUrl, nextPage: current.nextPage, loadingMore: true));
    try {
      final api = await ref.read(fanboxApiProvider.future);
      final next = await _fetch(api, location, current.nextUrl, current.nextPage ?? 1);
      if (!ref.mounted || revision != _revision) return;
      final seen = <String>{};
      final entries = [...current.entries, ...next.entries].where((e) => seen.add(_key(e))).toList(growable: false);
      state = AsyncData(
        FanboxCollection(
          entries,
          nextUrl: next.nextUrl == current.nextUrl ? null : next.nextUrl,
          nextPage: next.nextPage == current.nextPage ? null : next.nextPage,
        ),
      );
    } catch (error) {
      if (ref.mounted && revision == _revision) {
        state = AsyncData(FanboxCollection(current.entries, nextUrl: current.nextUrl, nextPage: current.nextPage, error: error));
      }
    }
  }

  String _key(FanboxEntry entry) => switch (entry) {
    FanboxPostEntry(:final post) => 'post:${post.id}',
    FanboxBookmarkEntry(:final postId) => 'post:$postId',
    FanboxCreatorEntry(:final creator) => 'creator:${creator.creatorId}',
    FanboxPlanEntry(:final plan) => 'plan:${plan.id}',
    FanboxTagEntry(:final tag) => 'tag:${tag.name}',
    FanboxNoticeEntry(:final notice) => 'notice:${notice.id}',
  };

  Future<FanboxCollection> _fetch(FanboxApi api, FanboxLocation location, String? cursor, int page) async {
    switch (location.section) {
      case FanboxSection.home:
      case FanboxSection.supporting:
      case FanboxSection.creatorPosts:
      case FanboxSection.tag:
        final feed = switch (location.section) {
          FanboxSection.supporting => const FanboxFeed.supporting(),
          FanboxSection.creatorPosts => FanboxFeed.creator(creatorId: location.creatorId),
          FanboxSection.tag => FanboxFeed.tag(tag: location.query, creatorId: location.creatorId.isEmpty ? null : location.creatorId, page: page),
          _ => const FanboxFeed.home(),
        };
        final result = cursor == null ? await api.getPosts(feed: feed) : await api.getNextPosts(url: cursor);
        return FanboxCollection(result.posts.map(FanboxPostEntry.new).toList(growable: false), nextUrl: result.nextUrl, nextPage: result.nextPage);
      case FanboxSection.following:
      case FanboxSection.recommended:
      case FanboxSection.pixiv:
        final list = switch (location.section) {
          FanboxSection.following => FanboxCreatorList.following,
          FanboxSection.pixiv => FanboxCreatorList.pixiv,
          _ => FanboxCreatorList.recommended,
        };
        return FanboxCollection((await api.getCreators(list: list)).map(FanboxCreatorEntry.new).toList(growable: false));
      case FanboxSection.searchCreators:
        final result = await api.searchCreators(keyword: location.query, page: page);
        return FanboxCollection(result.creators.map(FanboxCreatorEntry.new).toList(growable: false), nextPage: result.nextPage);
      case FanboxSection.searchTags:
        return FanboxCollection((await api.searchTags(keyword: location.query)).map(FanboxTagEntry.new).toList(growable: false));
      case FanboxSection.plans:
      case FanboxSection.creatorPlans:
        return FanboxCollection(
          (await api.getPlans(creatorId: location.section == FanboxSection.plans ? null : location.creatorId)).map(FanboxPlanEntry.new).toList(growable: false),
        );
      case FanboxSection.notices:
        final result = cursor == null ? await api.getNotices() : await api.getNextNotices(url: cursor);
        return FanboxCollection(result.notices.map(FanboxNoticeEntry.new).toList(growable: false), nextUrl: result.nextUrl);
      case FanboxSection.messages:
        return FanboxCollection((await api.getMessages()).map(FanboxNoticeEntry.new).toList(growable: false));
      case FanboxSection.bookmarks:
        return const FanboxCollection([]);
    }
  }
}

/// A loaded post stays for ten minutes after nothing shows it, like the
/// collections, so a bookmark row scrolled back into view is not fetched again.
/// A failed load is dropped as soon as nothing shows it.
@riverpod
Future<FanboxPost> fanboxPost(Ref ref, String id) async {
  final retention = ref.keepAlive();
  Timer? expiry;
  ref.onCancel(() => expiry = Timer(const Duration(minutes: 10), retention.close));
  ref.onResume(() => expiry?.cancel());
  ref.onDispose(() => expiry?.cancel());
  try {
    return await (await ref.watch(fanboxApiProvider.future)).getPost(postId: id);
  } catch (_) {
    retention.close();
    rethrow;
  }
}

@riverpod
Future<FanboxCreator> fanboxCreator(Ref ref, String id) async => (await ref.watch(fanboxApiProvider.future)).getCreator(creatorId: id);
@riverpod
Future<List<FanboxPlan>> fanboxPlans(Ref ref, String creatorId) async => (await ref.watch(fanboxApiProvider.future)).getPlans(creatorId: creatorId);
@riverpod
Future<List<FanboxTag>> fanboxTags(Ref ref, String creatorId) async => (await ref.watch(fanboxApiProvider.future)).getCreatorTags(creatorId: creatorId);
@riverpod
Future<FanboxSupport> fanboxSupport(Ref ref, String creatorId) async => (await ref.watch(fanboxApiProvider.future)).getCreatorSupport(creatorId: creatorId);
@riverpod
Future<Uint8List> fanboxMedia(Ref ref, String url) async => (await ref.watch(fanboxApiProvider.future)).getMediaBytes(url: url);

@riverpod
class FanboxComments extends _$FanboxComments {
  bool _loading = false;
  @override
  Future<FanboxCommentPage> build(String postId) async => (await ref.watch(fanboxApiProvider.future)).getComments(postId: postId);
  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (_loading || current?.nextUrl == null) return;
    _loading = true;
    try {
      final next = await (await ref.read(fanboxApiProvider.future)).getNextComments(url: current!.nextUrl!);
      if (ref.mounted && identical(state.asData?.value, current)) {
        state = AsyncData(FanboxCommentPage(comments: [...current.comments, ...next.comments], nextUrl: next.nextUrl, canComment: next.canComment));
      }
    } finally {
      _loading = false;
    }
  }
}

@Riverpod(keepAlive: true)
class FanboxBookmarks extends _$FanboxBookmarks {
  Future<void> _pending = Future.value();
  @override
  Future<List<String>> build() async {
    final store = await ref.watch(fanboxStoreProvider.future);
    return (jsonDecode(store.get('bookmarks', defaultValue: '[]')!) as List<Object?>).cast<String>();
  }

  Future<void> toggle(String id) {
    final next = _pending.then((_) => _toggle(id));
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<void> _toggle(String id) async {
    final current = await future;
    final next = current.contains(id) ? current.where((e) => e != id).toList() : [id, ...current];
    final store = await ref.read(fanboxStoreProvider.future);
    await store.put('bookmarks', jsonEncode(next));
    if (ref.mounted) state = AsyncData(List.unmodifiable(next));
  }
}

/// A creator being collected for download, with the posts read so far.
typedef FanboxCollecting = ({FanboxCreatorSource source, int posts});

bool _isFanboxHost(String host) => host == 'fanbox.cc' || host.endsWith('.fanbox.cc');

/// The headers a FANBOX download needs from the session (see
/// DownloadSessionHeaders): the stored session's cookie, for files on
/// FANBOX's own hosts, read each time a download starts.
Future<Map<String, String>> fanboxDownloadSessionHeaders(DownloadJob job) async {
  if (!_isFanboxHost(job.url.host)) return const {};
  final session = (await Hive.openBox<String>('fanbox')).get('session');
  if (session == null) throw DownloadException(t.fanbox.sessionExpired);
  return {'Cookie': 'FANBOXSESSID=$session'};
}

/// FANBOX downloads, run by the download manager like every other download.
///
/// Downloading a creator whole first collects their posts page by page,
/// queueing each post's files as soon as the post is read. The state is the
/// creators still being collected, by creator id, with how many posts were
/// read so far.
@Riverpod(keepAlive: true)
class FanboxDownloads extends _$FanboxDownloads {
  final _stopRequested = <String>{};
  int _sessionRevision = 0;

  @override
  Map<String, FanboxCollecting> build() {
    ref.listen(fanboxSessionProvider, (previous, next) {
      if (previous?.hasValue == true && next.hasValue && previous?.value != next.value) {
        // Another account, or none: what the old session asked for stops.
        _sessionRevision++;
        unawaited(_cancelActiveDownloads());
      }
    });
    return const {};
  }

  /// Queues every image and file of [post]; returns how many were queued,
  /// none when all of them already are.
  Future<int> downloadPost(FanboxPost post, {required FanboxPostSource source}) => _enqueue(_postJobs(post, source: source));

  /// Downloads one image or attachment shown under [source]; completes once
  /// it is saved.
  Future<DownloadedFile> downloadFile({required String url, required String filename, required DownloadSource source, bool image = true}) {
    final uri = Uri.parse(url);
    return downloadManager.download(
      origin: ContentFile.of(uri),
      source: source,
      url: uri,
      filename: filename,
      networkOptions: _requestOptions,
      validation: image ? _imageValidation : const DownloadValidationOptions(),
      thumbnailUrl: image ? url : null,
    );
  }

  /// Collects every post of [source]'s creator that the session can read
  /// and queues its files, each under its post; returns how many were queued.
  /// Does nothing while the creator is already being collected.
  Future<int> downloadCreator(FanboxCreatorSource source) async {
    final creatorId = source.creatorId;
    if (state.containsKey(creatorId)) return 0;
    final revision = _sessionRevision;
    _stopRequested.remove(creatorId);
    _setCollected(source, 0);
    var queued = 0;
    var posts = 0;
    bool stopped() => !ref.mounted || _stopRequested.contains(creatorId) || revision != _sessionRevision;
    try {
      final api = await ref.read(fanboxApiProvider.future);
      for (final url in await api.getCreatorPostPages(creatorId: creatorId)) {
        if (stopped()) break;
        final page = await api.getNextPosts(url: url);
        for (final summary in page.posts) {
          if (stopped()) break;
          if (summary.isRestricted) continue;
          final post = await api.getPost(postId: summary.id);
          if (stopped()) break;
          queued += await _enqueue(
            _postJobs(
              post,
              source: source,
              part: DownloadPart(id: post.id, title: post.title),
            ),
          );
          _setCollected(source, ++posts);
        }
      }
      return queued;
    } finally {
      _stopRequested.remove(creatorId);
      if (ref.mounted) state = Map.unmodifiable({...state}..remove(creatorId));
    }
  }

  /// Stops collecting [creatorId]'s posts; files already queued carry on
  /// unless cancelled themselves.
  void stopCollecting(String creatorId) {
    if (state.containsKey(creatorId)) _stopRequested.add(creatorId);
  }

  void _setCollected(FanboxCreatorSource source, int posts) {
    if (ref.mounted) state = Map.unmodifiable({...state, source.creatorId: (source: source, posts: posts)});
  }

  Future<int> _enqueue(List<DownloadJob> jobs) async {
    if (jobs.isEmpty) return 0;
    try {
      return await downloadManager.enqueue(jobs);
    } on DownloadAlreadyQueued {
      return 0;
    }
  }

  Future<void> _cancelActiveDownloads() async {
    for (final task in await downloadManager.listTasks()) {
      if (task.source is FanboxSource && !task.isTerminal) await downloadManager.cancel(task.id);
    }
  }

  static const _requestOptions = DownloadNetworkOptions(headers: {'Referer': 'https://www.fanbox.cc/'});
  static const _imageValidation = DownloadValidationOptions(allowedContentTypes: ['image/*']);

  List<DownloadJob> _postJobs(FanboxPost post, {required FanboxSource source, DownloadPart? part}) {
    DownloadJob job(String url, String filename, {required bool image, String? thumbnailUrl}) {
      final uri = Uri.parse(url);
      return DownloadJob.create(
        origin: ContentFile.of(uri),
        source: source,
        part: part,
        url: uri,
        filename: safeDownloadFilename(filename),
        saveTarget: const SaveTarget.downloadsFolder(),
        networkOptions: _requestOptions,
        validation: image ? _imageValidation : const DownloadValidationOptions(),
        thumbnailUrl: thumbnailUrl,
      );
    }

    return [
      for (final block in post.blocks)
        ...switch (block) {
          FanboxBlock_Image(:final image) => [
            job(image.originalUrl, '${post.id}_${image.id}.${image.extension_}', image: true, thumbnailUrl: image.thumbnailUrl),
          ],
          FanboxBlock_File(:final file) => [job(file.url, '${post.id}_${file.id}_${file.name}.${file.extension_}', image: false)],
          _ => const <DownloadJob>[],
        },
    ];
  }
}
