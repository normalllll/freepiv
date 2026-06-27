import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_models.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_suggestion.dart';
import 'package:freepiv/shared/widgets/highlight_text_field.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

class SearchAutocompleteSession extends ChangeNotifier {
  SearchAutocompleteSession({required SearchType initialType, String initialText = ''}) : _type = initialType {
    controller.addListener(_handleTextChanged);
    focusNode.addListener(_handleFocusNodeChanged);
    if (initialText.isNotEmpty) {
      setText(initialText, suppressAutocomplete: true);
    }
  }

  static final _numericPattern = RegExp(r'^\d+$');
  static const _debounceDuration = Duration(milliseconds: 360);

  final controller = HighlightTextEditingController();
  final focusNode = FocusNode();

  Timer? _debounceTimer;
  List<Tag> _tags = const [];
  SearchType _type;
  String _query = '';
  String _lastRawText = '';
  bool _lastComposing = false;
  bool _suppressNextTextChange = false;
  Object? _error;
  bool _loading = false;
  bool _autocompleteCompleted = false;
  bool _disposed = false;
  bool _skipTrailingSpaceOnNextBlur = false;
  int _requestId = 0;

  String get rawText => controller.text;

  String get searchText => rawText.trim();

  SearchType get type => _type;

  String get query => _query;

  Object? get error => _error;

  bool get loading => _loading;

  bool get hasSuggestionPanelContent {
    if (query.isEmpty) {
      return false;
    }

    if (suggestions.isNotEmpty || loading || error != null) {
      return true;
    }

    return _autocompleteCompleted && type != SearchType.user;
  }

  List<SearchSuggestion> get suggestions {
    final items = <SearchSuggestion>[];
    final activeQuery = query;

    if (!_hasCommittedTerms(rawText) && _numericPattern.hasMatch(activeQuery)) {
      final id = int.tryParse(activeQuery);
      if (id != null) {
        items.addAll([
          SearchSuggestion(kind: SearchItemKind.illust, label: 'Illust:$id', value: 'Illust:$id', id: id, icon: Icons.image_outlined),
          SearchSuggestion(kind: SearchItemKind.user, label: 'User:$id', value: 'User:$id', id: id, icon: Icons.person_outline),
          SearchSuggestion(kind: SearchItemKind.novel, label: 'Novel:$id', value: 'Novel:$id', id: id, icon: Icons.menu_book_outlined),
        ]);
      }
    }

    if (_type != SearchType.user) {
      for (final tag in _tags) {
        items.add(SearchSuggestion(kind: SearchItemKind.tag, label: '#${tag.name}', subtitle: tag.translatedName, value: tag.name, icon: Icons.tag));
      }
    }

    return items;
  }

  void applyDraft({required String text, required SearchType type}) {
    setType(type);
    setText(text, suppressAutocomplete: true);
  }

