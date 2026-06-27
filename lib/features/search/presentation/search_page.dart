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

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchBoxKey = GlobalKey<SearchBoxState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SearchHeader(searchBoxKey: _searchBoxKey, onSearch: _openSearchResult, onSelected: _handleSearchSelection),
            Expanded(
              child: DataRefreshView(
                onRefresh: () async {
                  await ref.read(searchTrendingTagsProvider.notifier).reload(keepPreviousData: true);
                  return true;
                },
                builder: (context, physics, locators) {
                  return DataLoadingCustomScrollView(
                    physics: physics,
                    slivers: [
                      ?locators.sliverHeader,
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
