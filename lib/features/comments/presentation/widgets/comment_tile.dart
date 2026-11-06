import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_timeline_lines.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/widgets/pixiv_comment_text.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:go_router/go_router.dart';
import 'package:frost_data/frost_data.dart';

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
    this.preview = false,
    this.hasLocalReply = false,
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
  final bool preview;
  final bool hasLocalReply;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final avatarSize = preview
        ? 32.0
        : compact
        ? 28.0
        : 38.0;
    final hasText = comment.comment.trim().isNotEmpty;
    final canDelete = currentUserId != null && comment.user.id == currentUserId && onDelete != null;
    final hasReplies = comment.hasReplies || hasLocalReply;
    final isDeleting = isDeletingComment?.call(comment) ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: preview
            ? 8
            : compact
            ? 6
            : 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: 48,
            child: FrostClickSurface(
              feedback: FrostClickFeedback.media,
              shape: const FrostClickShape.circle(),
              onTap: () => context.push(AppLocations.user(comment.user.id)),
              child: Center(
                child: SizedBox.square(
                  dimension: avatarSize,
                  child: PixivImage(url: comment.user.profileImageUrls.medium, fit: BoxFit.cover, borderRadius: BorderRadius.circular(avatarSize / 2)),
                ),
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: comment.user.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (comment.user.account.isNotEmpty)
                            TextSpan(
                              text: '  @${comment.user.account}',
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium,
                    ),
                    Text('· ${formatPixivDate(comment.date)}', style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                if (comment.stamp != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox.square(
                      dimension: preview
                          ? 64
                          : compact
                          ? 72
                          : 96,
                      child: PixivImage(url: comment.stamp!.stampUrl, fit: BoxFit.contain),
                    ),
                  ),
                ] else if (hasText) ...[
                  const SizedBox(height: 4),
                  PixivCommentText(
                    comment.comment,
                    assets: assets,
                    style: frostContentTextStyle(context, comment.comment, textTheme.bodyMedium?.copyWith(height: 1.4)),
                    maxLines: preview ? 3 : null,
                    overflow: preview ? TextOverflow.ellipsis : TextOverflow.clip,
                    sizeMultiplier: compact || preview ? 1.15 : 1.25,
                  ),
                ],
                if (onReply != null || canDelete) ...[
                  const SizedBox(height: 6),
                  _CommentActions(comment: comment, onReply: onReply, onDelete: canDelete ? () => onDelete!(comment, null) : null, isDeleting: isDeleting),
                ],
                if (preview && hasReplies)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(context.t.illust.comments.hasReplies, style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ),
                if (showReplies && hasReplies && repliesSourceBuilder != null) ...[
                  const SizedBox(height: 6),
                  CommentRepliesSection(
                    parentComment: comment,
                    assets: assets,
                    workType: workType,
                    source: repliesSourceBuilder!(comment),
                    initiallyExpanded: hasLocalReply,
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
    );
  }
}

class _CommentActions extends StatelessWidget {
  const _CommentActions({required this.comment, required this.onReply, required this.onDelete, required this.isDeleting});

  final Comment comment;
  final ValueChanged<Comment>? onReply;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (onReply != null) CommentReplyButton(onPressed: () => onReply!(comment)),
        if (onDelete != null)
          FrostMenuAnchor(
            entries: [
              FrostMenuAction(
                context.t.illust.comments.delete,
                leading: FrostGlyph.icon(const FrostIconData.glyph(Icons.delete_outline)),
                destructive: true,
                onSelected: onDelete,
              ),
            ],
            builder: (context, focusNode, toggle) => IconButton(
              focusNode: focusNode,
              tooltip: context.t.navigation.more,
              onPressed: isDeleting ? null : toggle,
              iconSize: 18,
              icon: isDeleting ? SizedBox.square(dimension: 16, child: PivSkeletonBlock()) : Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

/// The reply action under a comment; the loading skeleton renders the same
/// button so both occupy identical space.
class CommentReplyButton extends StatelessWidget {
  const CommentReplyButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.reply, size: 17),
      label: Text(context.t.illust.comments.reply),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsetsDirectional.only(end: 10),
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class CommentRepliesSection extends StatefulWidget {
  const CommentRepliesSection({
    required this.parentComment,
    required this.assets,
    required this.workType,
    required this.source,
    this.initiallyExpanded = false,
    this.currentUserId,
    this.onDelete,
    this.isDeletingComment,
    super.key,
  });

  final Comment parentComment;
  final PixivCommentAssets assets;
  final CommentWorkType workType;
  final CommentRepliesListSource source;
  final bool initiallyExpanded;
  final int? currentUserId;
  final CommentDeleteCallback? onDelete;
  final bool Function(Comment comment)? isDeletingComment;

  @override
  State<CommentRepliesSection> createState() => _CommentRepliesSectionState();
}

class _CommentRepliesSectionState extends State<CommentRepliesSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: _loadReplies,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          label: Text(context.t.illust.comments.loadReplies),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.padded, padding: EdgeInsets.zero),
        ),
      );
    }

    return AnimatedBuilder(
      animation: widget.source,
      builder: (context, child) {
        final source = widget.source;
        final lastError = source.lastError;

        if (source.phase == FrostLoadPhase.loading) {
          return _RepliesStatus(
            icon: SizedBox.square(dimension: 16, child: PivSkeletonBlock()),
            label: '',
          );
        }

        if (!source.initialized && lastError != null) {
          return FrostCompactMessage(
            icon: FrostIconData.glyph(Icons.error_outline),
            message: context.t.common.errorWithCause(message: context.t.illust.comments.repliesFailed, cause: formatPixivError(lastError)),
            details: pixivErrorDetails(lastError),
            actionLabel: context.t.common.retry,
            onAction: () => source.refresh(true),
          );
        }

        if (source.initialized && source.items.isEmpty) {
          return const SizedBox.shrink();
        }

        return CommentReplyRail(
          child: Column(
            children: [
              for (final reply in source.items) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 8),
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
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: _RepliesStatus(
                    icon: SizedBox.square(dimension: 16, child: PivSkeletonBlock()),
                    label: '',
                  ),
                )
              else if (source.initialized && lastError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FrostCompactMessage(
                    icon: FrostIconData.glyph(Icons.error_outline),
                    message: context.t.common.errorWithCause(message: context.t.illust.comments.repliesFailed, cause: formatPixivError(lastError)),
                    details: pixivErrorDetails(lastError),
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
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.padded, padding: EdgeInsets.zero),
                  ),
                ),
            ],
          ),
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
