import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:freepiv/shared/layout/fp_pinned_chrome.dart';
import 'package:freepiv/shared/layout/content_viewport.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/logic/search_trending_tags_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_box.dart';
import 'package:freepiv/features/search/presentation/widgets/search_header.dart';
import 'package:freepiv/features/search/presentation/widgets/search_trending_tags.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/layout/shell_navigation_scope.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/features/search/logic/search_history_logic.dart';
import 'pixivision_preview.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/ui/fp_icon.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';
import 'package:freepiv/shared/widgets/app_click_surface.dart';
import 'search_history.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _searchBoxKey = GlobalKey<SearchBoxState>();
  final _scrollController = ScrollController();
  ValueListenable<({AppRoute route, int sequence})>? _primaryReselection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ShellNavigationScope.maybeOf(context)?.primaryReselection;
    if (identical(next, _primaryReselection)) return;
    _primaryReselection?.removeListener(_handlePrimaryReselection);
    _primaryReselection = next;
    next?.addListener(_handlePrimaryReselection);
  }

  void _handlePrimaryReselection() {
    final signal = _primaryReselection?.value;
    if (signal == null || signal.route != AppRoute.search || signal.sequence == 0 || !_scrollController.hasClients) return;
    final duration = AppMotion.duration(context, AppMotion.navigation);
    if (duration == Duration.zero) {
      _scrollController.jumpTo(0);
    } else {
      unawaited(_scrollController.animateTo(0, duration: duration, curve: Curves.easeOutCubic));
    }
  }

  @override
  void dispose() {
    _primaryReselection?.removeListener(_handlePrimaryReselection);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The search row floats over the page as glass, like the results page's;
    // the sections scroll beneath it.
    return Scaffold(
      body: FpPinnedChrome(
        estimatedExtent: MediaQuery.paddingOf(context).top + AppMetrics.compactTargetHeight + AppMetrics.compactGap * 2,
        chrome: SafeArea(
          bottom: false,
          child: SearchHeader(
            searchBoxKey: _searchBoxKey,
            onSearch: _openSearchResult,
            onSelected: _handleSearchSelection,
            typePlacement: SearchTypePlacement.besideQuery,
            showFilters: false,
          ),
        ),
        body: DataRefreshView(
          onRefresh: () async {
            final language = pixivisionLanguagePath(context.t.$meta.locale);
            final articles = pixivisionBrowseProvider('https://www.pixivision.net/$language/');
            ref.invalidate(articles);
            await Future.wait([ref.read(searchTrendingTagsProvider.notifier).reload(keepPreviousData: true), ref.read(articles.future)]);
            return true;
          },
          builder: (context, physics, locators) {
            final overview = <Widget>[
              SliverToBoxAdapter(
                child: DiscoverySearchHistory(
                  onSelected: (query) {
                    final draft = ref.read(searchDraftProvider);
                    ref.read(searchDraftProvider.notifier).setDraft(draft.copyWith(text: query));
                    ref.read(searchHistoryProvider.notifier).record(query);
                    _openSearchResult(SearchSubmission(type: draft.type, query: query));
                  },
                ),
              ),
              const SliverToBoxAdapter(child: _FanboxEntry()),
              const SliverToBoxAdapter(child: DiscoveryPixivisionPreview()),
            ];
            final trending = <Widget>[
              SliverToBoxAdapter(
                child: ContentColumn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(context.t.search.trendingTags, style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ),
                ),
              ),
              SearchTrendingTagsSliver(
                onTagSelected: (tag) {
                  _searchBoxKey.currentState?.insertPopularTag(tag);
                },
              ),
            ];
            return DataLoadingCustomScrollView(
              key: const PageStorageKey('discover-content'),
              controller: _scrollController,
              physics: physics,
              slivers: [chromeSliverHeader(locators.sliverHeader), ...overview, ...trending],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openSearchResult(SearchSubmission submission) async {
    if (submission.query.trim().isEmpty) {
      return;
    }

    final route = switch (submission.type) {
      SearchType.illust => AppRoute.searchIllustResult,
      SearchType.novel => AppRoute.searchNovelResult,
      SearchType.user => AppRoute.searchUserResult,
    };

    await context.pushNamed(route.name, queryParameters: {'q': submission.query.trim()});
    // Coming back from the results, the box starts empty again; the query
    // lives on in recent searches.
    if (!mounted) return;
    final draft = ref.read(searchDraftProvider);
    ref.read(searchDraftProvider.notifier).setDraft(draft.copyWith(text: ''));
  }

  void _handleSearchSelection(SearchSelection selection) {
    switch (selection.kind) {
      case SearchItemKind.illust:
        final id = selection.id;
        if (id == null) {
          return;
        }
        context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': '$id'});
        return;
      case SearchItemKind.user:
        final id = selection.id;
        if (id == null) {
          return;
        }
        context.pushNamed(AppRoute.userDetail.name, pathParameters: {'id': '$id'});
        return;
      case SearchItemKind.novel:
        final id = selection.id;
        if (id == null) {
          return;
        }
        context.pushNamed(AppRoute.novelDetail.name, pathParameters: {'id': '$id'});
        return;
      case SearchItemKind.tag:
        return;
    }
  }
}

class _FanboxEntry extends StatelessWidget {
  const _FanboxEntry();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ContentColumn(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: FpSurface(
          role: FpSurfaceRole.glassPanel,
          child: AppClickSurface(
            borderRadius: BorderRadius.circular(AppMetrics.groupRadius),
            onTap: () => context.pushNamed(AppRoute.fanbox.name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FpIcon(FpIconName.heart, color: scheme.onSurface),
                  const SizedBox(width: 12),
                  Expanded(child: Text(context.t.fanbox.title, style: Theme.of(context).textTheme.titleSmall)),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
