import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/illust/logic/ugoira_playback.dart';
import 'package:freepiv/features/illust/presentation/artwork_actions.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/media.dart';

/// The detail page's stage: every page contained, paged
/// with edge buttons on hover, the indicator and, for more than one page, a
/// thumbnail strip; an animation plays in place. Tapping a page opens the
/// original image viewer; its menu downloads, copies and opens the work.
class IllustStage extends ConsumerWidget {
  const IllustStage({
    required this.illust,
    required this.pages,
    required this.pager,
    required this.page,
    required this.onPageChanged,
    required this.onOpenViewer,
    this.playback,
    this.heroTag,
    this.strip = true,
    this.overlay,
    super.key,
  });

  final Illust illust;
  final List<ArtworkPageImage> pages;
  final FrostPagerController pager;
  final int page;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onOpenViewer;

  /// The animation of an ugoira; null for still works.
  final UgoiraPlayback? playback;

  /// The opening card's tag: the first page flies in from it.
  final FrostMediaHeroTag? heroTag;

  /// The thumbnail strip under the pages (wide layout).
  final bool strip;

  /// Buttons over the stage's corners (the narrow layout's Back and More).
  final Widget? overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = this.playback;
    final Widget pagesView = playback != null
        ? _UgoiraStage(illust: illust, page: pages.first, playback: playback)
        : FrostPager(
            itemCount: pages.length,
            controller: pager,
            initialPage: page,
            onPageChanged: onPageChanged,
            showsIndicator: pages.length > 1,
            indicatorPlacement: FrostPageIndicatorPlacement.overlay,
            itemBuilder: (context, index) =>
                _StagePage(illust: illust, index: index, pages: pages, heroTag: index == 0 ? heroTag : null, onTap: () => onOpenViewer(index)),
          );
    return Column(
      children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [pagesView, ?overlay]),
        ),
        if (strip && playback == null && pages.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
            child: FrostThumbnailStrip(
              itemCount: pages.length,
              selectedIndex: page,
              size: FrostThumbnailSize.small,
              onSelected: (index) => unawaited(pager.animateTo(index)),
              itemBuilder: (context, index) => AppPixivImage(url: pages[index].previewUrl, aspectRatio: 1, radius: 0),
            ),
          ),
      ],
    );
  }
}

/// The menu of a page: download it or every page, copy it (desktop), copy
/// the link and open the work on Pixiv.
List<FrostMenuEntry> artworkPageMenu(BuildContext context, Illust illust, List<ArtworkPageImage> pages, int index) {
  final t = context.t;
  final page = pages[index];
  return [
    FrostMenuAction(
      t.illust.contextMenu.download,
      leading: const FrostGlyph.icon(PivIcons.download),
      onSelected: () => unawaited(downloadArtworkPage(illust, index, page, origin: DownloadFlight.originOf(context))),
    ),
    if (pages.length > 1)
      FrostMenuAction(
        t.illust.contextMenu.downloadAll,
        leading: const FrostGlyph.icon(PivIcons.images),
        onSelected: () => unawaited(downloadArtworkPages(illust, pages, origin: DownloadFlight.originOf(context))),
      ),
    if (isDesktopPlatform)
      FrostMenuAction(t.illust.contextMenu.copyImage, leading: const FrostGlyph.icon(PivIcons.copy), onSelected: () => unawaited(copyArtworkImage(page))),
    FrostMenuAction(t.illust.contextMenu.copyLink, leading: const FrostGlyph.icon(PivIcons.link), onSelected: () => unawaited(copyArtworkLink(illust.id))),
    FrostMenuAction(
      t.illust.contextMenu.openOriginal,
      leading: const FrostGlyph.icon(PivIcons.externalLink),
      onSelected: () => unawaited(openArtworkOnPixiv(illust.id)),
    ),
  ];
}

class _StagePage extends StatelessWidget {
  const _StagePage({required this.illust, required this.index, required this.pages, required this.heroTag, required this.onTap});

