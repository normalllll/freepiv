import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_tile.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_timeline_lines.dart';
import 'package:freepiv/features/comments/presentation/widgets/comments_skeleton.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:go_router/go_router.dart';

class NovelCommentsSection extends ConsumerStatefulWidget {
  const NovelCommentsSection({required this.novelId, required this.totalComments, this.initiallyExpanded = false, super.key});

  final int novelId;
  final int totalComments;
  final bool initiallyExpanded;

  @override
  ConsumerState<NovelCommentsSection> createState() => _NovelCommentsSectionState();
}

class _NovelCommentsSectionState extends ConsumerState<NovelCommentsSection> {
  late bool _expanded = widget.initiallyExpanded;
  late bool _hasOpened = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final translations = t;
    final colorScheme = Theme.of(context).colorScheme;
    final title = translations.illust.section.commentsWithCount(count: formatCount(widget.totalComments));

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppMetrics.groupRadius),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent),
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
            children: [if (_hasOpened) _CommentsBody(novelId: widget.novelId, totalComments: widget.totalComments)],
          ),
        ),
      ),
    );
  }

  void _openCommentsPage() {
    context.pushNamed(AppRoute.novelComments.name, pathParameters: {'id': '${widget.novelId}'}, extra: widget.totalComments);
  }
}

class _CommentsBody extends ConsumerWidget {
  const _CommentsBody({required this.novelId, required this.totalComments});

  final int novelId;
  final int totalComments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = t;
    final comments = ref.watch(novelCommentsProvider(novelId));

    return LoadStateSwitcher(
      animateSize: true,
      child: comments.when(
        loading: () => CommentsLoadingSkeleton(itemCount: _commentSkeletonItemCount, preview: true),
        error: (error, stackTrace) => CompactMessage(
          icon: Icons.error_outline,
          message: formatPixivError(error),
          details: pixivErrorDetails(error),
          actionLabel: translations.common.retry,
          onAction: () {
            ref.read(novelCommentsProvider(novelId).notifier).reload();
          },
        ),
        data: (result) => _CommentsList(result: result, novelId: novelId, totalComments: totalComments),
      ),
    );
  }

  int get _commentSkeletonItemCount {
    if (totalComments <= 0) {
      return 1;
    }

    return totalComments > 5 ? 5 : totalComments;
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList({required this.result, required this.novelId, required this.totalComments});

  final CommentPageResult result;
  final int novelId;
  final int totalComments;

  @override
  Widget build(BuildContext context) {
    final translations = t;
    final comments = result.comments;
    final previewComments = comments.take(5).toList(growable: false);

    if (comments.isEmpty) {
      return CompactMessage(icon: Icons.chat_bubble_outline, message: translations.illust.comments.empty);
    }

    return FutureBuilder<PixivCommentAssets>(
      future: PixivCommentAssets.load(),
      builder: (context, snapshot) {
        final assets = snapshot.data ?? PixivCommentAssets.empty;

        return Column(
          children: [
            for (final (index, comment) in previewComments.indexed) ...[
              PixivCommentTile(comment: comment, assets: assets, workType: CommentWorkType.novel, preview: true, showReplies: false),
              if (index < previewComments.length - 1) const CommentSeparator(),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton.icon(
                onPressed: () => context.pushNamed(AppRoute.novelComments.name, pathParameters: {'id': '$novelId'}, extra: totalComments),
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
