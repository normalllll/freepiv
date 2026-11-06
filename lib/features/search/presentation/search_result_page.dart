import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_box.dart';
import 'package:freepiv/features/search/presentation/widgets/search_header.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_novel_list_tab.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/illust_waterfall_skeleton.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:go_router/go_router.dart';
import 'package:frost_data/frost_data.dart';

class _ScopedSearchResultPage extends ConsumerStatefulWidget {
  const _ScopedSearchResultPage({required this.type, required this.initialKeyword});

  final SearchType type;
  final String initialKeyword;

  @override
  ConsumerState<_ScopedSearchResultPage> createState() => _SearchResultPageState();
}

const _searchTypeOrder = [SearchType.illust, SearchType.novel, SearchType.user];

class _SearchResultPageState extends ConsumerState<_ScopedSearchResultPage> with SingleTickerProviderStateMixin {
  late String _keyword;

  /// The query box was emptied: the old results no longer answer anything
  /// on screen, so they stay hidden until the next search.
  bool _cleared = false;
  late final TabController _tabs = TabController(length: _searchTypeOrder.length, initialIndex: _searchTypeOrder.indexOf(widget.type), vsync: this);

  @override
  void initState() {
    super.initState();
    _keyword = widget.initialKeyword.trim();
    _tabs.addListener(_syncDraftType);
  }

  @override
  void dispose() {
    _tabs.removeListener(_syncDraftType);
    _tabs.dispose();
    super.dispose();
  }

  /// The draft type follows the page the tabs are on, so the filter and the
  /// type controls beside the query show the visible type.
  void _syncDraftType() {
    final type = _searchTypeOrder[_tabs.index];
    final draft = ref.read(searchDraftProvider);
    if (draft.type != type) ref.read(searchDraftProvider.notifier).setDraft(draft.copyWith(type: type));
  }

