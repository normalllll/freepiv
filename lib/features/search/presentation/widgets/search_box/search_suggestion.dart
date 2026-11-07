import 'package:flutter/widgets.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_models.dart';

class SearchSuggestion {
  const SearchSuggestion({required this.kind, required this.label, required this.value, this.subtitle, this.id});

  final SearchItemKind kind;
  final String label;
  final String? subtitle;
  final String value;
  final int? id;
}

/// The suggestion's label; ID suggestions are already worded for the locale.
String searchSuggestionLabel(BuildContext context, SearchSuggestion suggestion) => suggestion.label;
