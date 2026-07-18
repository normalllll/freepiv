import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_autocomplete_session.dart';
import 'package:freepiv/features/search/presentation/widgets/search_filter_bar.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/highlight_text_field.dart';

class SearchField extends StatelessWidget {
  const SearchField({required this.type, required this.session, required this.onSubmitted, super.key});

  final SearchType type;
  final SearchAutocompleteSession session;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, child) {
        return TextFieldTapRegion(
          child: SearchInputSurface(type: type, session: session, autofocus: false, onSubmitted: onSubmitted, onTapOutside: (_) => session.focusNode.unfocus()),
        );
      },
    );
  }
}

class SearchInputSurface extends StatelessWidget {
  const SearchInputSurface({required this.type, required this.session, required this.autofocus, required this.onSubmitted, this.onTapOutside, super.key});

  final SearchType type;
  final SearchAutocompleteSession session;
  final bool autofocus;
  final ValueChanged<String> onSubmitted;
  final TapRegionCallback? onTapOutside;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = FreepivThemeTokens.of(context);
    final focused = session.focusNode.hasFocus;
    final canSubmit = session.searchText.isNotEmpty;

    return Material(
      color: focused ? Color.alphaBlend(tokens.brand.withValues(alpha: 0.045), colorScheme.surfaceContainerHighest) : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 2, 0),
          child: Row(
            children: [
              Icon(Icons.search, size: 18, color: focused ? tokens.brand : colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 2),
                  child: HighlightTextField(
                    autofocus: autofocus,
                    controller: session.controller,
                    rules: searchHighlightRules(context),
                    focusNode: session.focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSubmitted,
                    onTapOutside: onTapOutside,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      hintText: context.t.search.placeholder,
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              if (session.rawText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: session.clearAll,
                    icon: const Icon(Icons.close, size: 18),
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 30, height: 32),
                  ),
                ),
              SearchFilterButton(type: type, allowTypeSelection: false, compact: true),
              const SizedBox(width: 4),
              SizedBox.square(
                dimension: 32,
                child: IconButton(
                  onPressed: canSubmit ? () => onSubmitted(session.rawText) : null,
                  icon: Icon(Icons.search, size: 18, color: canSubmit ? tokens.brand : colorScheme.onSurfaceVariant.withValues(alpha: 0.42)),
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
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
