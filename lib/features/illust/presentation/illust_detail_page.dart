import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/logic/ugoira_playback.dart';
import 'package:freepiv/features/illust/presentation/artwork_actions.dart';
import 'package:freepiv/features/illust/presentation/illust_info.dart';
import 'package:freepiv/features/illust/presentation/illust_stage.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/media.dart';
import 'package:go_router/go_router.dart';

/// The illustration, manga and animation page. A work
/// handed over by a list shows at once; one known only by its id loads.
class IllustDetailPage extends ConsumerWidget {
  const IllustDetailPage({this.illustId, this.illust, this.heroTag, super.key}) : assert(illustId != null || illust != null);

  final int? illustId;
  final Illust? illust;
  final FrostMediaHeroTag? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = illustDetailProvider(IllustDetailArgs(illustId: illustId, illust: illust));
    final value = ref.watch(provider);
    final shown = value.asData?.value ?? illust;
    final Widget content = switch (value) {
      AsyncValue(:final value?) => IllustDetailContent(key: ValueKey(value.id), illust: value, heroTag: heroTag),
      // Riverpod keeps the error while it retries an exception.
      AsyncValue(:final error?) when shown == null =>
        _missing(error)
            ? AppPageError.notFound(message: context.t.illustDetail.missing)
            : AppPageError.fromError(error: error, onRetry: () => unawaited(ref.read(provider.notifier).reload())),
      _ when shown != null => IllustDetailContent(key: ValueKey(shown.id), illust: shown, heroTag: heroTag),
      _ => const _IllustDetailSkeleton(),
    };
    final id = illustId ?? illust?.id;
    if (id == null) return content;
    return FrostWindowTitleContribution(
      path: AppLocations.illust(id),
      page: shown == null
          ? null
          : FrostPageTitle(
              id: id,
              title: shown.title,
              kind: shown.kind,
              imageUrl: illustPreviewImageUrl(shown.imageUrls, ref.watch(previewImageQualityProvider)),
            ),
      child: content,
    );
  }

  /// Missing, or not visible to this account.
  static bool _missing(Object error) => error is PixivError && (error.status == 404 || error.status == 403);
}

class IllustDetailContent extends ConsumerStatefulWidget {
  const IllustDetailContent({required this.illust, this.heroTag, super.key});

  final Illust illust;
  final FrostMediaHeroTag? heroTag;

  /// Narrower content, or a portrait one, stacks the stage over the info.
  static const sideBySideFrom = 900.0;

  /// The info column beside the stage.
  static const infoWidth = 380.0;

  @override
  ConsumerState<IllustDetailContent> createState() => _IllustDetailContentState();
}

