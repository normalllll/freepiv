import 'package:flutter/material.dart';
import 'package:freepiv/shared/widgets/floating_filter_sliver.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_feed.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_filters.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_labels.dart';
import 'package:freepiv/shared/widgets/lazy_indexed_stack.dart';

class NewestAudienceTab extends StatefulWidget {
  const NewestAudienceTab({required this.audience, required this.state, required this.onWorkTypeChanged, required this.onFollowScopeChanged, super.key});

  final NewestAudience audience;
  final NewestState state;
  final ValueChanged<NewestWorkType> onWorkTypeChanged;
  final ValueChanged<NewestFollowScope> onFollowScopeChanged;

  @override
  State<NewestAudienceTab> createState() => _NewestAudienceTabState();
}

class _NewestAudienceTabState extends State<NewestAudienceTab> with AutomaticKeepAliveClientMixin {
  static const _filterHeight = 56.0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final feedKeys = newestFeedKeysForAudience(widget.audience);
    final selectedKey = widget.state.keyForAudience(widget.audience);
    final selectedIndex = feedKeys.indexOf(selectedKey);

    return LazyIndexedStack(
      index: selectedIndex < 0 ? 0 : selectedIndex,
      sizing: StackFit.expand,
      children: [
        for (final key in feedKeys)
          NewestFeedView(
            key: ValueKey(key),
            source: widget.state.sourceFor(key),
            filterSliver: FloatingFilterSliver(
              height: _filterHeight,
              child: NewestTabFilters(
                audience: widget.audience,
                state: widget.state,
                onWorkTypeChanged: widget.onWorkTypeChanged,
                onFollowScopeChanged: widget.onFollowScopeChanged,
              ),
            ),
          ),
      ],
    );
  }
}

class NewestTabFilters extends StatelessWidget {
  const NewestTabFilters({required this.audience, required this.state, required this.onWorkTypeChanged, required this.onFollowScopeChanged, super.key});

  final NewestAudience audience;
  final NewestState state;
  final ValueChanged<NewestWorkType> onWorkTypeChanged;
  final ValueChanged<NewestFollowScope> onFollowScopeChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;

              return NewestFilterControlsRow(
                audience: audience,
                state: state,
                compact: compact,
                onWorkTypeChanged: onWorkTypeChanged,
                onFollowScopeChanged: onFollowScopeChanged,
              );
            },
          ),
        ),
      ),
    );
  }
}
