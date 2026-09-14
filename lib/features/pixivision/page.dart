import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/search_input.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';
import 'package:freepiv/shared/widgets/data_refresh_view.dart';
import 'package:freepiv/shared/widgets/refresh_indicator.dart';
import 'package:freepiv/shared/widgets/floating_filter_sliver.dart';
import 'package:freepiv/shared/widgets/sliver_paged_data_list.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'logic.dart';
import 'widgets.dart';
import 'navigation.dart';

final _pixivisionBrowseStorage = PageStorageBucket();

class PixivisionPage extends ConsumerStatefulWidget {
  const PixivisionPage({this.url, super.key});
  final String? url;
  @override
  ConsumerState<PixivisionPage> createState() => _PixivisionPageState();
}

class _PixivisionPageState extends ConsumerState<PixivisionPage> {
  late final _search = TextEditingController(text: Uri.tryParse(widget.url ?? '')?.queryParameters['q'] ?? '');
  final _focus = FocusNode();
  late PixivisionSection _section = _initialSection();
  PixivisionSection _initialSection() {
    if (_isDirectory(widget.url)) return PixivisionSection.tags;
    final selection = ref.read(pixivisionBrowseSelectionProvider);
    return selection.url == widget.url ? selection.section : PixivisionSection.articles;
  }

  bool _isDirectory(String? url) {
    final segments = Uri.tryParse(url ?? '')?.pathSegments.where((part) => part.isNotEmpty).toList();
    return segments != null && segments.length == 2 && segments[1] == 't';
  }

  @override
  void didUpdateWidget(covariant PixivisionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _section = _isDirectory(widget.url) ? PixivisionSection.tags : PixivisionSection.articles;
      final query = Uri.tryParse(widget.url ?? '')?.queryParameters['q'] ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (Uri.tryParse(widget.url ?? '')?.queryParameters['q'] ?? '') == query && _search.text != query) _search.text = query;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.pixivision;
    final requested = validPixivisionUrl(widget.url);
    final language = requested == null ? pixivisionLanguagePath(context.t.$meta.locale) : Uri.parse(requested).pathSegments.first;
    final home = 'https://www.pixivision.net/$language/';
    final url = requested == null || _isDirectory(requested) ? home : requested;
    final state = ref.watch(pixivisionBrowseProvider(url));
    final homeState = ref.watch(pixivisionBrowseProvider(home));
    final categories = homeState.value?.page.categories ?? const <ArticleLink>[];
    void selectUrl(String next) {
      _focus.unfocus();
      setState(() => _section = PixivisionSection.articles);
      final path = GoRouterState.of(context).uri.path;
      ref.read(pixivisionBrowseSelectionProvider.notifier).select(url: next, section: PixivisionSection.articles);
      context.replace(Uri(path: path, queryParameters: {'url': next}).toString());
    }

