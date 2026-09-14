import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/logic/search_trending_tags_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_box.dart';
import 'package:freepiv/features/search/presentation/widgets/search_header.dart';
import 'package:freepiv/features/search/presentation/widgets/search_trending_tags.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/features/search/logic/search_history_logic.dart';
import 'pixivision_preview.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'search_history.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _searchBoxKey = GlobalKey<SearchBoxState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SearchHeader(
              searchBoxKey: _searchBoxKey,
              onSearch: _openSearchResult,
              onSelected: _handleSearchSelection,
              showTypeSelector: false,
              showFilters: false,
            ),
            Expanded(
              child: DataRefreshView(
                onRefresh: () async {
                  final language = pixivisionLanguagePath(context.t.$meta.locale);
                  final articles = pixivisionBrowseProvider('https://www.pixivision.net/$language/');
                  ref.invalidate(articles);
                  await Future.wait([ref.read(searchTrendingTagsProvider.notifier).reload(keepPreviousData: true), ref.read(articles.future)]);
                  return true;
                },
                builder: (context, physics, locators) {
                  return DataLoadingCustomScrollView(
                    key: const PageStorageKey('discover-content'),
                    physics: physics,
                    slivers: [
                      ?locators.sliverHeader,
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
                      const SliverToBoxAdapter(child: DiscoveryPixivisionPreview()),
                      SearchTrendingTagsSliver(
                        onTagSelected: (tag) {
                          _searchBoxKey.currentState?.insertPopularTag(tag);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearchResult(SearchSubmission submission) {
    if (submission.query.trim().isEmpty) {
      return;
    }

    final route = switch (submission.type) {
      SearchType.illust => AppRoute.searchIllustResult,
      SearchType.novel => AppRoute.searchNovelResult,
      SearchType.user => AppRoute.searchUserResult,
    };

    unawaited(context.pushNamed(route.name, queryParameters: {'q': submission.query.trim()}));
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
