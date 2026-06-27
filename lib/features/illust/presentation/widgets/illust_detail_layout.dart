import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_image_viewer.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_panel.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_related_waterfall.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

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
  final ValueChanged<Illust> onIllustTap;
  final VoidCallback onShowRelatedWorks;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final panelWidth = math.min(460.0, math.max(380.0, MediaQuery.sizeOf(context).width * 0.32));

    return ColoredBox(
      color: colorScheme.surface,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IllustImagePager(
                      illustId: illust.id,
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
                  PositionedDirectional(
                    top: 16,
                    end: 16,
                    child: IllustBookmarkButton(illustId: illust.id, initialIsBookmarked: illust.isBookmarked, floating: true),
                  ),
                ],
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),
            SizedBox(
              width: panelWidth,
              child: IllustDetailPanel(illust: illust, onIllustTap: onIllustTap, onShowRelatedWorks: onShowRelatedWorks),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileIllustDetailLayout extends StatelessWidget {
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
    required this.relatedSource,
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
  final ValueChanged<Illust> onIllustTap;
  final IllustRelatedListSource relatedSource;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final imageHeight = math.min(size.height * 0.68, math.max(360.0, size.width * 1.15));

    return AnimatedBuilder(
      animation: relatedSource,
      builder: (context, child) {
        return DataLoadingCustomScrollView(
          slivers: [
            SliverAppBar(pinned: true, title: Text(illust.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: imageHeight,
                child: IllustImagePager(
                  illustId: illust.id,
                  imagePages: imagePages,
                  isUgoira: isUgoira,
                  loadedImages: loadedImages,
                  pageController: pageController,
                  pageIndex: pageIndex,
                  onPageChanged: onPageChanged,
                  onImageTap: onImageTap,
                  showControls: false,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: IllustDetailPanel(illust: illust, onIllustTap: onIllustTap, showRelatedPreview: false, scrollable: false),
            ),
            ...IllustRelatedSlivers.build(context: context, source: relatedSource, currentIllustId: illust.id, onIllustTap: onIllustTap, topPadding: 0),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        );
      },
    );
  }
}
