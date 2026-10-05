import 'package:flutter/material.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_feed.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_labels.dart';
import 'package:frost_ui/frost_ui.dart';

class NewestAudienceTab extends StatefulWidget {
  const NewestAudienceTab({required this.audience, required this.state, super.key});

  final NewestAudience audience;
  final NewestState state;

  @override
  State<NewestAudienceTab> createState() => _NewestAudienceTabState();
}

class _NewestAudienceTabState extends State<NewestAudienceTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final feedKeys = newestFeedKeysForAudience(widget.audience);
    final selectedKey = widget.state.keyForAudience(widget.audience);
    final selectedIndex = feedKeys.indexOf(selectedKey);

    return FrostLazyIndexedStack(
      index: selectedIndex < 0 ? 0 : selectedIndex,
      sizing: StackFit.expand,
      children: [
        // Filters live in the pinned toolbar; each feed only reserves its height.
        for (final key in feedKeys) NewestFeedView(key: ValueKey(key), source: widget.state.sourceFor(key), filterSliver: const FrostChromeSpacer()),
      ],
    );
  }
}
