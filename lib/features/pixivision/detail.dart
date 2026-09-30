import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/shared/data/data_list_source.dart';
import 'package:freepiv/shared/widgets/load_state_switcher.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/refresh_dots.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'logic.dart';
import 'navigation.dart';
import 'widgets.dart';
import 'article_blocks.dart';
import 'description.dart';
import 'image.dart';

class PixivisionArticlePage extends ConsumerStatefulWidget {
  const PixivisionArticlePage({required this.url, this.summary, super.key});
  final String url;
  final ArticleSummary? summary;
  @override
  ConsumerState<PixivisionArticlePage> createState() => _PixivisionArticlePageState();
}

class _PixivisionArticlePageState extends ConsumerState<PixivisionArticlePage> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pixivisionArticleProvider(widget.url));
    final document = state.value;
    final article = document?.article;
    return PixivisionScaffold(
      title: pixivisionArticleTitle(article?.title ?? 'pixivision'),
      child: DotsRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pixivisionArticleProvider(widget.url));
          await ref.read(pixivisionArticleProvider(widget.url).future);
        },
        child: LayoutBuilder(
          builder: (context, constraints) => LoadStateSwitcher(
            phase: switch (article) {
              null when state.hasError => LoadPhase.error,
              null => LoadPhase.loading,
              _ => LoadPhase.content,
            },
            child: _buildPhase(context, state, article, document, constraints),
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(BuildContext context, AsyncValue<PixivisionDocument> state, Article? article, PixivisionDocument? document, BoxConstraints constraints) {
    if (article == null) {
      return ListView(
        padding: pixivisionReadingPadding(constraints.maxWidth),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (state.hasError)
            PixivisionError(error: state.error, retry: () => ref.invalidate(pixivisionArticleProvider(widget.url)))
          else ...[
            _ArticleHeader(summary: widget.summary, onLink: (_) {}),
            const SizedBox(height: 16),
            const _ArticleBodySkeleton(),
          ],
        ],
      );
    }
    return DownloadSourceScope(
      source: PixivisionSource(articleId: article.id, url: article.url, title: article.title, thumbnailUrl: article.thumbnail),
      child: _ArticleContent(article: article, imageRatios: document!.imageRatios, controller: _scroll),
    );
  }
}

class _ArticleContent extends StatefulWidget {
  const _ArticleContent({required this.article, required this.imageRatios, required this.controller});
  final Article article;
  final ScrollController controller;
  final Map<String, double> imageRatios;
  @override
  State<_ArticleContent> createState() => _ArticleContentState();
}

