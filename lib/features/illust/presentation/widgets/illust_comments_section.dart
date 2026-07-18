import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/features/comments/presentation/widgets/pixiv_comment_text.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:go_router/go_router.dart';

class IllustCommentsSection extends ConsumerStatefulWidget {
  const IllustCommentsSection({required this.illustId, required this.totalComments, this.initiallyExpanded = false, super.key});

  final int illustId;
  final int? totalComments;
  final bool initiallyExpanded;

  @override
  ConsumerState<IllustCommentsSection> createState() => _IllustCommentsSectionState();
}

class _IllustCommentsSectionState extends ConsumerState<IllustCommentsSection> {
  late bool _expanded = widget.initiallyExpanded;
  late bool _hasOpened = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final translations = t;
    final colorScheme = Theme.of(context).colorScheme;

    final title = widget.totalComments == null
        ? translations.illust.section.comments
        : translations.illust.section.commentsWithCount(count: formatCount(widget.totalComments!));

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: colorScheme.primary.withValues(alpha: 0.08),
            highlightColor: colorScheme.primary.withValues(alpha: 0.04),
          ),
          child: ExpansionTile(
            initiallyExpanded: widget.initiallyExpanded,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 4),
            shape: const Border(),
            collapsedShape: const Border(),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            trailing: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant),
            ),
            title: Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: translations.illust.comments.open,
                  onPressed: _openCommentsPage,
                  icon: Icon(Icons.open_in_full, size: 18, color: colorScheme.onSurfaceVariant),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            onExpansionChanged: (expanded) {
              setState(() {
                _expanded = expanded;

                if (expanded) {
                  _hasOpened = true;
                }
              });
            },
            children: [if (_hasOpened) _CommentsBody(illustId: widget.illustId, totalComments: widget.totalComments)],
          ),
        ),
      ),
    );
  }

  void _openCommentsPage() {
    context.pushNamed(AppRoute.illustComments.name, pathParameters: {'id': '${widget.illustId}'}, extra: widget.totalComments);
  }
}

class _CommentsBody extends ConsumerWidget {
  const _CommentsBody({required this.illustId, required this.totalComments});

  final int illustId;
  final int? totalComments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = t;
    final comments = ref.watch(illustCommentsProvider(illustId));

    return comments.when(
      loading: () => CommentsLoadingSkeleton(itemCount: _commentSkeletonItemCount),
      error: (error, stackTrace) => CompactMessage(
        icon: Icons.error_outline,
        message: formatPixivError(error),
        actionLabel: translations.common.retry,
        onAction: () {
          ref.read(illustCommentsProvider(illustId).notifier).reload();
        },
      ),
      data: (result) => _CommentsList(result: result, illustId: illustId, totalComments: totalComments),
    );
  }

  int get _commentSkeletonItemCount {
    final total = totalComments;

    if (total == null) {
      return 5;
    }

    if (total <= 0) {
      return 1;
    }

    return total > 5 ? 5 : total;
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList({required this.result, required this.illustId, required this.totalComments});

  final CommentPageResult result;
  final int illustId;
  final int? totalComments;

  @override
  Widget build(BuildContext context) {
    final translations = t;
    final comments = result.comments;

    if (comments.isEmpty) {
      return CompactMessage(icon: Icons.chat_bubble_outline, message: translations.illust.comments.empty);
    }

    return FutureBuilder<PixivCommentAssets>(
      future: PixivCommentAssets.load(),
      builder: (context, snapshot) {
        final assets = snapshot.data ?? PixivCommentAssets.empty;

        return Column(
          children: [
            for (final comment in comments.take(5)) _CommentTile(comment: comment, assets: assets),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton.icon(
                onPressed: () => context.pushNamed(AppRoute.illustComments.name, pathParameters: {'id': '$illustId'}, extra: totalComments),
                icon: const Icon(Icons.open_in_full, size: 17),
                label: Text(translations.illust.comments.open),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.assets});

  final Comment comment;
  final PixivCommentAssets assets;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 30,
                child: PixivImage(url: comment.user.profileImageUrls.medium, fit: BoxFit.cover, borderRadius: BorderRadius.circular(15)),
              ),
              const SizedBox(width: 8),
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
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(formatPixivDate(comment.date), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (comment.stamp != null)
                      SizedBox.square(
                        dimension: 56,
                        child: PixivImage(url: comment.stamp!.stampUrl, fit: BoxFit.contain),
                      )
                    else
                      PixivCommentText(
                        comment.comment,
                        assets: assets,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3),
                        sizeMultiplier: 1.15,
                      ),
                    if (comment.hasReplies) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.t.illust.comments.hasReplies,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
