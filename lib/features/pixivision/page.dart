import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/pixivision/article_card.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/features/pixivision/navigation.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/sectioned_page.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';

/// Pixivision: the latest, ranked and recommended
/// articles of a listing (all, a category or a search) and the tag
/// directory, one section each. The category is in the title menu and the
/// site search in the header; each listing keeps its own lists. The language
/// follows the interface, or the address opened.
class PixivisionPage extends ConsumerStatefulWidget {
  const PixivisionPage({this.url, super.key});

  /// A Pixivision listing address to open: a category, a search, or the tag
  /// directory.
  final String? url;

  @override
  ConsumerState<PixivisionPage> createState() => _PixivisionPageState();
}

class _PixivisionPageState extends ConsumerState<PixivisionPage> with SingleTickerProviderStateMixin {
  late String? _url = validPixivisionUrl(widget.url);
  late final _search = TextEditingController(text: _queryOf(_url));
  final _searchFocus = FocusNode();
  final _header = FrostPageHeaderSearchController();
  late final _tabs = TabController(
    length: PixivisionSection.values.length,
    initialIndex: _initialSection().index,
    animationDuration: FrostMotion.navigation,
    vsync: this,
  )..addListener(_sectionChanged);

  static String _queryOf(String? url) => Uri.tryParse(url ?? '')?.queryParameters['q'] ?? '';

  /// The tag directory's address (`/<language>/t/`).
  static bool _isDirectory(String? url) {
    final segments = Uri.tryParse(url ?? '')?.pathSegments.where((part) => part.isNotEmpty).toList();
    return segments != null && segments.length == 2 && segments[1] == 't';
  }

  PixivisionSection _initialSection() {
    if (_isDirectory(_url)) return PixivisionSection.tags;
    final selection = ref.read(pixivisionBrowseSelectionProvider);
    return selection.url == _url ? selection.section : PixivisionSection.articles;
  }

  /// The section is remembered for the next visit to the same listing.
  void _sectionChanged() {
    if (_tabs.indexIsChanging) return;
    ref.read(pixivisionBrowseSelectionProvider.notifier).select(url: _url, section: PixivisionSection.values[_tabs.index]);
  }

  @override
  void didUpdateWidget(covariant PixivisionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _show(validPixivisionUrl(widget.url));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _header.dispose();
    super.dispose();
  }

  /// Swaps the listing in this page; its latest articles come to the front.
  void _show(String? url) {
    _searchFocus.unfocus();
    setState(() => _url = url);
    _search.text = _queryOf(url);
    if (!_isDirectory(url)) _tabs.animateTo(PixivisionSection.articles.index, duration: Duration.zero);
    ref.read(pixivisionBrowseSelectionProvider.notifier).select(url: url, section: PixivisionSection.values[_tabs.index]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final language = _url == null ? pixivisionLanguagePath(t.$meta.locale) : Uri.parse(_url!).pathSegments.first;
    final home = 'https://www.pixivision.net/$language/';
    final listing = _url == null || _isDirectory(_url) ? home : _url!;
    final categories = ref.watch(pixivisionBrowseProvider(home)).value?.page.categories ?? const <ArticleLink>[];
    final query = _queryOf(listing);
    final category = categories.where((item) => item.url == listing).firstOrNull;
    final title = switch ((query, category)) {
      (final query, _) when query.isNotEmpty => query,
      (_, final category?) => category.title,
      _ => t.pixivision.allCategories,
    };
    FrostListSource<ArticleSummary> source(PixivisionSection section) =>
        ref.watch(pixivisionArticlesProvider((section == PixivisionSection.articles ? listing : home, section)));
    return AppSectionedPage(
      controller: _tabs,
      header: FrostPageHeader(
        searchController: _header,
        leading: [
          FrostTitleMenu(
            key: const ValueKey('pixivision-category'),
            title: '${t.pixivision.title} · $title',
            entries: [
              FrostMenuAction(t.pixivision.allCategories, checked: listing == home, onSelected: () => _show(home)),
              for (final item in categories) FrostMenuAction(item.title, checked: listing == item.url, onSelected: () => _show(item.url)),
            ],
          ),
        ],
        middle: FrostSearchInput(
          controller: _search,
          focusNode: _searchFocus,
          placeholder: t.pixivision.searchHint,
          onSubmitted: (value) {
            final words = value.trim();
            if (words.isEmpty) return;
            _header.collapse();
            _show(Uri.parse('${home}s/').replace(queryParameters: {'q': words}).toString());
          },
          onClear: () {
            _search.clear();
            if (query.isNotEmpty) _show(home);
          },
        ),
      ),
      tabs: [
        FrostTab(label: t.pixivision.latest),
        FrostTab(label: t.pixivision.ranking),
        FrostTab(label: t.pixivision.recommended),
        FrostTab(label: t.pixivision.tags),
      ],
      onRefresh: (section) async => switch (PixivisionSection.values[section]) {
        PixivisionSection.tags => ref.refresh(pixivisionTagsProvider(language).future),
        final section => source(section).refresh(false),
      },
      // Another listing starts its latest articles afresh at the top.
      sectionKey: (section) => PixivisionSection.values[section] == PixivisionSection.articles ? listing : home,
      slivers: (context, section) => switch (PixivisionSection.values[section]) {
        PixivisionSection.tags => [_TagDirectory(language: language)],
        final section => [
          FrostSliverDataWaterfallGrid<ArticleSummary>(
            source: source(section),
            firstLoadSkeleton: const AppPixivisionCardsSkeleton(),
            empty: FrostEmptyState(icon: FrostIconSet.of(context).empty, title: t.pixivision.empty),
            itemBuilder: (context, article, index) => AppPixivisionCard(article: article),
          ),
        ],
      },
    );
  }
}

/// The tag directory: each group's tags with their article counts, nested
/// groups under their own headings.
class _TagDirectory extends ConsumerWidget {
  const _TagDirectory({required this.language});

  final String language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final directory = ref.watch(pixivisionTagsProvider(language));
    return FrostSliverContentColumn(
      maxWidth: double.infinity,
      sliver: switch (directory) {
        AsyncValue(:final value?) when value.groups.isEmpty => SliverToBoxAdapter(
          child: FrostEmptyState(icon: FrostIconSet.of(context).empty, title: t.pixivision.empty),
        ),
        AsyncValue(:final value?) => SliverList.list(
          children: [
            for (final group in value.groups) ...[
              FrostSectionHeader(title: group.name),
              _TagNodes(nodes: group.nodes),
            ],
          ],
        ),
        AsyncValue(:final error?) => SliverToBoxAdapter(
          child: FrostErrorContent.fromError(error: error, onRetry: () => ref.invalidate(pixivisionTagsProvider(language))),
        ),
        _ => const SliverToBoxAdapter(child: AppRowsSkeleton(subtitle: false)),
      },
    );
  }
}

class _TagNodes extends StatelessWidget {
  const _TagNodes({required this.nodes});

  final List<TagNode> nodes;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FrostGap.related,
    children: [
      Wrap(
        spacing: FrostGap.inline,
        runSpacing: FrostGap.inline,
        children: [
          for (final node in nodes)
            if (node.tag case final tag?)
              FrostTag(
                label: tag.name,
                detail: node.articleCount == null ? null : '${node.articleCount}',
                onPressed: () => unawaited(openPixivisionLink(context, tag.url)),
              ),
        ],
      ),
      for (final node in nodes)
        if (node.children.isNotEmpty) ...[
          FrostText(node.name, role: FrostTextRole.headline),
          _TagNodes(nodes: node.children),
        ],
    ],
  );
}
