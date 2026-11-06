import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_labels.dart';
import 'package:freepiv/i18n/strings.g.dart';

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
        icon: Icon(newestWorkTypeIcon(workType), size: FrostControlSize.regular.iconSize),
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

    return FrostMenuAnchor(
      entries: [
        FrostMenuSection(
          header: translations.common.type,
          entries: [
            for (final option in newestWorkTypeOptions(audience))
              FrostMenuAction(
                newestWorkTypeLabel(option, translations),
                leading: FrostGlyph.icon(FrostIconData.glyph(newestWorkTypeIcon(option))),
                checked: option == workType,
                onSelected: () => onWorkTypeChanged(option),
              ),
          ],
        ),
        if (following)
          FrostMenuSection(
            header: translations.newest.followScope.title,
            entries: [
              for (final option in NewestFollowScope.values)
                FrostMenuAction(
                  newestFollowScopeLabel(option, translations),
                  checked: option == state.followScope,
                  onSelected: () => onFollowScopeChanged(option),
                ),
            ],
          ),
      ],
      builder: (context, focusNode, toggle) => trigger(toggle, focusNode: focusNode),
    );
  }

  Future<void> _showSheet(BuildContext context, NewestWorkType initialWorkType, NewestFollowScope initialScope) {
    var workType = initialWorkType;
    var scope = initialScope;
    return showModalBottomSheet<void>(
      context: context,
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
