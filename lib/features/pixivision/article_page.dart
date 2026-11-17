import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/features/downloads/presentation/content_image_entries.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/features/pixivision/article_card.dart';
import 'package:freepiv/features/pixivision/article_images.dart';
import 'package:freepiv/features/pixivision/description.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/features/pixivision/navigation.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/social.dart';
import 'package:go_router/go_router.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

/// A Pixivision article, a reading column: the title,
/// its category, date and translations, the banner and the opening once
/// each, then the body blocks (headings, text with links, code, questions,
/// tables, images, featured works with their authors, embeds and links),
/// the tags, the previous and next articles and the related ones. Pixiv
/// links open in the app, others outside; `#anchors` scroll the page.
class PixivisionArticlePage extends ConsumerStatefulWidget {
  const PixivisionArticlePage({required this.url, this.summary, super.key});

  final String url;

  /// The card it was opened from, shown while the article loads.
  final ArticleSummary? summary;

  @override
  ConsumerState<PixivisionArticlePage> createState() => _PixivisionArticlePageState();
}

class _PixivisionArticlePageState extends ConsumerState<PixivisionArticlePage> {
  final _scroll = ScrollController();
  final _headKey = GlobalKey();
  final _blocks = <int, GlobalKey>{};
  bool _headGone = false;
  double _headHeight = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_scrolled);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Once the title has scrolled away the header carries it. The list drops
  /// the head when it is far above; its last height still stands.
  void _scrolled() {
    _headHeight = _headKey.currentContext?.size?.height ?? _headHeight;
    final gone = _headHeight > 0 && _scroll.offset > _headHeight;
    if (gone != _headGone) setState(() => _headGone = gone);
  }

  /// Opens [value] from inside the article: an anchor of this article scrolls
  /// to its block; anything else goes where [openPixivisionLink] sends it.
  void _open(Article article, String value) {
    final base = Uri.parse(article.url);
    final uri = base.resolve(value);
    if (uri.fragment.isNotEmpty && uri.replace(fragment: '') == base.replace(fragment: '')) {
      final index = article.blocks.indexWhere((block) => block.anchor == uri.fragment);
      final target = _blocks[index]?.currentContext;
      if (target != null) {
        unawaited(Scrollable.ensureVisible(target, duration: FrostMotion.duration(context, FrostMotion.navigation), alignment: .05));
      }
      return;
    }
    unawaited(openPixivisionLink(context, uri.toString()));
  }

  Future<void> _refresh() async {
    ref.invalidate(pixivisionArticleProvider(widget.url));
    await ref.read(pixivisionArticleProvider(widget.url).future);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = ref.watch(pixivisionArticleProvider(widget.url));
    final document = state.value;
    final title = pixivisionArticleTitle(document?.article.title ?? widget.summary?.title ?? '');
    if (document == null && state.hasError) {
      return AppPageError.fromError(error: state.error!, onRetry: () => ref.invalidate(pixivisionArticleProvider(widget.url)));
    }
    final article = document?.article;
    final header = FrostContentColumn(
      maxWidth: FrostMetrics.readingMaxWidth,
      child: FrostPageHeader(
        title: _headGone ? FrostText(title) : null,
        actions: [
          // Beside "open original", so the category and date row never changes as translations arrive.
          if (article != null && article.translations.isNotEmpty)
            FrostToolbarItem.menu(
              label: t.pixivision.translations,
              entries: [for (final item in article.translations) FrostMenuAction(item.title, onSelected: () => _open(article, item.url))],
              priority: FrostToolbarPriority.low,
            ),
          FrostToolbarItem.action(
            icon: PivIcons.externalLink,
            label: t.pixivision.openOriginal,
            // A long title must not fold it away as the title arrives.
            priority: FrostToolbarPriority.high,
            onPressed: () => unawaited(openPixivisionExternalLink(context, article?.url ?? widget.url)),
          ),
        ],
      ),
    );
    final body = article == null
        ? [KeyedSubtree(key: _headKey, child: _Head(summary: widget.summary))]
        : [
            KeyedSubtree(
              key: _headKey,
              child: _Head(article: article, summary: widget.summary, onLink: (value) => _open(article, value)),
            ),
            for (final (index, block) in article.blocks.indexed)
              if (pixivisionBlockHasContent(block, headBanner: article.thumbnail))
                KeyedSubtree(
                  key: _blocks.putIfAbsent(index, GlobalKey.new),
                  child: PixivisionBlock(
                    block: block,
                    headBanner: article.thumbnail,
                    imageRatios: document!.imageRatios,
                    base: Uri.parse(article.url),
                    onLink: (value) => _open(article, value),
                  ),
                ),
            if (article.tags.isNotEmpty)
              Wrap(
                spacing: FrostGap.inline,
                runSpacing: FrostGap.inline,
                children: [for (final tag in article.tags) FrostTag(label: '#${tag.name}', onPressed: () => _open(article, tag.url))],
              ),
            if (article.previousUrl != null || article.nextUrl != null)
              Row(
                spacing: FrostGap.related,
                children: [
                  if (article.previousUrl case final url?)
                    FrostButton.outlined(label: t.pixivision.previous, icon: PivIcons.chevronLeft, onPressed: () => _open(article, url)),
                  const Spacer(),
                  if (article.nextUrl case final url?)
                    FrostButton.outlined(label: t.pixivision.next, icon: PivIcons.chevronRight, onPressed: () => _open(article, url)),
                ],
              ),
            for (final section in [
              ...article.related,
              ArticleSection(title: t.pixivision.ranking, articles: article.monthlyRanking),
              ArticleSection(title: t.pixivision.recommended, articles: article.recommended),
            ])
              if (section.articles.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: FrostGap.related,
                  children: [
                    FrostSectionHeader(
                      title: section.title,
                      actionLabel: section.url == null ? null : t.pixivision.loadMore,
                      onAction: switch (section.url) {
                        final url? => () => _open(article, url),
                        null => null,
                      },
                    ),
                    FrostGrid(
                      minItemWidth: _relatedWidth,
                      children: [for (final item in section.articles) AppPixivisionCard(article: item)],
                    ),
                  ],
                ),
          ];
    final page = AppRefreshScope(
      onRefresh: _refresh,
      child: FrostPinnedChrome(
        chrome: header,
        body: FrostRefreshView(
          onRefresh: () async {
            await _refresh();
            return true;
          },
          builder: (context, physics, locators) => FrostLoadingScrollView(
            controller: _scroll,
            physics: physics,
            slivers: [
              const FrostChromeSpacer(),
              ?locators.sliverHeader,
              FrostSliverContentColumn(
                maxWidth: FrostMetrics.readingMaxWidth,
                sliver: SliverList.list(
                  children: [
                    for (final (index, child) in body.indexed)
                      Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : FrostGap.group),
                        child: child,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // The banner's menu and viewer need a download source from the first frame, so a summary stands in until the article arrives.
    final summary = widget.summary;
    final source = switch ((article, summary)) {
      (final article?, _) => PixivisionSource(articleId: article.id, url: article.url, title: article.title, thumbnailUrl: article.thumbnail),
      (_, final summary?) => PixivisionSource(articleId: summary.id, url: summary.url, title: summary.title, thumbnailUrl: summary.thumbnail),
      _ => null,
    };
    if (source == null) return page;
    return DownloadSourceScope(source: source, child: page);
  }

  /// Related article cards share a row at this width.
  static const _relatedWidth = 220.0;
}

/// The title, the category and date, the banner and the opening. Whatever the
/// opening card knew is drawn in its final place from the first frame, so the
/// banner frame and the rows above the body keep their size when the article
/// arrives. Without a card the same layout stands as bones.
class _Head extends StatelessWidget {
  const _Head({this.article, this.summary, this.onLink});

  final Article? article;
  final ArticleSummary? summary;
  final ValueChanged<String>? onLink;

  static const _placeholderTitle = 'An article title on a single line';
  static const _placeholderCategory = ArticleLink(title: 'Illustration', url: '');

  @override
  Widget build(BuildContext context) {
    final loaded = article;
    final known = loaded != null || summary != null;
    final category = loaded?.category ?? summary?.category;
    final date = loaded?.publishDate ?? summary?.publishDate;
    final opening = loaded == null ? null : pixivisionHeaderDescription(loaded);
    final title = pixivisionArticleTitle(loaded?.title ?? summary?.title ?? _placeholderTitle);
    final cover = summary?.thumbnail;
    final banner = loaded?.thumbnail;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.related,
      children: [
        FrostText(title, content: true, role: FrostTextRole.title1),
        Wrap(
          spacing: FrostGap.inline,
          runSpacing: FrostGap.inline,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!known || category != null)
              FrostTag(label: (category ?? _placeholderCategory).title, onPressed: onLink == null || category == null ? null : () => onLink!(category.url)),
            if (!known || (date != null && date.isNotEmpty))
              FrostText(pixivisionDate(date ?? '2026-01-01'), role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
          ],
        ),
        if (!known)
          FrostMediaFrame.skeleton(aspectRatio: pixivisionBannerRatio)
        else if (cover != null)
          // The card's own picture, cropped the way the card crops it, stays the banner once loaded.
          _ArticleImage(url: cover, title: title, ratio: pixivisionBannerRatio, fit: BoxFit.cover)
        else if (banner != null)
          _ArticleImage(url: banner, title: title, ratio: pixivisionBannerRatio)
        else if (loaded == null)
          const FrostMediaFrame(aspectRatio: pixivisionBannerRatio, child: SizedBox.expand()),
        if (opening != null)
          FrostText(opening, content: true)
        else if (loaded == null)
          const _OpeningSkeleton(),
      ],
    );
    return known ? column : column.frostSkeleton(true);
  }
}

/// Bones for the opening paragraph: lines as wide as the reading column.
class _OpeningSkeleton extends StatelessWidget {
  const _OpeningSkeleton();

  static const _text =
      'An opening paragraph that runs over several lines of the reading column before the first block of the article begins, '
      'saying what the article is about, who made the works it brings together and why they are worth a look, in a few '
      'sentences that fill the width of the column from one edge to the other and carry on for as long as the usual ones do, '
      'so that the placeholder always has more lines than it may show on any width.';

  @override
  Widget build(BuildContext context) => const FrostText(_text, maxLines: 5).frostSkeleton(true);
}

/// Pixivision article banners are typically 1200×630 share images.
const pixivisionBannerRatio = 1200 / 630;

/// The header's opening, unless a body paragraph says the same. A description
/// cut off with an ellipsis is the same as the paragraph that starts with it.
String? pixivisionHeaderDescription(Article article) {
  final raw = article.description;
  final description = raw == null ? null : cleanPixivisionDescription(raw);
  if (description == null || description.isEmpty) return null;
  final head = _withoutSpaces(description).replaceFirst(RegExp(r'(…|\.\.\.)$'), '');
  final repeated = article.blocks.any((block) => block.kind == BlockKind.paragraph && head.isNotEmpty && _withoutSpaces(block.text).startsWith(head));
  return repeated ? null : description;
}

/// The images of [block] that the body shows: not the picture the header's
/// banner already is.
List<ArticleImage> pixivisionBodyImages(ArticleBlock block, String? headBanner) =>
    headBanner == null ? block.images : [for (final image in block.images) if (!_sameImage(image.url, headBanner)) image];

bool _sameImage(String left, String right) {
  final first = Uri.tryParse(left);
  final second = Uri.tryParse(right);
  if (first == null || second == null) return left == right;
  return first.replace(query: '', fragment: '') == second.replace(query: '', fragment: '');
}

/// The text without any whitespace: the description and the paragraph break lines in different places.
String _withoutSpaces(String value) => value.replaceAll(RegExp(r'\s+'), '');

/// Whether [block] is the article's share picture, the block pixivision puts
/// first in the body. The header shows its picture (or the card's cover), so the
/// body never does.
bool pixivisionIsShareImageBlock(ArticleBlock block) => RegExp(r'class="[^"]*__article_thumbnail[\s"]').hasMatch(block.html);

/// Whether [block] shows anything. The header already shows [headBanner], and
/// the share picture block is not repeated in the body.
bool pixivisionBlockHasContent(ArticleBlock block, {String? headBanner}) =>
    !pixivisionIsShareImageBlock(block) &&
    (block.text.trim().isNotEmpty ||
        pixivisionBodyImages(block, headBanner).isNotEmpty ||
        block.links.isNotEmpty ||
        block.works.isNotEmpty ||
        block.embeds.isNotEmpty ||
        block.kind == BlockKind.divider ||
        block.kind == BlockKind.unknown);

/// [htmlSource] as the inline grammar of [FrostRichText]: links (resolved
/// against [base]) as `[label](url)`, bold and italic marked, line breaks
/// and list items kept.
String pixivisionRichText(String htmlSource, {required Uri base, String fallback = ''}) {
  final out = StringBuffer();
  var pendingBreak = false;
  var lineStart = true;
  void write(String value, {bool verbatim = false}) {
    var text = verbatim ? value : value.replaceAll(RegExp(r'[\t\r\n ]+'), ' ');
    if (lineStart || pendingBreak) text = text.trimLeft();
    if (text.isEmpty) return;
    if (pendingBreak && out.isNotEmpty) out.write('\n');
    pendingBreak = false;
    lineStart = false;
    out.write(text);
  }

  void visit(dom.Node node, bool verbatim) {
    if (node is dom.Text) {
      write(node.text, verbatim: verbatim);
      return;
    }
    if (node is! dom.Element) return;
    final tag = node.localName;
    if (['img', 'iframe', 'video', 'audio', 'script', 'style'].contains(tag)) return;
    if (tag == 'br') {
      pendingBreak = true;
      return;
    }
    // An empty item would show as a lone bullet.
    if (tag == 'li' && node.text.trim().isEmpty) return;
    final isBlock = ['p', 'div', 'li', 'blockquote', 'h1', 'h2', 'h3', 'h4', 'pre'].contains(tag);
    if (isBlock) pendingBreak = out.isNotEmpty;
    final href = node.attributes['href'];
    final label = node.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (tag == 'a' && href != null && label.isNotEmpty) {
      final target = base.resolve(href);
      if (target.scheme == 'http' || target.scheme == 'https') {
        write('[${label.replaceAll(']', ')')}]($target)');
        return;
      }
    }
    final mark = switch (tag) {
      'b' || 'strong' => '**',
      'i' || 'em' => '*',
      _ => '',
    };
    if (tag == 'li') write('• ');
    if (mark.isNotEmpty && node.text.trim().isNotEmpty) {
      write('$mark${node.text.trim()}$mark');
    } else {
      for (final child in node.nodes) {
        visit(child, verbatim || tag == 'pre');
      }
    }
    if (isBlock) pendingBreak = true;
  }

  final nodes = html.parseFragment(htmlSource).nodes;
  if (nodes.isEmpty) return fallback.trim();
  for (final node in nodes) {
    visit(node, false);
  }
  return out.isEmpty ? fallback.trim() : out.toString();
}

/// One block of an article's body.
class PixivisionBlock extends StatelessWidget {
  const PixivisionBlock({required this.block, required this.imageRatios, required this.onLink, this.base, this.headBanner, super.key});

  final ArticleBlock block;
  final Map<String, double> imageRatios;
  final ValueChanged<String> onLink;

  /// The article's address, for links relative to it.
  final Uri? base;

  /// The picture the header shows as the banner; the body does not repeat it.
  final String? headBanner;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final base = this.base ?? Uri.parse('https://www.pixivision.net/');
    final text = block.text.trim();
    final rows = _tableRows(block.html);
    final children = <Widget>[
      switch (block.kind) {
        BlockKind.divider => const FrostDivider(),
        BlockKind.heading when text.isNotEmpty => FrostText(text, content: true, role: (block.headingLevel ?? 2) <= 2 ? FrostTextRole.title2 : FrostTextRole.headline),
        BlockKind.code when text.isNotEmpty => FrostCodeBlock(text: block.text),
        BlockKind.question when text.isNotEmpty => FrostText(text, content: true, role: FrostTextRole.headline),
        _ when rows.isNotEmpty => _ArticleTable(rows: rows),
        BlockKind.pixivWork when block.works.isNotEmpty => const SizedBox.shrink(),
        _ when text.isNotEmpty => FrostRichText(text: pixivisionRichText(block.html, base: base, fallback: block.text), onLink: (uri) => onLink('$uri')),
        _ => const SizedBox.shrink(),
      },
      if (block.kind != BlockKind.pixivWork)
        for (final image in pixivisionBodyImages(block, headBanner)) _ArticleImage(url: image.url, title: image.alt, ratio: imageRatios[image.url]),
      for (final work in block.works) _FeaturedWork(work: work, block: block, imageRatios: imageRatios, headBanner: headBanner, onLink: onLink),
      for (final embed in block.embeds)
        FrostLinkCard(
          title: embed.title ?? Uri.parse(embed.url).host,
          url: Uri.parse(embed.url),
          onPressed: () => unawaited(openPixivisionExternalLink(context, embed.url)),
        ),
      if (block.kind == BlockKind.articleCard || text.isEmpty)
        for (final link in block.links)
          FrostLinkCard(title: link.title.isEmpty ? t.pixivision.openOriginal : link.title, url: base.resolve(link.url), onPressed: () => onLink(link.url)),
      if (block.kind == BlockKind.unknown && text.isEmpty && block.images.isEmpty && block.embeds.isEmpty)
        FrostText(t.pixivision.unsupported, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: FrostGap.related, children: children);
  }

  static List<List<dom.Element>> _tableRows(String source) {
    final table = html.parseFragment(source).querySelector('table');
    return table
            ?.querySelectorAll('tr')
            .map((row) => row.children.where((cell) => cell.localName == 'td' || cell.localName == 'th').toList())
            .where((row) => row.isNotEmpty)
            .toList() ??
        const [];
  }
}

/// A table of an article, as tall as its rows, in the flow of the text, every
/// cell in full. A first row of header cells heads the columns; a table
/// without one has no header.
class _ArticleTable extends StatelessWidget {
  const _ArticleTable({required this.rows});

  final List<List<dom.Element>> rows;

  static String _text(dom.Element cell) => cell.text.replaceAll(RegExp(r'\s+'), ' ').trim();

  @override
  Widget build(BuildContext context) {
    final headed = rows.first.every((cell) => cell.localName == 'th');
    final body = [for (final row in headed ? rows.skip(1) : rows) [for (final cell in row) _text(cell)]];
    final width = rows.map((row) => row.length).reduce(math.max);
    final header = [for (var column = 0; column < width; column++) headed && column < rows.first.length ? _text(rows.first[column]) : ''];
    return FrostTable<List<String>>(
      shrinkWrap: true,
      showHeader: headed,
      columns: [
        for (final (column, label) in header.indexed)
          FrostTableColumn(
            label: label,
            primary: column == 0,
            text: (row) => column < row.length ? row[column] : '',
            cell: (context, row) => FrostText(column < row.length ? row[column] : '', content: true),
          ),
      ],
      rows: body,
    );
  }
}

/// A featured work: its title and author, which open them, and its image.
class _FeaturedWork extends ConsumerWidget {
  const _FeaturedWork({required this.work, required this.block, required this.imageRatios, required this.headBanner, required this.onLink});

  final FeaturedWork work;
  final ArticleBlock block;
  final Map<String, double> imageRatios;
  final String? headBanner;
  final ValueChanged<String> onLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = work.userId == null ? null : pixivisionWorkAuthor(work, block);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostListRow(title: work.title, contentTitle: true, accessory: FrostRowAccessory.chevron, onPressed: () => onLink(work.url)),
        if (author != null)
          FrostListRow(
            leading: FrostLeading.custom(
              FrostAvatar.person(
                name: author.name,
                colorKey: '${work.userId}',
                size: FrostAvatarSize.small,
                image: author.avatar == null ? null : pixivImageProvider(ref, author.avatar!, headers: pixivisionImageHeaders),
              ),
            ),
            title: author.name,
            contentTitle: true,
            accessory: FrostRowAccessory.chevron,
            onPressed: () => onLink('https://www.pixiv.net/users/${work.userId}'),
          ),
        if (work.preview case final preview? when headBanner == null || !_sameImage(preview, headBanner!))
          Padding(
            padding: const EdgeInsets.only(top: FrostGap.related),
            child: _ArticleImage(url: preview, title: work.title, ratio: imageRatios[preview], onPressed: () => onLink(work.url)),
          ),
      ],
    );
  }
}

