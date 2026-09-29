import 'package:flutter/material.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_tile.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_timeline_lines.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Loading rows built from the same layout, text styles and reply action as
/// [PixivCommentTile], so the skeleton keeps the loaded list's rhythm instead
/// of approximating it with fixed-size bones.
class CommentsLoadingSkeleton extends StatelessWidget {
  const CommentsLoadingSkeleton({this.itemCount, this.preview = false, this.showActions = false, super.key});

  final int? itemCount;

  /// Inline preview (detail pages): smaller avatar, tighter rows, no actions.
  final bool preview;

  /// The full comments page shows a reply action under each comment.
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final count = itemCount ?? (MediaQuery.sizeOf(context).height / 96).ceil() + 1;
    return Skeletonizer(
      child: Column(
        children: [
          for (var index = 0; index < count; index++) ...[
            _CommentSkeletonTile(preview: preview, showActions: showActions, bodyWords: index.isEven ? 22 : 7),
            if (index != count - 1) const CommentSeparator(),
          ],
        ],
      ),
    );
  }
}

class _CommentSkeletonTile extends StatelessWidget {
  const _CommentSkeletonTile({required this.preview, required this.showActions, required this.bodyWords});

  final bool preview;
  final bool showActions;
  final int bodyWords;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final avatarSize = preview ? 32.0 : 38.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: preview ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: 48,
            child: Center(child: Bone.circle(size: avatarSize)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(BoneMock.name, style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(BoneMock.date, style: textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(List.filled(bodyWords, 'Mock').join(' '), style: textTheme.bodyMedium?.copyWith(height: 1.4), maxLines: preview ? 3 : null),
                if (showActions && !preview) ...[const SizedBox(height: 6), const CommentReplyButton(onPressed: null)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
