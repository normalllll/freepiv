import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show visibleForOverriding;
import 'package:frost_data/frost_data.dart';

enum CommentWorkType { illust, novel }

extension CommentWorkTypeX on CommentWorkType {
  bool get supportsPosting => true;
}

/// The comments page's list for a work, kept while the page is open.
final workCommentsSourceProvider = Provider.autoDispose.family<WorkCommentsListSource, (CommentWorkType, int)>((ref, work) {
  final source = WorkCommentsListSource(workType: work.$1, workId: work.$2);
  ref.onDispose(source.dispose);
  return source;
});

/// Makes the list of one comment's replies; the comments page owns each one.
final commentRepliesSourceFactoryProvider = Provider<CommentRepliesListSource Function(CommentWorkType workType, int parentCommentId)>(
  (ref) =>
      (workType, parentCommentId) => CommentRepliesListSource(workType: workType, parentCommentId: parentCommentId),
);

class WorkCommentsListSource extends FrostCursorListSource<Comment, CommentPageResult> with _LocalCommentEdits {
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
      _prepend(result.comment);
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

  void _removeComment(Comment comment) => _remove(comment);
}

class CommentRepliesListSource extends FrostCursorListSource<Comment, CommentPageResult> with _LocalCommentEdits {
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

    _prepend(comment);
  }

  Future<void> deleteComment(Comment comment) async {
    await deleteOnServer(comment);
    _remove(comment);
  }

  /// Deletes the reply on Pixiv; the list drops it afterwards.
  @visibleForOverriding
  Future<void> deleteOnServer(Comment comment) => switch (workType) {
    CommentWorkType.illust => pixivApi.postIllustCommentDelete(commentId: comment.id),
    CommentWorkType.novel => pixivApi.postNovelCommentDelete(commentId: comment.id),
  };
}

/// Comments posted or deleted here, shown over the loaded pages until the next
/// refresh brings the server's list. The loaded pages themselves only change by
/// loading.
mixin _LocalCommentEdits on FrostListSource<Comment> {
  final List<Comment> _added = [];
  final Set<int> _removed = {};

  @override
  UnmodifiableListView<Comment> get items {
    final loaded = super.items;
    if (_added.isEmpty && _removed.isEmpty) return loaded;
    return UnmodifiableListView([
      for (final comment in _added)
        if (!_removed.contains(comment.id)) comment,
      for (final comment in loaded)
        if (!_removed.contains(comment.id) && !_added.any((added) => added.id == comment.id)) comment,
    ]);
  }

  void _prepend(Comment comment) {
    _added.insert(0, comment);
    _removed.remove(comment.id);
    notifyDataChanged();
  }

  void _remove(Comment comment) {
    if (!items.any((item) => item.id == comment.id)) return;
    _removed.add(comment.id);
    notifyDataChanged();
  }

  @override
  Future<bool> refresh([bool notifyStateChanged = false]) async {
    final refreshed = await super.refresh(notifyStateChanged);
    if (refreshed) {
      _added.clear();
      _removed.clear();
      notifyDataChanged();
    }
    return refreshed;
  }
}
