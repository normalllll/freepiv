import 'package:freepiv/shared/widgets/app_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/shared/layout/content_viewport.dart';
import 'package:freepiv/shared/layout/fp_pinned_chrome.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';
import 'package:freepiv/shared/widgets/compact_message.dart';
import 'package:freepiv/shared/data/data_list_source.dart';
import 'package:freepiv/shared/widgets/load_state_switcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/search_input.dart';
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

class _PixivisionPageState extends ConsumerState<PixivisionPage> with SingleTickerProviderStateMixin {
  late final _search = TextEditingController(text: Uri.tryParse(widget.url ?? '')?.queryParameters['q'] ?? '');
  final _focus = FocusNode();
  bool _searchExpanded = false;
  late PixivisionSection _section = _initialSection();
  late final _tabController = TabController(length: PixivisionSection.values.length, initialIndex: _section.index, vsync: this);
  late String? _url = widget.url;
  @override
  void initState() {
    super.initState();
    _tabController.addListener(_syncSection);
  }

  /// The section follows the page the tabs are on, so the browse selection
  /// remembers it for the next visit.
  void _syncSection() {
    final section = PixivisionSection.values[_tabController.index];
    if (section == _section) return;
    _section = section;
    ref.read(pixivisionBrowseSelectionProvider.notifier).select(url: _url, section: section);
  }

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
      _url = widget.url;
      _section = _isDirectory(_url) ? PixivisionSection.tags : PixivisionSection.articles;
      _tabController.animateTo(_section.index, duration: Duration.zero);
      final query = Uri.tryParse(_url ?? '')?.queryParameters['q'] ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (Uri.tryParse(_url ?? '')?.queryParameters['q'] ?? '') == query && _search.text != query) _search.text = query;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncSection);
    _tabController.dispose();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.pixivision;
    final requested = validPixivisionUrl(_url);
    final language = requested == null ? pixivisionLanguagePath(context.t.$meta.locale) : Uri.parse(requested).pathSegments.first;
    final home = 'https://www.pixivision.net/$language/';
    final url = requested == null || _isDirectory(requested) ? home : requested;
    final state = ref.watch(pixivisionBrowseProvider(url));
    final homeState = ref.watch(pixivisionBrowseProvider(home));
    final categories = homeState.value?.page.categories ?? const <ArticleLink>[];
    void selectUrl(String next) {
      _focus.unfocus();
      // The listing swaps in this page rather than opening another one.
      setState(() {
        _url = next;
        _section = PixivisionSection.articles;
      });
      _search.text = Uri.tryParse(next)?.queryParameters['q'] ?? '';
      _tabController.animateTo(_section.index, duration: Duration.zero);
      ref.read(pixivisionBrowseSelectionProvider.notifier).select(url: next, section: PixivisionSection.articles);
    }

    final query = Uri.parse(url).queryParameters['q'] ?? '';
    // Tabs carry their label padding, so the row bleeds by it.
    final chrome = ContentColumn(
      bleed: AppMetrics.tabLabelPadding(MediaQuery.sizeOf(context).width),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(
                child: AppTabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.symmetric(horizontal: AppMetrics.tabLabelPadding(MediaQuery.sizeOf(context).width)),
                  tabs: [
                    Tab(text: t.latest),
                    Tab(text: t.ranking),
                    Tab(text: t.recommended),
                    Tab(text: t.tags),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Search results and tag pages are not in the list; the button
              // then shows the first item, "All categories". At most half the
              // row, like the FANBOX collection picker beside its tabs.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: AppValueMenuButton<String>(
                  value: url,
                  items: [
                    AppSelectItem(value: home, label: t.allCategories),
                    for (final item in categories) AppSelectItem(value: item.url, label: item.title),
                  ],
                  onSelected: selectUrl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    const filterSliver = FpChromeSpacer();
    Widget sectionPage(PixivisionSection section) => section == PixivisionSection.tags
        ? PageStorage(
            bucket: _pixivisionBrowseStorage,
            child: _TagDirectory(language: language, filterSliver: filterSliver),
          )
        : DataRefreshView(
            onRefresh: () async {
              final target = section == PixivisionSection.articles ? url : home;
              ref.invalidate(pixivisionBrowseProvider(target));
              await ref.read(pixivisionBrowseProvider(target).future);
              return true;
            },
            builder: (context, physics, locators) => LayoutBuilder(
              builder: (context, constraints) {
                final active = section == PixivisionSection.articles ? state : homeState;
                final listing = active.value;
                final items = switch (section) {
                  PixivisionSection.ranking => listing?.page.monthlyRanking,
                  PixivisionSection.recommended => listing?.page.recommended,
                  _ => listing?.page.articles,
                };
                return PageStorage(
                  bucket: _pixivisionBrowseStorage,
                  child: LoadStateSwitcher(
                    phase: switch (items) {
                      null when active.hasError => LoadPhase.error,
                      null => LoadPhase.loading,
                      _ => LoadPhase.content,
                    },
                    child: DataLoadingCustomScrollView(
                      key: PageStorageKey((url, section)),
                      physics: physics,
                      slivers: [
                        filterSliver,
                        ?locators.sliverHeader,
                        if (items == null)
                          SliverPadding(
                            padding: pixivisionPadding(constraints.maxWidth),
                            sliver: SliverToBoxAdapter(
                              child: active.hasError
                                  ? PixivisionError(
                                      error: active.error,
                                      retry: () => ref.invalidate(pixivisionBrowseProvider(section == PixivisionSection.articles ? url : home)),
                                    )
                                  : const PixivisionCardSkeleton(),
                            ),
                          )
                        else
                          SliverPagedDataList<ArticleSummary>(
                            key: ValueKey((url, section)),
                            items: items,
                            hasMore: section == PixivisionSection.articles && listing?.page.nextUrl != null,
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
                                if (listing?.error case final error?)
                                  CompactMessage.error(
                                    error: error,
                                    actionLabel: t.loadMore,
                                    onAction: () => ref.read(pixivisionBrowseProvider(url).notifier).loadMore(),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
    return PixivisionScaffold(
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;
              final search = SearchInput(
                controller: _search,
                focusNode: _focus,
                hintText: t.searchHint,
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) {
                    selectUrl(Uri.parse('${home}s/').replace(queryParameters: {'q': trimmed}).toString());
                    if (compact) setState(() => _searchExpanded = false);
                  }
                },
                onClear: () {
                  _search.clear();
                  if (query.isNotEmpty) selectUrl(home);
                },
              );
              return ContentColumn(
                bleed: 12,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              query.isEmpty ? t.title : query,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (compact)
                            IconButton(
                              tooltip: t.searchHint,
                              onPressed: () {
                                setState(() => _searchExpanded = !_searchExpanded);
                                if (_searchExpanded) {
                                  _focus.requestFocus();
                                } else {
                                  _focus.unfocus();
                                }
                              },
                              icon: Icon(_searchExpanded ? Icons.close : Icons.search),
                            )
                          else
                            SizedBox(width: (constraints.maxWidth * .42).clamp(240, 420), child: search),
                        ],
                      ),
                      if (compact)
                        AnimatedSize(
                          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
                          alignment: Alignment.topCenter,
                          child: _searchExpanded
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Focus(
                                    onKeyEvent: (_, event) {
                                      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                                        _focus.unfocus();
                                        setState(() => _searchExpanded = false);
                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: search,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            // The tabs stay put while the sections slide beneath them.
            child: FpPinnedChrome(
              extent: compactFilterHeight(context),
              chrome: chrome,
              body: TabBarView(controller: _tabController, children: [for (final section in PixivisionSection.values) sectionPage(section)]),
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
                    PixivisionError(error: state.error, retry: () => ref.invalidate(pixivisionTagsProvider(language)))
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
