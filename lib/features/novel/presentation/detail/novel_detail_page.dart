import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/features/comments/presentation/comment_thread_item.dart';
import 'package:freepiv/features/downloads/presentation/content_image_entries.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/features/illust/presentation/illust_info.dart' show IllustAuthorLine;
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/novel_download_source.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reading_session.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/loading_section.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/compositions/pixiv_text.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The novel page, a reading column: cover, title,
/// author and meta, then Start / Continue reading as the solid button with
/// Bookmark, the caption, tags, the illustrations, comments, the author's
/// other novels and related novels. The text loads apart: when it fails the
/// page stays usable and only reading waits for a retry.
class NovelDetailPage extends ConsumerWidget {
  const NovelDetailPage({this.novelId, this.novel, super.key}) : assert(novelId != null || novel != null);

  final int? novelId;
  final Novel? novel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = novelDetailProvider(NovelDetailArgs(novelId: novelId, novel: novel));
    final value = ref.watch(provider);
    final shown = value.asData?.value ?? novel;
    final Widget content = switch (value) {
      AsyncValue(:final value?) => NovelDetailContent(key: ValueKey(value.id), novel: value),
      AsyncValue(:final error?) when shown == null =>
        error is PixivError && error.status == 404
            ? AppPageError.notFound(message: context.t.novelDetail.missing)
            : AppPageError.fromError(error: error, onRetry: () => unawaited(ref.read(provider.notifier).reload())),
      _ when shown != null => NovelDetailContent(key: ValueKey(shown.id), novel: shown),
      _ => const _NovelDetailSkeleton(),
    };
    final id = novelId ?? novel?.id;
    if (id == null) return content;
    return FrostWindowTitleContribution(
      path: AppLocations.novel(id),
      page: shown == null ? null : FrostPageTitle(id: id, title: shown.title, kind: 'novel', imageUrl: shown.imageUrls.medium),
      child: content,
    );
  }
}

class NovelDetailContent extends ConsumerStatefulWidget {
  const NovelDetailContent({required this.novel, super.key});

  final Novel novel;

  @override
  ConsumerState<NovelDetailContent> createState() => _NovelDetailContentState();
}

class _NovelDetailContentState extends ConsumerState<NovelDetailContent> {
  final _scroll = ScrollController();
  final _headKey = GlobalKey();
  bool _headGone = false;
  double _headHeight = 0;

  Novel get _novel => widget.novel;

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

  /// Once the title has scrolled away the header carries it and the
  /// reading button. The list drops the head when it is far above; its last
  /// height still stands.
  void _scrolled() {
    _headHeight = _headKey.currentContext?.size?.height ?? _headHeight;
    final gone = _headHeight > 0 && _scroll.offset > _headHeight;
    if (gone != _headGone) setState(() => _headGone = gone);
  }

