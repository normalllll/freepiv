import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'package:freepiv/ui/compositions/composer_bar.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/fanbox_image.dart';
import 'package:freepiv/ui/compositions/fanbox_rows.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/social.dart';
import 'package:html/parser.dart' as html;

import 'fanbox_actions.dart';
import 'fanbox_follow.dart';
import 'fanbox_plans.dart';
import 'logic.dart';

/// A FANBOX post, a reading column: the title, the
/// author with Follow, the date and access, the cover, the body blocks
/// (paragraphs, headings, images, files, embeds, post links; others say
/// they cannot show yet), then Like, the local bookmark, Download all, the
/// plans and the original, the previous and next posts, and the comments
/// with their input bar. A post the session cannot read shows what it needs
/// and the plans instead of a body, and no comments.
class FanboxPostDetailPage extends ConsumerStatefulWidget {
  const FanboxPostDetailPage({required this.postId, this.summary, super.key});

  final String postId;

  /// The card it was opened from, shown while the post loads.
  final FanboxPost? summary;

  @override
  ConsumerState<FanboxPostDetailPage> createState() => _FanboxPostDetailPageState();
}

class _FanboxPostDetailPageState extends ConsumerState<FanboxPostDetailPage> {
  final _scroll = ScrollController();
  final _headKey = GlobalKey();
  bool _headGone = false;
  double _headHeight = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_scrolled);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Once the title has scrolled away the header carries it. The list drops
  /// the head when it is far above; its last height still stands.
  void _scrolled() {
    _headHeight = _headKey.currentContext?.size?.height ?? _headHeight;
    final gone = _headHeight > 0 && _scroll.offset > _headHeight;
    if (gone != _headGone) setState(() => _headGone = gone);
  }

  Future<void> _refresh() async {
    ref.invalidate(fanboxPostProvider(widget.postId));
    ref.invalidate(fanboxCommentsProvider(widget.postId));
    await ref.read(fanboxPostProvider(widget.postId).future);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final fetched = ref.watch(fanboxPostProvider(widget.postId));
    // A restricted post the card already described stays readable as such.
    final state = switch (fetched.error) {
      PixivError(status: 403) when widget.summary?.isRestricted == true => AsyncData<FanboxPost>(widget.summary!),
      _ => fetched,
    };
    final post = state.value;
    if (post == null && state.hasError) {
      return AppPageError.fromError(error: state.error!, onRetry: () => ref.invalidate(fanboxPostProvider(widget.postId)));
    }
    final title = post?.title ?? widget.summary?.title ?? '';
    final header = FrostContentColumn(
      maxWidth: FrostMetrics.readingMaxWidth,
      child: FrostPageHeader(title: _headGone ? FrostText(title) : null),
    );
    final children = post == null
        ? [
            KeyedSubtree(key: _headKey, child: _Head(title: title, summary: widget.summary)),
            const _BodySkeleton(),
          ]
        : [
            KeyedSubtree(key: _headKey, child: _Head(title: title, post: post)),
            if (post.isRestricted) ...[
              FrostInlineBanner(
                tone: FrostBannerTone.info,
                title: t.fanbox.restricted(fee: formatCount(post.feeRequired)),
                message: [t.fanbox.restrictedInfo, if (post.excerpt.trim().isNotEmpty) post.excerpt.trim()].join('\n\n'),
              ),
              FrostSectionHeader(title: t.fanbox.creatorPlans),
              FanboxPlansList(creatorId: post.creatorId),
            ] else ...[
              for (final block in post.blocks) FanboxBlockView(block: block, title: post.title, gallery: fanboxPostImageUrls(post)),
              if (post.unknownBodyJson != null) FrostText(t.fanbox.unknown, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
            ],
            _PostActions(post: post),
            if (post.previousPostId != null || post.nextPostId != null)
              Row(
                children: [
                  if (post.previousPostId case final id?)
                    FrostButton.outlined(label: t.fanbox.previous, icon: PivIcons.chevronLeft, onPressed: () => openFanboxPost(context, id)),
                  const Spacer(),
                  if (post.nextPostId case final id?)
                    FrostButton.outlined(label: t.fanbox.next, icon: PivIcons.chevronRight, onPressed: () => openFanboxPost(context, id)),
                ],
              ),
            if (!post.isRestricted) _Comments(postId: post.id),
          ];
    final page = AppRefreshScope(
      onRefresh: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FrostPinnedChrome(
              chrome: header,
              body: FrostRefreshView(
                onRefresh: () async {
                  await _refresh();
                  return true;
                },
                builder: (context, physics, locators) => FrostLoadingScrollView(
                  controller: _scroll,
                  physics: physics,
                  slivers: [
                    const FrostChromeSpacer(),
                    ?locators.sliverHeader,
                    FrostSliverContentColumn(
                      maxWidth: FrostMetrics.readingMaxWidth,
                      sliver: SliverList.list(
                        children: [
                          for (final (index, child) in children.indexed)
                            Padding(
                              padding: EdgeInsets.only(top: index == 0 ? 0 : FrostGap.group),
                              child: child,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (post != null && !post.isRestricted) _CommentComposer(postId: post.id),
        ],
      ),
    );
    if (post == null) return page;
    return DownloadSourceScope(source: fanboxPostDownloadSource(post), child: page);
  }
}

/// The title, the author with Follow, the date and access, and the cover.
class _Head extends ConsumerWidget {
  const _Head({required this.title, this.post, this.summary});

  final String title;
  final FanboxPost? post;
  final FanboxPost? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final shown = post ?? summary;
    final cover = shown?.coverUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.related,
      children: [
        FrostText(title, content: true, role: FrostTextRole.title1),
        if (shown != null) ...[
          Row(
            spacing: FrostGap.related,
            children: [
              FrostClickSurface(
                shape: const FrostClickShape.circle(),
                onTap: () => openFanboxCreator(context, shown.creatorId),
                child: AppFanboxAvatar(user: shown.user),
              ),
              Expanded(
                child: FrostText(
                  shown.user.name.isEmpty ? shown.creatorId : shown.user.name,
                  content: true,
                  role: FrostTextRole.subheadline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (post != null) FanboxFollowButton(creatorId: shown.creatorId),
            ],
          ),
          Row(
            spacing: FrostGap.related,
            children: [
              FrostBadge(
                label: shown.feeRequired == 0 ? t.fanbox.free : t.fanbox.monthlyFee(fee: shown.feeRequired),
                tone: shown.isRestricted ? FrostBadgeTone.caution : FrostBadgeTone.neutral,
              ),
              Expanded(child: FrostMetaLine(items: [formatPixivDate(shown.publishedDatetime)])),
            ],
          ),
          if (shown.tags.isNotEmpty)
            Wrap(
              spacing: FrostGap.inline,
              runSpacing: FrostGap.inline,
              children: [for (final tag in shown.tags) FrostTag(label: '#$tag', onPressed: () => openFanboxTag(context, tag, creatorId: shown.creatorId))],
            ),
        ],
        if (cover != null && cover.isNotEmpty)
          post == null
              ? AppFanboxImage(url: cover, aspectRatio: AppFanboxPostCard.coverRatio)
              : FrostContextMenuRegion(
                  entries: fanboxImageMenu(context, ref, url: cover),
                  child: AppFanboxImage(url: cover, aspectRatio: AppFanboxPostCard.coverRatio, fit: BoxFit.contain),
                ),
      ],
    );
  }
}

class _BodySkeleton extends StatelessWidget {
  const _BodySkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FrostGap.group,
    children: [
      FrostText('The first paragraph of the post, a few lines long before its first image appears below it.', maxLines: 3),
      FrostMediaFrame(aspectRatio: 16 / 9, child: SizedBox.expand()),
      FrostText('Another paragraph follows the image.', maxLines: 2),
    ],
  ).frostSkeleton(true);
}

/// Like, the local bookmark, Download all, the plans and the original.
class _PostActions extends ConsumerWidget {
  const _PostActions({required this.post});

  final FanboxPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final scope = 'post:${post.id}';
    final operation = ref.watch(fanboxOperationProvider(scope));
    final saved = ref.watch(fanboxBookmarksProvider).value?.contains(post.id) ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.inline,
      children: [
        Wrap(
          spacing: FrostGap.related,
          runSpacing: FrostGap.related,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!post.isRestricted)
              FrostButton.prominent(
                key: const ValueKey('fanbox-like'),
                label: '${post.isLiked ? t.fanbox.liked : t.fanbox.like} · ${formatCount(post.likeCount)}',
                icon: post.isLiked ? PivIcons.heartFilled : PivIcons.heart,
                state: operation.isLoading ? const FrostActionState.running() : FrostActionState.idle,
                onPressed: post.isLiked || operation.isLoading
                    ? null
                    : () async {
                        final success = await ref.read(fanboxOperationProvider(scope).notifier).run(() async => (await ref.read(fanboxApiProvider.future)).likePost(postId: post.id));
                        if (success) {
                          ref.invalidate(fanboxPostProvider(post.id));
                          ref.invalidate(fanboxBrowseProvider);
                        }
                      },
              ),
            FrostButton.icon(
              key: const ValueKey('fanbox-bookmark'),
              icon: saved ? PivIcons.heartFilled : PivIcons.bookOpen,
              label: saved ? t.fanbox.saved : t.fanbox.save,
              selected: saved,
              onPressed: () => unawaited(ref.read(fanboxBookmarksProvider.notifier).toggle(post.id)),
            ),
            if (!post.isRestricted)
              Builder(
                builder: (buttonContext) => FrostButton.icon(
                  icon: PivIcons.download,
                  label: t.fanbox.downloadAll,
                  onPressed: () => unawaited(downloadFanboxPost(ref, post, origin: DownloadFlight.originOf(buttonContext))),
                ),
              ),
            FrostPopover(
              title: t.fanbox.creatorPlans,
              builder: (context, focusNode, toggle) => Focus(
                focusNode: focusNode,
                child: FrostButton.quiet(label: t.fanbox.viewPlans, onPressed: toggle),
              ),
              contentBuilder: (context, close) => FanboxPlansList(creatorId: post.creatorId),
            ),
            FrostMenuAnchor(
              entries: [
                FrostMenuAction(
                  t.fanbox.openOriginal,
                  leading: const FrostGlyph.icon(PivIcons.externalLink),
                  onSelected: () => unawaited(openFanboxLink(context, fanboxPostUrl(post.creatorId, post.id))),
                ),
              ],
              builder: (context, focusNode, toggle) => FrostButton.icon(icon: PivIcons.more, label: FrostScope.labelsOf(context).more, onPressed: toggle),
            ),
          ],
        ),
        if (operation.hasError) FrostText(fanboxError(context, operation.error!), role: FrostTextRole.footnote, tone: FrostTextTone.negative),
      ],
    );
  }
}

/// A creator's plans with their prices.
class FanboxPlansList extends ConsumerWidget {
  const FanboxPlansList({required this.creatorId, super.key});

  final String creatorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return switch (ref.watch(fanboxPlansProvider(creatorId))) {
      AsyncValue(:final value?) when value.isEmpty => FrostText(t.fanbox.noPlans, tone: FrostTextTone.secondary),
      AsyncValue(:final value?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final plan in value) FanboxPlanRow(plan: plan),
        ],
      ),
      AsyncValue(:final error?) => FrostCompactMessage.error(error: error, actionLabel: t.fanbox.retry, onAction: () => ref.invalidate(fanboxPlansProvider(creatorId))),
      _ => const AppRowsSkeleton(count: 2),
    };
  }
}