    final category = categories.where((item) => item.url == url).firstOrNull;
    final selector = AppSelect<String>(
      value: category?.url ?? home,
      items: [
        AppSelectItem(value: home, label: t.allCategories),
        for (final item in categories) AppSelectItem(value: item.url, label: item.title),
      ],
      onChanged: selectUrl,
    );
    final filterSliver = FloatingFilterSliver(
      height: compactFilterHeight(context),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabs = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<PixivisionSection>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: PixivisionSection.articles, label: Text(t.latest)),
                        ButtonSegment(value: PixivisionSection.ranking, label: Text(t.ranking)),
                        ButtonSegment(value: PixivisionSection.recommended, label: Text(t.recommended)),
                        ButtonSegment(value: PixivisionSection.tags, label: Text(t.tags)),
                      ],
                      selected: {_section},
                      onSelectionChanged: (values) {
                        ref.read(pixivisionBrowseSelectionProvider.notifier).select(url: widget.url, section: values.single);
                        setState(() => _section = values.single);
                      },
                    ),
                  );
                  return Row(
                    children: [
                      Expanded(child: tabs),
                      const SizedBox(width: 12),
                      SizedBox(width: (constraints.maxWidth * .4).clamp(0, 200), child: selector),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    return PixivisionScaffold(
      child: Column(
        children: [
          SearchInputRegion(
            child: SearchInput(
              controller: _search,
              focusNode: _focus,
              hintText: t.searchHint,
              onSubmitted: (query) {
                final value = query.trim();
                if (value.isNotEmpty) selectUrl(Uri.parse('${home}s/').replace(queryParameters: {'q': value}).toString());
              },
              onClear: () {
                _search.clear();
                if (Uri.parse(url).queryParameters.containsKey('q')) selectUrl(home);
              },
            ),
          ),
          Expanded(
            child: _section == PixivisionSection.tags
                ? PageStorage(
                    bucket: _pixivisionBrowseStorage,
                    child: _TagDirectory(language: language, filterSliver: filterSliver),
                  )
                : DataRefreshView(
                    onRefresh: () async {
                      final target = _section == PixivisionSection.articles ? url : home;
                      ref.invalidate(pixivisionBrowseProvider(target));
                      await ref.read(pixivisionBrowseProvider(target).future);
                      return true;
                    },
                    builder: (context, physics, locators) => LayoutBuilder(
                      builder: (context, constraints) {
                        final active = _section == PixivisionSection.articles ? state : homeState;
                        final listing = active.value;
                        final items = switch (_section) {
                          PixivisionSection.ranking => listing?.page.monthlyRanking,
                          PixivisionSection.recommended => listing?.page.recommended,
                          _ => listing?.page.articles,
                        };
                        return PageStorage(
                          bucket: _pixivisionBrowseStorage,
                          child: DataLoadingCustomScrollView(
                            key: PageStorageKey((url, _section)),
                            physics: physics,
                            slivers: [
                              filterSliver,
                              ?locators.sliverHeader,
                              if (url != home && _section == PixivisionSection.articles)
                                SliverPadding(
                                  padding: pixivisionPadding(constraints.maxWidth).copyWith(bottom: 0),
                                  sliver: SliverToBoxAdapter(
                                    child: Skeletonizer(
                                      enabled: listing == null,
                                      child: Text(
                                        listing?.page.title ?? t.latest,
                                        style: Theme.of(context).textTheme.titleLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              if (items == null)
                                SliverPadding(
                                  padding: pixivisionPadding(constraints.maxWidth),
                                  sliver: SliverToBoxAdapter(
                                    child: active.hasError
                                        ? PixivisionError(
                                            retry: () => ref.invalidate(pixivisionBrowseProvider(_section == PixivisionSection.articles ? url : home)),
                                          )
                                        : const PixivisionCardSkeleton(),
                                  ),
                                )
                              else
                                SliverPagedDataList<ArticleSummary>(
                                  key: ValueKey((url, _section)),
                                  items: items,
                                  hasMore: _section == PixivisionSection.articles && listing?.page.nextUrl != null,
                                  loading: active.isLoading || listing!.loadingMore,
                                  hasError: listing?.error != null,
                                  onLoadMore: () async {
                                    final provider = pixivisionBrowseProvider(url);
                                    await ref.read(provider.notifier).loadMore();
                                    return mounted && ref.read(provider).value?.error == null;
                                  },
                                  padding: pixivisionPadding(constraints.maxWidth),
                                  itemBuilder: (context, article, index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: PixivisionCard(article: article),
                                  ),
                                  footer: Column(
                                    children: [
                                      if (items.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Text(t.empty)),
                                      if (listing?.loadingMore ?? false) const PixivisionCardSkeleton(),
                                      if (listing?.error != null) ...[
                                        Text(t.requestFailed),
                                        OutlinedButton(onPressed: () => ref.read(pixivisionBrowseProvider(url).notifier).loadMore(), child: Text(t.loadMore)),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TagDirectory extends ConsumerWidget {
  const _TagDirectory({required this.language, required this.filterSliver});
  final String language;
  final Widget filterSliver;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pixivisionTagsProvider(language));
    return DataRefreshView(
      onRefresh: () async {
        ref.invalidate(pixivisionTagsProvider(language));
        await ref.read(pixivisionTagsProvider(language).future);
        return true;
      },
      builder: (context, physics, locators) => LayoutBuilder(
        builder: (context, constraints) => DataLoadingCustomScrollView(
          key: PageStorageKey(('pixivision-tags', language)),
          physics: physics,
          slivers: [
            filterSliver,
            ?locators.sliverHeader,
            SliverPadding(
              padding: pixivisionPadding(constraints.maxWidth),
              sliver: SliverList.list(
                children: [
                  if (state.value case final directory?) ...[
                    ..._groups(context, directory.groups),
                    if (directory.groups.isEmpty) Text(context.t.pixivision.empty),
                  ] else if (state.hasError)
                    PixivisionError(retry: () => ref.invalidate(pixivisionTagsProvider(language)))
                  else
                    Skeletonizer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _groups(context, [
                          for (var i = 0; i < (MediaQuery.sizeOf(context).height / 80).ceil(); i++)
                            TagGroup(
                              name: 'Tag group',
                              nodes: [
                                for (var j = 0; j < 8; j++)
                                  const TagNode(
                                    name: 'Tag name',
                                    tag: PixivisionTag(id: 0, name: 'Tag name', url: ''),
                                    children: [],
                                  ),
                              ],
                            ),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _groups(BuildContext context, List<TagGroup> groups) => [
    for (final group in groups) ...[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(group.name, style: Theme.of(context).textTheme.titleLarge),
      ),
      ..._nodes(context, group.nodes),
    ],
  ];

  List<Widget> _nodes(BuildContext context, List<TagNode> nodes) => [
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final node in nodes)
          if (node.tag case final tag?)
            ActionChip(
              label: Text(node.articleCount == null ? tag.name : '${tag.name} · ${node.articleCount}'),
              onPressed: () => openPixivisionLink(context, tag.url),
            ),
      ],
    ),
    for (final node in nodes)
      if (node.children.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(node.name, style: Theme.of(context).textTheme.titleMedium),
        ),
        ..._nodes(context, node.children),
      ],
  ];
}
