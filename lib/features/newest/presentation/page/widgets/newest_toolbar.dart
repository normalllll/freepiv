import 'package:flutter/material.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_labels.dart';
import 'package:freepiv/i18n/strings.g.dart';

class NewestToolbar extends StatelessWidget {
  const NewestToolbar({required this.tabController, required this.onAudienceChanged, super.key});

  final TabController tabController;
  final ValueChanged<NewestAudience> onAudienceChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = t;

    return Material(
      color: colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.42))),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final tabs = TabBar(
                  controller: tabController,
                  isScrollable: compact,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
                  onTap: (index) {
                    onAudienceChanged(newestAudienceForIndex(index));
                  },
                  tabs: [
                    Tab(text: translations.newest.audience.following),
                    Tab(text: translations.newest.audience.mypixiv),
                    Tab(text: translations.newest.audience.everyone),
                  ],
                );

                return SizedBox(
                  height: 48,
                  child: Row(
                    children: [if (compact) Expanded(child: tabs) else SizedBox(width: 420, child: tabs)],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
