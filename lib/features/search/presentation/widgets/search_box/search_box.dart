import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_autocomplete_session.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_input_surface.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_models.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_overlay_geometry.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_suggestion.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_suggestion_panel.dart';

export 'search_models.dart';

class SearchBox extends ConsumerStatefulWidget {
  const SearchBox({required this.onSearch, this.fixedType, this.onSelected, super.key});

  final SearchType? fixedType;
  final ValueChanged<SearchSubmission> onSearch;
  final ValueChanged<SearchSelection>? onSelected;

  @override
  ConsumerState<SearchBox> createState() => SearchBoxState();
}

class SearchBoxState extends ConsumerState<SearchBox> {
  final _layerLink = LayerLink();
  late final SearchAutocompleteSession _session;

  OverlayEntry? _overlayEntry;
  String _lastPublishedText = '';
  SearchType _lastPublishedType = SearchType.illust;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(searchDraftProvider);
    final initialType = widget.fixedType ?? draft.type;
    _lastPublishedText = draft.text;
    _lastPublishedType = initialType;
    _session = SearchAutocompleteSession(initialText: draft.text, initialType: initialType);
    _session.focusNode.addListener(_handleFocusChanged);
    _session.addListener(_handleSessionChanged);
  }

  @override
  void didUpdateWidget(covariant SearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixedType != widget.fixedType && widget.fixedType != null) {
      _session.setType(widget.fixedType!);
      _publishDraftIfNeeded();
    }
  }

  @override
  void dispose() {
    _hideSuggestionOverlay();
    _session.focusNode.removeListener(_handleFocusChanged);
    _session.removeListener(_handleSessionChanged);
    _session.dispose();
    super.dispose();
  }

  void insertPopularTag(String tag) {
    _session.commitTerm(tag, suppressAutocomplete: true);
    if (mounted) {
      _session.focusNode.requestFocus();
      _showSuggestionOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(searchDraftProvider.select((state) => state.type));

    ref.listen<SearchDraftState>(searchDraftProvider, (previous, next) {
      final nextType = widget.fixedType ?? next.type;
      final textChanged = next.text != _session.rawText;
      final typeChanged = nextType != _session.type;
      if (!textChanged && !typeChanged) {
        return;
      }
      _session.applyDraft(text: next.text, type: nextType);
      _lastPublishedText = next.text;
      _lastPublishedType = nextType;
    });

    final activeType = widget.fixedType ?? type;

    return CompositedTransformTarget(
      link: _layerLink,
      child: SearchField(type: activeType, session: _session, onSubmitted: _handleSubmitted),
    );
  }

  void _handleFocusChanged() {
    if (!mounted) {
      return;
    }

    if (_session.focusNode.hasFocus) {
      _showSuggestionOverlay();
      return;
    }

    _hideSuggestionOverlay();
  }

  void _handleSessionChanged() {
    _publishDraftIfNeeded();

    if (mounted && _session.focusNode.hasFocus) {
      if (_session.hasSuggestionPanelContent) {
        _showSuggestionOverlay();
      } else {
        _hideSuggestionOverlay();
      }
    }
    _overlayEntry?.markNeedsBuild();
  }

  void _publishDraftIfNeeded() {
    final type = widget.fixedType ?? _session.type;
    if (_lastPublishedText == _session.rawText && _lastPublishedType == type) {
      return;
    }

    _lastPublishedText = _session.rawText;
    _lastPublishedType = type;
    ref.read(searchDraftProvider.notifier).setDraft(SearchDraftState(text: _session.rawText, type: type));
  }

  void _showSuggestionOverlay() {
    if (!mounted || !_session.hasSuggestionPanelContent) {
      _hideSuggestionOverlay();
      return;
    }

    if (_overlayEntry != null) {
      _overlayEntry?.markNeedsBuild();
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final renderBox = context.findRenderObject() as RenderBox?;
        final width = renderBox?.size.width ?? 560.0;
        final geometry = suggestionOverlayGeometry(context, renderBox);

        return Positioned.fill(
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: geometry.offset,
                child: SizedBox(
                  width: width,
                  child: TextFieldTapRegion(
                    child: SuggestionSurface(session: _session, maxHeight: geometry.maxHeight, onSelected: _handleSuggestionSelected),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideSuggestionOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleSubmitted(String value) {
    final query = _session.searchText;
    if (query.isEmpty) {
      return;
    }

    _hideSuggestionOverlay();
    _session.focusNode.unfocus();
    widget.onSearch(SearchSubmission(type: widget.fixedType ?? _session.type, query: query));
  }

  void _handleSuggestionSelected(SearchSuggestion suggestion) {
    final selection = _selectionFromSuggestion(context, suggestion);

    if (selection.kind == SearchItemKind.tag) {
      _session.commitTerm(selection.query ?? selection.label);
      _showSuggestionOverlay();
      _session.focusNode.requestFocus();
      widget.onSelected?.call(selection);
      return;
    }

    if (_isDirectNavigation(selection)) {
      _hideSuggestionOverlay();
      _session.unfocus(appendTrailingSpace: false);
      widget.onSelected?.call(selection);
      return;
    }

    widget.onSelected?.call(selection);
  }
}

SearchSelection _selectionFromSuggestion(BuildContext context, SearchSuggestion suggestion) {
  return SearchSelection(kind: suggestion.kind, label: searchSuggestionLabel(context, suggestion), query: suggestion.value, id: suggestion.id);
}

bool _isDirectNavigation(SearchSelection selection) {
  return selection.kind == SearchItemKind.illust || selection.kind == SearchItemKind.user || (selection.kind == SearchItemKind.novel && selection.id != null);
}