class _ArticleContentState extends State<_ArticleContent> {
  final _keys = <int, GlobalKey>{};
  void _open(String value) {
    final uri = Uri.parse(widget.article.url).resolve(value);
    if (uri.fragment.isNotEmpty && uri.replace(fragment: '').toString() == Uri.parse(widget.article.url).replace(fragment: '').toString()) {
      final index = widget.article.blocks.indexWhere((block) => block.anchor == uri.fragment);
      final target = _keys[index]?.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250),
          alignment: 0.05,
        );
      }
      return;
    }
    openPixivisionLink(context, uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final t = context.t.pixivision;
    final related = [
      ...article.related,
      ArticleSection(title: t.ranking, articles: article.monthlyRanking),
      ArticleSection(title: t.recommended, articles: article.recommended),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: widget.controller,
        padding: pixivisionReadingPadding(constraints.maxWidth),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ArticleHeader(article: article, onLink: _open),
            const SizedBox(height: 16),
            for (var index = 0; index < article.blocks.length; index++)
              Padding(
                key: _keys.putIfAbsent(index, GlobalKey.new),
                padding: EdgeInsets.only(bottom: pixivisionBlockHasContent(article.blocks[index]) ? 12 : 0),
                child: PixivisionBlock(block: article.blocks[index], imageRatios: widget.imageRatios, onLink: _open),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (article.previousUrl case final url?)
                  OutlinedButton.icon(onPressed: () => _open(url), icon: const Icon(Icons.chevron_left), label: Text(t.previous)),
                if (article.nextUrl case final url?)
                  OutlinedButton.icon(onPressed: () => _open(url), icon: const Icon(Icons.chevron_right), label: Text(t.next)),
              ],
            ),
            for (final section in related)
              if (section.articles.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(section.title, style: Theme.of(context).textTheme.titleLarge)),
                      if (section.url case final url?) TextButton(onPressed: () => _open(url), child: Text(t.loadMore)),
                    ],
                  ),
                ),
                for (final item in section.articles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PixivisionCard(article: item),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class _ArticleHeader extends StatelessWidget {
  const _ArticleHeader({this.article, this.summary, required this.onLink});
  final Article? article;
  final ArticleSummary? summary;
  final ValueChanged<String> onLink;
  @override
  Widget build(BuildContext context) {
    final t = context.t.pixivision;
    final loaded = article;
    final category = loaded?.category ?? summary?.category;
    final tags = loaded?.tags ?? summary?.tags ?? const <PixivisionTag>[];
    final thumbnail = loaded == null ? summary?.thumbnail : pixivisionHeaderThumbnail(loaded);
    final description = loaded == null ? null : pixivisionHeaderDescription(loaded);
    return Skeletonizer(
      enabled: article == null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableText(
                  pixivisionArticleTitle(article?.title ?? summary?.title ?? 'Article title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: t.openOriginal,
                onPressed: article == null ? null : () => openPixivisionExternalLink(context, article!.url),
                icon: const Icon(Icons.open_in_new),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(pixivisionDate(context, article?.publishDate ?? summary?.publishDate ?? '')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (category != null) ActionChip(label: Text(category.title), onPressed: () => onLink(category.url)),
              for (final tag in tags) ActionChip(label: Text('#${tag.name}'), onPressed: () => onLink(tag.url)),
              AppMenuAnchor(
                menuChildren: [
                  for (final item in article?.translations ?? const <ArticleLink>[]) AppMenuItem(onPressed: () => onLink(item.url), child: Text(item.title)),
                ],
                builder: (context, focusNode, toggle) => ActionChip(
                  focusNode: focusNode,
                  avatar: const Icon(Icons.translate, size: 18),
                  label: Text(t.translations),
                  onPressed: (article?.translations.isNotEmpty ?? false) ? toggle : null,
                ),
              ),
            ],
          ),
          if (thumbnail != null) ...[
            const SizedBox(height: 20),
            // While the article loads the banner is a fixed bone: probing the
            // thumbnail here resized the skeleton once, and the loaded page
            // may place or drop the banner anyway, which resized it again.
            if (loaded == null)
              const AspectRatio(aspectRatio: pixivisionBannerRatio, child: ImageLoadingSkeleton())
            else
              PixivisionImageMenu(
                url: thumbnail,
                title: loaded.title,
                child: PixivisionImage(url: thumbnail, fit: BoxFit.contain, resolveAspectRatio: true, placeholderRatio: pixivisionBannerRatio),
              ),
          ],
          if (description != null) ...[const SizedBox(height: 20), SelectableText(description, style: Theme.of(context).textTheme.bodyLarge)],
        ],
      ),
    );
  }
}

String? pixivisionHeaderThumbnail(Article article) {
  final thumbnail = article.thumbnail;
  if (thumbnail == null) return null;
  final repeated = article.blocks.any(
    (block) =>
        block.images.any((image) => _sameImage(image.url, thumbnail)) ||
        block.works.any((work) => work.preview != null && _sameImage(work.preview!, thumbnail)),
  );
  return repeated ? null : thumbnail;
}

String? pixivisionHeaderDescription(Article article) {
  final raw = article.description;
  final description = raw == null ? null : cleanPixivisionDescription(raw);
  if (description == null || description.isEmpty) return null;
  final repeated = article.blocks.any((block) => block.kind == BlockKind.paragraph && _normalizedText(block.text) == _normalizedText(description));
  return repeated ? null : description;
}

bool _sameImage(String left, String right) {
  final first = Uri.tryParse(left);
  final second = Uri.tryParse(right);
  if (first == null || second == null) return left == right;
  return first.replace(query: '', fragment: '') == second.replace(query: '', fragment: '');
}

String _normalizedText(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Pixivision article banners are typically 1200×630 share images.
const pixivisionBannerRatio = 1200 / 630;

class _ArticleBodySkeleton extends StatelessWidget {
  const _ArticleBodySkeleton();
  @override
  // The order of a typical article: the introduction first, then each work
  // as title, author and image, so the loaded page replaces bones in place.
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var group = 0; group < (MediaQuery.sizeOf(context).height / 320).ceil(); group++) ...[
        for (var line = 0; line < 5; line++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: line == 4 ? .65 : 1,
              child: const LoadingSkeletonBlock(width: double.infinity, height: 16),
            ),
          ),
        const SizedBox(height: 12),
        const LoadingSkeletonBlock(width: double.infinity, height: 24),
        const SizedBox(height: 8),
        const Row(
          children: [
            ClipOval(child: SizedBox.square(dimension: 32, child: ImageLoadingSkeleton())),
            SizedBox(width: 8),
            Flexible(child: LoadingSkeletonBlock(width: 120, height: 20)),
          ],
        ),
        const SizedBox(height: 8),
        const AspectRatio(aspectRatio: 16 / 9, child: ImageLoadingSkeleton()),
        const SizedBox(height: 12),
      ],
    ],
  );
}
