import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
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
FrostThreadItem appCommentItem(BuildContext context, Comment comment, {required PixivCommentAssets assets, VoidCallback? onReply, VoidCallback? onDelete}) {
  final t = context.t;
  return FrostThreadItem(
    avatar: AppUserAvatar(user: comment.user, size: FrostAvatarSize.small),
    author: comment.user.name,
    body: AppCommentBody(comment: comment, assets: assets),
    time: formatPixivDate(comment.date),
    reply: onReply == null ? null : FrostThreadAction(icon: PivIcons.messageCircle, label: t.illust.comments.reply, onPressed: onReply),
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
