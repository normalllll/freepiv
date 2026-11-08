import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/loading_section.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/social.dart';
import 'package:go_router/go_router.dart';

/// The built-in emoji and stamps, loaded once.
final pixivCommentAssets = PixivCommentAssets.load();

/// A Pixiv comment as a thread item: the author's name
/// (opening their page), the text with its emoji or the stamp, and a footer
/// of the time and Reply. The signed-in user's own comment has Delete in its
/// menu.
FrostThreadItem appCommentItem(
  BuildContext context,
  Comment comment, {
  required PixivCommentAssets assets,
  VoidCallback? onReply,
  VoidCallback? onDelete,
  Widget? actions,
}) {
  final t = context.t;
  return FrostThreadItem(
    avatar: AppUserAvatar(user: comment.user, size: FrostAvatarSize.small),
    author: comment.user.name,
    body: AppCommentBody(comment: comment, assets: assets),
    time: formatPixivDate(comment.date),
    reply: onReply == null ? null : FrostThreadAction(icon: PivIcons.messageCircle, label: t.illust.comments.reply, onPressed: onReply),
    actions: actions,
    onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.user(comment.user.id))),
    contextMenu: [
      if (onDelete != null)
        FrostMenuAction(t.illust.comments.delete, leading: FrostGlyph.icon(FrostIconSet.of(context).delete), destructive: true, onSelected: onDelete),
    ],
  );
}

/// A comment's text, its emoji drawn in the line, or its stamp.
class AppCommentBody extends StatelessWidget {
  const AppCommentBody({required this.comment, required this.assets, super.key});

  final Comment comment;
  final PixivCommentAssets assets;

  /// Stamps show at the size Pixiv draws them.
  static const stampExtent = 96.0;

  /// Emoji stand a little taller than the text around them.
  static const emojiScale = 1.25;

  @override
  Widget build(BuildContext context) {
    if (comment.stamp case final stamp?) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox.square(
          dimension: stampExtent,
          child: AppPixivImage(url: stamp.stampUrl, aspectRatio: 1, fit: BoxFit.contain),
        ),
      );
    }
    final text = plainTextFromHtml(comment.comment);
    final size =
        (FrostTypography.of(context).style(FrostTextRole.body).fontSize ?? FrostTypography.of(context).style(FrostTextRole.footnote).fontSize!) * emojiScale;
    final emoji = assets.emojiByName;
    final spans = <InlineSpan>[];
    var index = 0;
    for (final match in pixivEmojiTokenPattern.allMatches(text)) {
      final asset = emoji[match.group(1)];
      if (asset == null) continue;
      if (match.start > index) spans.add(TextSpan(text: text.substring(index, match.start)));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Image.asset(asset.path, width: size, height: size, filterQuality: FilterQuality.medium, semanticLabel: asset.name),
        ),
      );
      index = match.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    return FrostText.rich(TextSpan(children: spans), content: true, selectable: true);
  }
}

/// The first comments of a work and the way to all of them, loading
/// and failing on their own.
class AppCommentsPreview extends StatelessWidget {
  const AppCommentsPreview({required this.value, required this.total, required this.onRetry, required this.location, super.key});

  final AsyncValue<CommentPageResult> value;
  final int? total;
  final VoidCallback onRetry;

  /// The comments page.
  final String location;

  /// Comments the preview shows.
  static const shown = 3;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final total = this.total;
    // The way to the comments page stays without comments and when they
    // fail: the full page is where the first comment is written.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.related,
      children: [
        AppLoadingSection(
          title: total == null ? t.illust.section.comments : t.illust.section.commentsWithCount(count: total),
          value: value,
          onRetry: onRetry,
          failed: t.illust.comments.failed,
          builder: (page) {
            if (page.comments.isEmpty) return FrostText(t.illust.comments.empty, role: FrostTextRole.footnote, tone: FrostTextTone.secondary);
            return FutureBuilder(
              future: pixivCommentAssets,
              builder: (context, assets) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final comment in page.comments.take(shown))
                    FrostThread(item: appCommentItem(context, comment, assets: assets.data ?? PixivCommentAssets.empty)),
                ],
              ),
            );
          },
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FrostButton.quiet(
            label: entryLabel(t, total, noComments: value.value?.comments.isEmpty ?? false, failed: value.hasError),
            edgeAlignment: FrostButtonEdgeAlignment.start,
            onPressed: () => unawaited(GoRouter.of(context).push(location, extra: total)),
          ),
        ),
      ],
    );
  }

  /// The way to the comments page: to all of them, to write the first one
  /// when there are none, or plainly to the page when the count is unknown
  /// or the preview failed.
  static String entryLabel(Translations t, int? total, {bool noComments = false, bool failed = false}) {
    if (total != null && total > 0) return t.illustDetail.allComments(count: total);
    return !failed && (total == 0 || noComments) ? t.illust.comments.write : t.illust.comments.open;
  }
}
