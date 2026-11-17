import 'dart:async';

import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/features/comments/presentation/comment_thread_item.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/logic/novel_series_progress.dart';
import 'package:freepiv/features/novel/logic/novel_structure.dart';
import 'package:freepiv/features/novel/logic/reading_progress.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_about.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_actions.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_author_novels.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_facts.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_head.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_illustrations.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_series_block.dart';
import 'package:freepiv/features/novel/presentation/novel_download_source.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart' show WebviewNovel;
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The novel page. Wide windows put the cover, the reading button and the
/// facts in a column beside the title, caption, series and illustrations; a
/// narrow window stacks them, and a phone pins the reading button in a bar at
/// the bottom. Comments, the author's other novels and related novels follow
/// below. The text loads apart: when it fails the page stays usable and only
/// reading waits for a retry.
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

/// How the page lays out at the width it has.
enum _Layout { wide, narrow }

/// The content width from which the page has two columns.
const _wideFrom = 960.0;

/// The width from which a narrow page puts the title block beside the cover.
const _sideBySideFrom = 600.0;

const _leftColumn = 300.0;

/// The cover's width beside the title block.
const _sideCoverWidth = 160.0;

class NovelDetailContent extends ConsumerStatefulWidget {
  const NovelDetailContent({required this.novel, super.key});

  final Novel novel;

  @override
  ConsumerState<NovelDetailContent> createState() => _NovelDetailContentState();
}

class _NovelDetailContentState extends ConsumerState<NovelDetailContent> {
  final _scroll = ScrollController();
  final _titleKey = GlobalKey();
  final _chromeKey = GlobalKey();
  bool _titleGone = false;

  /// Where the title block ends, in the scrolled content; its last place stands
  /// while the list has dropped it.
  double _titleBottom = 0;

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

  /// Once the title block has gone under the header, the header carries the
  /// title and the reading button.
  void _scrolled() {
    final box = _titleKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      _titleBottom = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset + box.size.height;
    }
    // The height the pinned header covers, which the content under it starts below.
    final header = _chromeKey.currentContext == null ? 0.0 : MediaQuery.paddingOf(_chromeKey.currentContext!).top;
    final gone = _titleBottom > 0 && _titleBottom - _scroll.offset <= header;
    if (gone != _titleGone) setState(() => _titleGone = gone);
  }

  Future<void> _read() async {
    await GoRouter.of(context).push(AppLocations.novelReader(_novel.id), extra: _novel);
    // The reader may have moved the progress of this novel in its series.
    ref.invalidate(novelBatchReadingProgressProvider);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final text = ref.watch(novelTextProvider(_novel.id));
    final webview = text.value;
    final readable = webview?.text.trim().isNotEmpty ?? false;
    final progress = ref.watch(novelReadingProgressProvider(_novel.id)).value;
    final phone = FrostSizeClass.of(context) == FrostSizeClass.compact;
    final readLabel = progress == null ? t.novel.detail.startReading : t.novel.detail.continueReading(percent: progress.percent);
    final related = ref.watch(novelRelatedWorksProvider(_novel.id));
    void read() => unawaited(_read());
    final onRead = readable ? read : null;
    final textFailed = text.hasError && !text.isLoading;
    final structure = ref.watch(novelStructureProvider(_novel.id));
    final Widget scroll = FrostLoadingScrollView(
      controller: _scroll,
      slivers: [
        FrostChromeSpacer(key: _chromeKey),
        FrostSliverContentColumn(
          sliver: SliverToBoxAdapter(
            child: KeyedSubtree(
              key: const ValueKey('detail-head'),
              child: _DetailHead(
                titleKey: _titleKey,
                novel: _novel,
                webview: webview,
                phone: phone,
                controls: (inline) => _Controls(
                  novel: _novel,
                  progress: progress,
                  onRead: onRead,
                  phone: phone,
                  inline: inline,
                  textFailed: textFailed,
                  onRetry: () => unawaited(ref.read(novelTextProvider(_novel.id).notifier).reload()),
                ),
                about: NovelAbout(novel: _novel, caption: webview?.caption),
                facts: NovelFacts(novel: _novel, structure: structure, loading: text.isLoading),
                images: NovelIllustrations(novel: _novel, pictures: structure?.pictures ?? const []),
                showControlsOnPhone: textFailed,
              ),
            ),
          ),
        ),
        FrostSliverContentColumn(
          sliver: SliverList.list(
            children: [
              const SizedBox(height: FrostGap.section),
              AppCommentsPreview(
                value: ref.watch(novelCommentsProvider(_novel.id)),
                total: _novel.totalComments,
                onRetry: () => unawaited(ref.read(novelCommentsProvider(_novel.id).notifier).reload()),
                location: AppLocations.novelComments(_novel.id),
              ),
              const SizedBox(height: FrostGap.section),
              NovelAuthorNovels(novel: _novel),
              const SizedBox(height: FrostGap.section),
              FrostSectionHeader(title: t.novelDetail.related),
            ],
          ),
        ),
        FrostSliverContentColumn(
          sliver: FrostSliverDataList<Novel>(
            source: related,
            firstLoadSkeleton: const AppNovelRowsSkeleton(),
            empty: FrostText(t.novelDetail.noRelated, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
            itemBuilder: (context, novel, index) => AppNovelRow(novel: novel),
          ),
        ),
      ],
    );
    return DownloadSourceScope(
      source: novelDownloadSource(_novel),
      child: FrostPinnedChrome(
        chrome: FrostContentColumn(
          child: FrostPageHeader(
            title: _titleGone ? FrostText(_novel.title) : null,
            actions: [
              if (_titleGone && readable && !phone) FrostToolbarItem.action(icon: PivIcons.newspaper, label: readLabel, showsLabel: true, onPressed: read),
            ],
          ),
        ),
        body: phone
            ? Column(
                children: [
                  Expanded(child: scroll),
                  NovelBottomActionBar(novel: _novel, progress: progress, onRead: onRead),
                ],
              )
            : scroll,
      ),
    );
  }
}

