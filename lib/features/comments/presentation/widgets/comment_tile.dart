import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/widgets/pixiv_comment_text.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:go_router/go_router.dart';

typedef CommentRepliesSourceBuilder = CommentRepliesListSource Function(Comment comment);
typedef CommentDeleteCallback = void Function(Comment comment, CommentRepliesListSource? repliesSource);

class PixivCommentTile extends StatelessWidget {
  const PixivCommentTile({
    required this.comment,
    required this.assets,
    required this.workType,
    this.repliesSourceBuilder,
    this.onReply,
    this.onDelete,
    this.currentUserId,
    this.isDeletingComment,
    this.showReplies = true,
    this.compact = false,
    super.key,
  });

  final Comment comment;
  final PixivCommentAssets assets;
  final CommentWorkType workType;
  final CommentRepliesSourceBuilder? repliesSourceBuilder;
  final ValueChanged<Comment>? onReply;
  final CommentDeleteCallback? onDelete;
  final int? currentUserId;
  final bool Function(Comment comment)? isDeletingComment;
  final bool showReplies;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final avatarSize = compact ? 28.0 : 38.0;
    final hasText = comment.comment.trim().isNotEmpty;
    final canDelete = currentUserId != null && comment.user.id == currentUserId && onDelete != null;
    final isDeleting = isDeletingComment?.call(comment) ?? false;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: compact ? colorScheme.surface : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.pushNamed(AppRoute.userDetail.name, pathParameters: {'id': '${comment.user.id}'}),
              child: SizedBox.square(
                dimension: avatarSize,
                child: PixivImage(url: comment.user.profileImageUrls.medium, fit: BoxFit.cover, borderRadius: BorderRadius.circular(avatarSize / 2)),
              ),
            ),
            SizedBox(width: compact ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(formatPixivDate(comment.date), style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  if (comment.stamp != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox.square(
                        dimension: compact ? 72 : 96,
                        child: PixivImage(url: comment.stamp!.stampUrl, fit: BoxFit.contain),
                      ),
                    ),
                  ] else if (hasText) ...[
                    const SizedBox(height: 7),
                    PixivCommentText(
                      comment.comment,
                      assets: assets,
                      style: textTheme.bodyMedium?.copyWith(height: 1.35),
                      sizeMultiplier: compact ? 1.15 : 1.25,
                    ),
                  ],
                  if (onReply != null || canDelete) ...[
                    const SizedBox(height: 6),
                    _CommentActions(
                      comment: comment,
                      hasReplies: comment.hasReplies,
                      onReply: onReply,
                      onDelete: canDelete ? () => onDelete!(comment, null) : null,
                      isDeleting: isDeleting,
                    ),
                  ],
                  if (showReplies && comment.hasReplies && repliesSourceBuilder != null) ...[
                    const SizedBox(height: 6),
                    CommentRepliesSection(
                      parentComment: comment,
                      assets: assets,
                      workType: workType,
                      source: repliesSourceBuilder!(comment),
                      currentUserId: currentUserId,
                      onDelete: onDelete,
                      isDeletingComment: isDeletingComment,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentActions extends StatelessWidget {
  const _CommentActions({required this.comment, required this.hasReplies, required this.onReply, required this.onDelete, required this.isDeleting});

  final Comment comment;
  final bool hasReplies;
  final ValueChanged<Comment>? onReply;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (onReply != null)
          TextButton.icon(
            onPressed: () => onReply!(comment),
            icon: const Icon(Icons.reply, size: 17),
            label: Text(context.t.illust.comments.reply),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsetsDirectional.only(end: 10),
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
          ),
        if (onDelete != null)
          IconButton(
            tooltip: context.t.illust.comments.delete,
            onPressed: isDeleting ? null : onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            icon: isDeleting
                ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
          ),
        if (hasReplies) Icon(Icons.mode_comment_outlined, size: 16, color: colorScheme.primary),
      ],
    );
  }
}

class CommentRepliesSection extends StatefulWidget {
  const CommentRepliesSection({
    required this.parentComment,
    required this.assets,
    required this.workType,
    required this.source,
    this.currentUserId,
    this.onDelete,
    this.isDeletingComment,
    super.key,
  });

  final Comment parentComment;
  final PixivCommentAssets assets;
  final CommentWorkType workType;
  final CommentRepliesListSource source;
  final int? currentUserId;
  final CommentDeleteCallback? onDelete;
  final bool Function(Comment comment)? isDeletingComment;

  @override
  State<CommentRepliesSection> createState() => _CommentRepliesSectionState();
}

class _CommentRepliesSectionState extends State<CommentRepliesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: _loadReplies,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          label: Text(context.t.illust.comments.loadReplies),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: EdgeInsets.zero),
        ),
      );
    }

    return AnimatedBuilder(
      animation: widget.source,
      builder: (context, child) {
        final source = widget.source;
        final lastError = source.lastError;

        if (!source.initialized && source.refreshing && source.isEmpty) {
          return const _RepliesStatus(
            icon: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            label: '',
          );
        }

        if (!source.initialized && lastError != null) {
          return CompactMessage(
            icon: Icons.error_outline,
            message: context.t.common.errorWithCause(message: context.t.illust.comments.repliesFailed, cause: formatPixivError(lastError)),
            actionLabel: context.t.common.retry,
            onAction: () => source.refresh(true),
          );
        }

        if (source.initialized && source.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            for (final reply in source.items) ...[
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 8, start: 8),
                child: PixivCommentTile(
                  comment: reply,
                  assets: widget.assets,
                  workType: widget.workType,
                  compact: true,
                  showReplies: false,
                  currentUserId: widget.currentUserId,
                  onDelete: widget.onDelete == null ? null : (comment, _) => widget.onDelete!(comment, widget.source),
                  isDeletingComment: widget.isDeletingComment,
                ),
              ),
            ],
            if (source.loadingMore)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: _RepliesStatus(
                  icon: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  label: '',
                ),
              )
            else if (source.initialized && lastError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CompactMessage(
                  icon: Icons.error_outline,
                  message: context.t.common.errorWithCause(message: context.t.illust.comments.repliesFailed, cause: formatPixivError(lastError)),
                  actionLabel: context.t.common.retry,
                  onAction: source.errorRefresh,
                ),
              )
            else if (source.hasNextPage)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: source.loadMore,
                  icon: const Icon(Icons.more_horiz, size: 18),
                  label: Text(context.t.illust.comments.loadMoreReplies),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: EdgeInsets.zero),
                ),
              ),
          ],
        );
      },
    );
  }

  void _loadReplies() {
    setState(() => _expanded = true);
    if (!widget.source.initialized && !widget.source.busy) {
      widget.source.refresh(true);
    }
  }
}

class _RepliesStatus extends StatelessWidget {
  const _RepliesStatus({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        if (label.isNotEmpty) ...[const SizedBox(width: 8), Text(label, style: Theme.of(context).textTheme.labelSmall)],
      ],
    );
  }
}