/// A featured work's author as the article names them, with the avatar the
/// article shows beside the name; the user ID stands in for a missing name.
({String name, String? avatar}) pixivisionWorkAuthor(FeaturedWork work, ArticleBlock block) {
  final id = work.userId!;
  var name = work.userName?.trim() ?? '';
  String? avatar;
  // Match both author anchors: the avatar link may precede the named link.
  for (final anchor in html.parseFragment(block.html).querySelectorAll('a[href]')) {
    final uri = Uri.tryParse(anchor.attributes['href']!);
    if (uri == null || !['www.pixiv.net', 'pixiv.net'].contains(uri.host)) continue;
    final parts = uri.pathSegments;
    final userIndex = parts.indexOf('users');
    final candidate = userIndex >= 0 && parts.length > userIndex + 1 ? parts[userIndex + 1] : uri.queryParameters['id'];
    if (candidate != id.toString() || (userIndex < 0 && !uri.path.endsWith('/member.php'))) continue;
    if (name.isEmpty) name = anchor.text.trim();
    final imageUrl = anchor.querySelector('img')?.attributes['src'];
    if (imageUrl != null && block.images.any((image) => image.url == imageUrl)) avatar = imageUrl;
  }
  return (name: name.isEmpty ? t.pixivision.userId(id: id.toString()) : name, avatar: avatar);
}

