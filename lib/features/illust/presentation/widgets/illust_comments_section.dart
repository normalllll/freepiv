import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_tile.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_timeline_lines.dart';
import 'package:freepiv/features/comments/presentation/widgets/comments_skeleton.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_ui/frost_ui.dart';
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
      borderRadius: BorderRadius.circular(FrostMetrics.groupRadius),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey<String>('illust-comments-${widget.illustId}'),
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
                // The full comments page is reached from the list's footer;
                // the header only toggles the preview.
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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
}

class _CommentsBody extends ConsumerWidget {
  const _CommentsBody({required this.illustId, required this.totalComments});

  final int illustId;
  final int? totalComments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = t;
    final comments = ref.watch(illustCommentsProvider(illustId));

    return FrostLoadStateSwitcher(
      animateSize: true,
      child: comments.when(
        loading: () => CommentsLoadingSkeleton(itemCount: _commentSkeletonItemCount, preview: true),
        error: (error, stackTrace) => FrostCompactMessage(
          icon: FrostIconData.glyph(Icons.error_outline),
          message: formatPixivError(error),
          details: pixivErrorDetails(error),
          actionLabel: translations.common.retry,
          onAction: () {
            ref.read(illustCommentsProvider(illustId).notifier).reload();
          },
        ),
        data: (result) => _CommentsList(result: result, illustId: illustId, totalComments: totalComments),
      ),
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
    final previewComments = comments.take(5).toList(growable: false);

    // The footer stays even without comments; the full page is where a
    // first comment is written.
    final openAll = Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextButton.icon(
        onPressed: () => context.pushNamed(AppRoute.illustComments.name, pathParameters: {'id': '$illustId'}, extra: totalComments),
        icon: const Icon(Icons.open_in_full, size: 17),
        label: Text(translations.illust.comments.open),
      ),
    );

    if (comments.isEmpty) {
      return Column(
        children: [
          FrostCompactMessage(icon: FrostIconData.glyph(Icons.chat_bubble_outline), message: translations.illust.comments.empty),
          openAll,
        ],
      );
    }

    return FutureBuilder<PixivCommentAssets>(
      future: PixivCommentAssets.load(),
      builder: (context, snapshot) {
        final assets = snapshot.data ?? PixivCommentAssets.empty;

        return Column(
          children: [
            for (final (index, comment) in previewComments.indexed) ...[
              PixivCommentTile(comment: comment, assets: assets, workType: CommentWorkType.illust, preview: true, showReplies: false),
              if (index < previewComments.length - 1) const CommentSeparator(),
            ],
            openAll,
          ],
        );
      },
    );
  }
}
