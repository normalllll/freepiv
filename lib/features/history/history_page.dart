import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/features/history/history_actions.dart';
import 'package:freepiv/features/history/history_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/history_card.dart';
import 'package:freepiv/ui/compositions/sectioned_page.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';

/// The browsing history (plan F6): what the current account viewed on this
/// device, the last viewed first, in two tabs: illustrations and manga as
/// cards, novels as rows. Cards and rows come from what was stored, so no work
/// is fetched. More clears the history.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  HistorySource _source(int section) => ref.read(historySourceProvider(section == 1));

  void _cleared() {
    for (final section in [0, 1]) {
      _source(section).removeWhere((_) => true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppSectionedPage(
      controller: _tabs,
      header: FrostPageHeader(
        title: FrostText(t.history.title),
        actions: [
          FrostToolbarItem.menu(
            label: FrostScope.labelsOf(context).more,
            icon: PivIcons.more,
            showsLabel: false,
            entries: [
              FrostMenuAction(
                t.history.clear,
                leading: const FrostGlyph.icon(PivIcons.trash),
                onSelected: () => unawaited(confirmClearHistory(context, onCleared: _cleared)),
              ),
            ],
          ),
        ],
      ),
      tabs: [
        FrostTab(label: t.history.illustrations),
        FrostTab(label: t.history.novels),
      ],
      onRefresh: (section) async => _source(section).refresh(false),
      slivers: (context, section) {
        final novels = section == 1;
        final source = ref.watch(historySourceProvider(novels));
        final empty = FrostEmptyState(icon: PivIcons.clock, title: t.history.empty);
        final localOnly = FrostSliverContentColumn(
          maxWidth: novels ? FrostMetrics.readingMaxWidth : double.infinity,
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: FrostGap.related),
              child: FrostText(t.history.localOnly, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
            ),
          ),
        );
        if (novels) {
          return [
            localOnly,
            FrostSliverContentColumn(
              maxWidth: FrostMetrics.readingMaxWidth,
              sliver: FrostSliverDataList<HistoryEntry>(
                source: source,
                firstLoadSkeleton: const AppNovelRowsSkeleton(),
                empty: empty,
                itemBuilder: (context, entry, index) =>
                    AppHistoryNovelRow(key: ValueKey(entry.workId), entry: entry, onRemove: () => unawaited(source.remove(entry))),
              ),
            ),
          ];
        }
        return [
          localOnly,
          FrostSliverDataWaterfallGrid<HistoryEntry>(
            source: source,
            firstLoadSkeleton: const AppArtworkWaterfallSkeleton(),
            empty: empty,
            itemBuilder: (context, entry, index) =>
                AppHistoryCard(key: ValueKey((entry.kind, entry.workId)), entry: entry, onRemove: () => unawaited(source.remove(entry))),
          ),
        ];
      },
    );
  }
}