/// [text] with [spans] in the inline grammar of [FrostRichText]: links as
/// `[label](url)`, bold and italic marked.
String fanboxRichText(String text, List<FanboxTextSpan> spans) {
  final boundaries = <int>{0, text.length};
  for (final span in spans) {
    boundaries
      ..add(span.offset.clamp(0, text.length))
      ..add((span.offset + span.length).clamp(0, text.length));
  }
  final sorted = boundaries.toList()..sort();
  final out = StringBuffer();
  for (var index = 0; index + 1 < sorted.length; index++) {
    final start = sorted[index], end = sorted[index + 1];
    final piece = text.substring(start, end);
    if (piece.isEmpty) continue;
    final active = spans.where((span) => span.offset <= start && span.offset + span.length >= end);
    final url = active.map((span) => span.url).whereType<String>().firstOrNull;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && piece.trim().isNotEmpty) {
      out.write('[${piece.replaceAll(']', ')')}]($uri)');
      continue;
    }
    final mark = active.any((span) => span.bold) ? '**' : (active.any((span) => span.italic) ? '*' : '');
    out.write(mark.isEmpty || piece.trim().isEmpty ? piece : '$mark$piece$mark');
  }
  return out.toString();
}

/// The post's body images in order.
List<String> fanboxPostImageUrls(FanboxPost post) => [
  for (final block in post.blocks)
    if (block case FanboxBlock_Image(:final image)) image.originalUrl,
];

