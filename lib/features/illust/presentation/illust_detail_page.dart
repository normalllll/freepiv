import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_image_viewer.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_layout.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_skeleton.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_related_overlay.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:go_router/go_router.dart';

class IllustDetailPage extends ConsumerWidget {
  const IllustDetailPage({this.illustId, this.illust, super.key}) : assert(illustId != null || illust != null);

  final int? illustId;
  final Illust? illust;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = IllustDetailArgs(illustId: illustId, illust: illust);
    final provider = illustDetailProvider(args);
    final detailValue = ref.watch(provider);

    return detailValue.when(
      data: (illust) => IllustDetailContent(key: ValueKey<String>('illust-detail-content-${illust.id}'), illust: illust),
      loading: () {
        final initialIllust = illust;
        if (initialIllust != null) {
          return IllustDetailContent(key: ValueKey<String>('illust-detail-content-${initialIllust.id}'), illust: initialIllust);
        }

        return const IllustDetailSkeletonPage();
      },
      error: (error, stackTrace) {
        if (_isNotFoundError(error)) {
          return const _IllustNotFoundPage();
        }

        return ErrorPage(message: formatPixivError(error), onRetry: () => ref.read(provider.notifier).reload());
      },
    );
  }
}

class IllustDetailContent extends ConsumerStatefulWidget {
  const IllustDetailContent({required this.illust, super.key});

  final Illust illust;

  @override
  ConsumerState<IllustDetailContent> createState() => _IllustDetailContentState();
}

class _IllustDetailContentState extends ConsumerState<IllustDetailContent> {
  late final PageController _pageController;

  bool get isUgoira => widget.illust.kind == 'ugoira';
  final _loadedImages = LoadedIllustImages();
  int _pageIndex = 0;
  bool _showRelatedWorks = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _ensureRelatedWorksLoaded();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewerQuality = ref.watch(viewerImageQualityProvider);
    final relatedSource = ref.watch(illustRelatedWorksProvider(widget.illust.id));
    final imagePages = illustPageImages(widget.illust, viewerQuality);
    final useDesktopLayout = MediaQuery.sizeOf(context).width >= 900;
    final showRelatedOverlay = _showRelatedWorks && useDesktopLayout;

    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        return Scaffold(
          body: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              IgnorePointer(
                ignoring: showRelatedOverlay,
                child: AnimatedSlide(
                  offset: showRelatedOverlay ? const Offset(0, -1) : Offset.zero,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (shouldUseDesktopShell) {
                        return DesktopIllustDetailLayout(
                          illust: widget.illust,
                          imagePages: imagePages,
                          isUgoira: isUgoira,
                          loadedImages: _loadedImages,
                          pageController: _pageController,
                          pageIndex: _pageIndex,
                          onPageChanged: _setPageIndex,
                          onImageTap: isUgoira ? null : (index) => _openOriginalImageViewer(imagePages, index),
                          onIllustTap: _openIllustDetail,
                          onShowRelatedWorks: _openRelatedWorks,
                        );
                      }
                      return MobileIllustDetailLayout(
                        illust: widget.illust,
                        imagePages: imagePages,
                        isUgoira: isUgoira,
                        loadedImages: _loadedImages,
                        pageController: _pageController,
                        pageIndex: _pageIndex,
                        onPageChanged: _setPageIndex,
                        onImageTap: isUgoira ? null : (index) => _openOriginalImageViewer(imagePages, index),
                        onIllustTap: _openIllustDetail,
                        relatedSource: relatedSource,
                      );
                    },
                  ),
                ),
              ),

              if (showRelatedOverlay)
                IllustRelatedOverlay(
                  visible: true,
                  source: relatedSource,
                  currentIllustId: widget.illust.id,
                  onIllustTap: _openIllustDetail,
                  onClose: _closeRelatedWorks,
                ),
            ],
          ),
          floatingActionButton: useDesktopLayout || showRelatedOverlay
              ? null
              : IllustBookmarkButton(illustId: widget.illust.id, initialIsBookmarked: widget.illust.isBookmarked, floating: true),
        );
      },
    );
  }

  void _setPageIndex(int index) {
    setState(() => _pageIndex = index);
  }

  void _openRelatedWorks() {
    setState(() => _showRelatedWorks = true);
  }

  void _closeRelatedWorks() {
    setState(() => _showRelatedWorks = false);
  }

  void _openIllustDetail(Illust illust) {
    context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': '${illust.id}'}, extra: illust);
  }

  void _openOriginalImageViewer(List<IllustPageImage> imagePages, int index) {
    context.pushNamed(
      AppRoute.originalImageViewer.name,
      extra: OriginalImageViewerArgs(
        workId: widget.illust.id,
        title: widget.illust.title,
        initialIndex: index,
        pages: [for (final image in imagePages) OriginalImagePage(url: image.originalUrl, previewUrl: image.previewUrl, aspectRatio: image.aspectRatio)],
      ),
    );
  }

  void _ensureRelatedWorksLoaded() {
    final source = ref.read(illustRelatedWorksProvider(widget.illust.id));
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }
}

class _IllustNotFoundPage extends StatelessWidget {
  const _IllustNotFoundPage();

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        return Scaffold(
          appBar: shouldUseDesktopShell ? null : AppBar(title: Text(context.t.common.notFound)),
          body: SafeArea(
            child: EmptyContent(icon: Icons.image_not_supported_outlined, title: context.t.common.notFound),
          ),
        );
      },
    );
  }
}

bool _isNotFoundError(Object error) {
  return error is PixivError && error.status == 404;
}
