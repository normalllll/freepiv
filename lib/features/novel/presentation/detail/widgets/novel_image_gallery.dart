import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_detail_constraints.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:go_router/go_router.dart';

class NovelImageGallery extends StatefulWidget {
  const NovelImageGallery({required this.novel, required this.webviewNovel, super.key});

  final Novel novel;
  final WebviewNovel webviewNovel;

  @override
  State<NovelImageGallery> createState() => _NovelImageGalleryState();
}

class _NovelImageGalleryState extends State<NovelImageGallery> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = novelExtraImageUrls(widget.novel, widget.webviewNovel);
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return NovelDetailWidthLimiter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IllustSectionTitle(title: context.t.novel.detail.images, icon: Icons.photo_library_outlined),
            const SizedBox(height: 10),
            _NovelImagePager(
              novel: widget.novel,
              imageUrls: imageUrls,
              pageController: _pageController,
              pageIndex: _pageIndex,
              onPageChanged: (index) => setState(() => _pageIndex = index),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovelImagePager extends StatelessWidget {
  const _NovelImagePager({required this.novel, required this.imageUrls, required this.pageController, required this.pageIndex, required this.onPageChanged});

  final Novel novel;
  final List<String> imageUrls;
  final PageController pageController;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
        final height = math.min(560.0, math.max(220.0, maxWidth * 0.72));
        final pageCount = imageUrls.length;

        return SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: pageController,
                itemCount: pageCount,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  final url = imageUrls[index];
                  return NovelGalleryImage(url: url, onTap: () => _openOriginalImageViewer(context, index));
                },
              ),
              if (pageCount > 1)
                PositionedDirectional(
                  bottom: 12,
                  start: 16,
                  end: 16,
                  child: Center(
                    child: _NovelPageIndicator(pageIndex: pageIndex, pageCount: pageCount),
                  ),
                ),
              if (pageCount > 1) ...[
                PositionedDirectional(
                  start: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SurfaceIconButton(
                      icon: Icons.chevron_left,
                      tooltip: context.t.illust.tooltip.previousImage,
                      onPressed: pageIndex == 0 ? null : () => _animateToPage(pageIndex - 1),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SurfaceIconButton(
                      icon: Icons.chevron_right,
                      tooltip: context.t.illust.tooltip.nextImage,
                      onPressed: pageIndex >= pageCount - 1 ? null : () => _animateToPage(pageIndex + 1),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _animateToPage(int index) {
    pageController.animateToPage(index, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
  }

  void _openOriginalImageViewer(BuildContext context, int index) {
    context.pushNamed(
      AppRoute.originalImageViewer.name,
      extra: OriginalImageViewerArgs(
        workId: novel.id,
        title: novel.title,
        initialIndex: index,
        pages: [for (final url in imageUrls) OriginalImagePage(url: url, previewUrl: url)],
      ),
    );
  }
}

class NovelGalleryImage extends StatelessWidget {
  const NovelGalleryImage({required this.url, required this.onTap, super.key});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: PixivImage(url: url, fit: BoxFit.contain, borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _NovelPageIndicator extends StatelessWidget {
  const _NovelPageIndicator({required this.pageIndex, required this.pageCount});

  final int pageIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.58), borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          '${pageIndex + 1} / $pageCount',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
