import 'package:freepiv/features/novel/presentation/novel_download_source.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/shared/layout/fp_pinned_chrome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/window/window_title.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_creator_section.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_detail_constraints.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_header.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_image_gallery.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_not_found_page.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_related_slivers.dart';
import 'package:freepiv/features/novel/presentation/widgets/novel_comments_section.dart';
import 'package:freepiv/features/novel/presentation/widgets/novel_detail_skeleton.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/layout/fp_page_header.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:go_router/go_router.dart';

class NovelDetailPage extends ConsumerWidget {
  const NovelDetailPage({this.novelId, this.novel, super.key}) : assert(novelId != null || novel != null);

  final int? novelId;
  final Novel? novel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = NovelDetailArgs(novelId: novelId, novel: novel);
    final provider = novelDetailProvider(args);
    final detailValue = ref.watch(provider);

    final visibleNovel = detailValue.asData?.value.novel ?? novel;
    final content = detailValue.when(
      skipLoadingOnRefresh: false,
      data: (detail) => NovelDetailContent(key: ValueKey<String>('novel-detail-content-${detail.novel.id}'), detail: detail),
      loading: () => const NovelDetailSkeletonPage(),
      error: (error, stackTrace) {
        if (_isNotFoundError(error)) {
          return const NovelNotFoundPage();
        }

        return ErrorPage.fromError(error: error, onRetry: () => ref.read(provider.notifier).reload());
      },
    );
    final id = novelId ?? novel?.id;
    if (id == null) return content;
    return WindowTitleContribution(
      path: '/novel/$id',
      work: visibleNovel == null ? null : WorkWindowTitle(id: id, title: visibleNovel.title, kind: 'novel', artworkUrl: visibleNovel.imageUrls.squareMedium),
      child: content,
    );
  }
}

class NovelDetailContent extends ConsumerStatefulWidget {
  const NovelDetailContent({required this.detail, super.key});

  final NovelDetailData detail;

  @override
  ConsumerState<NovelDetailContent> createState() => _NovelDetailContentState();
}

class _NovelDetailContentState extends ConsumerState<NovelDetailContent> {
  Novel get _novel => widget.detail.novel;

  WebviewNovel get _webviewNovel => widget.detail.webviewNovel;

  @override
  void initState() {
    super.initState();
    _ensureRelatedWorksLoaded();
  }

  @override
  void didUpdateWidget(covariant NovelDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.novel.id != widget.detail.novel.id) {
      _ensureRelatedWorksLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final relatedSource = ref.watch(novelRelatedWorksProvider(_novel.id));

    return DownloadSourceScope(
      source: novelDownloadSource(_novel),
      child: AutoScaffold(
        builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool useHorizontalLayout) {
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: AnimatedBuilder(
                animation: relatedSource,
                builder: (context, child) {
                  return DataLoadingCustomScrollView(
                    slivers: [
                      if (!useHorizontalLayout)
                        SliverAppBar(
                          // Collapses while the list scrolls on and returns on the way back.
                          floating: true,
                          snap: true,
                          backgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          flexibleSpace: const PinnedChromeGlass(opacity: 1),
                          automaticallyImplyLeading: false,
                          leading: FpPageHeader.leadingFor(context),
                          leadingWidth: FpPageHeader.leadingWidth,
                          titleSpacing: FpPageHeader.titleSpacingOf(context),
                          title: Text(_novel.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      SliverToBoxAdapter(
                        child: NovelHeader(novel: _novel, webviewNovel: _webviewNovel, onStartReading: _openNovelReader),
                      ),
                      SliverToBoxAdapter(
                        child: NovelImageGallery(novel: _novel, webviewNovel: _webviewNovel),
                      ),
                      SliverToBoxAdapter(
                        child: NovelCreatorSection(novel: _novel, onNovelTap: _openNovelDetail),
                      ),
                      SliverToBoxAdapter(
                        child: NovelDetailWidthLimiter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
                            child: NovelCommentsSection(novelId: _novel.id, totalComments: _novel.totalComments),
                          ),
                        ),
                      ),
                      ...NovelRelatedSlivers.build(context: context, source: relatedSource, currentNovelId: _novel.id, onNovelTap: _openNovelDetail),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openNovelDetail(Novel novel) {
    context.pushNamed(AppRoute.novelDetail.name, pathParameters: {'id': '${novel.id}'}, extra: novel);
  }

  Future<void> _openNovelReader() async {
    await context.pushNamed(AppRoute.novelReader.name, pathParameters: {'id': '${_novel.id}'}, extra: _novel);
    if (mounted) setState(() {});
  }

  void _ensureRelatedWorksLoaded() {
    final source = ref.read(novelRelatedWorksProvider(_novel.id));
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }
}

bool _isNotFoundError(Object error) {
  return error is PixivError && error.status == 404;
}