/// One block of a post's body.
class FanboxBlockView extends ConsumerWidget {
  const FanboxBlockView({required this.block, this.title = '', this.gallery = const [], super.key});

  final FanboxBlock block;

  /// What the image viewer names; the post's title.
  final String title;

  /// Every image of the post, which the viewer pages through from an image.
  final List<String> gallery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return switch (block) {
      FanboxBlock_Paragraph(:final text, :final spans) => FrostRichText(
        text: fanboxRichText(text, spans),
        onLink: (uri) => unawaited(openFanboxLink(context, '$uri')),
      ),
      FanboxBlock_Heading(:final text) => FrostText(text, content: true, role: FrostTextRole.title2),
      FanboxBlock_Image(:final image) => FrostContextMenuRegion(
        entries: fanboxImageMenu(context, ref, url: image.originalUrl, filename: '${image.id}.${image.extension_}'),
        child: FrostClickSurface(
          shape: FrostClickShape.rounded(BorderRadius.circular(FrostRadius.lg)),
          onTap: () {
            final urls = gallery.contains(image.originalUrl) ? gallery : [image.originalUrl];
            openFanboxImages(context, ref, urls: urls, index: urls.indexOf(image.originalUrl), title: title);
          },
          child: AppFanboxImage(
            url: image.originalUrl,
            aspectRatio: image.width > 0 && image.height > 0 ? image.width / image.height : 16 / 9,
            fit: BoxFit.contain,
          ),
        ),
      ),
      FanboxBlock_File(:final file) => FrostListRow(
        leading: const FrostGlyph.icon(PivIcons.download),
        title: '${file.name}.${file.extension_}',
        contentTitle: true,
        subtitle: FrostRowSubtitle(formatByteSize(file.size)),
        onPressed: () => unawaited(
          downloadFanboxFile(ref, url: file.url, filename: '${file.id}_${file.name}.${file.extension_}', source: DownloadSourceScope.of(context), image: false),
        ),
      ),
      FanboxBlock_Embed(:final url, :final html) => _Embed(url: url, content: html),
      FanboxBlock_PostLink(:final postId, :final title) => FrostListRow(
        leading: const FrostGlyph.icon(PivIcons.newspaper),
        title: title,
        contentTitle: true,
        accessory: FrostRowAccessory.chevron,
        onPressed: () => openFanboxPost(context, postId),
      ),
      FanboxBlock_Unknown(:final text) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostGap.inline,
        children: [
          if (text.isNotEmpty) FrostText(text, content: true),
          FrostText(t.fanbox.unknown, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
        ],
      ),
    };
  }
}

