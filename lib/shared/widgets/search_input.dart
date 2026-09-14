import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';

/// Shared search chrome; each service owns its query and optional controls.
class SearchInput extends StatelessWidget {
  const SearchInput({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onSubmitted,
    this.onClear,
    this.field,
    this.actions = const [],
    super.key,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;
  final Widget? field;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, focusNode]),
    builder: (context, _) {
      final colors = Theme.of(context).colorScheme;
      final brand = FreepivThemeTokens.of(context).brand;
      const size = 36.0;
      return Material(
        color: focusNode.hasFocus ? Color.alphaBlend(brand.withValues(alpha: .045), colors.surfaceContainerHighest) : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: size + 8,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 2, 0),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: focusNode.hasFocus ? brand : colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      field ??
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onSubmitted: onSubmitted,
                        onTapOutside: (_) => focusNode.unfocus(),
                        textInputAction: TextInputAction.search,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: searchInputDecoration(context, hintText),
                      ),
                ),
                Visibility(
                  visible: controller.text.isNotEmpty,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: SizedBox.square(
                    dimension: size,
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                      onPressed: onClear ?? controller.clear,
                      icon: const Icon(Icons.close, size: 18),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                for (final action in actions) SizedBox.square(dimension: size, child: action),
                SizedBox.square(
                  dimension: size,
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(context).searchFieldLabel,
                    onPressed: controller.text.trim().isEmpty ? null : () => onSubmitted(controller.text),
                    icon: const Icon(Icons.search, size: 18),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

InputDecoration searchInputDecoration(BuildContext context, String hint) => InputDecoration(
  isDense: true,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  filled: false,
  contentPadding: EdgeInsets.zero,
  hintText: hint,
  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
);

/// Matches the search field to the centered list's 900-wide padded column.
class SearchInputRegion extends StatelessWidget {
  const SearchInputRegion({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), child: child),
    ),
  );
}
