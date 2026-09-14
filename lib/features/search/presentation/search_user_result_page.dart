import 'package:flutter/widgets.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/search_result_page.dart';

class SearchUserResultPage extends StatelessWidget {
  const SearchUserResultPage({required this.keyword, this.initialFilters, super.key});

  final String keyword;
  final SearchFiltersState? initialFilters;

  @override
  Widget build(BuildContext context) {
    return SearchResultPage(type: SearchType.user, initialKeyword: keyword, initialFilters: initialFilters);
  }
}
