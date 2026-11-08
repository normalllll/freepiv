import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/comment_thread_item.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/composer_bar.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/social.dart';

/// A work's comments in a centred reading column:
/// threads with their replies in a light block, the signed-in user's own
/// comments deletable from their menu, and the input bar at the bottom.
/// Leaving with a draft asks whether to keep editing or discard it.
class WorkCommentsPage extends ConsumerStatefulWidget {
  const WorkCommentsPage({required this.workType, required this.workId, this.totalComments, super.key});

  final CommentWorkType workType;
  final int workId;
  final int? totalComments;

  @override
  ConsumerState<WorkCommentsPage> createState() => _WorkCommentsPageState();
}

class _WorkCommentsPageState extends ConsumerState<WorkCommentsPage> {
  late final _keep = ref.listenManual(workCommentsSourceProvider((widget.workType, widget.workId)), (_, _) {});
  WorkCommentsListSource get _source => _keep.read();
  final _replies = <int, CommentRepliesListSource>{};
  final _draft = TextEditingController();
  final _input = FocusNode();
  Comment? _replyingTo;
  bool _sending = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _keep;
    _draft.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _keep.close();
    for (final source in _replies.values) {
      source.dispose();
    }
    _draft.dispose();
    _input.dispose();
    super.dispose();
  }

  bool get _hasDraft => _draft.text.trim().isNotEmpty;

  CommentRepliesListSource _repliesOf(Comment comment) =>
      _replies.putIfAbsent(comment.id, () => ref.read(commentRepliesSourceFactoryProvider)(widget.workType, comment.id));

  /// The detail page's comment preview shows the change.
  void _syncDetail() => switch (widget.workType) {
    CommentWorkType.illust => ref.invalidate(illustCommentsProvider(widget.workId)),
    CommentWorkType.novel => ref.invalidate(novelCommentsProvider(widget.workId)),
  };

  Future<void> _confirmDiscard() async {
    final t = context.t;
    final discard = await showFrostConfirm(
      context: context,
      title: t.illust.comments.discardDraftTitle,
      message: t.illust.comments.discardDraftMessage,
      confirmLabel: t.illust.comments.discardDraft,
      cancelLabel: t.illust.comments.continueEditing,
    );
    if (!mounted || !discard) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(Navigator.of(context).maybePop());
    });
  }

  Future<void> _send({String? text, int? stampId}) async {
    if (_sending) return;
    final parent = _replyingTo;
    setState(() => _sending = true);
    try {
      final added = await _source.addComment(comment: text ?? '', stampId: stampId, parentCommentId: parent?.id);
      if (!mounted) return;
      if (parent != null) {
        final replies = _repliesOf(parent);
        if (replies.initialized) {
          replies.prependReply(added);
        } else {
          unawaited(replies.refresh(true));
        }
      }
      if (stampId == null) _draft.clear();
      _syncDetail();
      setState(() => _replyingTo = null);
    } catch (error) {
      // The draft stays for another try.
      toastErrorWithCause(t.illust.comments.sendFailed, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(Comment comment, CommentRepliesListSource? replies) async {
    final t = context.t;
    final confirmed = await showFrostConfirm(context: context, title: t.illust.comments.deleteConfirm, confirmLabel: t.illust.comments.delete);
    if (!mounted || !confirmed) return;
    try {
      await (replies == null ? _source.deleteComment(comment) : replies.deleteComment(comment));
      if (!mounted) return;
      _syncDetail();
      if (_replyingTo?.id == comment.id) setState(() => _replyingTo = null);
    } catch (error) {
      toastErrorWithCause(t.illust.comments.deleteFailed, error);
    }
  }

  /// Reloads the comments; every thread's replies load afresh after it.
  Future<bool> _refresh() async {
    final stale = [..._replies.values];
    _replies.clear();
    setState(() {});
    // The old sources go once no thread is built from them any more.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final source in stale) {
        source.dispose();
      }
    });
    return _source.refresh(false);
  }

  void _reply(Comment comment) {
    setState(() => _replyingTo = comment);
    _input.requestFocus();
  }

  void _insertEmoji(PixivCommentAsset asset) {
    final token = '(${asset.name})';
    final value = _draft.value;
    final selection = value.selection;
    final start = selection.isValid ? math.min(selection.start, selection.end) : value.text.length;
    final end = selection.isValid ? math.max(selection.start, selection.end) : value.text.length;
    _draft.value = value.copyWith(
      text: value.text.replaceRange(start, end, token),
      selection: TextSelection.collapsed(offset: start + token.length),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final total = widget.totalComments;
    final me = int.tryParse(pixivAccountNotifier.value?.user.id ?? '');
    final canPost = widget.workType.supportsPosting;
    return PopScope(
      canPop: !_hasDraft || _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasDraft) unawaited(_confirmDiscard());
      },
      child: FutureBuilder(
        future: pixivCommentAssets,
        builder: (context, snapshot) {
          final assets = snapshot.data ?? PixivCommentAssets.empty;
          FrostThread thread(Comment comment, {CommentRepliesListSource? parentReplies}) {
            final replies = comment.hasReplies && parentReplies == null ? _repliesOf(comment) : null;
            return FrostThread(
              item: appCommentItem(
                context,
                comment,
                assets: assets,
                onReply: canPost && parentReplies == null ? () => _reply(comment) : null,
                onDelete: comment.user.id == me ? () => unawaited(_delete(comment, parentReplies)) : null,
                // Loading the replies sits in the comment's footer, on its text column.
                actions: replies == null ? null : _RepliesFooter.of(context, replies),
              ),
              replies: [
                if (replies != null && replies.initialized)
                  for (final reply in replies.items) thread(reply, parentReplies: replies),
              ],
            );
          }

          return AppRefreshScope(
            onRefresh: _refresh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: FrostPinnedChrome(
                    chrome: FrostContentColumn(
                      maxWidth: FrostMetrics.readingMaxWidth,
                      child: FrostPageHeader(
                        title: FrostText(total == null ? t.illust.section.comments : t.illust.section.commentsWithCount(count: formatCount(total))),
                      ),
                    ),
                    body: FrostRefreshView(
                      onRefresh: _refresh,
                      builder: (context, physics, locators) => FrostLoadingScrollView(
                        physics: physics,
                        slivers: [
                          const FrostChromeSpacer(),
                          ?locators.sliverHeader,
                          FrostSliverContentColumn(
                            maxWidth: FrostMetrics.readingMaxWidth,
                            sliver: FrostSliverDataList<Comment>(
                              source: _source,
                              firstLoadSkeleton: const AppCommentRowsSkeleton(),
                              empty: FrostEmptyState(icon: PivIcons.messageCircle, title: t.commentsPage.empty),
                              itemBuilder: (context, comment, index) {
                                if (!comment.hasReplies) return thread(comment);
                                // The thread follows its replies as they load and change.
                                final replies = _repliesOf(comment);
                                return StreamBuilder(stream: replies.rebuild, builder: (context, _) => thread(comment));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (canPost)
                  SafeArea(
                    top: false,
                    child: FrostContentColumn(
                      maxWidth: FrostMetrics.readingMaxWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
                        child: AppComposerBar(
                          controller: _draft,
                          focusNode: _input,
                          placeholder: switch (_replyingTo) {
                            final parent? => t.illust.comments.replyInputHint(name: parent.user.name),
                            null => t.illust.comments.inputHint,
                          },
                          sendLabel: t.common.send,
                          sending: _sending,
                          onSend: _hasDraft && !_sending ? () => unawaited(_send(text: _draft.text.trim())) : null,
                          replyLabel: switch (_replyingTo) {
                            final parent? => t.illust.comments.replyingTo(name: parent.user.name),
                            null => null,
                          },
                          onCancelReply: () => setState(() => _replyingTo = null),
                          emojiLabel: t.illust.comments.emoji,
                          emojiPanel: assets.emojis.isEmpty
                              ? null
                              : (context, close) => _AssetGrid(assets: assets.emojis, extent: _AssetGrid.emojiExtent, onSelected: _insertEmoji),
                          stampLabel: t.illust.comments.stamp,
                          stampPanel: assets.stamps.isEmpty
                              ? null
                              : (context, close) => _AssetGrid(
                                  assets: assets.stamps,
                                  extent: _AssetGrid.stampExtent,
                                  onSelected: (asset) {
                                    close();
                                    if (int.tryParse(asset.name) case final id?) unawaited(_send(stampId: id));
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Loads a comment's replies into its thread, then more of them: a compact
/// action in the comment's footer, so it lines up with the comment's text.
abstract final class _RepliesFooter {
  /// The footer action for [source], or null once every reply is shown.
  static Widget? of(BuildContext context, CommentRepliesListSource source) {
    final t = context.t;
    final String label;
    if (source.lastError != null) {
      label = t.common.retry;
    } else if (!source.initialized) {
      label = t.illust.comments.loadReplies;
    } else if (source.hasMore) {
      label = t.illust.comments.loadMoreReplies;
    } else {
      return null;
    }
    return FrostButton.quiet(
      key: const ValueKey('comment-replies-action'),
      label: label,
      edgeAlignment: FrostButtonEdgeAlignment.start,
      size: FrostControlSize.compact,
      state: source.busy ? const FrostActionState.running() : FrostActionState.idle,
      onPressed: source.busy ? null : () => unawaited(source.initialized ? source.loadMore() : source.refresh(true)),
    );
  }
}

/// The emoji or stamp picker.
class _AssetGrid extends StatelessWidget {
  const _AssetGrid({required this.assets, required this.extent, required this.onSelected});

  final List<PixivCommentAsset> assets;
  final double extent;
  final ValueChanged<PixivCommentAsset> onSelected;

  static const emojiExtent = 32.0;
  static const stampExtent = 64.0;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: FrostGap.inline,
    runSpacing: FrostGap.inline,
    children: [
      for (final asset in assets)
        Semantics(
          button: true,
          label: asset.name,
          excludeSemantics: true,
          child: FrostClickSurface(
            onTap: () => onSelected(asset),
            child: Padding(
              padding: const EdgeInsets.all(FrostGap.inline),
              child: Image.asset(asset.path, width: extent, height: extent, filterQuality: FilterQuality.medium),
            ),
          ),
        ),
    ],
  );
}
