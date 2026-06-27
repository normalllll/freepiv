import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_labels.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';

class NewestFilterControlsRow extends StatelessWidget {
  const NewestFilterControlsRow({
    required this.audience,
    required this.state,
    required this.compact,
    required this.onWorkTypeChanged,
    required this.onFollowScopeChanged,
    super.key,
  });

  final NewestAudience audience;
  final NewestState state;
  final bool compact;
  final ValueChanged<NewestWorkType> onWorkTypeChanged;
  final ValueChanged<NewestFollowScope> onFollowScopeChanged;

  @override
  Widget build(BuildContext context) {
    final hasFollowScope = audience == NewestAudience.following;
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: NewestWorkTypeSelector(audience: audience, state: state, compact: compact, onChanged: onWorkTypeChanged),
        ),
        if (hasFollowScope) ...[
          const SizedBox(width: 8),
          NewestFollowScopePopupButton(state: state, compact: compact, onFollowScopeChanged: onFollowScopeChanged),
        ],
      ],
    );

    if (compact) {
      return controls;
    }

    return Align(alignment: AlignmentDirectional.center, child: controls);
  }
}

class NewestWorkTypeSelector extends StatelessWidget {
  const NewestWorkTypeSelector({required this.audience, required this.state, required this.compact, required this.onChanged, super.key});

  final NewestAudience audience;
  final NewestState state;
  final bool compact;
  final ValueChanged<NewestWorkType> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedWorkType = selectedNewestWorkType(state, audience);
    final translations = t;

    return ConstrainedSegmentedButton<NewestWorkType>(
      maxWidth: compact ? null : 420,
      alignment: compact ? AlignmentDirectional.centerStart : AlignmentDirectional.center,
      segments: [
        for (final workType in newestWorkTypeOptions(audience))
          ButtonSegment(
            value: workType,
            icon: Icon(newestWorkTypeIcon(workType)),
            label: Text(compact ? newestWorkTypeCompactLabel(workType, translations) : newestWorkTypeLabel(workType, translations)),
          ),
      ],
      selected: {selectedWorkType},
      onSelectionChanged: (selection) => onChanged(selection.single),
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class NewestFollowScopePopupButton extends StatelessWidget {
  const NewestFollowScopePopupButton({required this.state, required this.compact, required this.onFollowScopeChanged, super.key});

  final NewestState state;
  final bool compact;
  final ValueChanged<NewestFollowScope> onFollowScopeChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return NewestFilterPopupButton<NewestFollowScope>(
      icon: Icons.visibility_outlined,
      label: compact ? newestFollowScopeCompactLabel(state.followScope, translations) : newestFollowScopeLabel(state.followScope, translations),
      values: NewestFollowScope.values,
      selectedValue: state.followScope,
      labelFor: (scope) => newestFollowScopeLabel(scope, translations),
      onSelected: onFollowScopeChanged,
      compact: compact,
    );
  }
}

class NewestFilterPopupButton<T> extends StatelessWidget {
  const NewestFilterPopupButton({
    required this.icon,
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.labelFor,
    required this.onSelected,
    required this.compact,
    super.key,
  });

  final IconData icon;
  final String label;
  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelFor;
  final ValueChanged<T> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) {
        return [for (final value in values) CheckedPopupMenuItem<T>(value: value, checked: value == selectedValue, child: Text(labelFor(value)))];
      },
      child: NewestToolbarFilterChip(icon: icon, label: label, compact: compact),
    );
  }
}

class NewestToolbarFilterChip extends StatelessWidget {
  const NewestToolbarFilterChip({required this.icon, required this.label, required this.compact, super.key});

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = FreepivThemeTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: Color.alphaBlend(tokens.brand.withValues(alpha: 0.055), tokens.surfaceRaised), borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(compact ? 9 : 11, 8, compact ? 7 : 9, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: tokens.brand),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 96 : 150),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 20, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