class _IllustDetailContentState extends ConsumerState<IllustDetailContent> {
  final _pager = FrostPagerController();
  final _stageKey = GlobalKey();
  late final UgoiraPlayback? _playback = widget.illust.kind == 'ugoira' ? UgoiraPlayback(widget.illust.id) : null;
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    _playback?.dispose();
    super.dispose();
  }

  void _openViewer(List<ArtworkPageImage> pages, int index) {
    final illust = widget.illust;
    unawaited(
      GoRouter.of(context).push(
        AppRoute.originalImageViewer.path,
        extra: OriginalImageViewerArgs(
          title: illust.title.trim().isNotEmpty ? illust.title : t.nativeWindow.workFallback(type: t.nativeWindow.illust, id: '${illust.id}'),
          source: artworkSourceOf(illust),
          initialIndex: index,
          pages: [
            for (final (pageIndex, page) in pages.indexed)
              OriginalImagePage(
                url: page.originalUrl,
                previewUrl: page.previewUrl,
                downloadOrigin: ArtworkPage(illustId: illust.id, pageIndex: pageIndex),
              ),
          ],
        ),
      ),
    );
  }

  void _turn(int by, int count) {
    final next = (_page + by).clamp(0, count - 1);
    if (next != _page) unawaited(_pager.animateTo(next));
  }

  @override
  Widget build(BuildContext context) {
    final illust = widget.illust;
    final pages = artworkPages(illust, ref.watch(viewerImageQualityProvider), ref.watch(previewImageQualityProvider));
    final info = IllustInfoContext(illust: illust, pages: pages, page: _page, playback: _playback);
    final previewUrl = pages.first.previewUrl;
    Widget stage({bool strip = true, Widget? overlay}) => KeyedSubtree(
      key: _stageKey,
      child: IllustStage(
        illust: illust,
        pages: pages,
        pager: _pager,
        page: _page,
        playback: _playback,
        heroTag: widget.heroTag,
        strip: strip,
        overlay: overlay,
        onPageChanged: (page) => setState(() => _page = page),
        onOpenViewer: (index) => _openViewer(pages, index),
      ),
    );
    final Widget page = LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= IllustDetailContent.sideBySideFrom && constraints.maxWidth > constraints.maxHeight;
        return wide ? _wide(context, info, stage()) : _NarrowIllustDetail(info: info, stage: stage, viewportHeight: constraints.maxHeight);
      },
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _turn(-1, pages.length),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _turn(1, pages.length),
      },
      child: Focus(
        autofocus: true,
        child: previewUrl.isEmpty ? page : FrostAmbientBackdrop.fromImage(image: pixivImageProvider(ref, previewUrl), stageKey: _stageKey, child: page),
      ),
    );
  }

  /// The stage fixed beside a fixed-width info column, the only scrolling
  /// area.
  Widget _wide(BuildContext context, IllustInfoContext info, Widget stage) {
    final back = FrostPageHeader.leadingFor(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SafeArea(
            right: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                stage,
                if (back != null) PositionedDirectional(top: FrostGap.related, start: FrostGap.related, child: back),
              ],
            ),
          ),
        ),
        SizedBox(
          width: IllustDetailContent.infoWidth,
          child: SafeArea(
            left: false,
            child: FrostLoadingScrollView(
              key: const ValueKey('illust-info'),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(FrostGap.section),
                  sliver: SliverList.list(
                    children: [
                      IllustInfoHeading(info: info),
                      const SizedBox(height: FrostGap.section),
                      IllustAbout(illust: info.illust),
                      const SizedBox(height: FrostGap.section),
                      IllustCommentsPreview(illust: info.illust),
                      const SizedBox(height: FrostGap.section),
                      IllustAuthorWorks(illust: info.illust),
                      const SizedBox(height: FrostGap.section),
                      IllustRelatedPreview(illust: info.illust),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The narrow layout: the picture edge to edge scrolls with the
/// info; once it has scrolled away the header shows the title, and the
/// About / Comments tabs stay under it once they reach it.
class _NarrowIllustDetail extends StatefulWidget {
  const _NarrowIllustDetail({required this.info, required this.stage, required this.viewportHeight});

  final IllustInfoContext info;
  final Widget Function({bool strip, Widget? overlay}) stage;
  final double viewportHeight;

  @override
  State<_NarrowIllustDetail> createState() => _NarrowIllustDetailState();
}

class _NarrowIllustDetailState extends State<_NarrowIllustDetail> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this, animationDuration: Duration.zero)..addListener(() => setState(() {}));
  final _imageKey = GlobalKey();
  final _tabsKey = GlobalKey();
  bool _imageGone = false;
  bool _tabsPinned = false;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _above(GlobalKey key, double line) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return false;
    final viewport = context.findRenderObject() as RenderBox?;
    if (viewport == null) return false;
    final bottom = viewport.globalToLocal(box.localToGlobal(Offset(0, box.size.height))).dy;
    return bottom <= line;
  }

  bool _scrolled(ScrollNotification notification) {
    final header = MediaQuery.paddingOf(context).top + FrostPageHeader.verticalHeight;
    final imageGone = _above(_imageKey, header);
    final tabsPinned = _above(_tabsKey, header);
    if (imageGone != _imageGone || tabsPinned != _tabsPinned) {
      setState(() {
        _imageGone = imageGone;
        _tabsPinned = tabsPinned;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final info = widget.info;
    final illust = info.illust;
    final ratio = illust.width > 0 && illust.height > 0 ? illust.width / illust.height : 1.0;
    final tabBar = FrostTabBar(
      controller: _tabs,
      scrollable: true,
      tabs: [
        FrostTab(label: t.illustDetail.tabs.about),
        FrostTab(label: t.illustDetail.tabs.comments),
      ],
    );
    final header = FrostPageHeader(
      title: _imageGone ? FrostText(illust.title) : null,
      actions: [FrostToolbarItem.menu(label: FrostScope.labelsOf(context).more, icon: PivIcons.more, entries: illustMoreMenu(context, info))],
    );
    return FrostMediaSystemChrome(
      active: !_imageGone,
      child: FrostPinnedChrome(
        chrome: _tabsPinned ? FrostHeaderSections(header: header, tabs: tabBar) : header,
        body: NotificationListener<ScrollNotification>(
          onNotification: _scrolled,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // A very long picture stops at one screen.
              final height = math.min(constraints.maxWidth / ratio, widget.viewportHeight);
              return FrostLoadingScrollView(
                key: const ValueKey('illust-narrow'),
                slivers: [
                  const FrostChromeSpacer(),
                  SliverToBoxAdapter(
                    child: SizedBox(key: _imageKey, height: height, child: widget.stage(strip: false)),
                  ),
                  FrostSliverContentColumn(
                    maxWidth: FrostMetrics.readingMaxWidth,
                    sliver: SliverList.list(
                      children: [
                        const SizedBox(height: FrostGap.group),
                        IllustInfoHeading(info: info),
                        const SizedBox(height: FrostGap.group),
                        Opacity(
                          opacity: _tabsPinned ? 0 : 1,
                          child: KeyedSubtree(key: _tabsKey, child: tabBar),
                        ),
                        const SizedBox(height: FrostGap.group),
                        if (_tabs.index == 0) ...[
                          IllustAbout(illust: illust),
                          const SizedBox(height: FrostGap.section),
                          IllustAuthorWorks(illust: illust),
                          const SizedBox(height: FrostGap.section),
                          IllustRelatedPreview(illust: illust),
                        ] else
                          IllustCommentsPreview(illust: illust),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// While a work known only by its id loads: the stage and the info column
/// at their size.
class _IllustDetailSkeleton extends StatelessWidget {
  const _IllustDetailSkeleton();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= IllustDetailContent.sideBySideFrom && constraints.maxWidth > constraints.maxHeight;
      final info = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FrostListRow.skeleton(title: 'A sample work title', icon: false, subtitle: null, value: null),
          FrostListRow.skeleton(title: 'Sample artist', icon: true, subtitle: null, value: null),
          const AppRowsSkeleton(count: 3, subtitle: false),
        ],
      );
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(child: FrostMediaFrame.skeleton(aspectRatio: 3 / 4, radius: 0)),
            ),
            SizedBox(
              width: IllustDetailContent.infoWidth,
              child: SafeArea(child: info),
            ),
          ],
        );
      }
      return FrostPinnedChrome(
        chrome: const FrostPageHeader(),
        body: FrostLoadingScrollView(
          slivers: [
            const FrostChromeSpacer(),
            SliverToBoxAdapter(child: FrostMediaFrame.skeleton(aspectRatio: 1, radius: 0)),
            FrostSliverContentColumn(
              maxWidth: FrostMetrics.readingMaxWidth,
              sliver: SliverToBoxAdapter(child: info),
            ),
          ],
        ),
      );
    },
  );
}
