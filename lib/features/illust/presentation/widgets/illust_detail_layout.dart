import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_image_viewer.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_panel.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_related_section.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

class DesktopIllustDetailLayout extends StatelessWidget {
  const DesktopIllustDetailLayout({
    required this.illust,
    required this.imagePages,
    required this.isUgoira,
    required this.loadedImages,
    required this.pageController,
    required this.pageIndex,
    required this.onPageChanged,
    required this.onImageTap,
    required this.onIllustTap,
    required this.onShowRelatedWorks,
    this.viewerKey,
    super.key,
  });

  final Illust illust;
  final List<IllustPageImage> imagePages;
  final bool isUgoira;
  final LoadedIllustImages loadedImages;
  final PageController pageController;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onImageTap;
  final IllustOpener onIllustTap;
  final VoidCallback onShowRelatedWorks;
  final Key? viewerKey;

  @override
  Widget build(BuildContext context) {
    final panelWidth = math.min(460.0, math.max(380.0, MediaQuery.sizeOf(context).width * 0.32));

    // The artwork stage is transparent: the window backdrop behind it is the
    // work's own blurred colours. The information panel floats beside it.
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: IllustImagePager(
              key: viewerKey,
              artwork: artworkDownloadSource(illust),
              imagePages: imagePages,
              isUgoira: isUgoira,
              loadedImages: loadedImages,
              pageController: pageController,
              pageIndex: pageIndex,
              onPageChanged: onPageChanged,
              onImageTap: onImageTap,
              showControls: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 8, 8),
            child: SizedBox(
              width: panelWidth,
              child: FrostSurface(
                role: FrostSurfaceRole.panel,
                borderRadius: BorderRadius.circular(FrostRadius.xl + 4),
                child: IllustDetailPanel(
                  illust: illust,
                  onIllustTap: onIllustTap,
                  onShowRelatedWorks: onShowRelatedWorks,
                  actions: IllustPageActions(
                    artwork: artworkDownloadSource(illust),
                    pageIndex: pageIndex,
                    imagePages: imagePages,
                    loadedImages: loadedImages,
                    isUgoira: isUgoira,
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

class MobileIllustDetailLayout extends StatefulWidget {
  const MobileIllustDetailLayout({
    required this.illust,
    required this.imagePages,
    required this.isUgoira,
    required this.loadedImages,
    required this.pageController,
    required this.pageIndex,
    required this.onPageChanged,
    required this.onImageTap,
    required this.onIllustTap,
    required this.onShowRelatedWorks,
    this.viewerKey,
    super.key,
  });

  final Illust illust;
  final List<IllustPageImage> imagePages;
  final bool isUgoira;
  final LoadedIllustImages loadedImages;
  final PageController pageController;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onImageTap;
  final IllustOpener onIllustTap;
  final VoidCallback onShowRelatedWorks;
  final Key? viewerKey;

  @override
  State<MobileIllustDetailLayout> createState() => _MobileIllustDetailLayoutState();
}

class _MobileIllustDetailLayoutState extends State<MobileIllustDetailLayout> {
  final _scrollController = ScrollController();
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final leading = FrostPageHeader.leadingFor(context);
    final actions = IllustPageActions(
      artwork: artworkDownloadSource(widget.illust),
      pageIndex: widget.pageIndex,
      imagePages: widget.imagePages,
      loadedImages: widget.loadedImages,
      isUgoira: widget.isUgoira,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Pixiv supplies a work ratio for the detail. Keep one stage for every
        // page, since individual page dimensions are not part of this model.
        final ratio = widget.illust.width > 0 && widget.illust.height > 0 ? widget.illust.width / widget.illust.height : 1.0;
        final width = constraints.maxWidth;
        final imageHeight = (width / ratio).clamp(140.0, math.max(140.0, size.height * .78)).toDouble();
        // The bar appears once the body title (just below the image) has
        // scrolled under it, never as an empty strip over the artwork.
        final titleThreshold = topInset + imageHeight - kToolbarHeight + 24;

        return Stack(
          children: [
            FrostLoadingScrollView(
              key: PageStorageKey<String>('illust-detail-scroll-${widget.illust.id}'),
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topInset)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: imageHeight,
                    child: IllustImagePager(
                      key: widget.viewerKey,
                      artwork: artworkDownloadSource(widget.illust),
                      imagePages: widget.imagePages,
                      isUgoira: widget.isUgoira,
                      loadedImages: widget.loadedImages,
                      pageController: widget.pageController,
                      pageIndex: widget.pageIndex,
                      onPageChanged: widget.onPageChanged,
                      onImageTap: widget.onImageTap,
                      showControls: true,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: IllustDetailPanel(
                    illust: widget.illust,
                    onIllustTap: widget.onIllustTap,
                    showRelatedPreview: false,
                    scrollable: false,
                    actions: actions,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: IllustRelatedSection(illustId: widget.illust.id, onIllustTap: widget.onIllustTap, onShowMore: widget.onShowRelatedWorks),
                  ),
                ),
                // Phones keep room for the floating download button; beside the
                // sidebar the dock lives in the sidebar column instead.
                SliverToBoxAdapter(child: SizedBox(height: FrostAutoScaffold.usesHorizontalLayoutOf(context) ? MediaQuery.paddingOf(context).bottom : 88)),
              ],
            ),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: topInset + kToolbarHeight,
              child: AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) => _CompactTitleBar(
                  coverage: _scrollController.hasClients ? ((_scrollController.offset - titleThreshold) / 24).clamp(0.0, 1.0) : 0,
                  title: widget.illust.title,
                  leading: leading,
                  trailing: IllustBookmarkButton(illustId: widget.illust.id, initialIsBookmarked: widget.illust.isBookmarked),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Narrow detail chrome. At rest only the back control floats over the
/// artwork; after the title scrolls away a glass bar with the title and the
/// nearest action fades in. Beside the sidebar there is no back control here
/// (the sidebar owns it) and the bar floats like every other pinned bar.
class _CompactTitleBar extends StatelessWidget {
  const _CompactTitleBar({required this.coverage, required this.title, required this.leading, required this.trailing});

  final double coverage;
  final String title;
  final Widget? leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    return FrostPinnedChromeGlass(
      opacity: coverage,
      animate: false,
      child: SafeArea(
        bottom: false,
        // Beside the sidebar the glass floats inset from the bar's edges; the
        // controls keep their usual distance from the glass, not the page, so
        // the action does not crowd the rounded end. Without a back control
        // the title then starts on the body's 16 edge.
        child: Padding(
          padding: EdgeInsetsDirectional.zero,
          child: Row(
            children: [
              const SizedBox(width: 4),
              if (leading != null)
                SizedBox.square(
                  dimension: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: 1 - coverage,
                              child: FrostSurface(role: FrostSurfaceRole.chrome, borderRadius: BorderRadius.circular(22), child: const SizedBox.expand()),
                            ),
                          ),
                        ),
                      ),
                      leading,
                    ],
                  ),
                ),
              Expanded(
                child: ExcludeSemantics(
                  excluding: coverage == 0,
                  child: Opacity(
                    opacity: coverage,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: coverage == 0,
                child: ExcludeFocus(
                  excluding: coverage == 0,
                  child: ExcludeSemantics(
                    excluding: coverage == 0,
                    child: Opacity(opacity: coverage, child: trailing),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