  void setText(String text, {bool suppressAutocomplete = false}) {
    if (controller.text == text) {
      return;
    }

    _suppressNextTextChange = suppressAutocomplete;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void clearAll() {
    setText('');
    _resetAutocompleteState(query: '');
    notifyListeners();
  }

  void commitTerm(String term, {bool suppressAutocomplete = false}) {
    final normalized = _normalizeTerm(term);
    if (normalized.isEmpty) {
      return;
    }

    final prefix = _prefixBeforeActiveTerm(rawText).trimRight();
    final nextText = prefix.isEmpty ? '$normalized ' : '$prefix $normalized ';
    setText(nextText, suppressAutocomplete: suppressAutocomplete);
  }

  void setType(SearchType type) {
    if (_type == type) {
      return;
    }

    _type = type;
    _tags = const [];
    _error = null;
    _autocompleteCompleted = false;
    _debounceTimer?.cancel();
    _requestId++;

    if (_type == SearchType.user || query.isEmpty) {
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    _scheduleAutocomplete(query);
  }

  void retry() {
    final activeQuery = query;
    if (activeQuery.isEmpty || type == SearchType.user) {
      return;
    }

    _debounceTimer?.cancel();
    final requestId = ++_requestId;
    _loading = true;
    _error = null;
    _autocompleteCompleted = false;
    notifyListeners();
    unawaited(_fetchAutocomplete(activeQuery, requestId));
  }

  void unfocus({bool appendTrailingSpace = true}) {
    _skipTrailingSpaceOnNextBlur = !appendTrailingSpace;
    focusNode.unfocus();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    controller.removeListener(_handleTextChanged);
    focusNode.removeListener(_handleFocusNodeChanged);
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _handleFocusNodeChanged() {
    if (!focusNode.hasFocus && !_skipTrailingSpaceOnNextBlur) {
      _appendTrailingSpaceForHighlight();
    }
    _skipTrailingSpaceOnNextBlur = false;
    notifyListeners();
  }

  void _appendTrailingSpaceForHighlight() {
    final text = controller.text;
    if (text.isEmpty || RegExp(r'\s$').hasMatch(text) || text.trimRight().isEmpty) {
      return;
    }

    setText('${text.trimRight()} ', suppressAutocomplete: true);
  }

  void _handleTextChanged() {
    final value = controller.value;
    final composing = _isComposing(value);

    if (_suppressNextTextChange) {
      _suppressNextTextChange = false;
      _lastRawText = value.text;
      _lastComposing = composing;
      _debounceTimer?.cancel();
      _requestId++;
      _resetAutocompleteState(query: '');
      notifyListeners();
      return;
    }

    if (value.text == _lastRawText && composing == _lastComposing) {
      return;
    }

    _lastRawText = value.text;
    _lastComposing = composing;

    final nextQuery = _activeQuery(value.text);

    if (composing) {
      _debounceTimer?.cancel();
      _requestId++;
      _resetAutocompleteState(query: nextQuery);
      notifyListeners();
      return;
    }

    if (nextQuery.isEmpty) {
      _debounceTimer?.cancel();
      _requestId++;
      _resetAutocompleteState(query: '');
      notifyListeners();
      return;
    }

    if (nextQuery == _query && !_loading && _error == null && _autocompleteCompleted) {
      return;
    }

    _query = nextQuery;
    _tags = const [];
    _error = null;
    _autocompleteCompleted = false;

    if (_type == SearchType.user) {
      _debounceTimer?.cancel();
      _requestId++;
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _scheduleAutocomplete(nextQuery);
  }

  Future<void> _fetchAutocomplete(String query, int requestId) async {
    try {
      final result = await pixivApi.getSearchAutocomplete(word: query);
      if (_disposed || requestId != _requestId) {
        return;
      }

      _tags = result.tags;
      _error = null;
      _loading = false;
      _autocompleteCompleted = true;
      notifyListeners();
    } catch (error) {
      if (_disposed || requestId != _requestId) {
        return;
      }

      _tags = const [];
      _error = error;
      _loading = false;
      _autocompleteCompleted = true;
      notifyListeners();
    }
  }

  void _scheduleAutocomplete(String query) {
    _debounceTimer?.cancel();
    final requestId = ++_requestId;
    _debounceTimer = Timer(_debounceDuration, () {
      unawaited(_fetchAutocomplete(query, requestId));
    });
  }

  void _resetAutocompleteState({required String query}) {
    _query = query;
    _tags = const [];
    _loading = false;
    _error = null;
    _autocompleteCompleted = false;
  }

  String _normalizeTerm(String tag) {
    return tag.trim().replaceFirst(RegExp(r'^#+'), '').trim();
  }

  String _activeQuery(String text) {
    if (text.isEmpty || RegExp(r'\s$').hasMatch(text)) {
      return '';
    }

    final match = RegExp(r'\S+$').firstMatch(text);
    return _normalizeTerm(match?.group(0) ?? '');
  }

  String _prefixBeforeActiveTerm(String text) {
    if (text.isEmpty || RegExp(r'\s$').hasMatch(text)) {
      return text;
    }

    final match = RegExp(r'\S+$').firstMatch(text);
    if (match == null) {
      return text;
    }

    return text.substring(0, match.start);
  }

  bool _hasCommittedTerms(String text) {
    return RegExp(r'\S+(?=\s)').hasMatch(text);
  }

  bool _isComposing(TextEditingValue value) {
    final range = value.composing;
    return range.isValid && !range.isCollapsed;
  }
}
