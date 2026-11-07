import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/features/search/presentation/search_filter_panel.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_box.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/sectioned_page.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';

/// Search results: Illust & Manga, Novels and Users as
/// sections of one page, each loading and failing on its own. Sort and
/// Filter sit at the end of the tab row; the filters in effect show over the
/// results. A search submitted while this page is on top changes its words
/// in place.
class SearchResultPage extends ConsumerWidget {
  const SearchResultPage({required this.type, required this.initialKeyword, this.initialFilters, super.key});

  final SearchType type;
  final String initialKeyword;
  final SearchFiltersState? initialFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ProviderScope(
    key: ValueKey((type, initialKeyword)),
    overrides: [
      searchDraftProvider.overrideWith(() => _ResultDraft(SearchDraftState(text: initialKeyword.trim(), type: type))),
      searchFiltersProvider.overrideWith(() => _ResultFilters(initialFilters ?? ref.read(searchFiltersProvider))),
    ],
    child: _ScopedSearchResultPage(type: type, initialKeyword: initialKeyword),
  );
}

class _ResultDraft extends SearchDraft {
  _ResultDraft(this.initial);
  final SearchDraftState initial;
  @override
  SearchDraftState build() => initial;
}

class _ResultFilters extends SearchFilters {
  _ResultFilters(this.initial);
  final SearchFiltersState initial;
  @override
  SearchFiltersState build() => initial;
}

const _types = [SearchType.illust, SearchType.novel, SearchType.user];

class _ScopedSearchResultPage extends ConsumerStatefulWidget {
  const _ScopedSearchResultPage({required this.type, required this.initialKeyword});

  final SearchType type;
  final String initialKeyword;

