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
import 'package:freepiv/ui/compositions/page_error.dart';
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
    // The artwork the window is tinted with: the preview the card showed, or
    // for a page opened without one the detail's, and then it stays.
    final artwork = illust ?? shown;
    return FrostWindowTitleContribution(
      path: AppLocations.illust(id),
      page: shown == null
          ? null
          : FrostPageTitle(
              id: id,
              title: shown.title,
              kind: shown.kind,
              imageUrl: illustPreviewImageUrl(artwork!.imageUrls, ref.watch(previewImageQualityProvider)),
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
        child: page,
      ),
    );
  }

  Widget _wide(BuildContext context, IllustInfoContext info, Widget stage) => _wideLayout(
    context,
    stage: stage,
    info: _infoBlocks(
      afterHeading: FrostGap.section,
      heading: IllustInfoHeading(info: info),
      about: IllustAbout(illust: info.illust),
      comments: IllustCommentsPanel(illust: info.illust),
      works: IllustAuthorWorks(illust: info.illust),
      related: IllustRelatedPreview(illust: info.illust),
    ),
  );
}

/// Keys of the info column's blocks, the same in the loaded column and its
/// skeleton.
abstract final class IllustInfoBlocks {
  static const heading = ValueKey('info-heading');
  static const about = ValueKey('info-about');
  static const comments = ValueKey('info-comments');
  static const works = ValueKey('info-works');
  static const related = ValueKey('info-related');
}

/// The info blocks in order, with the gaps between them. The comments stay
/// one row until they are opened, so nothing below moves when they load.
List<Widget> _infoBlocks({
  required double afterHeading,
  required Widget heading,
  required Widget about,
  required Widget comments,
  required Widget works,
  required Widget related,
}) => [
  KeyedSubtree(key: IllustInfoBlocks.heading, child: heading),
  SizedBox(height: afterHeading),
  KeyedSubtree(key: IllustInfoBlocks.about, child: about),
  const SizedBox(height: FrostGap.group),
  KeyedSubtree(key: IllustInfoBlocks.comments, child: comments),
  // The works bring the gap above them, as they may be absent.
  KeyedSubtree(key: IllustInfoBlocks.works, child: works),
  const SizedBox(height: FrostGap.section),
  KeyedSubtree(key: IllustInfoBlocks.related, child: related),
];

/// The stage fixed beside a fixed-width info column, the only scrolling
/// area; the loaded page and its skeleton both lay out through this.
Widget _wideLayout(BuildContext context, {required Widget stage, required List<Widget> info}) {
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
                padding: const EdgeInsets.symmetric(vertical: FrostGap.section),
                sliver: FrostSliverContentColumn(
                  maxWidth: IllustDetailContent.infoWidth,
                  sliver: SliverList.list(children: info),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// The narrow layout: the picture edge to edge scrolls with the
/// info; once it has scrolled away the header shows the title, and the way
/// back no longer flies in from far above the screen.
class _NarrowIllustDetail extends StatefulWidget {
  const _NarrowIllustDetail({required this.info, required this.stage, required this.viewportHeight});

  final IllustInfoContext info;
  final Widget Function({bool strip, Widget? overlay}) stage;
  final double viewportHeight;

  @override
  State<_NarrowIllustDetail> createState() => _NarrowIllustDetailState();
}

class _NarrowIllustDetailState extends State<_NarrowIllustDetail> {
  final _imageKey = GlobalKey();
  bool _imageGone = false;

  /// Whether the picture's bottom is above [line]. The list drops what is far
  /// from the viewport, so a picture that is not there keeps the last answer.
  bool _above(double line) {
    final box = _imageKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return _imageGone;
    final viewport = context.findRenderObject() as RenderBox?;
    if (viewport == null) return _imageGone;
    final bottom = viewport.globalToLocal(box.localToGlobal(Offset(0, box.size.height))).dy;
    return bottom <= line;
  }

  bool _measuring = false;

  /// A scroll is reported before the list lays out, so the picture is read
  /// once the frame has placed it.
  bool _scrolled(ScrollNotification notification) {
    if (_measuring) return false;
    _measuring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measuring = false;
      if (!mounted) return;
      final imageGone = _above(MediaQuery.paddingOf(context).top + FrostPageHeader.verticalHeight);
      if (imageGone != _imageGone) setState(() => _imageGone = imageGone);
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final illust = info.illust;
    final ratio = illust.width > 0 && illust.height > 0 ? illust.width / illust.height : 1.0;
    final header = FrostPageHeader(
      title: _imageGone ? FrostText(illust.title) : null,
      actions: [
        FrostToolbarItem.menu(
          label: FrostScope.labelsOf(context).more,
          icon: PivIcons.more,
          showsLabel: false,
          priority: FrostToolbarPriority.high,
          entries: illustMoreMenu(context, info),
        ),
      ],
    );
    return FrostPinnedChrome(
      chrome: header,
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
                  child: SizedBox(
                    key: _imageKey,
                    height: height,
                    // From far above the screen a flight back would cross it in a blink.
                    child: HeroMode(enabled: !_imageGone, child: widget.stage(strip: false)),
                  ),
                ),
                FrostSliverContentColumn(
                  maxWidth: FrostMetrics.readingMaxWidth,
                  sliver: SliverList.list(
                    children: [
                      const SizedBox(height: FrostGap.group),
                      ..._infoBlocks(
                        afterHeading: FrostGap.group,
                        heading: IllustInfoHeading(info: info),
                        about: IllustAbout(illust: illust),
                        comments: IllustCommentsPanel(illust: illust),
                        works: IllustAuthorWorks(illust: illust),
                        related: IllustRelatedPreview(illust: illust),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// While a work known only by its id loads: the loaded page's own layout,
/// with the stage and every block of the info column as bones of the same
/// size, so nothing moves when the work arrives.
class _IllustDetailSkeleton extends StatelessWidget {
  const _IllustDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= IllustDetailContent.sideBySideFrom && constraints.maxWidth > constraints.maxHeight;
        if (wide) {
          return _wideLayout(
            context,
            stage: Center(child: FrostMediaFrame.skeleton(aspectRatio: 3 / 4, radius: 0)),
            info: _infoBlocks(
              afterHeading: FrostGap.section,
              heading: const IllustInfoHeadingSkeleton(),
              about: const IllustAboutSkeleton(),
              comments: const IllustCommentsPanelSkeleton(),
              works: const IllustAuthorWorksLoading(),
              related: const IllustRelatedLoading(),
            ),
          );
        }
        return FrostPinnedChrome(
          chrome: const FrostPageHeader(),
          body: LayoutBuilder(
            builder: (context, body) => FrostLoadingScrollView(
              key: const ValueKey('illust-narrow'),
              slivers: [
                const FrostChromeSpacer(),
                SliverToBoxAdapter(
                  child: SizedBox(height: math.min(body.maxWidth, constraints.maxHeight), child: FrostMediaFrame.skeleton(aspectRatio: null, radius: 0)),
                ),
                FrostSliverContentColumn(
                  maxWidth: FrostMetrics.readingMaxWidth,
                  sliver: SliverList.list(
                    children: [
                      const SizedBox(height: FrostGap.group),
                      ..._infoBlocks(
                        afterHeading: FrostGap.group,
                        heading: const IllustInfoHeadingSkeleton(),
                        about: const IllustAboutSkeleton(),
                        comments: const IllustCommentsPanelSkeleton(),
                        works: const IllustAuthorWorksLoading(),
                        related: const IllustRelatedLoading(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
