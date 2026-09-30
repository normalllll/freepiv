import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/downloads/download_manager.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/shared/widgets/constrained_segmented_button.dart';
import 'package:freepiv/shared/widgets/app_click_surface.dart';
import 'package:freepiv/shared/widgets/refresh_dots.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';
import 'skeletons.dart';
import 'package:freepiv/shared/widgets/energetic_card.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/shared/widgets/user_follow_button.dart';
import 'package:freepiv/shared/ui/app_dialog.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';
import 'package:freepiv/app/theme/app_feedback.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_timeline_lines.dart';
import 'package:freepiv/features/comments/presentation/widgets/comments_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html;
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'logic.dart';
import 'layout.dart';
import 'page.dart';
import 'widgets.dart';
import 'cards.dart';

/// Queues every image and file of [post]. [origin] is where the download was
/// asked for; the post's cover flies from there to the download badge.
Future<void> downloadFanboxPost(WidgetRef ref, FanboxPost post, {Rect? origin}) async {
  final source = fanboxPostDownloadSource(post);
  await _downloadFanboxBatch(
    origin: origin,
    artworkUrl: source.thumbnailUrl,
    queue: () => ref.read(fanboxDownloadsProvider.notifier).downloadPost(post, source: source),
  );
}

/// Collects and queues every post of [creator] the session can read.
Future<void> downloadFanboxCreator(WidgetRef ref, FanboxCreator creator, {Rect? origin}) async {
  final source = fanboxCreatorDownloadSource(creator);
  AppToast.info(t.fanbox.downloadPreparing);
  await _downloadFanboxBatch(origin: origin, artworkUrl: source.thumbnailUrl, queue: () => ref.read(fanboxDownloadsProvider.notifier).downloadCreator(source));
}

Future<void> _downloadFanboxBatch({required Rect? origin, required String? artworkUrl, required Future<int> Function() queue}) async {
  try {
    await downloadManager.ensureReadyForDownloads();
    DownloadFlight.launch(origin: origin, artwork: artworkUrl == null ? null : FanboxImageView(artworkUrl));
    final queued = await queue();
    if (queued > 0) {
      AppToast.info(t.fanbox.downloadQueued(count: queued));
    } else {
      AppToast.info(t.fanbox.downloadNothingNew);
    }
  } catch (error) {
    AppToast.errorWithCause(t.illust.toast.downloadFailed, error);
  }
}

class FanboxCreatorDetailPage extends ConsumerStatefulWidget {
  const FanboxCreatorDetailPage({required this.creatorId, this.showPlans = false, this.summary, super.key});
  final String creatorId;
  final bool showPlans;
  final FanboxCreator? summary;
  @override
  ConsumerState<FanboxCreatorDetailPage> createState() => _FanboxCreatorDetailPageState();
}

