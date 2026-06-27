import 'package:freepiv/features/search/logic/search_logic.dart';

class SearchSubmission {
  const SearchSubmission({required this.type, required this.query});

  final SearchType type;
  final String query;
}

class SearchSelection {
  const SearchSelection({required this.kind, required this.label, this.query, this.id});

  final SearchItemKind kind;
  final String label;
  final String? query;
  final int? id;
}

enum SearchItemKind { illust, user, novel, tag }
