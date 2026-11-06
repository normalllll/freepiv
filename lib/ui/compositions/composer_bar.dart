import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';

/// The bottom input bar of comment threads: a composer
/// field that grows to five lines (Enter adds a line), emoji and stamp
/// buttons and send, on one row at every width. While replying, a line above
/// names the comment and closes the reply.
class AppComposerBar extends StatelessWidget {
  const AppComposerBar({
    required this.controller,
    required this.placeholder,
    required this.sendLabel,
    required this.onSend,
    this.focusNode,
    this.emojiLabel,
    this.onEmoji,
    this.stampLabel,
    this.onStamp,
    this.replyLabel,
    this.cancelReplyLabel,
    this.onCancelReply,
    this.sending = false,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String placeholder;
  final String sendLabel;

  /// Null while there is nothing to send.
  final VoidCallback? onSend;
  final String? emojiLabel;
  final VoidCallback? onEmoji;
  final String? stampLabel;
  final VoidCallback? onStamp;

  /// "Replying to …" while replying, with [onCancelReply] closing it.
  final String? replyLabel;
  final String? cancelReplyLabel;
  final VoidCallback? onCancelReply;
  final bool sending;

  static const maxLines = 5;

  // No emoji glyph in the app's Lucide set yet; the Material one stands in
  // until the rebuild adds it with the comment pages.
  static const emojiIcon = FrostIconData.glyph(Icons.emoji_emotions_outlined);

  @override
  Widget build(BuildContext context) {
    final icons = FrostScope.configOf(context).icons;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (replyLabel case final reply?)
          Row(
            children: [
              Expanded(
                child: FrostText(reply, role: FrostTextRole.footnote, tone: FrostTextTone.secondary, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              FrostButton.icon(icon: icons.close, label: cancelReplyLabel ?? FrostScope.labelsOf(context).cancel, onPressed: onCancelReply),
            ],
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: FrostTextField(
                controller: controller,
                focusNode: focusNode,
                placeholder: placeholder,
                appearance: FrostFieldAppearance.composer,
                minLines: 1,
                maxLines: maxLines,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ),
            if (onEmoji != null) FrostButton.icon(icon: emojiIcon, label: emojiLabel ?? '', onPressed: onEmoji),
            if (onStamp != null) FrostButton.icon(icon: icons.image, label: stampLabel ?? '', onPressed: onStamp),
            FrostButton.icon(
              icon: PivIcons.send,
              label: sendLabel,
              onPressed: onSend,
              state: sending ? const FrostActionState.running() : FrostActionState.idle,
            ),
          ],
        ),
      ],
    );
  }
}
