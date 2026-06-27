import 'package:flutter/material.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_input_bar.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_tile.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

class WorkCommentsPage extends StatefulWidget {
  const WorkCommentsPage({required this.workType, required this.workId, this.totalComments, super.key});

  final CommentWorkType workType;
  final int workId;
  final int? totalComments;

  @override
  State<WorkCommentsPage> createState() => _WorkCommentsPageState();
}

class _WorkCommentsPageState extends State<WorkCommentsPage> {
  late final WorkCommentsListSource _source = WorkCommentsListSource(workType: widget.workType, workId: widget.workId);
  late final Future<PixivCommentAssets> _assetsFuture = PixivCommentAssets.load();

  final Map<int, CommentRepliesListSource> _replySources = {};
  final Set<int> _deletingCommentIds = {};
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _source.refresh(true);
  }

  @override
  void dispose() {
    _source.dispose();
    for (final source in _replySources.values) {
      source.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        final canPost = widget.workType.supportsPosting;
        final currentUserId = int.tryParse(pixivAccountNotifier.value?.user.id ?? '');
        final title = _title(context);

        return FutureBuilder<PixivCommentAssets>(
          future: _assetsFuture,
          builder: (context, snapshot) {
            final assets = snapshot.data ?? PixivCommentAssets.empty;
            final commentsView = _CommentsRefreshView(
              source: _source,
              assets: assets,
              workType: widget.workType,
              repliesSourceBuilder: _replySourceFor,
              onRefresh: () => _source.refresh(_source.isEmpty),
              onReply: canPost ? _setReplyingTo : null,
              onDelete: _deleteComment,
              currentUserId: currentUserId,
              isDeletingComment: _isDeletingComment,
            );
            final inputBar = canPost
                ? CommentInputBar(assets: assets, replyingTo: _replyingTo, onCancelReply: _clearReplyingTo, onSubmit: _submitComment)
                : null;

            if (shouldUseDesktopShell) {
              return _DesktopCommentsScaffold(title: title, inputBar: inputBar, child: commentsView);
            }

            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: commentsView,
              bottomNavigationBar: inputBar,
            );
          },
        );
      },
    );
  }

  String _title(BuildContext context) {
    final totalComments = widget.totalComments;
    if (totalComments == null) {
      return context.t.illust.section.comments;
    }

    return context.t.illust.section.commentsWithCount(count: formatCount(totalComments));
  }

  CommentRepliesListSource _replySourceFor(Comment comment) {
    return _replySources.putIfAbsent(comment.id, () => CommentRepliesListSource(workType: widget.workType, parentCommentId: comment.id));
  }

  void _setReplyingTo(Comment comment) {
    setState(() => _replyingTo = comment);
  }

  void _clearReplyingTo() {
    setState(() => _replyingTo = null);
  }

  Future<bool> _submitComment({required String text, int? stampId}) async {
    final parentComment = _replyingTo;

    try {
      final added = await _source.addComment(comment: text, stampId: stampId, parentCommentId: parentComment?.id);
      if (parentComment != null) {
        _replySourceFor(parentComment).prependReply(added);
      }

      if (mounted) {
        setState(() => _replyingTo = null);
      }

      return true;
    } catch (error) {
      AppToast.errorWithCause(t.illust.comments.sendFailed, error);
      return false;
    }
  }

  bool _isDeletingComment(Comment comment) {
    return _deletingCommentIds.contains(comment.id);
  }

  Future<void> _deleteComment(Comment comment, CommentRepliesListSource? repliesSource) async {
    if (_deletingCommentIds.contains(comment.id)) {
      return;
    }

    setState(() => _deletingCommentIds.add(comment.id));
    try {
      if (repliesSource == null) {
        await _source.deleteComment(comment);
      } else {
        await repliesSource.deleteComment(comment);
      }

      if (mounted && _replyingTo?.id == comment.id) {
        setState(() => _replyingTo = null);
      }
    } catch (error) {
      AppToast.errorWithCause(t.illust.comments.deleteFailed, error);
    } finally {
      if (mounted) {
        setState(() => _deletingCommentIds.remove(comment.id));
      }
    }
  }
}

class _DesktopCommentsScaffold extends StatelessWidget {
  const _DesktopCommentsScaffold({required this.title, required this.child, required this.inputBar});

  static const _maxContentWidth = 840.0;

  final String title;
  final Widget child;
  final Widget? inputBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DesktopCommentsHeader(title: title),
                Expanded(child: child),
                ?inputBar,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopCommentsHeader extends StatelessWidget {
  const _DesktopCommentsHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _CommentsRefreshView extends StatelessWidget {
  const _CommentsRefreshView({
    required this.source,
    required this.assets,
    required this.workType,
    required this.repliesSourceBuilder,
    required this.onRefresh,
    required this.onReply,
    required this.onDelete,
    required this.currentUserId,
    required this.isDeletingComment,
  });

  final WorkCommentsListSource source;
  final PixivCommentAssets assets;
  final CommentWorkType workType;
  final CommentRepliesSourceBuilder repliesSourceBuilder;
  final DataRefreshAction onRefresh;
  final ValueChanged<Comment>? onReply;
  final CommentDeleteCallback onDelete;
  final int? currentUserId;
  final bool Function(Comment comment) isDeletingComment;

  @override
  Widget build(BuildContext context) {
    return DataRefreshView(
      onRefresh: onRefresh,
      builder: (context, physics, locators) {
        return AnimatedBuilder(
          animation: source,
          builder: (context, child) {
            return _CommentsBody(
              source: source,
              assets: assets,
              workType: workType,
              physics: physics,
              locators: locators,
              repliesSourceBuilder: repliesSourceBuilder,
              onReply: onReply,
              onDelete: onDelete,
              currentUserId: currentUserId,
              isDeletingComment: isDeletingComment,
            );
          },
        );
      },
    );
  }
}

class _CommentsBody extends StatelessWidget {
  const _CommentsBody({
    required this.source,
    required this.assets,
    required this.workType,
    required this.physics,
    required this.locators,
    required this.repliesSourceBuilder,
    required this.onReply,
    required this.onDelete,
    required this.currentUserId,
    required this.isDeletingComment,
  });

  final WorkCommentsListSource source;
  final PixivCommentAssets assets;
  final CommentWorkType workType;
  final ScrollPhysics? physics;
  final DataRefreshLocators locators;
  final CommentRepliesSourceBuilder repliesSourceBuilder;
  final ValueChanged<Comment>? onReply;
  final CommentDeleteCallback onDelete;
  final int? currentUserId;
  final bool Function(Comment comment) isDeletingComment;

  @override
  Widget build(BuildContext context) {
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return DataLoadingCustomScrollView(
        physics: physics,
        slivers: [
          ?locators.sliverHeader,
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: CommentsLoadingSkeleton(itemCount: 6)),
          ),
        ],
      );
    }

    if (!source.initialized && lastError != null) {
      return DataSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: ErrorContent(message: formatPixivError(lastError), onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return DataSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: EmptyContent(icon: Icons.chat_bubble_outline, title: context.t.illust.comments.empty),
      );
    }

    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?locators.sliverHeader,
        SliverDataList<Comment>(
          source: source,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemBuilder: (context, comment, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PixivCommentTile(
                comment: comment,
                assets: assets,
                workType: workType,
                repliesSourceBuilder: repliesSourceBuilder,
                onReply: onReply,
                onDelete: onDelete,
                currentUserId: currentUserId,
                isDeletingComment: isDeletingComment,
              ),
            );
          },
        ),
      ],
    );
  }
}
