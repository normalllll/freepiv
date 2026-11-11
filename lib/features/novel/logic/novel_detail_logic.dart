import 'dart:async';

import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frost_data/frost_data.dart';

part 'novel_detail_logic.g.dart';

class NovelDetailArgs {
  const NovelDetailArgs({this.novelId, this.novel}) : assert(novelId != null || novel != null);

  final int? novelId;
  final Novel? novel;

  int get resolvedNovelId {
    final novel = this.novel;
    if (novel != null) {
      return novel.id;
    }

    final novelId = this.novelId;
    if (novelId == null) {
      throw ArgumentError('Either novelId or novel must be provided.');
    }

    return novelId;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is NovelDetailArgs && other.resolvedNovelId == resolvedNovelId;
  }

  @override
  int get hashCode => resolvedNovelId.hashCode;
}

class NovelDetailData {
  const NovelDetailData({required this.novel, required this.webviewNovel});

  final Novel novel;
  final WebviewNovel webviewNovel;
}

Duration? noRetry(int retryCount, Object error) => null;

@Riverpod(keepAlive: true)
String? novelAccountId(Ref ref) {
  void changed() => ref.invalidateSelf();
  pixivAccountNotifier.addListener(changed);
  ref.onDispose(() => pixivAccountNotifier.removeListener(changed));
  return pixivAccountNotifier.value?.user.id;
}

/// The novel's details: the work passed in when it opens, or fetched. Its
/// text loads on its own ([NovelText]), so a failed text leaves the details
/// usable.
@Riverpod(keepAlive: true, retry: noRetry)
class NovelDetail extends _$NovelDetail {
  int _requestVersion = 0;
  bool _seedAccountCaptured = false;
  String? _seedAccountId;

  @override
  FutureOr<Novel> build(NovelDetailArgs args) async {
    final accountId = ref.watch(novelAccountIdProvider);
    _requestVersion++;
    if (!_seedAccountCaptured) {
      _seedAccountCaptured = true;
      _seedAccountId = accountId;
    }
    return _load(args, useSeed: accountId == _seedAccountId);
  }

  Future<void> reload() async {
    final accountId = ref.read(novelAccountIdProvider);
    final request = ++_requestVersion;
    state = const AsyncLoading<Novel>();
    final result = await AsyncValue.guard(() => _load(args, useSeed: accountId == _seedAccountId));
    if (ref.mounted && request == _requestVersion && pixivAccountNotifier.value?.user.id == accountId) state = result;
  }

  Future<Novel> _load(NovelDetailArgs args, {required bool useSeed}) async {
    final novel = (useSeed ? args.novel : null) ?? (await pixivApi.getNovelDetail(novelId: args.resolvedNovelId)).novel;
    unawaited(recordNovelView(novel));
    return novel;
  }
}

/// The novel's text and the details only its web view carries (cover, images,
/// original and AI flags), per account.
@Riverpod(keepAlive: true, retry: noRetry)
class NovelText extends _$NovelText {
  int _requestVersion = 0;

  @override
  FutureOr<WebviewNovel> build(int novelId) {
    ref.watch(novelAccountIdProvider);
    _requestVersion++;
    return pixivApi.getWebviewNovel(novelId: novelId);
  }

  Future<void> reload() async {
    final accountId = ref.read(novelAccountIdProvider);
    final request = ++_requestVersion;
    state = const AsyncLoading<WebviewNovel>();
    final result = await AsyncValue.guard(() => pixivApi.getWebviewNovel(novelId: novelId));
    if (ref.mounted && request == _requestVersion && pixivAccountNotifier.value?.user.id == accountId) state = result;
  }
}

@Riverpod(keepAlive: true)
class NovelComments extends _$NovelComments {
  @override
  Future<CommentPageResult> build(int novelId) {
    return pixivApi.getNovelCommentPage(novelId: novelId);
  }

  Future<void> reload() async {
    state = const AsyncLoading<CommentPageResult>();
    state = await AsyncValue.guard(() => pixivApi.getNovelCommentPage(novelId: novelId));
  }
}

@Riverpod(keepAlive: true)
class NovelUserWorks extends _$NovelUserWorks {
  @override
  Future<NovelPageResult> build(int userId) {
    return pixivApi.getUserNovelPage(userId: userId);
  }

  Future<void> reload() async {
    state = const AsyncLoading<NovelPageResult>();
    state = await AsyncValue.guard(() => pixivApi.getUserNovelPage(userId: userId));
  }
}

@Riverpod(keepAlive: true)
class NovelRelatedWorks extends _$NovelRelatedWorks {
  @override
  NovelRelatedListSource build(int novelId) {
    final source = NovelRelatedListSource(novelId: novelId);
    ref.onDispose(source.dispose);
    return source;
  }
}

class NovelRelatedListSource extends FrostCursorListSource<Novel, NovelPageResult> {
  NovelRelatedListSource({required this.novelId});

  final int novelId;

  @override
  Future<NovelPageResult> loadFirstPage() {
    return pixivApi.getNovelRelatedPage(novelId: novelId);
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
}
