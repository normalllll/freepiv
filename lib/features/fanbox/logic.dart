import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'login_logic.dart';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:freepiv/core/downloads/download_file_system.dart';
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
    final api = await ref.watch(fanboxApiProvider.future);
    if (location.section == FanboxSection.bookmarks) {
      final ids = await ref.watch(fanboxBookmarksProvider.future);
      final posts = <FanboxEntry>[];
      for (final id in ids) {
        posts.add(FanboxPostEntry(await api.getPost(postId: id)));
      }
      return FanboxCollection(List.unmodifiable(posts));
    }
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

@riverpod
Future<FanboxPost> fanboxPost(Ref ref, String id) async => (await ref.watch(fanboxApiProvider.future)).getPost(postId: id);
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

class FanboxDownloadProgress {
  const FanboxDownloadProgress({this.running = false, this.completed = 0, this.total = 0, this.error, this.files = const [], this.cancelled = false});
  final bool running;
  final int completed;
  final int total;
  final Object? error;
  final List<String> files;
  final bool cancelled;
  bool get visible => running || total > 0 || error != null || cancelled;
}

Future<String> fanboxDownloadDirectory() async {
  final root = Platform.isWindows || Platform.isLinux || Platform.isMacOS
      ? await resolveDesktopDownloadDirectory()
      : p.join((await getApplicationDocumentsDirectory()).path, appDownloadDirectoryName);
  return p.join(root, 'fanbox');
}

@Riverpod(keepAlive: true)
class FanboxDownloads extends _$FanboxDownloads {
  bool _cancelled = false;
  ({String directory, FanboxPost? post, String? creatorId, List<({String url, String filename})> media})? _lastRequest;
  @override
  FanboxDownloadProgress build() {
    ref.onDispose(() => _cancelled = true);
    ref.listen(fanboxSessionProvider, (previous, next) {
      if (previous?.hasValue == true && next.hasValue && previous?.value != next.value) {
        _cancelled = true;
        _lastRequest = null;
      }
    });
    return const FanboxDownloadProgress();
  }

  void cancel() {
    _cancelled = true;
  }

  Future<void> retry() async {
    final request = _lastRequest;
    if (request != null) await downloadPosts(directory: request.directory, post: request.post, creatorId: request.creatorId, media: request.media);
  }

  Future<void> downloadPosts({required String directory, FanboxPost? post, String? creatorId, List<({String url, String filename})> media = const []}) async {
    if (state.running) return;
    _lastRequest = (directory: directory, post: post, creatorId: creatorId, media: List.unmodifiable(media));
    _cancelled = false;
    state = const FanboxDownloadProgress(running: true);
    var completed = 0;
    var total = 0;
    var files = const <String>[];
    try {
      await Directory(directory).create(recursive: true);
      final api = await ref.read(fanboxApiProvider.future);
      final posts = <FanboxPost>[];
      if (post != null) posts.add(post);
      if (creatorId != null) {
        for (final url in await api.getCreatorPostPages(creatorId: creatorId)) {
          if (_cancelled) break;
          final page = await api.getNextPosts(url: url);
          for (final summary in page.posts) {
            if (_cancelled) break;
            if (!summary.isRestricted) posts.add(await api.getPost(postId: summary.id));
          }
        }
      }
      final downloads = <({String url, String filename})>[...media];
      for (final post in posts) {
        for (final block in post.blocks) {
          switch (block) {
            case FanboxBlock_Image(:final image):
              downloads.add((url: image.originalUrl, filename: '${post.id}_${image.id}.${image.extension_}'));
            case FanboxBlock_File(:final file):
              downloads.add((url: file.url, filename: '${post.id}_${file.id}_${file.name}.${file.extension_}'));
            default:
              break;
          }
        }
      }
      total = downloads.length;
      files = List.unmodifiable(downloads.map((item) => item.filename));
      if (!ref.mounted) return;
      state = FanboxDownloadProgress(running: true, completed: completed, total: total, files: files);
      for (final item in downloads) {
        if (_cancelled) break;
        final filename = safeDownloadFilename(item.filename);
        final destination = p.join(directory, filename);
        if (!await File(destination).exists()) await api.downloadMedia(url: item.url, path: destination);
        completed++;
        if (!ref.mounted) return;
        state = FanboxDownloadProgress(running: true, completed: completed, total: total, files: files);
      }
      if (ref.mounted) state = FanboxDownloadProgress(completed: completed, total: total, files: files, cancelled: _cancelled);
    } catch (error) {
      if (ref.mounted) state = FanboxDownloadProgress(completed: completed, total: total, error: error, files: files);
    }
  }
}
