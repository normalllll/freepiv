import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_input_bar.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_tile.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_timeline_lines.dart';
import 'package:freepiv/features/comments/presentation/widgets/comments_skeleton.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

class WorkCommentsPage extends ConsumerStatefulWidget {
  const WorkCommentsPage({required this.workType, required this.workId, this.totalComments, super.key});

  final CommentWorkType workType;
  final int workId;
  final int? totalComments;

  @override
  ConsumerState<WorkCommentsPage> createState() => _WorkCommentsPageState();
}

class _WorkCommentsPageState extends ConsumerState<WorkCommentsPage> {
  late final WorkCommentsListSource _source = WorkCommentsListSource(workType: widget.workType, workId: widget.workId);
  late final Future<PixivCommentAssets> _assetsFuture = PixivCommentAssets.load();

  final Map<int, CommentRepliesListSource> _replySources = {};
  final Set<int> _deletingCommentIds = {};
  final Set<int> _localReplyParentIds = {};
  Comment? _replyingTo;
  bool _hasDraft = false;
  bool _allowPop = false;
  bool _confirmingDiscard = false;

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
    return PopScope(
      canPop: !_hasDraft || _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasDraft) _confirmDiscard();
      },
      child: FrostAutoScaffold(
        builder: (BuildContext context, FrostSizeLayout layout, Orientation orientation, bool useHorizontalLayout) {
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
                hasLocalReply: (comment) => _localReplyParentIds.contains(comment.id),
              );
              final inputBar = canPost
                  ? CommentInputBar(
                      assets: assets,
                      replyingTo: _replyingTo,
                      onCancelReply: _clearReplyingTo,
                      onDraftChanged: (hasDraft) {
                        if (mounted && hasDraft != _hasDraft) setState(() => _hasDraft = hasDraft);
                      },
                      onSubmit: _submitComment,
                    )
                  : null;

              if (useHorizontalLayout) {
                return _DesktopCommentsScaffold(title: title, inputBar: inputBar, child: commentsView);
              }

              return Scaffold(
                body: FrostCollapsingHeader(
                  header: FrostPageHeader(title: Text(title)),
                  child: commentsView,
                ),
                bottomNavigationBar: inputBar,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    if (_confirmingDiscard) return;
    _confirmingDiscard = true;
    final discard = await showFrostDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t.illust.comments.discardDraftTitle),
        content: Text(dialogContext.t.illust.comments.discardDraftMessage),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(dialogContext.t.illust.comments.continueEditing)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(dialogContext.t.illust.comments.discardDraft)),
        ],
      ),
    );
    _confirmingDiscard = false;
    if (!mounted || discard != true) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  void _syncDetailComments() {
    switch (widget.workType) {
      case CommentWorkType.illust:
        ref.invalidate(illustCommentsProvider(widget.workId));
      case CommentWorkType.novel:
        ref.invalidate(novelCommentsProvider(widget.workId));
    }
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
      if (!mounted) return true;
      if (parentComment != null) {
        final repliesSource = _replySourceFor(parentComment);
        if (repliesSource.initialized) {
          repliesSource.prependReply(added);
        } else {
          unawaited(repliesSource.refresh(true));
        }
      }
      _syncDetailComments();

      setState(() {
        _replyingTo = null;
        if (parentComment != null) _localReplyParentIds.add(parentComment.id);
      });

      return true;
    } catch (error) {
      toastErrorWithCause(t.illust.comments.sendFailed, error);
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

    final confirmed = await showFrostDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t.illust.comments.delete),
        content: Text(dialogContext.t.illust.comments.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(dialogContext.t.common.cancel)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(dialogContext.t.illust.comments.delete)),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _deletingCommentIds.add(comment.id));
    try {
      if (repliesSource == null) {
        await _source.deleteComment(comment);
      } else {
        await repliesSource.deleteComment(comment);
      }
      if (!mounted) return;
      _syncDetailComments();

      if (mounted && _replyingTo?.id == comment.id) {
        setState(() => _replyingTo = null);
      }
    } catch (error) {
      toastErrorWithCause(t.illust.comments.deleteFailed, error);
    } finally {
      if (mounted) {
        setState(() => _deletingCommentIds.remove(comment.id));
      }
    }
  }
}

class _DesktopCommentsScaffold extends StatelessWidget {
  const _DesktopCommentsScaffold({required this.title, required this.child, required this.inputBar});

  final String title;
  final Widget child;
  final Widget? inputBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FrostContentColumn(child: _DesktopCommentsHeader(title: title)),
            Expanded(child: child),
            ?inputBar,
          ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 14),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
    required this.hasLocalReply,
  });

  final WorkCommentsListSource source;
  final PixivCommentAssets assets;
  final CommentWorkType workType;
  final CommentRepliesSourceBuilder repliesSourceBuilder;
  final FrostRefreshAction onRefresh;
  final ValueChanged<Comment>? onReply;
  final CommentDeleteCallback onDelete;
  final int? currentUserId;
  final bool Function(Comment comment) isDeletingComment;
  final bool Function(Comment comment) hasLocalReply;

  @override
  Widget build(BuildContext context) {
    return FrostRefreshView(
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
              hasLocalReply: hasLocalReply,
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
    required this.hasLocalReply,
  });

  final WorkCommentsListSource source;
  final PixivCommentAssets assets;
  final CommentWorkType workType;
  final ScrollPhysics? physics;
  final FrostRefreshLocators locators;
  final CommentRepliesSourceBuilder repliesSourceBuilder;
  final ValueChanged<Comment>? onReply;
  final CommentDeleteCallback onDelete;
  final int? currentUserId;
  final bool Function(Comment comment) isDeletingComment;
  final bool Function(Comment comment) hasLocalReply;

  @override
  Widget build(BuildContext context) => FrostLoadStateSwitcher(phase: source.phase, child: _buildPhase(context));

  Widget _buildPhase(BuildContext context) {
    final lastError = source.lastError;

    if (source.phase == FrostLoadPhase.loading) {
      return FrostLoadingScrollView(
        physics: physics,
        slivers: [
          ?locators.sliverHeader,
          SliverPadding(
            // Same insets as the loaded list below.
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            sliver: SliverToBoxAdapter(child: FrostContentColumn(child: CommentsLoadingSkeleton(itemCount: 6, showActions: true))),
          ),
        ],
      );
    }

    if (!source.initialized && lastError != null) {
      return FrostSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: FrostErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return FrostSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: FrostEmptyContent(icon: FrostIconData.glyph(Icons.chat_bubble_outline), title: context.t.illust.comments.empty),
      );
    }

    return FrostLoadingScrollView(
      physics: physics,
      slivers: [
        ?locators.sliverHeader,
        FrostSliverDataList<Comment>(
          firstLoadSkeleton: const FullScreenLoadingSkeleton(),
          source: source,
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          itemBuilder: (context, comment, index) {
            return FrostContentColumn(
              child: Column(
                children: [
                  PixivCommentTile(
                    comment: comment,
                    assets: assets,
                    workType: workType,
                    repliesSourceBuilder: repliesSourceBuilder,
                    onReply: onReply,
                    onDelete: onDelete,
                    currentUserId: currentUserId,
                    isDeletingComment: isDeletingComment,
                    hasLocalReply: hasLocalReply(comment),
                  ),
                  if (index < source.length - 1) const CommentSeparator(),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