class _FanboxCreatorDetailPageState extends ConsumerState<FanboxCreatorDetailPage> {
  late bool _plans = widget.showPlans;
  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    final creatorState = ref.watch(fanboxCreatorProvider(widget.creatorId));
    final action = ref.watch(fanboxOperationProvider('creator:${widget.creatorId}'));
    final tags = ref.watch(fanboxTagsProvider(widget.creatorId));
    final collecting = ref.watch(fanboxDownloadsProvider.select((creators) => creators.containsKey(widget.creatorId)));
    final creator =
        creatorState.value ??
        widget.summary ??
        const FanboxCreator(
          creatorId: 'creator',
          user: FanboxUser(id: '', name: 'Creator name'),
          description: 'Creator description',
          isFollowed: false,
          isSupported: false,
          hasAdultContent: false,
          profileLinks: [],
          profileImages: [],
        );
    return FanboxScaffold(
      title: creatorState.asData?.value.user.name ?? widget.creatorId,
      body: creatorState.hasError && creatorState.value == null
          ? FanboxErrorView(creatorState.error!, retry: () => ref.invalidate(fanboxCreatorProvider(widget.creatorId)))
          : DownloadSourceScope(
              source: fanboxCreatorDownloadSource(creator),
              child: FanboxCollectionView(
                location: (section: _plans ? FanboxSection.creatorPlans : FanboxSection.creatorPosts, creatorId: widget.creatorId, query: ''),
                header: Skeletonizer(
                  enabled: creatorState.value == null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (creator.coverUrl != null) ClipRRect(borderRadius: BorderRadius.circular(16), child: FanboxImageView(creator.coverUrl, height: 220)),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        leading: SizedBox(width: 56, height: 56, child: ClipOval(child: FanboxImageView(creator.user.iconUrl))),
                        title: Text(creator.user.name, style: Theme.of(context).textTheme.headlineSmall),
                        subtitle: Text('@${creator.creatorId}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FollowToggleButton(
                              isFollowed: creator.isFollowed,
                              updating: action.isLoading,
                              onPressed: action.isLoading
                                  ? null
                                  : () async {
                                      final success = await ref.read(fanboxOperationProvider('creator:${widget.creatorId}').notifier).run(() async {
                                        final api = await ref.read(fanboxApiProvider.future);
                                        if (creator.isFollowed) {
                                          await api.unfollowCreator(userId: creator.user.id);
                                        } else {
                                          await api.followCreator(userId: creator.user.id);
                                        }
                                      });
                                      if (success && mounted) {
                                        ref.invalidate(fanboxCreatorProvider(widget.creatorId));
                                        ref.invalidate(fanboxBrowseProvider);
                                      }
                                    },
                            ),
                            AppMenuAnchor(
                              menuChildren: [
                                Builder(
                                  builder: (itemContext) => AppMenuItem(
                                    onPressed: collecting || creatorState.value == null
                                        ? null
                                        : () => downloadFanboxCreator(ref, creator, origin: DownloadFlight.originOf(itemContext)),
                                    child: Text(t.downloadCreator),
                                  ),
                                ),
                                AppMenuItem(
                                  onPressed: () => openFanboxLink(context, 'https://www.fanbox.cc/@${Uri.encodeComponent(widget.creatorId)}'),
                                  child: Text(t.openOriginal),
                                ),
                              ],
                              builder: (context, focusNode, toggle) => IconButton(
                                focusNode: focusNode,
                                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                                onPressed: toggle,
                                icon: const Icon(Icons.more_vert),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        child: action.hasError ? Text(fanboxError(context, action.error!)) : const SizedBox.shrink(),
                      ),
                      if (creator.description.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(top: 8, bottom: 8), child: SelectableText(creator.description)),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final url in creator.profileLinks)
                            TextButton.icon(
                              onPressed: () => openFanboxLink(context, url),
                              icon: const Icon(Icons.link),
                              label: Text(Uri.tryParse(url)?.host ?? t.openLink),
                            ),
                        ],
                      ),
                      if (creator.profileImages.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: creator.profileImages.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (_, index) => SizedBox(
                              width: 160,
                              child: AppClickSurface(
                                feedback: AppClickFeedback.artwork,
                                onTap: () => showFanboxImage(context, creator.profileImages[index]),
                                child: FanboxImageMenu(url: creator.profileImages[index], child: FanboxImageView(creator.profileImages[index])),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (creator.isSupported)
                        TextButton.icon(
                          onPressed: () => showAppDialog<void>(
                            context: context,
                            builder: (_) => FanboxFanCardDialog(creatorId: creator.creatorId, source: fanboxCreatorDownloadSource(creator)),
                          ),
                          icon: const Icon(Icons.card_membership),
                          label: Text(t.fanCard),
                        ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.topCenter,
                        child: (tags.hasError || (tags.value?.isNotEmpty ?? false))
                            ? SizedBox(
                                height: 48,
                                child: tags.when(
                                  loading: () => const SizedBox.shrink(),
                                  error: (error, _) => TextButton(onPressed: () => ref.invalidate(fanboxTagsProvider(widget.creatorId)), child: Text(t.retry)),
                                  data: (values) => ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: values.length,
                                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                                    itemBuilder: (context, index) => ActionChip(
                                      label: Text('#${values[index].name}'),
                                      onPressed: () => openFanboxTag(context, values[index].name, creatorId: widget.creatorId),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AppSegmentedButton<bool>(
                          segments: [
                            ButtonSegment(value: false, label: Text(t.posts), icon: const Icon(Icons.article_outlined)),
                            ButtonSegment(value: true, label: Text(t.creatorPlans), icon: const Icon(Icons.card_membership)),
                          ],
                          selected: {_plans},
                          onSelectionChanged: (value) => setState(() => _plans = value.single),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class FanboxFanCardDialog extends ConsumerWidget {
  const FanboxFanCardDialog({required this.creatorId, required this.source, super.key});
  final String creatorId;

  /// The creator, which the fan card's download is filed under.
  final FanboxCreatorSource source;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AlertDialog(
    title: Text(context.t.fanbox.fanCard),
    content: SizedBox(
      width: 500,
      child: ref
          .watch(fanboxSupportProvider(creatorId))
          .when(
            loading: () => Skeletonizer.zone(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AspectRatio(aspectRatio: 1.6, child: ImageLoadingSkeleton()),
                  TextButton(onPressed: null, child: Text(context.t.fanbox.download)),
                ],
              ),
            ),
            error: (error, _) => FanboxErrorView(error, retry: () => ref.invalidate(fanboxSupportProvider(creatorId))),
            data: (support) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (support.fanCardUrl case final url?) ...[
                  AspectRatio(aspectRatio: 1.6, child: FanboxImageView(url, fit: BoxFit.contain)),
                  TextButton(
                    onPressed: () => downloadFanboxFile(ref, url: url, filename: 'fanbox-card-${Uri.encodeComponent(creatorId)}.png', source: source),
                    child: Text(context.t.fanbox.download),
                  ),
                ] else
                  Text(context.t.fanbox.empty),
              ],
            ),
          ),
    ),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t.fanbox.done))],
  );
}

class FanboxPostDetailPage extends ConsumerWidget {
  const FanboxPostDetailPage({required this.postId, this.summary, super.key});
  final String postId;
  final FanboxPost? summary;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetched = ref.watch(fanboxPostProvider(postId));
    final state = switch (fetched.error) {
      PixivError(status: 403) when summary?.isRestricted == true => AsyncData<FanboxPost>(summary!),
      _ => fetched,
    };
    final operation = ref.watch(fanboxOperationProvider('post:$postId'));
    final saved = ref.watch(fanboxBookmarksProvider).asData?.value.contains(postId) ?? false;
    final t = context.t.fanbox;
    return FanboxScaffold(
      title: state.asData?.value.title ?? t.posts,
      body: state.when(
        loading: () => LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: fanboxReadingPadding(constraints.maxWidth),
            child: FanboxArticleSkeleton(title: summary?.title),
          ),
        ),
        error: (error, _) => FanboxErrorView(error, retry: () => ref.invalidate(fanboxPostProvider(postId))),
        data: (post) => DownloadSourceScope(
          source: fanboxPostDownloadSource(post),
          child: DotsRefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fanboxPostProvider(postId));
              await ref.read(fanboxPostProvider(postId).future);
            },
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                padding: fanboxReadingPadding(constraints.maxWidth),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: SelectableText(post.title, style: Theme.of(context).textTheme.headlineMedium)),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: saved ? t.saved : t.save,
                        onPressed: () => ref.read(fanboxBookmarksProvider.notifier).toggle(postId),
                        icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline),
                      ),
                      IconButton(
                        tooltip: t.openOriginal,
                        onPressed: () => openFanboxLink(
                          context,
                          'https://www.fanbox.cc/@${Uri.encodeComponent(state.asData?.value.creatorId ?? '')}/posts/${Uri.encodeComponent(postId)}',
                        ),
                        icon: const Icon(Icons.open_in_new),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(post.user.name.isEmpty ? post.creatorId : post.user.name),
                    subtitle: Text(fanboxDate(context, post.publishedDatetime)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openFanboxCreator(context, post.creatorId),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(post.isRestricted ? Icons.lock : Icons.lock_open, size: 16),
                          label: Text(post.feeRequired > 0 ? t.restricted(fee: fanboxFee(context, post.feeRequired)) : t.free),
                        ),
                        for (final tag in post.tags)
                          ActionChip(
                            label: Text('#$tag'),
                            onPressed: () => openFanboxTag(context, tag, creatorId: post.creatorId),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (post.coverUrl case final cover?) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FanboxImageMenu(
                        url: cover,
                        child: FanboxImageView(cover, height: 320, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (post.isRestricted) ...[
                    EnergeticCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.lock_outline, size: 40),
                            const SizedBox(height: 12),
                            Text(t.restricted(fee: fanboxFee(context, post.feeRequired)), style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(t.restrictedInfo),
                            if (post.excerpt.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(post.excerpt)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(t.creatorPlans, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    FanboxPlansPanel(creatorId: post.creatorId),
                  ] else ...[
                    for (final block in post.blocks) Padding(padding: const EdgeInsets.only(bottom: 16), child: FanboxBlockView(block)),
                    if (post.unknownBodyJson != null)
                      EnergeticCard(
                        child: Padding(padding: const EdgeInsets.all(16), child: Text(t.unknown)),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.tonalIcon(
                          style: appSecondaryButtonStyle(FreepivThemeTokens.of(context)),
                          onPressed: post.isLiked || operation.isLoading
                              ? null
                              : () async {
                                  final success = await ref
                                      .read(fanboxOperationProvider('post:$postId').notifier)
                                      .run(() async => (await ref.read(fanboxApiProvider.future)).likePost(postId: postId));
                                  if (success && context.mounted) {
                                    ref.invalidate(fanboxPostProvider(postId));
                                    ref.invalidate(fanboxBrowseProvider);
                                  }
                                },
                          icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border),
                          label: Text('${post.isLiked ? t.liked : t.like} · ${post.likeCount}'),
                        ),
                        Builder(
                          builder: (buttonContext) => OutlinedButton.icon(
                            onPressed: () => downloadFanboxPost(ref, post, origin: DownloadFlight.originOf(buttonContext)),
                            icon: const Icon(Icons.download),
                            label: Text(t.downloadAll),
                          ),
                        ),
                        TextButton(
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            sheetAnimationStyle: appSheetAnimationStyle(context),
                            isScrollControlled: true,
                            builder: (_) => SafeArea(
                              child: DraggableScrollableSheet(
                                expand: false,
                                initialChildSize: 0.75,
                                builder: (_, controller) => ListView(
                                  controller: controller,
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    Text(t.creatorPlans, style: Theme.of(context).textTheme.titleLarge),
                                    FanboxPlansPanel(creatorId: post.creatorId),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          child: Text(t.viewPlans),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.topLeft,
                      child: operation.hasError ? Text(fanboxError(context, operation.error!)) : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
                    FanboxCommentsPanel(postId: postId),
                  ],
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (post.previousPostId case final id?) OutlinedButton(onPressed: () => openFanboxPost(context, id), child: Text(t.previous)),
                      if (post.nextPostId case final id?) OutlinedButton(onPressed: () => openFanboxPost(context, id), child: Text(t.next)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FanboxPlansPanel extends ConsumerWidget {
  const FanboxPlansPanel({required this.creatorId, super.key});
  final String creatorId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(fanboxPlansProvider(creatorId))
      .when(
        loading: () => const FanboxCollectionSkeleton(section: FanboxSection.creatorPlans),
        error: (error, _) => FanboxErrorView(error, retry: () => ref.invalidate(fanboxPlansProvider(creatorId))),
        data: (plans) => plans.isEmpty
            ? Padding(padding: const EdgeInsets.all(20), child: Text(context.t.fanbox.noPlans))
            : Column(
                children: [for (final plan in plans) Padding(padding: const EdgeInsets.only(bottom: 12), child: FanboxPlanCard(plan))],
              ),
      );
}

/// Shows [url] full screen; its menu files downloads under the page's
/// source, as the image it was opened from does.
void showFanboxImage(BuildContext context, String url) {
  final source = DownloadSourceScope.of(context);
  showAppDialog<void>(
    context: context,
    builder: (context) => DownloadSourceScope(
      source: source,
      child: Dialog.fullscreen(
        child: Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 8,
                      child: FanboxImageMenu(
                        url: url,
                        child: FanboxImageView(url, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(tooltip: context.t.fanbox.openOriginal, onPressed: () => openFanboxLink(context, url), icon: const Icon(Icons.open_in_new)),
                      const CloseButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class FanboxBlockView extends ConsumerWidget {
  const FanboxBlockView(this.block, {super.key});
  final FanboxBlock block;
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (block) {
    FanboxBlock_Paragraph(:final text, :final spans) => FanboxParagraph(text: text, spans: spans),
    FanboxBlock_Heading(:final text) => SelectableText(text, style: Theme.of(context).textTheme.headlineSmall),
    FanboxBlock_Image(:final image) => AspectRatio(
      aspectRatio: image.width > 0 && image.height > 0 ? image.width / image.height : 16 / 9,
      child: AppClickSurface(
        feedback: AppClickFeedback.artwork,
        onTap: () => showFanboxImage(context, image.originalUrl),
        child: FanboxImageMenu(
          url: image.originalUrl,
          filename: '${image.id}.${image.extension_}',
          child: FanboxImageView(image.originalUrl, fit: BoxFit.contain),
        ),
      ),
    ),
    FanboxBlock_File(:final file) => EnergeticCard(
      child: ListTile(
        leading: const Icon(Icons.attach_file),
        title: Text('${file.name}.${file.extension_}'),
        subtitle: Text(formatByteSize(file.size)),
        trailing: const Icon(Icons.download),
        onTap: () => downloadFanboxFile(
          ref,
          url: file.url,
          filename: '${file.id}_${file.name}.${file.extension_}',
          source: DownloadSourceScope.of(context),
          image: false,
        ),
      ),
    ),
    FanboxBlock_Embed(:final url, :final html) => _FanboxEmbed(url: url, content: html),
    FanboxBlock_PostLink(:final postId, :final title) => EnergeticCard(
      child: ListTile(
        leading: const Icon(Icons.article_outlined),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openFanboxPost(context, postId),
      ),
    ),
    FanboxBlock_Unknown(:final text) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text.isNotEmpty) SelectableText(text),
        Text(context.t.fanbox.unknown, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  };
}

class _FanboxEmbed extends StatelessWidget {
  const _FanboxEmbed({this.url, this.content});
  final String? url;
  final String? content;
  @override
  Widget build(BuildContext context) {
    final document = html.parseFragment(content ?? '');
    final links = <String>{?url, ...document.querySelectorAll('a[href]').map((e) => e.attributes['href']!)};
    return EnergeticCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (document.text?.trim() case final text? when text.isNotEmpty) SelectableText(text),
            for (final image in document.querySelectorAll('img[src]'))
              AspectRatio(
                aspectRatio: 16 / 9,
                child: FanboxImageView(image.attributes['src'], fit: BoxFit.contain),
              ),
            for (final link in links)
              TextButton.icon(
                onPressed: () => openFanboxLink(context, link),
                icon: const Icon(Icons.open_in_new),
                label: Text(Uri.tryParse(link)?.host ?? context.t.fanbox.openLink),
              ),
            if (links.isEmpty && (document.text?.trim().isEmpty ?? true)) Text(context.t.fanbox.unknown),
          ],
        ),
      ),
    );
  }
}

class FanboxParagraph extends StatefulWidget {
  const FanboxParagraph({required this.text, required this.spans, super.key});
  final String text;
  final List<FanboxTextSpan> spans;
  @override
  State<FanboxParagraph> createState() => _FanboxParagraphState();
}

class _FanboxParagraphState extends State<FanboxParagraph> {
  final Map<String, TapGestureRecognizer> _links = {};
  void _updateLinks() {
    for (final recognizer in _links.values) {
      recognizer.dispose();
    }
    _links.clear();
    for (final span in widget.spans) {
      if (span.url case final url?) _links.putIfAbsent(url, () => TapGestureRecognizer()..onTap = () => openFanboxLink(context, url));
    }
  }

  @override
  void initState() {
    super.initState();
    _updateLinks();
  }

  @override
  void didUpdateWidget(covariant FanboxParagraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateLinks();
  }

  @override
  void dispose() {
    for (final recognizer in _links.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boundaries = <int>{0, widget.text.length};
    for (final span in widget.spans) {
      boundaries.add(span.offset.clamp(0, widget.text.length));
      boundaries.add((span.offset + span.length).clamp(0, widget.text.length));
    }
    final sorted = boundaries.toList()..sort();
    final spans = <TextSpan>[];
    for (var i = 0; i + 1 < sorted.length; i++) {
      final start = sorted[i], end = sorted[i + 1];
      final active = widget.spans.where((span) => span.offset <= start && span.offset + span.length >= end);
      final url = active.map((e) => e.url).whereType<String>().firstOrNull;
      spans.add(
        TextSpan(
          text: widget.text.substring(start, end),
          recognizer: _links[url],
          style: TextStyle(
            fontWeight: active.any((e) => e.bold) ? FontWeight.bold : null,
            fontStyle: active.any((e) => e.italic) ? FontStyle.italic : null,
            color: url == null ? null : FreepivThemeTokens.of(context).textPrimary,
            decoration: url == null ? null : TextDecoration.underline,
          ),
        ),
      );
    }
    return SelectableText.rich(TextSpan(children: spans), style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.65));
  }
}

class FanboxCommentsPanel extends ConsumerStatefulWidget {
  const FanboxCommentsPanel({required this.postId, super.key});
  final String postId;
  @override
  ConsumerState<FanboxCommentsPanel> createState() => _FanboxCommentsPanelState();
}

class _FanboxCommentsPanelState extends ConsumerState<FanboxCommentsPanel> {
  final _text = TextEditingController();
  ({String rootId, String parentId, String name})? _reply;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<bool> _run(Future<void> Function(FanboxApi) action) async {
    final success = await ref
        .read(fanboxOperationProvider('comments:${widget.postId}').notifier)
        .run(() async => action(await ref.read(fanboxApiProvider.future)));
    if (success && mounted) ref.invalidate(fanboxCommentsProvider(widget.postId));
    return success;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    final state = ref.watch(fanboxCommentsProvider(widget.postId));
    final operation = ref.watch(fanboxOperationProvider('comments:${widget.postId}'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.comments, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topLeft,
          child: _reply == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text('${t.reply} ${_reply!.name}')),
                      IconButton(onPressed: () => setState(() => _reply = null), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
        ),
        TextField(
          controller: _text,
          enabled: state.asData?.value.canComment ?? false,
          minLines: 2,
          maxLines: 6,
          decoration: InputDecoration(hintText: t.commentHint),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: operation.isLoading || !(state.asData?.value.canComment ?? false)
                ? null
                : () async {
                    if (_text.text.trim().isEmpty) return;
                    final text = _text.text;
                    final reply = _reply;
                    if (await _run(
                          (api) => api.addComment(postId: widget.postId, body: text, rootCommentId: reply?.rootId, parentCommentId: reply?.parentId),
                        ) &&
                        mounted) {
                      _text.clear();
                      setState(() => _reply = null);
                    }
                  },
            child: Text(t.send),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topLeft,
          child: operation.hasError ? Text(fanboxError(context, operation.error!)) : const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        state.when(
          loading: () => const CommentsLoadingSkeleton(),
          error: (error, _) => FanboxErrorView(error, retry: () => ref.invalidate(fanboxCommentsProvider(widget.postId))),
          data: (page) => Column(
            children: [
              for (final (index, comment) in page.comments.indexed) ...[
                _comment(context, comment, comment.id, operation.isLoading),
                if (index < page.comments.length - 1) const CommentSeparator(),
              ],
              if (page.nextUrl != null)
                OutlinedButton(
                  onPressed: operation.isLoading
                      ? null
                      : () => ref
                            .read(fanboxOperationProvider('comments:${widget.postId}').notifier)
                            .run(() => ref.read(fanboxCommentsProvider(widget.postId).notifier).loadMore()),
                  child: Text(t.loadMore),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comment(BuildContext context, FanboxComment comment, String rootId, bool busy) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${comment.user.name} · ${fanboxDate(context, comment.createdDatetime)}', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SelectableText(comment.body),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: busy ? null : () => setState(() => _reply = (rootId: rootId, parentId: comment.id, name: comment.user.name)),
              child: Text(context.t.fanbox.reply),
            ),
            TextButton(
              onPressed: busy || comment.isLiked ? null : () => _run((api) => api.likeComment(commentId: comment.id)),
              child: Text('${comment.isLiked ? context.t.fanbox.liked : context.t.fanbox.like} ${comment.likeCount}'),
            ),
            if (comment.isOwn)
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        final accepted = await showAppDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(context.t.fanbox.deleteConfirm),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t.fanbox.cancel)),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.t.fanbox.deleteComment)),
                            ],
                          ),
                        );
                        if (accepted == true && mounted) await _run((api) => api.deleteComment(commentId: comment.id));
                      },
                child: Text(context.t.fanbox.deleteComment),
              ),
          ],
        ),
        if (comment.replies.isNotEmpty)
          CommentReplyRail(contentInset: 18, child: Column(children: [for (final reply in comment.replies) _comment(context, reply, rootId, busy)])),
      ],
    ),
  );
}