  final Illust illust;
  final int index;
  final List<ArtworkPageImage> pages;
  final FrostMediaHeroTag? heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final page = pages[index];
    final ratio = illust.width > 0 && illust.height > 0 ? illust.width / illust.height : 1.0;
    final image = AppPixivImage(url: page.viewUrl, placeholderUrl: page.previewUrl, aspectRatio: ratio, radius: 0, fit: BoxFit.contain);
    final tag = heroTag;
    return FrostContextMenuRegion(
      entries: artworkPageMenu(context, illust, pages, index),
      child: Semantics(
        button: true,
        label: illust.title,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: FrostMediaStage(
              aspectRatio: ratio,
              child: tag == null
                  ? image
                  : FrostMediaFrame(
                      radius: 0,
                      child: FrostMediaHero(tag: tag, fit: BoxFit.contain, child: image),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An animation: its poster with Play, the stages and progress while it
/// loads, then the frames with a play / pause control at the bottom.
class _UgoiraStage extends StatefulWidget {
  const _UgoiraStage({required this.illust, required this.page, required this.playback});

  final Illust illust;
  final ArtworkPageImage page;
  final UgoiraPlayback playback;

  @override
  State<_UgoiraStage> createState() => _UgoiraStageState();
}

class _UgoiraStageState extends State<_UgoiraStage> {
  Timer? _timer;
  int _frame = 0;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    widget.playback.addListener(_changed);
  }

  @override
  void dispose() {
    widget.playback.removeListener(_changed);
    _timer?.cancel();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    if (widget.playback.frames != null && _timer == null && !_paused) _next();
  }

  void _next() {
    final frames = widget.playback.frames;
    if (frames == null || frames.length <= 1 || _paused) return;
    final delays = widget.playback.delays;
    final delay = delays.isEmpty ? _defaultFrameDelay : delays[_frame.clamp(0, delays.length - 1)];
    _timer = Timer(Duration(milliseconds: math.max(_minimumFrameDelay, delay)), () {
      if (!mounted) return;
      setState(() => _frame = (_frame + 1) % frames.length);
      _next();
    });
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    _timer?.cancel();
    _timer = null;
    if (!_paused) _next();
  }

  Future<void> _play() async {
    try {
      await widget.playback.play();
    } catch (error) {
      toastErrorWithCause(t.illust.toast.downloadFailed, error);
    }
  }

  static const _defaultFrameDelay = 100;
  static const _minimumFrameDelay = 16;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final playback = widget.playback;
    final frames = playback.frames;
    final ratio = widget.illust.width > 0 && widget.illust.height > 0 ? widget.illust.width / widget.illust.height : 1.0;
    final phase = playback.phase;
    final progress = playback.progress;
    return FrostContextMenuRegion(
      entries: [
        FrostMenuAction(
          t.illustDetail.downloadGif,
          leading: const FrostGlyph.icon(PivIcons.download),
          onSelected: () => unawaited(downloadUgoiraGif(playback, widget.illust, page: widget.page, origin: DownloadFlight.originOf(context))),
        ),
        if (isDesktopPlatform)
          FrostMenuAction(t.illustDetail.copyGif, leading: const FrostGlyph.icon(PivIcons.copy), onSelected: () => unawaited(copyUgoiraGif(playback))),
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: FrostMediaStage(
              aspectRatio: ratio,
              child: frames == null || frames.isEmpty
                  ? AppPixivImage(url: widget.page.viewUrl, placeholderUrl: widget.page.previewUrl, aspectRatio: ratio, radius: 0, fit: BoxFit.contain)
                  : FrostMediaFrame(
                      radius: 0,
                      aspectRatio: ratio,
                      child: FrostMediaImage(
                        child: RawImage(image: frames[_frame.clamp(0, frames.length - 1)], fit: BoxFit.contain),
                      ),
                    ),
            ),
          ),
          if (phase == UgoiraPhase.idle || phase == UgoiraPhase.failed)
            Center(
              child: FrostButton.iconOnMedia(
                icon: phase == UgoiraPhase.failed ? PivIcons.refreshCw : PivIcons.play,
                label: phase == UgoiraPhase.failed ? t.common.retry : t.illust.tooltip.play,
                size: FrostControlSize.large,
                onPressed: () => unawaited(_play()),
              ),
            ),
          if (phase.busy)
            Align(
              alignment: Alignment.bottomCenter,
              child: FrostContentColumn(
                maxWidth: FrostMetrics.readingMaxWidth,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: FrostGap.section),
                  child: FrostSurface(
                    role: FrostSurfaceRole.module,
                    child: Padding(
                      padding: const EdgeInsets.all(FrostGap.group),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: FrostGap.related,
                        children: [
                          FrostText(_phaseLabel(t, phase), role: FrostTextRole.footnote, maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (progress != null)
                            FrostProgressBar(value: progress, semanticLabel: _phaseLabel(t, phase))
                          else
                            FrostActivityIndicator(semanticLabel: _phaseLabel(t, phase)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (frames != null && frames.length > 1)
            FrostMediaChrome(
              autoHide: false,
              bottom: Center(
                child: FrostButton.iconOnMedia(
                  icon: _paused ? PivIcons.play : PivIcons.pause,
                  label: _paused ? t.illust.tooltip.play : t.illustDetail.pause,
                  onPressed: _togglePause,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _phaseLabel(Translations t, UgoiraPhase phase) => switch (phase) {
  UgoiraPhase.fetchingMetadata => t.illustDetail.ugoira.metadata,
  UgoiraPhase.downloadingZip => t.illustDetail.ugoira.frames,
  UgoiraPhase.extractingFrames => t.illustDetail.ugoira.extracting,
  UgoiraPhase.decodingFrames => t.illustDetail.ugoira.preparing,
  UgoiraPhase.composingGif => t.illustDetail.ugoira.composing,
  UgoiraPhase.savingGif => t.illustDetail.ugoira.saving,
  UgoiraPhase.idle || UgoiraPhase.ready || UgoiraPhase.failed => '',
};
