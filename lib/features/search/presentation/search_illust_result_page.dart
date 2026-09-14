import 'package:flutter/widgets.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/search_result_page.dart';

class SearchIllustResultPage extends StatelessWidget {
  const SearchIllustResultPage({required this.keyword, this.initialFilters, super.key});

  final String keyword;
  final SearchFiltersState? initialFilters;

  @override
  Widget build(BuildContext context) {
    return SearchResultPage(type: SearchType.illust, initialKeyword: keyword, initialFilters: initialFilters);
  }
}
