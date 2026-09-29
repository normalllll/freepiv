import 'package:flutter/material.dart';
import 'package:freepiv/core/downloads/models/download_origin.dart';
import 'package:freepiv/core/utils/illust_image_url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/window/window_title.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_image_viewer.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_layout.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_skeleton.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/shared/layout/fp_page_header.dart';
import 'package:freepiv/shared/ui/layout_crossfade.dart';

class IllustDetailPage extends ConsumerWidget {
  const IllustDetailPage({this.illustId, this.illust, super.key}) : assert(illustId != null || illust != null);

  final int? illustId;
  final Illust? illust;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = IllustDetailArgs(illustId: illustId, illust: illust);
    final provider = illustDetailProvider(args);
    final detailValue = ref.watch(provider);

    final visibleIllust = detailValue.asData?.value ?? illust;
    final content = detailValue.when(
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

        return ErrorPage.fromError(error: error, onRetry: () => ref.read(provider.notifier).reload());
      },
    );
    final id = illustId ?? illust?.id;
    if (id == null) return content;
    return WindowTitleContribution(
      path: '/illust/$id',
      work: visibleIllust == null
          ? null
          // The list tile's own image: its bytes are already cached, so the
          // backdrop tint arrives with the page transition, not after it.
          : WorkWindowTitle(
              id: id,
              title: visibleIllust.title,
              kind: visibleIllust.kind,
              artworkUrl: illustPreviewImageUrl(visibleIllust.imageUrls, ref.watch(previewImageQualityProvider)),
            ),
      child: content,
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
  final GlobalKey _viewerKey = GlobalKey(debugLabel: 'illust-detail-viewer');

  bool get isUgoira => widget.illust.kind == 'ugoira';
  final _loadedImages = LoadedIllustImages();
  int _pageIndex = 0;

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
    final imagePages = illustPageImages(widget.illust, viewerQuality, ref.watch(previewImageQualityProvider));

    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool useHorizontalLayout) {
        final splitDetail = layout.width >= 960;
        return Scaffold(
          body: LayoutCrossfade(
            layoutIdentity: splitDetail,
            child: splitDetail
                ? DesktopIllustDetailLayout(
                    key: PageStorageKey<String>('illust-detail-wide-${widget.illust.id}'),
                    viewerKey: _viewerKey,
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
                  )
                : MobileIllustDetailLayout(
                    key: PageStorageKey<String>('illust-detail-narrow-${widget.illust.id}'),
                    viewerKey: _viewerKey,
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
                  ),
          ),
        );
      },
    );
  }

  void _setPageIndex(int index) {
    setState(() => _pageIndex = index);
  }

  void _openRelatedWorks() {
    context.pushNamed(AppRoute.illustRelated.name, pathParameters: {'id': '${widget.illust.id}'}, extra: widget.illust);
  }

  void _openIllustDetail(Illust illust, ArtworkHeroTag heroTag) => openIllustDetail(context, illust, heroTag);

  void _openOriginalImageViewer(List<IllustPageImage> imagePages, int index) {
    context.pushNamed(
      AppRoute.originalImageViewer.name,
      extra: OriginalImageViewerArgs(
        title: widget.illust.title.trim().isNotEmpty
            ? widget.illust.title
            : t.nativeWindow.workFallback(type: t.nativeWindow.illust, id: '${widget.illust.id}'),
        initialIndex: index,
        pages: [
          for (final (pageIndex, image) in imagePages.indexed)
            OriginalImagePage(
              url: image.originalUrl,
              previewUrl: image.previewUrl,
              downloadOrigin: ArtworkPage(illustId: widget.illust.id, pageIndex: pageIndex),
              aspectRatio: image.aspectRatio,
            ),
        ],
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
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool useHorizontalLayout) {
        return Scaffold(
          appBar: useHorizontalLayout ? null : FpPageHeader(title: Text(context.t.common.notFound)),
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