  void _showType(SearchType type) {
    final index = _searchTypeOrder.indexOf(type);
    if (_tabs.index != index) _tabs.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchDraftProvider.select((draft) => draft.type), (_, type) => _showType(type));
    ref.listen(searchDraftProvider.select((draft) => draft.text.trim().isEmpty), (_, empty) {
      if (empty && !_cleared) setState(() => _cleared = true);
    });
    return FrostAutoScaffold(
      builder: (BuildContext context, FrostSizeLayout layout, Orientation orientation, bool useHorizontalLayout) {
        // The query bar floats over the results; they scroll beneath it.
        return Scaffold(
          body: FrostPinnedChrome(
            chrome: SafeArea(
              bottom: false,
              child: SearchHeader(
                showBackButton: !useHorizontalLayout,
                onBack: () => Navigator.of(context).maybePop(),
                onSearch: _submitSearch,
                onSelected: _handleSearchSelection,
                onTypeChanged: _showType,
                typeController: _tabs,
              ),
            ),
            body: _cleared
                ? const SizedBox.expand()
                : TabBarView(
                    controller: _tabs,
                    children: [
                      // A new keyword gets fresh tabs, so each starts at the top.
                      FrostKeepAlive(
                        key: ValueKey(('illust', _keyword)),
                        child: Consumer(builder: (context, ref, _) => _buildIllustResult(ref)),
                      ),
                      FrostKeepAlive(
                        key: ValueKey(('novel', _keyword)),
                        child: Consumer(builder: (context, ref, _) => _buildNovelResult(ref)),
                      ),
                      FrostKeepAlive(
                        key: ValueKey(('user', _keyword)),
                        child: Consumer(builder: (context, ref, _) => _buildUserResult(ref)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildIllustResult(WidgetRef ref) {
    final filter = ref.watch(searchFiltersProvider.select((state) => state.illust));
    final source = ref.watch(searchIllustResultSourceProvider(SearchResultRequest(keyword: _keyword, filter: filter)));
    _ensureLoaded(source);

    return FrostRefreshView(
      key: ValueKey(filter),
      onRefresh: () => source.refresh(source.items.isEmpty),
      builder: (context, physics, locators) {
        return AnimatedBuilder(
          animation: source,
          builder: (context, child) {
            return _IllustResultBody(
              source: source,
              physics: physics,
              locators: locators,
              hasActiveFilter: filter != const SearchFilterState(),
              onResetFilters: () => ref.read(searchFiltersProvider.notifier).setFilter(SearchType.illust, const SearchFilterState()),
            );
          },
        );
      },
    );
  }

  Widget _buildNovelResult(WidgetRef ref) {
    final filter = ref.watch(searchFiltersProvider.select((state) => state.novel));
    final source = ref.watch(searchNovelResultSourceProvider(SearchResultRequest(keyword: _keyword, filter: filter)));
    _ensureLoaded(source);

    return FrostRefreshView(
      key: ValueKey(filter),
      onRefresh: () => source.refresh(source.items.isEmpty),
      builder: (context, physics, locators) {
        return AnimatedBuilder(
          animation: source,
          builder: (context, child) {
            if (source.initialized && source.items.isEmpty && filter != const SearchFilterState()) {
              return FrostSliverFillBody(
                physics: physics,
                sliverHeader: frostChromeSliverHeader(locators.sliverHeader),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FrostEmptyState(icon: FrostIconData.glyph(Icons.menu_book_outlined), title: context.t.search.empty.novels),
                    TextButton(
                      onPressed: () => ref.read(searchFiltersProvider.notifier).setFilter(SearchType.novel, const SearchFilterState()),
                      child: Text(context.t.common.reset),
                    ),
                  ],
                ),
              );
            }
            return UserNovelListBody(
              source: source,
              physics: physics,
              sliverHeader: frostChromeSliverHeader(locators.sliverHeader),
              emptyTitle: context.t.search.empty.novels,
            );
          },
        );
      },
    );
  }

  Widget _buildUserResult(WidgetRef ref) {
    final source = ref.watch(searchUserResultSourceProvider(_keyword));
    _ensureLoaded(source);

    return FrostRefreshView(
      onRefresh: () => source.refresh(source.items.isEmpty),
      builder: (context, physics, locators) {
        return AnimatedBuilder(
          animation: source,
          builder: (context, child) {
            return _UserResultBody(source: source, physics: physics, locators: locators);
          },
        );
      },
    );
  }

  void _submitSearch(SearchSubmission submission) {
    final query = submission.query.trim();
    if (query.isEmpty) return;
    // A new keyword reloads this page's tabs rather than opening another page.
    if (query != _keyword || _cleared) {
      setState(() {
        _keyword = query;
        _cleared = false;
      });
    }
    _showType(submission.type);
  }

  void _handleSearchSelection(SearchSelection selection) {
    switch (selection.kind) {
      case SearchItemKind.illust:
        final id = selection.id;
        if (id == null) {
          return;
        }
        context.push(AppLocations.illust(id));
        return;
      case SearchItemKind.user:
        final id = selection.id;
        if (id == null) {
          return;
        }
        context.push(AppLocations.user(id));
        return;
      case SearchItemKind.novel:
        final id = selection.id;
        if (id == null) {
          return;
        }
        context.push(AppLocations.novel(id));
        return;
      case SearchItemKind.tag:
        return;
    }
  }

  void _ensureLoaded<T>(FrostListSource<T> source) {
    if (source.initialized || source.refreshing || source.lastError != null) {
      return;
    }

    Future.microtask(() {
      if (!mounted || source.initialized || source.refreshing || source.lastError != null) {
        return;
      }
      unawaited(source.refresh(true));
    });
  }
}

class _IllustResultBody extends StatelessWidget {
  const _IllustResultBody({required this.source, required this.physics, required this.locators, required this.hasActiveFilter, required this.onResetFilters});

  final SearchIllustListSource source;
  final ScrollPhysics? physics;
  final FrostRefreshLocators locators;
  final bool hasActiveFilter;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) => FrostLoadStateSwitcher(phase: source.phase, child: _buildPhase(context));

  Widget _buildPhase(BuildContext context) {
    final lastError = source.lastError;

    if (source.phase == FrostLoadPhase.loading) {
      return FrostLoadingScrollView(physics: physics, slivers: [frostChromeSliverHeader(locators.sliverHeader), const SliverIllustWaterfallSkeleton()]);
    }

    if (!source.initialized && lastError != null) {
      return FrostSliverFillBody(
        physics: physics,
        sliverHeader: frostChromeSliverHeader(locators.sliverHeader),
        child: FrostErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.items.isEmpty) {
      return FrostSliverFillBody(
        physics: physics,
        sliverHeader: frostChromeSliverHeader(locators.sliverHeader),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FrostEmptyState(icon: FrostIconData.glyph(Icons.image_not_supported_outlined), title: context.t.search.empty.illustrations),
            if (hasActiveFilter) TextButton(onPressed: onResetFilters, child: Text(context.t.common.reset)),
          ],
        ),
      );
    }

    return FrostLoadingScrollView(
      physics: physics,
      slivers: [
        frostChromeSliverHeader(locators.sliverHeader),
        FrostSliverDataWaterfallGrid<Illust>(
          firstLoadSkeleton: const FullScreenLoadingSkeleton(),
          source: source,
          itemBuilder: (context, illust, index) {
            return IllustPreviewer(illust: illust, onOpen: (heroTag) => openIllustDetail(context, illust, heroTag));
          },
        ),
      ],
    );
  }
}

class _UserResultBody extends StatelessWidget {
  const _UserResultBody({required this.source, required this.physics, required this.locators});

  final SearchUserListSource source;
  final ScrollPhysics? physics;
  final FrostRefreshLocators locators;

  @override
  Widget build(BuildContext context) => FrostLoadStateSwitcher(phase: source.phase, child: _buildPhase(context));

  Widget _buildPhase(BuildContext context) {
    final lastError = source.lastError;

    if (source.phase == FrostLoadPhase.loading) {
      return FrostLoadingScrollView(physics: physics, slivers: [frostChromeSliverHeader(locators.sliverHeader), const SliverUserPreviewerSkeletonGrid()]);
    }

    if (!source.initialized && lastError != null) {
      return FrostSliverFillBody(
        physics: physics,
        sliverHeader: frostChromeSliverHeader(locators.sliverHeader),
        child: FrostErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.items.isEmpty) {
      return FrostSliverFillBody(
        physics: physics,
        sliverHeader: frostChromeSliverHeader(locators.sliverHeader),
        child: FrostEmptyState(icon: FrostIconData.glyph(Icons.people_outline), title: context.t.search.empty.users),
      );
    }

    return FrostLoadingScrollView(
      physics: physics,
      slivers: [
        frostChromeSliverHeader(locators.sliverHeader),
        SliverUserPreviewGrid(source: source),
      ],
    );
  }
}

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
