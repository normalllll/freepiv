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
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/illust_waterfall_skeleton.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:go_router/go_router.dart';

class SearchResultPage extends ConsumerStatefulWidget {
  const SearchResultPage({required this.type, required this.initialKeyword, super.key});

  final SearchType type;
  final String initialKeyword;

  @override
  ConsumerState<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends ConsumerState<SearchResultPage> {
  late String _keyword;

  @override
  void initState() {
    super.initState();
    _keyword = widget.initialKeyword.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(searchDraftProvider.notifier).setDraft(SearchDraftState(text: _keyword, type: widget.type));
    });
  }

  @override
  void didUpdateWidget(covariant SearchResultPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextKeyword = widget.initialKeyword.trim();
    if (oldWidget.initialKeyword != widget.initialKeyword && nextKeyword != _keyword) {
      setState(() => _keyword = nextKeyword);
      ref.read(searchDraftProvider.notifier).setDraft(SearchDraftState(text: nextKeyword, type: widget.type));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        return Scaffold(
          appBar: shouldUseDesktopShell ? null : _mobileAppBar(),
          body: SafeArea(
            top: shouldUseDesktopShell,
            bottom: false,
            child: Column(
              children: [
                if (shouldUseDesktopShell)
                  Material(
                    color: colorScheme.surface,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
                      ),
                      child: SearchHeader(showTypeSelector: false, compact: true, onSearch: _submitSearch, onSelected: _handleSearchSelection),
                    ),
                  ),
                Expanded(
                  child: switch (widget.type) {
                    SearchType.illust => _buildIllustResult(),
                    SearchType.novel => _buildNovelResult(),
                    SearchType.user => _buildUserResult(),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _mobileAppBar() {
    return AppBar(
      titleSpacing: 0,
      toolbarHeight: 64,
      title: Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: SearchBox(onSearch: _submitSearch, onSelected: _handleSearchSelection),
      ),
    );
  }

  Widget _buildIllustResult() {
    final filter = ref.watch(searchFiltersProvider.select((state) => state.illust));
    final source = ref.watch(searchIllustResultSourceProvider(SearchResultRequest(keyword: _keyword, filter: filter)));
    _ensureLoaded(source);

    return DataRefreshView(
      onRefresh: () => source.refresh(source.isEmpty),
      builder: (context, physics, locators) {
        return AnimatedBuilder(
          animation: source,
          builder: (context, child) {
            return _IllustResultBody(source: source, physics: physics, locators: locators);
          },
        );
      },
    );
  }

  Widget _buildNovelResult() {
    final filter = ref.watch(searchFiltersProvider.select((state) => state.novel));
    final source = ref.watch(searchNovelResultSourceProvider(SearchResultRequest(keyword: _keyword, filter: filter)));
    _ensureLoaded(source);

    return DataRefreshView(
      onRefresh: () => source.refresh(source.isEmpty),
      builder: (context, physics, locators) {
        return AnimatedBuilder(
          animation: source,
          builder: (context, child) {
            return UserNovelListBody(source: source, physics: physics, sliverHeader: locators.sliverHeader, emptyTitle: context.t.search.empty.novels);
          },
        );
      },
    );
  }

  Widget _buildUserResult() {
    final source = ref.watch(searchUserResultSourceProvider(_keyword));
    _ensureLoaded(source);

    return DataRefreshView(
      onRefresh: () => source.refresh(source.isEmpty),
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
    if (query.isEmpty || (query == _keyword && submission.type == widget.type)) {
      return;
    }

    unawaited(context.pushNamed(_routeForType(submission.type).name, queryParameters: {'q': query}));
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

  void _ensureLoaded<T>(DataListSource<T> source) {
    if (source.initialized || source.refreshing) {
      return;
    }

    Future.microtask(() {
      if (!mounted || source.initialized || source.refreshing) {
        return;
      }
      unawaited(source.refresh(true));
    });
  }
}

AppRoute _routeForType(SearchType type) {
  return switch (type) {
    SearchType.illust => AppRoute.searchIllustResult,
    SearchType.novel => AppRoute.searchNovelResult,
    SearchType.user => AppRoute.searchUserResult,
  };
}

class _IllustResultBody extends StatelessWidget {
  const _IllustResultBody({required this.source, required this.physics, required this.locators});

  final SearchIllustListSource source;
  final ScrollPhysics? physics;
  final DataRefreshLocators locators;

  @override
  Widget build(BuildContext context) {
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return DataLoadingCustomScrollView(physics: physics, slivers: [?locators.sliverHeader, const SliverIllustWaterfallSkeleton()]);
    }

    if (!source.initialized && lastError != null) {
      return DataSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: ErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return DataSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: EmptyContent(icon: Icons.image_not_supported_outlined, title: context.t.search.empty.illustrations),
      );
    }

    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?locators.sliverHeader,
        SliverDataWaterfallGrid<Illust>(
          source: source,
          padding: const EdgeInsets.all(12),
          maxCrossAxisExtent: 240,
          itemBuilder: (context, illust, index) {
            return IllustPreviewer(
              illust: illust,
              onTap: () {
                context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': '${illust.id}'}, extra: illust);
              },
            );
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
  final DataRefreshLocators locators;

  @override
  Widget build(BuildContext context) {
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return DataLoadingCustomScrollView(
        physics: physics,
        slivers: [
          ?locators.sliverHeader,
          const SliverPadding(padding: EdgeInsets.all(12), sliver: SliverUserPreviewerSkeletonList()),
        ],
      );
    }

    if (!source.initialized && lastError != null) {
      return DataSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: ErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return DataSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: EmptyContent(icon: Icons.people_outline, title: context.t.search.empty.users),
      );
    }

    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?locators.sliverHeader,
        SliverDataList<UserPreview>(
          source: source,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, userPreview, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: UserPreviewer(userPreview: userPreview),
            );
          },
        ),
      ],
    );
  }
}