/// An embedded page: its text and a card for each of its links.
class _Embed extends StatelessWidget {
  const _Embed({this.url, this.content});

  final String? url;
  final String? content;

  @override
  Widget build(BuildContext context) {
    final document = html.parseFragment(content ?? '');
    final links = <String>{?url, ...document.querySelectorAll('a[href]').map((element) => element.attributes['href']!)};
    final text = document.text?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.related,
      children: [
        if (text.isNotEmpty) FrostText(text, content: true),
        for (final link in links)
          if (Uri.tryParse(link) case final uri? when uri.hasScheme)
            FrostLinkCard(title: uri.host, url: uri, onPressed: () => unawaited(openFanboxLink(context, link))),
        if (links.isEmpty && text.isEmpty) FrostText(context.t.fanbox.unknown, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
      ],
    );
  }
}

/// Who is being answered, kept between the comments and the input bar.
typedef _ReplyTarget = ({String rootId, String parentId, String name});

class _Replying extends Notifier<_ReplyTarget?> {
  _Replying(this.postId);

  /// The post whose comment is being answered.
  final String postId;

  @override
  _ReplyTarget? build() => null;

  void to(_ReplyTarget? target) => state = target;
}

final _replyingTo = NotifierProvider.autoDispose.family<_Replying, _ReplyTarget?, String>(_Replying.new);

