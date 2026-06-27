import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

typedef CommentSubmitCallback = Future<bool> Function({required String text, int? stampId});

class CommentInputBar extends StatefulWidget {
  const CommentInputBar({required this.assets, required this.onSubmit, this.replyingTo, this.onCancelReply, super.key});

  final PixivCommentAssets assets;
  final Comment? replyingTo;
  final VoidCallback? onCancelReply;
  final CommentSubmitCallback onSubmit;

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  late final PixivEmojiTextEditingController _controller = PixivEmojiTextEditingController(widget.assets);
  late final FocusNode _focusNode = FocusNode(debugLabel: 'comment-input');

  _CommentInputPanel _panel = _CommentInputPanel.none;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
    _controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant CommentInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.assets = widget.assets;
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.illust.comments;
    final colorScheme = Theme.of(context).colorScheme;
    final replyingTo = widget.replyingTo;
    final hasText = _controller.text.trim().isNotEmpty;
    final panelHeight = math.min(MediaQuery.sizeOf(context).height * 0.36, 280.0);

    return Material(
      elevation: 12,
      color: colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyingTo != null)
              _ReplyHeader(
                label: translations.replyingTo(name: replyingTo.user.name),
                onCancel: widget.onCancelReply,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: translations.emoji,
                    onPressed: _submitting || widget.assets.emojis.isEmpty ? null : () => _togglePanel(_CommentInputPanel.emoji),
                    icon: Icon(_panel == _CommentInputPanel.emoji ? Icons.emoji_emotions : Icons.emoji_emotions_outlined),
                    color: _panel == _CommentInputPanel.emoji ? colorScheme.primary : null,
                  ),
                  IconButton(
                    tooltip: translations.stamp,
                    onPressed: _submitting || hasText || widget.assets.stamps.isEmpty ? null : () => _togglePanel(_CommentInputPanel.stamp),
                    icon: Icon(_panel == _CommentInputPanel.stamp ? Icons.image : Icons.image_outlined),
                    color: _panel == _CommentInputPanel.stamp ? colorScheme.primary : null,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      enabled: !_submitting,
                      decoration: InputDecoration(
                        hintText: replyingTo == null ? translations.inputHint : translations.replyInputHint(name: replyingTo.user.name),
                        isDense: true,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: _submitting || !hasText ? null : _submitText,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 42),
                    ),
                    child: _submitting ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.t.common.send),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: switch (_panel) {
                _CommentInputPanel.none => const SizedBox.shrink(),
                _CommentInputPanel.emoji => SizedBox(
                  key: const ValueKey<String>('emoji-panel'),
                  height: panelHeight,
                  child: _EmojiGrid(assets: widget.assets.emojis, onSelected: _insertEmoji),
                ),
                _CommentInputPanel.stamp => SizedBox(
                  key: const ValueKey<String>('stamp-panel'),
                  height: panelHeight,
                  child: _StampGrid(assets: widget.assets.stamps, onSelected: _submitStamp),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus && _panel != _CommentInputPanel.none) {
      setState(() => _panel = _CommentInputPanel.none);
    }
  }

  void _handleTextChanged() {
    setState(() {
      if (_controller.text.trim().isNotEmpty && _panel == _CommentInputPanel.stamp) {
        _panel = _CommentInputPanel.none;
      }
    });
  }

  void _togglePanel(_CommentInputPanel panel) {
    _focusNode.unfocus();
    setState(() {
      _panel = _panel == panel ? _CommentInputPanel.none : panel;
    });
  }

  void _insertEmoji(PixivCommentAsset asset) {
    final token = '(${asset.name})';
    final value = _controller.value;
    final selection = value.selection;
    final start = selection.isValid ? math.min(selection.start, selection.end) : value.text.length;
    final end = selection.isValid ? math.max(selection.start, selection.end) : value.text.length;
    final nextText = value.text.replaceRange(start, end, token);
    final nextOffset = start + token.length;

    _controller.value = value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
      composing: TextRange.empty,
    );
  }

  Future<void> _submitText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    await _submit(text: text);
  }

  Future<void> _submitStamp(PixivCommentAsset asset) async {
    final stampId = int.tryParse(asset.name);
    if (stampId == null) {
      return;
    }

    await _submit(text: '', stampId: stampId);
  }

  Future<void> _submit({required String text, int? stampId}) async {
    setState(() => _submitting = true);
    final success = await widget.onSubmit(text: text, stampId: stampId);
    if (!mounted) {
      return;
    }

    setState(() => _submitting = false);
    if (!success) {
      return;
    }

    if (stampId == null) {
      _controller.clear();
    }

    setState(() => _panel = _CommentInputPanel.none);
  }
}

class _ReplyHeader extends StatelessWidget {
  const _ReplyHeader({required this.label, this.onCancel});

  final String label;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 8, 6),
        child: Row(
          children: [
            Icon(Icons.reply, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(tooltip: context.t.common.cancel, onPressed: onCancel, visualDensity: VisualDensity.compact, icon: const Icon(Icons.close)),
          ],
        ),
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.assets, required this.onSelected});

  final List<PixivCommentAsset> assets;
  final ValueChanged<PixivCommentAsset> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 46, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return Tooltip(
          message: asset.name,
          child: InkResponse(
            onTap: () => onSelected(asset),
            radius: 24,
            child: Center(child: Image.asset(asset.path, width: 30, height: 30, filterQuality: FilterQuality.medium)),
          ),
        );
      },
    );
  }
}

class _StampGrid extends StatelessWidget {
  const _StampGrid({required this.assets, required this.onSelected});

  final List<PixivCommentAsset> assets;
  final ValueChanged<PixivCommentAsset> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 72, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return Tooltip(
          message: asset.name,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelected(asset),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(asset.path, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
            ),
          ),
        );
      },
    );
  }
}

enum _CommentInputPanel { none, emoji, stamp }