/// The head of the page: cover, title block and controls, then what follows
/// them in the layout the width allows. The skeleton builds it from a
/// placeholder novel with the pieces that need data left out, so the cover,
/// the title and the controls sit where the loaded ones will.
class _DetailHead extends StatelessWidget {
  const _DetailHead({
    required this.novel,
    required this.webview,
    required this.phone,
    required this.controls,
    this.titleKey,
    this.about,
    this.facts,
    this.images,
    this.showControlsOnPhone = false,
  });

  final Novel novel;
  final WebviewNovel? webview;
  final bool phone;

  /// The controls, told whether the read button and the bookmark row share a row.
  final Widget Function(bool inline) controls;

  /// Names the title block, for what follows its scrolling.
  final GlobalKey? titleKey;
  final Widget? about;
  final Widget? facts;
  final Widget? images;

  /// Whether the controls are in the page on a phone, which otherwise leaves them to the bottom bar.
  final bool showControlsOnPhone;

  @override
  Widget build(BuildContext context) {
    final novel = this.novel;
    final seriesBlock = switch (novel.series) {
      Series(:final id?, :final title?) when about != null => NovelSeriesBlock(novel: novel, seriesId: id, title: title),
      _ => null,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = constraints.maxWidth >= _wideFrom ? _Layout.wide : _Layout.narrow;
        // Where both fit, the read button and the bookmark row share one row.
        final controls = this.controls(layout == _Layout.narrow);
        return switch (layout) {
          _Layout.wide => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FrostGap.section,
            children: [
              SizedBox(
                width: _leftColumn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: FrostGap.group,
                  children: [
                    NovelCover(novel: novel, webview: webview, width: _leftColumn),
                    controls,
                    ?facts,
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: FrostGap.section,
                  children: [
                    NovelTitleBlock(key: titleKey, novel: novel, webview: webview, titleRole: FrostTextRole.title1),
                    ?about,
                    ?seriesBlock,
                    ?images,
                  ],
                ),
              ),
            ],
          ),
          _Layout.narrow => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostGap.section,
            children: [
              if (constraints.maxWidth >= _sideBySideFrom)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostGap.section,
                  children: [
                    NovelCover(novel: novel, webview: webview, width: _sideCoverWidth),
                    // The title at the cover's top and the controls at its bottom: the cover is
                    // taller than the title block, and the controls keep their place whatever the title.
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: _sideCoverWidth / NovelCover.ratio),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: FrostGap.group,
                          children: [
                            NovelTitleBlock(key: titleKey, novel: novel, webview: webview),
                            if (!phone || showControlsOnPhone) controls,
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: FrostGap.group,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: NovelCover(novel: novel, webview: webview, width: 140),
                    ),
                    NovelTitleBlock(key: titleKey, novel: novel, webview: webview),
                  ],
                ),
              if (constraints.maxWidth < _sideBySideFrom && (!phone || showControlsOnPhone)) controls,
              ?about,
              ?facts,
              ?seriesBlock,
              ?images,
            ],
          ),
        };
      },
    );
  }
}

/// The read button and the secondary row, which a phone leaves to its bottom
/// bar, and the retry that follows a text that failed to load.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.novel,
    required this.progress,
    required this.onRead,
    required this.phone,
    required this.inline,
    required this.textFailed,
    required this.onRetry,
  });

  final Novel novel;
  final ReadingProgress? progress;
  final VoidCallback? onRead;
  final bool phone;

  /// Read, bookmark and More on one row rather than stacked.
  final bool inline;
  final bool textFailed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.group,
      children: [
        if (!phone && inline)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FrostGap.related,
            children: [
              Expanded(
                child: NovelReadButton(progress: progress, onPressed: onRead),
              ),
              NovelSecondaryActions(novel: novel, fill: false),
            ],
          )
        else if (!phone) ...[
          NovelReadButton(progress: progress, onPressed: onRead),
          NovelSecondaryActions(novel: novel),
        ],
        if (textFailed)
          Row(
            children: [
              Expanded(
                child: FrostText(t.novelText.loadFailed, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
              ),
              FrostButton.quiet(label: t.common.retry, onPressed: onRetry),
            ],
          ),
      ],
    );
  }
}

class _NovelDetailSkeleton extends StatelessWidget {
  const _NovelDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final placeholder = novelPlaceholder();
    final phone = FrostSizeClass.of(context) == FrostSizeClass.compact;
    final scroll = FrostLoadingScrollView(
      slivers: [
        const FrostChromeSpacer(),
        FrostSliverContentColumn(
          sliver: SliverToBoxAdapter(
            child: appBones(
              DownloadSourceScope(
                source: novelDownloadSource(placeholder),
                child: _DetailHead(
                  novel: placeholder,
                  webview: null,
                  phone: phone,
                  controls: (inline) =>
                      _Controls(novel: placeholder, progress: null, onRead: () {}, phone: phone, inline: inline, textFailed: false, onRetry: () {}),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return FrostPinnedChrome(
      chrome: const FrostPageHeader(),
      body: phone
          ? Column(
              children: [
                Expanded(child: scroll),
                appBones(NovelBottomActionBar(novel: placeholder, progress: null, onRead: () {})),
              ],
            )
          : scroll,
    );
  }
}
