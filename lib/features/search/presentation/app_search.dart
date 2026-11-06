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
    final router = GoRouter.of(context);
    final location = AppLocations.search(appSearchKind(kind), query);
    final top = AppRoute.match(router.state.uri.path);
    final onResults = top == AppRoute.searchIllustResult || top == AppRoute.searchNovelResult || top == AppRoute.searchUserResult;
    if (onResults) {
      router.pushReplacement(location);
    } else {
      router.push(location);
    }
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
List<FrostSearchSuggestionGroup> appSearchSuggestions(BuildContext context, WidgetRef ref, AppSearchActions actions) {
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
        FrostSearchSuggestionGroup(
          title: t.discover.history,
          actionLabel: t.appSearch.allHistory,
          onAction: () => actions.open(AppRoute.discover.path),
          items: [
            for (final entry in history.take(_recentSearches))
              FrostSearchSuggestion(
                label: entry,
                icon: const FrostIconData.glyph(Icons.history),
                onSelected: () => actions.submit(text: entry),
                onRemove: () => ref.read(searchHistoryProvider.notifier).remove(entry),
              ),
          ],
        ),
      FrostSearchSuggestionGroup(
        title: t.common.discover,
        items: [
          FrostSearchSuggestion(label: t.navigation.ranking, icon: PivIcons.activity, onSelected: () => actions.open(AppLocations.ranking())),
          FrostSearchSuggestion(label: t.pixivision.title, icon: PivIcons.newspaper, onSelected: () => actions.open(AppRoute.pixivision.path)),
          FrostSearchSuggestion(label: t.fanbox.title, icon: PivIcons.heart, onSelected: () => actions.open(AppRoute.fanbox.path)),
        ],
      ),
      if (trending.isNotEmpty)
        FrostSearchSuggestionGroup(
          title: t.search.trendingTags,
          keepsOpen: true,
          actionLabel: t.appSearch.allTrendingTags,
          onAction: () => actions.open(AppRoute.discover.path),
          items: [
            for (final tag in trending.take(_dropdownTrendingTags))
              FrostSearchSuggestion(label: '#${tag.tag}', detail: tag.translatedName, inlineDetail: true, onSelected: () => actions.insertTag(tag.tag)),
          ],
        ),
      if (articles.isNotEmpty)
        FrostSearchSuggestionGroup(
          title: t.pixivision.title,
          actionLabel: t.discover.viewAll,
          onAction: () => actions.open(AppRoute.pixivision.path),
          items: [
            for (final article in articles)
              FrostSearchSuggestion(
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
    FrostSearchSuggestionGroup(
      title: t.navigation.search,
      items: [
        for (final type in types)
          FrostSearchSuggestion(
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
      FrostSearchSuggestionGroup(
        title: t.appSearch.openGroup,
        items: [
          for (final suggestion in direct)
            FrostSearchSuggestion(
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
      FrostSearchSuggestionGroup(
        title: t.appSearch.tagGroup,
        keepsOpen: true,
        items: [
          for (final tag in tags)
            FrostSearchSuggestion(label: tag.label, detail: tag.subtitle, inlineDetail: true, onSelected: () => session.commitTerm(tag.value)),
        ],
      ),
    if (session.error != null)
      FrostSearchSuggestionGroup(
        keepsOpen: true,
        items: [FrostSearchSuggestion(label: t.common.retry, icon: PivIcons.refreshCw, onSelected: session.retry)],
      ),
  ];
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
          suggestions: appSearchSuggestions(context, ref, actions),
          loading: session.loading,
          message: appSearchMessage(context, session),
          onSubmitted: (_) => actions.submit(),
        );
      },
    );
  }
}
