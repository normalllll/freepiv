import 'package:flutter/material.dart';
import 'package:freepiv/shared/ui/app_dialog.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_labels.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';

/// Compact summary of the feed's work type (and follow scope for Following).
/// It sits on the audience tab row, so the page keeps a single toolbar row;
/// pointer platforms open an anchored menu, touch opens a bottom sheet.
class NewestFilterButton extends StatelessWidget {
  const NewestFilterButton({required this.audience, required this.state, required this.onWorkTypeChanged, required this.onFollowScopeChanged, super.key});

  final NewestAudience audience;
  final NewestState state;
  final ValueChanged<NewestWorkType> onWorkTypeChanged;
  final ValueChanged<NewestFollowScope> onFollowScopeChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;
    final workType = selectedNewestWorkType(state, audience);
    final following = audience == NewestAudience.following;
    final summary = following
        ? '${newestWorkTypeCompactLabel(workType, translations)} · ${newestFollowScopeCompactLabel(state.followScope, translations)}'
        : newestWorkTypeCompactLabel(workType, translations);
    final pointer = switch (Theme.of(context).platform) {
      TargetPlatform.windows || TargetPlatform.macOS || TargetPlatform.linux => true,
      _ => false,
    };
    Widget trigger(VoidCallback onPressed, {FocusNode? focusNode}) => Tooltip(
      message: translations.common.filter,
      child: TextButton.icon(
        focusNode: focusNode,
        onPressed: onPressed,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
        icon: Icon(newestWorkTypeIcon(workType), size: AppMetrics.iconSize),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
    if (!pointer) return trigger(() => _showSheet(context, workType, state.followScope));

    final tokens = FreepivThemeTokens.of(context);
    Widget check(bool selected) => SizedBox.square(dimension: 18, child: selected ? Icon(Icons.check_rounded, size: 18, color: tokens.selectionInk) : null);
    Widget heading(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tokens.textSecondary)),
    );
    return AppMenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        heading(translations.common.type),
        for (final option in newestWorkTypeOptions(audience))
          AppMenuItem(
            leadingIcon: Icon(newestWorkTypeIcon(option), size: AppMetrics.iconSize),
            trailingIcon: check(option == workType),
            onPressed: () => onWorkTypeChanged(option),
            child: Text(newestWorkTypeLabel(option, translations)),
          ),
        if (following) ...[
          const Divider(height: 9),
          heading(translations.newest.followScope.title),
          for (final option in NewestFollowScope.values)
            AppMenuItem(
              trailingIcon: check(option == state.followScope),
              onPressed: () => onFollowScopeChanged(option),
              child: Text(newestFollowScopeLabel(option, translations)),
            ),
        ],
      ],
      builder: (context, focusNode, toggle) => trigger(toggle, focusNode: focusNode),
    );
  }

  Future<void> _showSheet(BuildContext context, NewestWorkType initialWorkType, NewestFollowScope initialScope) {
    var workType = initialWorkType;
    var scope = initialScope;
    return showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: appSheetAnimationStyle(context),
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * .72),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(t.common.type, style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final option in newestWorkTypeOptions(audience))
                ListTile(
                  selected: workType == option,
                  leading: Icon(newestWorkTypeIcon(option)),
                  title: Text(newestWorkTypeLabel(option, t)),
                  trailing: workType == option ? const Icon(Icons.check) : null,
                  onTap: () {
                    updateSheet(() => workType = option);
                    onWorkTypeChanged(option);
                  },
                ),
              if (audience == NewestAudience.following) ...[
                const SizedBox(height: 12),
                Text(t.newest.followScope.title, style: Theme.of(sheetContext).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final option in NewestFollowScope.values)
                  ListTile(
                    selected: scope == option,
                    title: Text(newestFollowScopeLabel(option, t)),
                    trailing: scope == option ? const Icon(Icons.check) : null,
                    onTap: () {
                      updateSheet(() => scope = option);
                      onFollowScopeChanged(option);
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
