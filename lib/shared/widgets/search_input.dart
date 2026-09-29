import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/shared/layout/content_viewport.dart';
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
      final focus = FreepivThemeTokens.of(context).fieldFocus;
      final size = AppMetrics.fieldHeight(context);
      final radius = BorderRadius.circular(AppMetrics.controlRadius);
      // The outline is an unclipped foreground stroke inside the field's
      // edge. Clipping a stroked shape cuts its outer half and lets the fill
      // bleed through the antialiased corner, which reads as jagged.
      return AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.hover),
        decoration: BoxDecoration(color: FreepivThemeTokens.of(context).surfaceRaised, borderRadius: radius),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: focusNode.hasFocus ? focus : colors.outlineVariant,
            width: focusNode.hasFocus ? AppMetrics.fieldFocusWidth : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: SizedBox(
          height: size,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 2, 0),
            child: Row(
              children: [
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

/// Centres the search row in the page column it belongs to, with the same
/// gap above and below so it never sits on the edge of its bar.
class SearchInputRegion extends StatelessWidget {
  const SearchInputRegion({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => ContentColumn(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppMetrics.compactGap),
      child: child,
    ),
  );
}