  @override
  ConsumerState<_ScopedSearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends ConsumerState<_ScopedSearchResultPage> with SingleTickerProviderStateMixin {
  late String _keyword = widget.initialKeyword.trim();
  late final _tabs = TabController(length: _types.length, initialIndex: _types.indexOf(widget.type), vsync: this)..addListener(_syncDraftType);

  SearchType get _type => _types[_tabs.index];

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// The draft type follows the visible tab.
  void _syncDraftType() {
    if (_tabs.indexIsChanging) return;
    final draft = ref.read(searchDraftProvider);
    if (draft.type != _type) ref.read(searchDraftProvider.notifier).setDraft(draft.copyWith(type: _type));
    setState(() {});
  }

  void _show(SearchType type) {
    final index = _types.indexOf(type);
    if (_tabs.index != index) _tabs.animateTo(index);
  }

  void _submit(SearchSubmission submission) {
    final query = submission.query.trim();
    if (query.isEmpty) return;
    if (query != _keyword) setState(() => _keyword = query);
    _show(submission.type);
  }

  SearchFilterState _filterOf(SearchType type) => switch (type) {
    SearchType.illust => ref.watch(searchFiltersProvider.select((state) => state.illust)),
    SearchType.novel => ref.watch(searchFiltersProvider.select((state) => state.novel)),
    SearchType.user => const SearchFilterState(),
  };

  void _setFilter(SearchType type, SearchFilterState filter) => ref.read(searchFiltersProvider.notifier).setFilter(type, filter);

  FrostListSource<Object?> _source(SearchType type) => switch (type) {
    SearchType.illust => ref.read(searchIllustResultSourceProvider(SearchResultRequest(keyword: _keyword, filter: _filterOf(type)))),
    SearchType.novel => ref.read(searchNovelResultSourceProvider(SearchResultRequest(keyword: _keyword, filter: _filterOf(type)))),
    SearchType.user => ref.read(searchUserResultSourceProvider(_keyword)),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    ref.listen(searchDraftProvider.select((draft) => draft.type), (_, type) => _show(type));
    final inCaption = FrostShell.titleContentInCaptionOf(context);
    return AppSearchResultsScope(
      onSubmitted: (query, type) => _submit(SearchSubmission(type: type, query: query)),
      child: AppSectionedPage(
        controller: _tabs,
        header: FrostPageHeader(
          title: inCaption ? FrostText(_keyword) : null,
          middle: inCaption ? null : SearchBox(onSearch: _submit),
        ),
        tabs: [
          FrostTab(label: t.search.type.illustManga),
          FrostTab(label: t.search.type.novel),
          FrostTab(label: t.search.type.user),
        ],
        trailing: _ResultControls(type: _type, filter: _filterOf(_type), onChanged: (filter) => _setFilter(_type, filter)),
        onRefresh: (section) async => _source(_types[section]).refresh(false),
        // New words start each tab again at its top.
        sectionKey: (section) => (_types[section], _keyword),
        slivers: (context, section) => _slivers(context, _types[section]),
      ),
    );
  }

  List<Widget> _slivers(BuildContext context, SearchType type) {
    final t = context.t;
    final filter = _filterOf(type);
    final active = activeSearchFilters(t, type, filter);
    Widget empty(String title) => FrostEmptyState(
      icon: FrostIconSet.of(context).empty,
      title: title,
      actionLabel: active.isEmpty ? null : t.searchPage.clearFilters,
      onAction: active.isEmpty ? null : () => _setFilter(type, SearchFilterState(order: filter.order)),
    );
    final bar = [
      if (active.isNotEmpty)
        SliverToBoxAdapter(
          child: FrostContentColumn(
            maxWidth: double.infinity,
            child: FrostFilterBar(
              chips: [for (final chip in active) FrostFilterChip(label: chip.label, value: chip.value, onClear: () => _setFilter(type, chip.cleared))],
              onClearAll: () => _setFilter(type, SearchFilterState(order: filter.order)),
            ),
          ),
        ),
      if (filter.isPopularPreview)
        SliverToBoxAdapter(
          child: FrostContentColumn(
            maxWidth: double.infinity,
            child: FrostText(t.search.filters.previewNote, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
          ),
        ),
    ];
    return switch (type) {
      SearchType.illust => [
        ...bar,
        FrostSliverDataWaterfallGrid<Illust>(
          key: ValueKey(('illust', _keyword)),
          source: ref.watch(searchIllustResultSourceProvider(SearchResultRequest(keyword: _keyword, filter: filter))),
          firstLoadSkeleton: const AppArtworkWaterfallSkeleton(),
          empty: empty(t.search.empty.illustrations),
          itemBuilder: (context, illust, index) => AppArtworkCard(illust: illust),
        ),
      ],
      SearchType.novel => [
        ...bar,
        FrostSliverContentColumn(
          maxWidth: FrostMetrics.readingMaxWidth,
          sliver: FrostSliverDataList<Novel>(
            key: ValueKey(('novel', _keyword)),
            source: ref.watch(searchNovelResultSourceProvider(SearchResultRequest(keyword: _keyword, filter: filter))),
            firstLoadSkeleton: const AppRowsSkeleton(),
            empty: empty(t.search.empty.novels),
            itemBuilder: (context, novel, index) => AppNovelRow(novel: novel),
          ),
        ),
      ],
      SearchType.user => [
        FrostSliverContentColumn(
          maxWidth: FrostMetrics.readingMaxWidth,
          sliver: FrostSliverDataList<UserPreview>(
            key: ValueKey(('user', _keyword)),
            source: ref.watch(searchUserResultSourceProvider(_keyword)),
            firstLoadSkeleton: const AppRowsSkeleton(),
            empty: empty(t.search.empty.users),
            itemBuilder: (context, preview, index) => AppUserRow(preview: preview),
          ),
        ),
      ],
    };
  }
}

/// Sort and Filter for the visible tab; users have neither, Filter says why.
class _ResultControls extends StatelessWidget {
  const _ResultControls({required this.type, required this.filter, required this.onChanged});

  final SearchType type;
  final SearchFilterState filter;
  final ValueChanged<SearchFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final users = type == SearchType.user;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FrostGap.inline,
      children: [
        if (!users)
          FrostToolbarMenuButton(
            label: t.search.filters.sort,
            valueLabel: t.order(filter.order),
            icon: FrostIconSet.of(context).sort,
            entries: [
              for (final order in SearchOrder.values)
                FrostMenuAction(
                  t.order(order),
                  checked: filter.order == order,
                  onSelected: () => onChanged(filter.copyWith(order: order)),
                ),
            ],
          ),
        if (users)
          FrostButton.icon(icon: FrostIconSet.of(context).filter, label: t.common.filter, tooltip: t.searchPage.noUserFilters, onPressed: null)
        else
          FrostPopover(
            title: t.search.filters.title,
            maxWidth: SearchFilterPanel.popoverWidth,
            builder: (context, focusNode, toggle) => Focus(
              focusNode: focusNode,
              child: FrostButton.icon(icon: FrostIconSet.of(context).filter, label: t.common.filter, onPressed: toggle),
            ),
            contentBuilder: (context, close) => SearchFilterPanel(
              type: type,
              filter: filter,
              onCancel: close,
              onApply: (applied) {
                close();
                onChanged(applied);
              },
            ),
          ),
      ],
    );
  }
}
