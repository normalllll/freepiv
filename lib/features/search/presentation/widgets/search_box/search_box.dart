import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_autocomplete_session.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_models.dart';
import 'package:freepiv/features/search/presentation/widgets/search_filter_bar.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

export 'search_models.dart';

/// A page header's search: the app's one search session in the page, shown
/// only while the title row does not hold it (FrostShell.titleContentInCaptionOf).
/// The draft of the page's scope follows the session and the other way round.
class SearchBox extends ConsumerStatefulWidget {
  const SearchBox({required this.onSearch, this.fixedType, this.onSelected, this.showFilters = true, super.key});

  final bool showFilters;

  final SearchType? fixedType;
  final ValueChanged<SearchSubmission> onSearch;

  /// Kept for the pages built before the rebuild; the shared suggestions open
  /// works and users themselves.
  final ValueChanged<SearchSelection>? onSelected;

  @override
  ConsumerState<SearchBox> createState() => SearchBoxState();
}

class SearchBoxState extends ConsumerState<SearchBox> {
  final _focus = FocusNode(debugLabel: 'Page header search');
  late final SearchAutocompleteSession _session = ref.read(appSearchSessionProvider);

  @override
  void initState() {
    super.initState();
    _session.addInputFocus(_focus);
    _session.addListener(_publishDraft);
    final draft = ref.read(searchDraftProvider);
    if (!_session.hasFocus) _session.applyDraft(text: draft.text, type: widget.fixedType ?? draft.type);
  }

  @override
  void didUpdateWidget(covariant SearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixedType != widget.fixedType && widget.fixedType != null) {
      _session.setType(widget.fixedType!);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_publishDraft);
    _session.removeInputFocus(_focus);
    _focus.dispose();
    super.dispose();
  }

  /// Adds a trending tag to the query and keeps the search open for more.
  void insertPopularTag(String tag) {
    _session.commitTerm(tag, suppressAutocomplete: true);
    if (!mounted) return;
    (FrostShell.titleContentInCaptionOf(context) ? _session.focusNode : _focus).requestFocus();
  }

  bool get _current => mounted && (ModalRoute.isCurrentOf(context) ?? true);

  void _publishDraft() {
    if (!_current) return;
    final type = widget.fixedType ?? _session.type;
    final draft = ref.read(searchDraftProvider);
    if (draft.text == _session.rawText && draft.type == type) return;
    ref.read(searchDraftProvider.notifier).setDraft(SearchDraftState(text: _session.rawText, type: type));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SearchDraftState>(searchDraftProvider, (previous, next) {
      if (!_current) return;
      final type = widget.fixedType ?? next.type;
      if (next.text == _session.rawText && type == _session.type) return;
      _session.applyDraft(text: next.text, type: type);
    });
    if (FrostShell.titleContentInCaptionOf(context)) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final actions = AppSearchActions(
          ref,
          context,
          onSubmitted: (query, type) => widget.onSearch(SearchSubmission(type: widget.fixedType ?? type, query: query)),
        );
        final type = widget.fixedType ?? _session.type;
        return FrostSearchInput.suggesting(
          controller: _session.controller,
          focusNode: _focus,
          placeholder: context.t.discover.searchHint,
          onSubmitted: (_) => actions.submit(type: widget.fixedType),
          onClear: _session.clearAll,
          suggestions: appSearchSuggestions(context, ref, actions),
          loading: _session.loading,
          message: appSearchMessage(context, _session),
          actions: [if (widget.showFilters && type != SearchType.user) SearchFilterButton(type: type, allowTypeSelection: false, compact: true)],
        );
      },
    );
  }
}
