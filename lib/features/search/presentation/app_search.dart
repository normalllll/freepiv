import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/features/pixivision/navigation.dart';
import 'package:freepiv/features/search/logic/search_history_logic.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/logic/search_trending_tags_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_autocomplete_session.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_models.dart';
import 'package:freepiv/i18n/strings.g.dart';
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

/// How many recent searches and trending tags the dropdown shows.
const _recentSearches = 5;
const _dropdownTrendingTags = 8;
const _dropdownArticles = 3;

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

/// The dropdown's groups. With no input: recent searches, the discover entries,
/// trending tags and Pixivision articles (text rows until Frost can show
/// media in suggestions, freepiv-20261107-search-media-suggestions). With
/// input: search the whole query by type, open a number directly, and
/// complete the last word with a tag.
List<Widget> appSearchSuggestions(BuildContext context, WidgetRef ref, AppSearchActions actions) {
  final t = context.t;
  final session = ref.watch(appSearchSessionProvider);
  final query = session.searchText;
  if (query.isEmpty) {
    final history = ref.watch(searchHistoryProvider);
    final trending = ref.watch(searchTrendingTagsProvider).value ?? const [];
    final language = pixivisionLanguagePath(t.$meta.locale);
    final pixivision = ref.watch(pixivisionBrowseProvider('https://www.pixivision.net/$language/')).value?.page;
    final articles = pixivision == null
        ? const []
        : (pixivision.recommended.isNotEmpty ? pixivision.recommended : pixivision.articles).take(_dropdownArticles).toList();
    return [
      if (history.isNotEmpty)
        FrostSearchSection(
          title: t.discover.history,
          actionLabel: t.appSearch.allHistory,
          onAction: () => actions.open(AppRoute.discover.path),
          children: [
            for (final entry in history.take(_recentSearches))
              FrostSearchSuggestionRow(
                label: entry,
                icon: const FrostIconData.glyph(Icons.history),
                onSelected: () => actions.submit(text: entry),
                onRemove: () => ref.read(searchHistoryProvider.notifier).remove(entry),
              ),
          ],
        ),
      FrostSearchSection(
        title: t.common.discover,
        children: [
          FrostSearchSuggestionRow(label: t.navigation.ranking, icon: PivIcons.activity, onSelected: () => actions.open(AppLocations.ranking())),
          FrostSearchSuggestionRow(label: t.pixivision.title, icon: PivIcons.newspaper, onSelected: () => actions.open(AppRoute.pixivision.path)),
          FrostSearchSuggestionRow(label: t.fanbox.title, icon: PivIcons.heart, onSelected: () => actions.open(AppRoute.fanbox.path)),
        ],
      ),
      if (trending.isNotEmpty)
        FrostSearchSection(
          title: t.search.trendingTags,
          actionLabel: t.appSearch.allTrendingTags,
          onAction: () => actions.open(AppRoute.discover.path),
          children: [
            for (final tag in trending.take(_dropdownTrendingTags))
              FrostSearchSuggestionRow(label: '#${tag.tag}', detail: tag.translatedName, inlineDetail: true, keepsOpen: true, onSelected: () => actions.insertTag(tag.tag)),
          ],
        ),
      if (articles.isNotEmpty)
        FrostSearchSection(
          title: t.pixivision.title,
          actionLabel: t.discover.viewAll,
          onAction: () => actions.open(AppRoute.pixivision.path),
          children: [
            for (final article in articles)
              FrostSearchSuggestionRow(
                label: article.title,
                icon: PivIcons.newspaper,
                onSelected: () {
                  session.unfocus(appendTrailingSpace: false);
                  openPixivisionLink(context, article.url, summary: article);
                },
              ),
          ],
        ),
    ];
  }

  final types = [session.type, ...SearchType.values.where((type) => type != session.type)];
  final direct = session.suggestions.where((suggestion) => suggestion.id != null).toList();
  final tags = session.suggestions.where((suggestion) => suggestion.kind == SearchItemKind.tag).toList();
  return [
    FrostSearchSection(
      title: t.navigation.search,
      children: [
        for (final type in types)
          FrostSearchSuggestionRow(
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
              label: suggestion.label,
              icon: FrostIconData.glyph(suggestion.icon),
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
            FrostSearchSuggestionRow(label: tag.label, detail: tag.subtitle, inlineDetail: true, keepsOpen: true, onSelected: () => session.commitTerm(tag.value)),
        ],
      ),
    if (session.error != null)
      FrostSearchSection(
        children: [FrostSearchSuggestionRow(label: t.common.retry, icon: PivIcons.refreshCw, keepsOpen: true, onSelected: session.retry)],
      ),
  ];
}

/// The dropdown's status line: a failed or empty tag completion.
/// The dropdown content ([FrostCaptionSearch.content]): the suggestion
/// sections, then the completion status.
Widget appSearchContent(BuildContext context, WidgetRef ref, AppSearchActions actions) {
  final session = ref.watch(appSearchSessionProvider);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ...appSearchSuggestions(context, ref, actions),
      FrostSearchStatus(loading: session.loading, message: appSearchMessage(context, session)),
    ],
  );
}

String? appSearchMessage(BuildContext context, SearchAutocompleteSession session) {
  if (session.searchText.isEmpty) return null;
  if (session.error != null) return context.t.appSearch.suggestionsFailed;
  if (!session.loading && session.autocompleteCompleted && session.type != SearchType.user && session.suggestions.isEmpty) {
    return context.t.appSearch.noSuggestions;
  }
  return null;
}

/// The search in the window's title row ([FrostShell.titleBarSearch]).
class AppTitleBarSearch extends ConsumerWidget {
  const AppTitleBarSearch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSearchSessionProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final actions = AppSearchActions(ref, context);
        return FrostCaptionSearch(
          controller: session.controller,
          focusNode: session.focusNode,
          placeholder: context.t.appSearch.placeholder,
          hint: const FrostShortcut(LogicalKeyboardKey.keyK, primary: true).hintLabel(context),
          content: appSearchContent(context, ref, actions),
          onSubmitted: (_) => actions.submit(),
        );
      },
    );
  }
}
