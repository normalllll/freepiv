import 'package:flutter/material.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';

class PixivCommentText extends StatelessWidget {
  const PixivCommentText(
    this.comment, {
    required this.assets,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.sizeMultiplier = 1.25,
    super.key,
  });

  final String comment;
  final PixivCommentAssets assets;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final double sizeMultiplier;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveStyle =
        style ?? Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface, height: 1.35) ?? TextStyle(color: colorScheme.onSurface);
    final text = plainTextFromHtml(comment);

    return RichText(
      overflow: overflow,
      maxLines: maxLines,
      text: TextSpan(
        style: effectiveStyle,
        children: buildPixivEmojiInlineSpans(text, emojiByName: assets.emojiByName, style: effectiveStyle, sizeMultiplier: sizeMultiplier),
      ),
    );
  }
}
