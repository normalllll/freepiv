import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

enum CommentWorkType { illust, novel }

extension CommentWorkTypeX on CommentWorkType {
  bool get supportsPosting => true;
}

class WorkCommentsListSource extends NextUrlListSource<Comment, CommentPageResult> {
  WorkCommentsListSource({required this.workType, required this.workId});

  final CommentWorkType workType;
  final int workId;

  @override
  Future<CommentPageResult> loadFirstPage() {
    return switch (workType) {
      CommentWorkType.illust => pixivApi.getIllustCommentPage(illustId: workId),
      CommentWorkType.novel => pixivApi.getNovelCommentPage(novelId: workId),
    };
  }

  @override
  Future<CommentPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextCommentPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(CommentPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Comment> itemsFromPage(CommentPageResult page) {
    return page.comments;
  }

  Future<Comment> addComment({required String comment, int? stampId, int? parentCommentId}) async {
    final options = CommentAddOptions(comment: comment, stampId: stampId, parentCommentId: parentCommentId);
    final result = switch (workType) {
      CommentWorkType.illust => await pixivApi.postIllustCommentAdd(illustId: workId, options: options),
      CommentWorkType.novel => await pixivApi.postNovelCommentAdd(novelId: workId, options: options),
    };

    if (parentCommentId == null && initialized) {
      insert(0, result.comment);
      notifyDataChanged();
    }

    return result.comment;
  }

  Future<void> deleteComment(Comment comment) async {
    await switch (workType) {
      CommentWorkType.illust => pixivApi.postIllustCommentDelete(commentId: comment.id),
      CommentWorkType.novel => pixivApi.postNovelCommentDelete(commentId: comment.id),
    };

    _removeComment(comment);
  }

  void _removeComment(Comment comment) {
    final index = indexWhere((item) => item.id == comment.id);
    if (index < 0) {
      return;
    }

    removeAt(index);
    notifyDataChanged();
  }
}

class CommentRepliesListSource extends NextUrlListSource<Comment, CommentPageResult> {
  CommentRepliesListSource({required this.workType, required this.parentCommentId});

  final CommentWorkType workType;
  final int parentCommentId;

  @override
  Future<CommentPageResult> loadFirstPage() {
    return switch (workType) {
      CommentWorkType.illust => pixivApi.getIllustCommentReplyPage(commentId: parentCommentId),
      CommentWorkType.novel => pixivApi.getNovelCommentReplyPage(commentId: parentCommentId),
    };
  }

  @override
  Future<CommentPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextCommentPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(CommentPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Comment> itemsFromPage(CommentPageResult page) {
    return page.comments;
  }

  void prependReply(Comment comment) {
    if (!initialized) {
      return;
    }

    insert(0, comment);
    notifyDataChanged();
  }

  Future<void> deleteComment(Comment comment) async {
    await switch (workType) {
      CommentWorkType.illust => pixivApi.postIllustCommentDelete(commentId: comment.id),
      CommentWorkType.novel => pixivApi.postNovelCommentDelete(commentId: comment.id),
    };

    final index = indexWhere((item) => item.id == comment.id);
    if (index < 0) {
      return;
    }

    removeAt(index);
    notifyDataChanged();
  }
}
