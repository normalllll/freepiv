import 'package:flutter/services.dart';
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
    this.emojiPanel,
    this.stampLabel,
    this.stampPanel,
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

  /// The emoji picker, anchored to its button (a sheet on narrow windows);
  /// [close] closes it.
  final Widget Function(BuildContext context, VoidCallback close)? emojiPanel;
  final String? stampLabel;

  /// The stamp picker, like [emojiPanel].
  final Widget Function(BuildContext context, VoidCallback close)? stampPanel;

  /// "Replying to …" while replying, with [onCancelReply] closing it.
  final String? replyLabel;
  final String? cancelReplyLabel;
  final VoidCallback? onCancelReply;
  final bool sending;

  static const maxLines = 5;

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
            if (emojiPanel case final panel?) _panelButton(icon: PivIcons.smile, label: emojiLabel ?? '', panel: panel),
            if (stampPanel case final panel?) _panelButton(icon: icons.image, label: stampLabel ?? '', panel: panel),
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

  Widget _panelButton({required FrostIconData icon, required String label, required Widget Function(BuildContext, VoidCallback) panel}) => FrostPopover(
    title: label,
    builder: (context, focusNode, toggle) => Focus(
      focusNode: focusNode,
      child: FrostButton.icon(icon: icon, label: label, onPressed: sending ? null : toggle),
    ),
    contentBuilder: panel,
  );
}
