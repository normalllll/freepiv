import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/search/logic/search_history_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';

class DiscoverySearchHistory extends ConsumerWidget {
  const DiscoverySearchHistory({required this.onSelected, super.key});
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);
    final t = context.t.discover;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.topCenter,
      child: history.isEmpty
          ? const SizedBox(width: double.infinity)
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(t.history, style: Theme.of(context).textTheme.titleSmall)),
                          TextButton(onPressed: () => _showAll(context), child: Text(t.viewAll)),
                        ],
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final query in history.take(6))
                              Padding(
                                padding: const EdgeInsetsDirectional.only(end: 8),
                                child: ActionChip(
                                  label: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 180),
                                    child: Text(query, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  onPressed: () => onSelected(query),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _showAll(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final history = ref.watch(searchHistoryProvider);
        return AlertDialog(
          title: Text(context.t.discover.history),
          content: SizedBox(
            width: 420,
            height: (MediaQuery.sizeOf(context).height * .5).clamp(120, 420),
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(history[index], maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  final query = history[index];
                  Navigator.pop(context);
                  onSelected(query);
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: history.isEmpty
                  ? null
                  : () {
                      ref.read(searchHistoryProvider.notifier).clear();
                      Navigator.pop(context);
                    },
              child: Text(context.t.discover.clearHistory),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(MaterialLocalizations.of(context).closeButtonLabel)),
          ],
        );
      },
    ),
  );
}