  Future<void> _read() async {
    await GoRouter.of(context).push(AppLocations.novelReader(_novel.id), extra: _novel);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = ref.watch(novelTextProvider(_novel.id));
    final webview = text.value;
    final readable = webview?.text.trim().isNotEmpty ?? false;
    final readLabel = novelReadingPosition(context, _novel.id) == null ? t.novel.detail.startReading : t.novel.detail.continueReading;
    final related = ref.watch(novelRelatedWorksProvider(_novel.id));
    return DownloadSourceScope(
      source: novelDownloadSource(_novel),
      child: FrostPinnedChrome(
        chrome: FrostContentColumn(
          maxWidth: FrostMetrics.readingMaxWidth,
          child: FrostPageHeader(
            title: _headGone ? FrostText(_novel.title) : null,
            actions: [
              if (_headGone && readable)
                FrostToolbarItem.action(icon: PivIcons.newspaper, label: readLabel, showsLabel: true, onPressed: () => unawaited(_read())),
            ],
          ),
        ),
        body: FrostLoadingScrollView(
          controller: _scroll,
          slivers: [
            const FrostChromeSpacer(),
            FrostSliverContentColumn(
              maxWidth: FrostMetrics.readingMaxWidth,
              sliver: SliverList.list(
                children: [
                  KeyedSubtree(
                    key: _headKey,
                    child: _NovelHead(novel: _novel),
                  ),
                  const SizedBox(height: FrostGap.group),
                  Wrap(
                    spacing: FrostGap.related,
                    runSpacing: FrostGap.related,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FrostButton.prominent(label: readLabel, icon: PivIcons.newspaper, onPressed: readable ? () => unawaited(_read()) : null),
                      AppBookmarkBuilder(
                        workId: _novel.id,
                        initiallyBookmarked: _novel.isBookmarked,
                        novel: true,
                        builder: (context, bookmarked, toggle) => AppDetailBookmarkButton(
                          bookmarked: bookmarked,
                          label: bookmarked ? t.novelDetail.bookmarked : t.novelDetail.bookmark,
                          onPressed: toggle,
                        ),
                      ),
                    ],
                  ),
                  if (text.hasError && !text.isLoading)
                    Row(
                      children: [
                        Flexible(
                          child: FrostText(t.novelText.loadFailed, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
                        ),
                        FrostButton.quiet(label: t.common.retry, onPressed: () => unawaited(ref.read(novelTextProvider(_novel.id).notifier).reload())),
                      ],
                    ),
                  _NovelAbout(novel: _novel, caption: webview?.caption),
                  _NovelImages(novel: _novel, imageUrls: novelExtraImageUrls(_novel, webview)),
                  const SizedBox(height: FrostGap.section),
                  AppCommentsPreview(
                    value: ref.watch(novelCommentsProvider(_novel.id)),
                    total: _novel.totalComments,
                    onRetry: () => unawaited(ref.read(novelCommentsProvider(_novel.id).notifier).reload()),
                    location: AppLocations.novelComments(_novel.id),
                  ),
                  const SizedBox(height: FrostGap.section),
                  _AuthorNovels(novel: _novel),
                  const SizedBox(height: FrostGap.section),
                  FrostSectionHeader(title: t.novelDetail.related),
                ],
              ),
            ),
            FrostSliverContentColumn(
              maxWidth: FrostMetrics.readingMaxWidth,
              sliver: FrostSliverDataList<Novel>(
                source: related,
                firstLoadSkeleton: const AppNovelRowsSkeleton(),
                empty: FrostText(t.novelDetail.noRelated, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
                itemBuilder: (context, novel, index) => AppNovelRow(novel: novel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cover, title, author line and meta.
class _NovelHead extends ConsumerWidget {
  const _NovelHead({required this.novel});

  final Novel novel;

  static const coverWidth = 96.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cover = novel.imageUrls.medium;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FrostGap.group,
      children: [
        SizedBox(
          width: coverWidth,
          child: FrostContextMenuRegion(
            entries: contentImageMenu(context, ref.read(rustMediaTransportProvider), url: cover, title: novel.title),
            child: FrostThumbnail(
              size: FrostThumbnailSize.large,
              semanticLabel: t.novel.detail.images,
              image: AppPixivImage(url: cover, aspectRatio: 1 / 1.414, radius: 0),
              onPressed: () => _openImages(context, novel, [cover], 0),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostGap.related,
            children: [
              FrostText(novel.title, content: true, role: FrostTextRole.title2, selectable: true),
              IllustAuthorLine(user: novel.user),
              FrostMetaLine(
                items: [
                  t.novel.detail.totalChars(count: formatCount(novel.textLength)),
                  formatPixivDate(novel.createDate),
                  t.novelDetail.bookmarks(count: formatCount(novel.totalBookmarks)),
                  ?novel.series.title,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _openImages(BuildContext context, Novel novel, List<String> urls, int index) => unawaited(
  GoRouter.of(context).push(
    AppRoute.originalImageViewer.path,
    extra: OriginalImageViewerArgs(
      title: novel.title,
      source: DownloadSourceScope.of(context),
      initialIndex: index,
      pages: [for (final url in urls) OriginalImagePage(url: url, previewUrl: url, downloadOrigin: DownloadOrigin.ofImageUrl(Uri.parse(url)))],
    ),
  ),
);

/// The caption and the tags, which search novels, with the gap above them; a
/// novel with neither leaves nothing.
class _NovelAbout extends StatelessWidget {
  const _NovelAbout({required this.novel, required this.caption});

  final Novel novel;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = plainTextFromHtml(caption?.trim().isNotEmpty ?? false ? caption! : novel.caption).trim();
    if (text.isEmpty && novel.tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: FrostGap.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostGap.group,
        children: [
          if (text.isNotEmpty) AppPixivText(caption?.trim().isNotEmpty ?? false ? caption! : novel.caption),
          if (novel.tags.isNotEmpty)
            FrostWrap(
              children: [
                for (final tag in novel.tags)
                  FrostTag(
                    label: '#${tag.name}',
                    detail: tag.translatedName,
                    style: FrostTagStyle.topic,
                    onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.tagSearch(tag.name, kind: AppSearchKind.novel))),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The novel's illustrations as a thumbnail strip opening the viewer.
class _NovelImages extends ConsumerWidget {
  const _NovelImages({required this.novel, required this.imageUrls});

  final Novel novel;
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: FrostGap.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostGap.related,
        children: [
          FrostSectionHeader(title: context.t.novel.detail.images),
          FrostThumbnailStrip(
            itemCount: imageUrls.length,
            selectedIndex: null,
            onSelected: (index) => _openImages(context, novel, imageUrls, index),
            itemBuilder: (context, index) => FrostContextMenuRegion(
              entries: contentImageMenu(context, ref.read(rustMediaTransportProvider), url: imageUrls[index], title: novel.title),
              child: AppPixivImage(url: imageUrls[index], aspectRatio: 1, radius: 0),
            ),
          ),
        ],
      ),
    );
  }
}

/// The author's other novels, with the way to their page.
class _AuthorNovels extends ConsumerWidget {
  const _AuthorNovels({required this.novel});

  final Novel novel;

  static const shown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final provider = novelUserWorksProvider(novel.user.id);
    return AppLoadingSection(
      title: t.novelDetail.authorNovels,
      value: ref.watch(provider),
      onRetry: () => unawaited(ref.read(provider.notifier).reload()),
      failed: t.illust.works.failed,
      skeleton: const AppNovelRowsSkeleton(count: shown, showAuthor: false),
      action: FrostButton.quiet(label: t.home.seeMore, onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.user(novel.user.id)))),
      builder: (page) {
        final others = page.novels.where((other) => other.id != novel.id).take(shown).toList();
        if (others.isEmpty) return FrostText(t.illust.works.empty, role: FrostTextRole.footnote, tone: FrostTextTone.secondary);
        return Column(children: [for (final other in others) AppNovelRow(novel: other, showAuthor: false)]);
      },
    );
  }
}

class _NovelDetailSkeleton extends StatelessWidget {
  const _NovelDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return FrostPinnedChrome(
      chrome: const FrostPageHeader(),
      body: FrostLoadingScrollView(
        slivers: [
          const FrostChromeSpacer(),
          FrostSliverContentColumn(
            maxWidth: FrostMetrics.readingMaxWidth,
            sliver: SliverToBoxAdapter(
              child: appBones(
                DownloadSourceScope(
                  source: novelDownloadSource(novelPlaceholder()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: FrostGap.group,
                    children: [
                      _NovelHead(novel: novelPlaceholder()),
                      Wrap(
                        spacing: FrostGap.related,
                        runSpacing: FrostGap.related,
                        children: [
                          FrostButton.prominent(label: t.novel.detail.startReading, icon: PivIcons.newspaper, onPressed: () {}),
                          AppDetailBookmarkButton(bookmarked: false, label: t.novelDetail.bookmark, onPressed: () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
