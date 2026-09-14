import 'package:flutter/material.dart';
import 'package:freepiv/shared/widgets/search_input.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_autocomplete_session.dart';
import 'package:freepiv/features/search/presentation/widgets/search_filter_bar.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/highlight_text_field.dart';

class SearchField extends StatelessWidget {
  const SearchField({required this.type, required this.session, required this.onSubmitted, this.showFilters = true, super.key});

  final SearchType type;
  final bool showFilters;
  final SearchAutocompleteSession session;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, child) {
        return TextFieldTapRegion(
          child: SearchInputSurface(
            type: type,
            session: session,
            autofocus: false,
            onSubmitted: onSubmitted,
            showFilters: showFilters,
            onTapOutside: (_) => session.focusNode.unfocus(),
          ),
        );
      },
    );
  }
}

class SearchInputSurface extends StatelessWidget {
  const SearchInputSurface({
    required this.type,
    required this.session,
    required this.autofocus,
    required this.onSubmitted,
    this.onTapOutside,
    this.showFilters = true,
    super.key,
  });

  final SearchType type;
  final bool showFilters;
  final SearchAutocompleteSession session;
  final bool autofocus;
  final ValueChanged<String> onSubmitted;
  final TapRegionCallback? onTapOutside;

  @override
  Widget build(BuildContext context) {
    return SearchInput(
      controller: session.controller,
      focusNode: session.focusNode,
      hintText: context.t.discover.searchHint,
      onSubmitted: onSubmitted,
      onClear: session.clearAll,
      actions: [if (showFilters) SearchFilterButton(type: type, allowTypeSelection: false, compact: true)],
      field: HighlightTextField(
        autofocus: autofocus,
        controller: session.controller,
        rules: searchHighlightRules(context),
        focusNode: session.focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        onTapOutside: onTapOutside,
        maxLines: 1,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: searchInputDecoration(context, context.t.discover.searchHint),
      ),
    );
  }
}

List<HighlightRule> searchHighlightRules(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return [
    HighlightRule(
      pattern: RegExp(r'^\S+$'),
      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
    ),
  ];
}
