import 'dart:async';

import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

@Riverpod(keepAlive: true, retry: noRetry)
class NovelDetail extends _$NovelDetail {
  @override
  FutureOr<NovelDetailData> build(NovelDetailArgs args) async {
    return _load(args);
  }

  Future<void> reload() async {
    state = const AsyncLoading<NovelDetailData>();
    state = await AsyncValue.guard(() => _load(args));
  }

  Future<NovelDetailData> _load(NovelDetailArgs args) async {
    final novel = args.novel;
    final novelId = args.resolvedNovelId;
    final webviewFuture = pixivApi.getWebviewNovel(novelId: novelId);

    if (novel != null) {
      return NovelDetailData(novel: novel, webviewNovel: await webviewFuture);
    }

    final detailFuture = pixivApi.getNovelDetail(novelId: novelId);
    final detail = await detailFuture;

    return NovelDetailData(novel: detail.novel, webviewNovel: await webviewFuture);
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

class NovelRelatedListSource extends NextUrlListSource<Novel, NovelPageResult> {
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
