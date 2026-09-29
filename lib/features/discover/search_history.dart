import 'package:flutter/material.dart';
import 'package:freepiv/shared/ui/app_dialog.dart';
import 'package:freepiv/shared/layout/content_viewport.dart';
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
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 240),
      alignment: Alignment.topCenter,
      child: history.isEmpty
          ? ContentColumn(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
                // Guidance, not a history row: it names what will appear
                // here instead of repeating the search field's placeholder.
                child: Row(
                  children: [
                    Icon(Icons.history, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.emptyHistory,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ContentColumn(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
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
                              child: InputChip(
                                label: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 180),
                                  child: Text(query, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                onPressed: () => onSelected(query),
                                onDeleted: () => ref.read(searchHistoryProvider.notifier).remove(query),
                                deleteButtonTooltipMessage: '${context.t.discover.clearHistory}: $query',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showAll(BuildContext context) => showAppDialog<void>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final history = ref.watch(searchHistoryProvider);
        return AlertDialog(
          title: Text(context.t.discover.history),
          // As tall as the records need; the list scrolls once the dialog is full.
          content: SizedBox(
            width: 420,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: history.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(history[index], maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: '${context.t.discover.clearHistory}: ${history[index]}',
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(searchHistoryProvider.notifier).remove(history[index]),
                ),
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
