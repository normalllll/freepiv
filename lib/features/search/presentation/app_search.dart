import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/features/discover/discover_sections.dart';
import 'package:freepiv/features/pixivision/navigation.dart';
import 'package:freepiv/features/search/logic/search_history_logic.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/logic/search_trending_tags_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_autocomplete_session.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_models.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The one search of the app. The title bar search and the page header
/// search show the same controller, focus, draft type and suggestions; only
/// one of them is on screen at a time.
final appSearchSessionProvider = Provider<SearchAutocompleteSession>((ref) {
  final session = SearchAutocompleteSession(initialType: SearchType.illust);
  ref.onDispose(session.dispose);
  return session;
});

/// Whether the title row shows the search right now; kept by
/// [AppSearchPlacementProbe] inside the shell.
final appSearchInCaption = ValueNotifier<bool>(false);

/// Asks the page header search on top to take focus.
final appSearchHeaderFocusRequests = ValueNotifier<int>(0);

/// Ctrl K and the home page's search entry: the title bar search when the
/// title row shows it; otherwise the discover page, opened with its search
/// focused (or, when it is already on top, its search focused again).
void openAppSearch(WidgetRef ref, GoRouter router) {
  if (appSearchInCaption.value) {
    ref.read(appSearchSessionProvider).focusNode.requestFocus();
    return;
  }
  if (AppRoute.match(router.state.uri.path) == AppRoute.discover) {
    appSearchHeaderFocusRequests.value++;
    return;
  }
  router.push(AppLocations.discover(focusSearch: true));
}

/// Marks a search result page: a search submitted from the title bar or a
/// header while it is on top goes to [onSubmitted] instead of opening another
/// result page.
class AppSearchResultsScope extends StatefulWidget {
  const AppSearchResultsScope({required this.onSubmitted, required this.child, super.key});

  final void Function(String query, SearchType type) onSubmitted;
  final Widget child;

  static final List<_AppSearchResultsScopeState> _scopes = [];

  /// The result page on the current route, if any.
  static _AppSearchResultsScopeState? get _visible {
    for (final scope in _scopes.reversed) {
      if (scope.mounted && (ModalRoute.isCurrentOf(scope.context) ?? false)) return scope;
    }
    return null;
  }

  @override
  State<AppSearchResultsScope> createState() => _AppSearchResultsScopeState();
}

class _AppSearchResultsScopeState extends State<AppSearchResultsScope> {
  @override
  void initState() {
    super.initState();
    AppSearchResultsScope._scopes.add(this);
  }