/// The comments: each with its time, Like and Reply, the replies under it,
/// and Delete in the menu of one's own; more load on request.
class _Comments extends ConsumerWidget {
  const _Comments({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final scope = 'comments:$postId';
    final busy = ref.watch(fanboxOperationProvider(scope)).isLoading;
    Future<void> run(Future<void> Function(FanboxApi api) action) async {
      final success = await ref.read(fanboxOperationProvider(scope).notifier).run(() async => action(await ref.read(fanboxApiProvider.future)));
      if (success) ref.invalidate(fanboxCommentsProvider(postId));
    }

    FrostThread thread(FanboxComment comment, String rootId) => FrostThread(
      key: ValueKey(comment.id),
      item: FrostThreadItem(
        avatar: AppFanboxAvatar(user: comment.user, size: FrostAvatarSize.small),
        author: comment.user.name,
        body: FrostText(comment.body, content: true),
        time: formatPixivDate(comment.createdDatetime),
        like: FrostThreadAction(
          icon: comment.isLiked ? PivIcons.heartFilled : PivIcons.heart,
          label: comment.isLiked ? t.fanbox.liked : t.fanbox.like,
          count: formatCount(comment.likeCount),
          selected: comment.isLiked,
          onPressed: busy || comment.isLiked ? null : () => unawaited(run((api) => api.likeComment(commentId: comment.id))),
        ),
        reply: FrostThreadAction(
          icon: PivIcons.messageCircle,
          label: t.fanbox.reply,
          onPressed: () => ref.read(_replyingTo(postId).notifier).to((rootId: rootId, parentId: comment.id, name: comment.user.name)),
        ),
        contextMenu: [
          if (comment.isOwn)
            FrostMenuAction(
              t.fanbox.deleteComment,
              leading: FrostGlyph.icon(FrostIconSet.of(context).delete),
              destructive: true,
              onSelected: () async {
                final confirmed = await showFrostConfirm(context: context, title: t.fanbox.deleteConfirm, confirmLabel: t.fanbox.deleteComment, destructive: true);
                if (confirmed) await run((api) => api.deleteComment(commentId: comment.id));
              },
            ),
        ],
      ),
      replies: [for (final reply in comment.replies) thread(reply, rootId)],
    );

    return switch (ref.watch(fanboxCommentsProvider(postId))) {
      AsyncValue(:final value?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FrostSectionHeader(title: t.fanbox.comments),
          if (value.comments.isEmpty) FrostText(t.fanboxPage.noComments, tone: FrostTextTone.secondary),
          for (final comment in value.comments) thread(comment, comment.id),
          if (value.nextUrl != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FrostButton.quiet(
                label: t.fanbox.loadMore,
                state: busy ? const FrostActionState.running() : FrostActionState.idle,
                onPressed: busy ? null : () => unawaited(ref.read(fanboxOperationProvider(scope).notifier).run(() => ref.read(fanboxCommentsProvider(postId).notifier).loadMore())),
              ),
            ),
        ],
      ),
      AsyncValue(:final error?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FrostSectionHeader(title: t.fanbox.comments),
          FrostCompactMessage.error(error: error, actionLabel: t.fanbox.retry, onAction: () => ref.invalidate(fanboxCommentsProvider(postId))),
        ],
      ),
      _ => const AppRowsSkeleton(count: 3),
    };
  }
}

/// The input bar under the post's comments, answering one when asked.
class _CommentComposer extends ConsumerStatefulWidget {
  const _CommentComposer({required this.postId});

  final String postId;

  @override
  ConsumerState<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<_CommentComposer> {
  final _draft = TextEditingController();
  final _input = FocusNode();

  @override
  void initState() {
    super.initState();
    _draft.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _draft.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _draft.text.trim();
    if (text.isEmpty) return;
    final reply = ref.read(_replyingTo(widget.postId));
    final scope = 'comments:${widget.postId}';
    final success = await ref.read(fanboxOperationProvider(scope).notifier).run(() async {
      final api = await ref.read(fanboxApiProvider.future);
      await api.addComment(postId: widget.postId, body: text, rootCommentId: reply?.rootId, parentCommentId: reply?.parentId);
    });
    if (!mounted) return;
    if (success) {
      _draft.clear();
      ref.read(_replyingTo(widget.postId).notifier).to(null);
      ref.invalidate(fanboxCommentsProvider(widget.postId));
    } else {
      FrostToast.error(fanboxError(context, ref.read(fanboxOperationProvider(scope)).error ?? StateError('')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final comments = ref.watch(fanboxCommentsProvider(widget.postId));
    if (!(comments.value?.canComment ?? false)) return const SizedBox.shrink();
    final reply = ref.watch(_replyingTo(widget.postId));
    ref.listen(_replyingTo(widget.postId), (_, next) {
      if (next != null) _input.requestFocus();
    });
    final sending = ref.watch(fanboxOperationProvider('comments:${widget.postId}')).isLoading;
    return SafeArea(
      top: false,
      child: FrostContentColumn(
        maxWidth: FrostMetrics.readingMaxWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
          child: AppComposerBar(
            controller: _draft,
            focusNode: _input,
            placeholder: t.fanbox.commentHint,
            sendLabel: t.fanbox.send,
            sending: sending,
            onSend: _draft.text.trim().isNotEmpty && !sending ? () => unawaited(_send()) : null,
            replyLabel: reply == null ? null : '${t.fanbox.reply} ${reply.name}',
            onCancelReply: () => ref.read(_replyingTo(widget.postId).notifier).to(null),
          ),
        ),
      ),
    );
  }
}
