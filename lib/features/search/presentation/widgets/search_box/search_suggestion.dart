import 'package:flutter/material.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_models.dart';
import 'package:freepiv/i18n/strings.g.dart';

class SearchSuggestion {
  const SearchSuggestion({required this.kind, required this.label, required this.value, required this.icon, this.subtitle, this.id});

  final SearchItemKind kind;
  final String label;
  final String? subtitle;
  final String value;
  final int? id;
  final IconData icon;
}

String searchSuggestionLabel(BuildContext context, SearchSuggestion suggestion) {
  final id = suggestion.id;
  if (id == null) {
    return suggestion.label;
  }

  return switch (suggestion.kind) {
    SearchItemKind.illust => context.t.search.direct.illust(id: id),
    SearchItemKind.user => context.t.search.direct.user(id: id),
    SearchItemKind.novel => context.t.search.direct.novel(id: id),
    SearchItemKind.tag => suggestion.label,
  };
}