  @override
  void dispose() {
    AppSearchResultsScope._scopes.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Placed in the shell's content: records whether the title row holds the
/// search ([FrostShell.titleContentInCaptionOf]), which the shell's own
/// shortcuts cannot ask from above the shell.
class AppSearchPlacementProbe extends StatelessWidget {
  const AppSearchPlacementProbe({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inCaption = FrostShell.titleContentInCaptionOf(context);
    if (appSearchInCaption.value != inCaption) {
      WidgetsBinding.instance.addPostFrameCallback((_) => appSearchInCaption.value = inCaption);
    }
    return child;
  }
}


AppSearchKind appSearchKind(SearchType type) => switch (type) {
  SearchType.illust => AppSearchKind.illust,
  SearchType.novel => AppSearchKind.novel,
  SearchType.user => AppSearchKind.user,
};

/// What the search does with a query, a chosen suggestion or a tag; shared by
/// the title bar and the page header searches.
class AppSearchActions {
  AppSearchActions(this.ref, this.context, {this.onSubmitted, this.onCollapse});

  final WidgetRef ref;
  final BuildContext context;

  /// Takes the submission instead of opening a result page, for a result page
  /// that reloads in place. Gets the trimmed query and the type.
  final void Function(String query, SearchType type)? onSubmitted;

  /// Closes the input's expanded or dropdown state after a submission.
  final VoidCallback? onCollapse;

  SearchAutocompleteSession get session => ref.read(appSearchSessionProvider);

  /// Searches [text] (the whole query by default) as [type] (the draft type by
  /// default): blank queries do nothing; the query goes into the history, the
  /// input lets go, and a result page on top changes its words in place
  /// instead of opening another one.
  void submit({String? text, SearchType? type}) {
    if (session.isComposing) return;
    final query = (text ?? session.rawText).trim();
    if (query.isEmpty) return;
    final kind = type ?? session.type;
    session.setType(kind);
    ref.read(searchHistoryProvider.notifier).record(query);
    session.unfocus();
    onCollapse?.call();
    if (onSubmitted case final callback?) {
      callback(query, kind);
      return;
    }
    // A result page on top (a tag search included) changes its words in place,
    // keeping its filters, tabs and scroll.
    if (AppSearchResultsScope._visible case final results?) {
      results.widget.onSubmitted(query, kind);
      return;
    }
    GoRouter.of(context).push(AppLocations.search(appSearchKind(kind), query));
  }

  void open(String location) {
    session.unfocus(appendTrailingSpace: false);
    onCollapse?.call();
    GoRouter.of(context).push(location);
  }

  /// Adds [tag] as a completed word and keeps the input open for the next one.
  void insertTag(String tag) {
    session.commitTerm(tag, suppressAutocomplete: true);
    session.focusNode.requestFocus();
  }
}

/// How many recent searches and trending tags the compact discover shows.
const appSearchRecentCount = 5;
const appSearchTagCount = 8;

/// Trending tags stand in rows of this many in the compact discover.
const appSearchTagColumns = 4;

/// The dropdown's content ([FrostCaptionSearch.content],
/// [FrostSearchInput.suggesting]). With no input, the compact discover:
/// the last searches, two rows of trending tag cards and
/// a row of Pixivision cards, each section only when it has something. With
/// input: search the whole query by type, open a number
/// directly, complete the last word with a tag, and the completion's status,
/// a failure with its details and a retry. Every row and card is an option
/// the field's arrow keys and Enter reach.
///
/// The compact discover belongs to the title bar search; a page header
/// search ([compactDiscover] false) shows nothing until there is input,
/// the page under it being the discover page or results.
Widget? appSearchContent(BuildContext context, WidgetRef ref, AppSearchActions actions, {bool compactDiscover = true}) {
  final session = ref.watch(appSearchSessionProvider);
  if (session.searchText.isEmpty) return compactDiscover ? _CompactDiscover(actions: actions) : null;
  return _Suggestions(actions: actions);
}

/// Each time the dropdown opens on the compact discover, stale trending tags
/// and Pixivision are fetched again behind what is shown.
void appSearchOpened(WidgetRef ref, BuildContext context) {
  if (ref.read(appSearchSessionProvider).searchText.isNotEmpty) return;
  ref.read(discoverFreshnessProvider).refreshIfStale(ref, context.t);
}

class _CompactDiscover extends ConsumerWidget {
  const _CompactDiscover({required this.actions});

  final AppSearchActions actions;

  /// Tag cards are a little wider than tall, so two rows and the rest fit
  /// the dropdown without scrolling.
  static const _tagAspect = 3 / 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final history = ref.watch(searchHistoryProvider);
    final trending = ref.watch(searchTrendingTagsProvider).value ?? const [];
    final listing = ref.watch(discoverPixivision(t)).value;
    final articles = listing == null ? const <ArticleSummary>[] : discoverArticles(listing);
    final tags = trending.take(appSearchTagCount).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (history.isNotEmpty)
          FrostSearchSection(
            title: t.discover.history,
            actionLabel: t.appSearch.allHistory,
            onAction: () => actions.open(AppLocations.discover(section: DiscoverSection.history.name)),
            children: [
              for (final entry in history.take(appSearchRecentCount))
                FrostSearchSuggestionRow(
                  key: ValueKey(('history', entry)),
                  label: entry,
                  icon: PivIcons.history,
                  onSelected: () => actions.submit(text: entry),
                  onRemove: () => ref.read(searchHistoryProvider.notifier).remove(entry),
                ),
            ],
          ),
        if (tags.isNotEmpty)
          FrostSearchSection(
            title: t.search.trendingTags,
            actionLabel: t.appSearch.allTrendingTags,
            onAction: () => actions.open(AppLocations.discover(section: DiscoverSection.trending.name)),
            children: [
              for (var start = 0; start < tags.length; start += appSearchTagColumns)
                Padding(
                  padding: EdgeInsets.only(top: start == 0 ? 0 : FrostGap.inline),
                  child: _OptionRow(
                    columns: appSearchTagColumns,
                    children: [
                      for (final tag in tags.skip(start).take(appSearchTagColumns))
                        FrostSearchOption(
                          key: ValueKey(('tag', tag.tag)),
                          keepsOpen: true,
                          semanticLabel: '#${tag.tag}',
                          onSelected: () => actions.insertTag(tag.tag),
                          // The option takes the tap; the card only shows.
                          child: IgnorePointer(child: DiscoverTagCard(tag: tag, aspectRatio: _tagAspect)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        if (articles.isNotEmpty)
          FrostSearchSection(
            title: t.pixivision.title,
            actionLabel: t.discover.viewAll,
            onAction: () => actions.open(AppRoute.pixivision.path),
            children: [
              _OptionRow(
                columns: discoverArticleCount,
                children: [
                  for (final article in articles)
                    FrostSearchOption(
                      key: ValueKey(('article', article.id)),
                      semanticLabel: article.title,
                      onSelected: () {
                        actions.session.unfocus(appendTrailingSpace: false);
                        actions.onCollapse?.call();
                        unawaited(openPixivisionLink(context, article.url, summary: article));
                      },
                      child: IgnorePointer(child: DiscoverArticleCard(article: article, titleLines: 1)),
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

/// Options sharing a row in equal columns; a short row keeps its columns.
class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FrostGap.inline,
    children: [for (var index = 0; index < columns; index++) Expanded(child: index < children.length ? children[index] : const SizedBox.shrink())],
  );
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.actions});

  final AppSearchActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final session = ref.watch(appSearchSessionProvider);
    final query = session.searchText;
    final types = [session.type, ...SearchType.values.where((type) => type != session.type)];
    final direct = session.suggestions.where((suggestion) => suggestion.id != null).toList();
    final tags = session.suggestions.where((suggestion) => suggestion.kind == SearchItemKind.tag).toList();
    final error = session.error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostSearchSection(
          title: t.navigation.search,
          children: [
            for (final type in types)
              FrostSearchSuggestionRow(
                key: ValueKey(('search', type)),
                label: switch (type) {
                  SearchType.illust => t.appSearch.searchIllust(query: query),
                  SearchType.novel => t.appSearch.searchNovel(query: query),
                  SearchType.user => t.appSearch.searchUser(query: query),
                },
                icon: PivIcons.search,
                onSelected: () => actions.submit(type: type),
              ),
          ],
        ),
        if (direct.isNotEmpty)
          FrostSearchSection(
            title: t.appSearch.openGroup,
            children: [
              for (final suggestion in direct)
                FrostSearchSuggestionRow(
                  key: ValueKey(('open', suggestion.kind)),
                  label: suggestion.label,
                  icon: switch (suggestion.kind) {
                    SearchItemKind.illust => PivIcons.image,
                    SearchItemKind.user => PivIcons.user,
                    SearchItemKind.novel || SearchItemKind.tag => PivIcons.bookOpen,
                  },
                  onSelected: () => actions.open(switch (suggestion.kind) {
                    SearchItemKind.illust => AppLocations.illust(suggestion.id!),
                    SearchItemKind.user => AppLocations.user(suggestion.id!),
                    SearchItemKind.novel || SearchItemKind.tag => AppLocations.novel(suggestion.id!),
                  }),
                ),
            ],
          ),
        if (tags.isNotEmpty)
          FrostSearchSection(
            title: t.appSearch.tagGroup,
            children: [
              for (final tag in tags)
                FrostSearchSuggestionRow(
                  key: ValueKey(('completion', tag.value)),
                  label: tag.label,
                  icon: PivIcons.tags,
                  detail: tag.subtitle,
                  inlineDetail: true,
                  keepsOpen: true,
                  onSelected: () => session.commitTerm(tag.value),
                ),
            ],
          ),
        FrostSearchStatus(loading: session.loading, message: appSearchMessage(context, session)),
        if (error != null)
          FrostSearchSection(
            children: [
              FrostSearchSuggestionRow(
                key: const ValueKey('completion-retry'),
                label: t.common.retry,
                icon: PivIcons.refreshCw,
                keepsOpen: true,
                onSelected: session.retry,
              ),
              FrostErrorDetails.quiet(details: pixivErrorDetails(error)),
            ],
          ),
      ],
    );
  }
}

/// The dropdown's status line: a failed or empty tag completion.
String? appSearchMessage(BuildContext context, SearchAutocompleteSession session) {
  if (session.searchText.isEmpty) return null;
  if (session.error != null) return context.t.appSearch.suggestionsFailed;
  if (!session.loading && session.autocompleteCompleted && session.type != SearchType.user && session.suggestions.isEmpty) {
    return context.t.appSearch.noSuggestions;
  }
  return null;
}

/// The search in the window's title row ([FrostShell.titleBarSearch]).
class AppTitleBarSearch extends ConsumerStatefulWidget {
  const AppTitleBarSearch({super.key});

  @override
  ConsumerState<AppTitleBarSearch> createState() => _AppTitleBarSearchState();
}

class _AppTitleBarSearchState extends ConsumerState<AppTitleBarSearch> {
  late final SearchAutocompleteSession _session = ref.read(appSearchSessionProvider);

  @override
  void initState() {
    super.initState();
    _session.focusNode.addListener(_focusChanged);
  }

  @override
  void dispose() {
    _session.focusNode.removeListener(_focusChanged);
    super.dispose();
  }

  void _focusChanged() {
    if (_session.focusNode.hasFocus && mounted) appSearchOpened(ref, context);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _session,
    builder: (context, _) {
      final actions = AppSearchActions(ref, context);
      final t = context.t;
      String label(SearchType type) => switch (type) {
        SearchType.illust => t.search.type.illustManga,
        SearchType.novel => t.search.type.novel,
        SearchType.user => t.search.type.user,
      };
      return FrostCaptionSearch(
        controller: _session.controller,
        focusNode: _session.focusNode,
        placeholder: t.appSearch.placeholder,
        content: appSearchContent(context, ref, actions),
        actions: [
          FrostToolbarMenuButton(
            label: t.common.type,
            valueLabel: label(_session.type),
            entries: [
              for (final type in SearchType.values) FrostMenuAction(label(type), checked: type == _session.type, onSelected: () => _session.setType(type)),
            ],
          ),
        ],
        onSubmitted: (_) => actions.submit(),
      );
    },
  );
}