/// An image of an article: at its known shape, else at [ratio] or a wide
/// frame until it has loaded and its shape is read once. Its menu downloads
/// or copies it; a tap opens it in the image viewer, or runs [onPressed].
class _ArticleImage extends ConsumerStatefulWidget {
  const _ArticleImage({required this.url, required this.title, this.ratio, this.onPressed, this.fit = BoxFit.contain});

  final String url;
  final String title;
  final double? ratio;
  final VoidCallback? onPressed;

  final BoxFit fit;

  @override
  ConsumerState<_ArticleImage> createState() => _ArticleImageState();
}

class _ArticleImageState extends ConsumerState<_ArticleImage> {
  double? _probed;

  @override
  void initState() {
    super.initState();
    if (widget.ratio == null) unawaited(_probe());
  }

  Future<void> _probe() async {
    final url = widget.url;
    final ratio = await probePixivisionImageRatio(ref.read(rustMediaTransportProvider), url);
    if (mounted && ratio != null && url == widget.url) setState(() => _probed = ratio);
  }

  void _view() => unawaited(
    GoRouter.of(context).push(
      AppRoute.originalImageViewer.path,
      extra: OriginalImageViewerArgs(
        title: widget.title,
        source: DownloadSourceScope.of(context),
        pages: [
          OriginalImagePage(
            url: widget.url,
            previewUrl: widget.url,
            downloadOrigin: DownloadOrigin.ofImageUrl(Uri.parse(widget.url)),
            headers: pixivisionImageHeaders,
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ratio = widget.ratio ?? _probed ?? 16 / 9;
    return FrostContextMenuRegion(
      entries: contentImageMenu(context, ref.read(rustMediaTransportProvider), url: widget.url, title: widget.title, headers: pixivisionImageHeaders),
      child: Semantics(
        button: true,
        label: widget.title,
        child: FrostClickSurface(
          shape: FrostClickShape.rounded(BorderRadius.circular(FrostRadius.lg)),
          onTap: widget.onPressed ?? _view,
          child: AppPixivImage(
            url: widget.url,
            aspectRatio: ratio,
            fit: widget.fit,
            headers: pixivisionImageHeaders,
            semanticLabel: widget.title,
            // The card decoded the cover at its layout size; the same request is reused.
            decodeAtLayoutSize: widget.fit == BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
