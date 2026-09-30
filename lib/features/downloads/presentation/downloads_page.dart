import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/shared/layout/fp_collapsing_header.dart';
import 'package:freepiv/features/downloads/presentation/download_bulk_actions.dart';
import 'package:freepiv/shared/widgets/constrained_segmented_button.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/widgets/refresh_dots.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/logic.dart';
import 'package:freepiv/features/downloads/presentation/download_item_widgets.dart';
import 'package:freepiv/features/downloads/presentation/download_task_widgets.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/layout/fp_page_header.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({this.focusItem, this.taskStream, super.key});

  /// The key of an item to open and bring into view, as the floating panel
  /// asks when one of its items is tapped.
  final String? focusItem;

  /// The tasks to show in place of the download manager's, for tests.
  @visibleForTesting
  final Stream<List<DownloadTaskSnapshot>>? taskStream;

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool useHorizontalLayout) {
        return Scaffold(
          body: FpCollapsingHeader(
            header: useHorizontalLayout ? null : _downloadsAppBar(),
            child: SafeArea(
              top: useHorizontalLayout,
              child: Column(
                children: [
                  if (useHorizontalLayout)
                    FpInlinePageHeading(
                      title: t.settings.downloads.tasksTitle,
                      actions: [
                        IconButton(tooltip: t.settings.downloads.sync, icon: const Icon(Icons.sync_outlined), onPressed: () => unawaited(_syncDownloads())),
                      ],
                    ),

                  Expanded(
                    child: _DownloadsBody(onSync: _syncDownloads, focusItem: focusItem, taskStream: taskStream),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  FpPageHeader _downloadsAppBar() {
    return FpPageHeader(
      title: Text(t.settings.downloads.tasksTitle),
      actions: [IconButton(tooltip: t.settings.downloads.sync, icon: const Icon(Icons.sync_outlined), onPressed: () => unawaited(_syncDownloads()))],
    );
  }

  Future<void> _syncDownloads() async {
    try {
      await downloadManager.sync();
    } catch (error) {
      AppToast.errorWithCause(t.settings.downloads.syncFailed, error);
    }
  }
}

enum _TaskFilter { all, active, failed, saved }

class _DownloadsBody extends ConsumerStatefulWidget {
  const _DownloadsBody({required this.onSync, this.focusItem, this.taskStream});
  final Future<void> Function() onSync;
  final String? focusItem;
  final Stream<List<DownloadTaskSnapshot>>? taskStream;
  @override
  ConsumerState<_DownloadsBody> createState() => _DownloadsBodyState();
}

class _DownloadsBodyState extends ConsumerState<_DownloadsBody> {
  late Stream<List<DownloadTaskSnapshot>> _tasks = widget.taskStream ?? downloadManager.watchTasks();
  _TaskFilter _filter = _TaskFilter.all;

  /// Items whose files are shown; temporary, so it lives with the page.
  late final Set<String> _expanded = {?widget.focusItem};
  final _focusKey = GlobalKey(debugLabel: 'focused-download-item');
  bool _focusShown = false;

  void _retry() => setState(() => _tasks = downloadManager.watchTasks());

  void _toggle(String key) => setState(() {
    if (!_expanded.remove(key)) _expanded.add(key);
  });

  /// Brings the item the page was opened for into view once it is built.
  void _showFocusedItem() {
    if (_focusShown) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focused = _focusKey.currentContext;
      if (!mounted || focused == null || _focusShown) return;
      _focusShown = true;
      unawaited(Scrollable.ensureVisible(focused, duration: AppMotion.duration(context, AppMotion.expand), curve: Curves.easeInOutCubic, alignment: .1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.t.settings.downloads;
    return StreamBuilder<List<DownloadTaskSnapshot>>(
      stream: _tasks,
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return ErrorContent.fromError(error: snapshot.error!, onRetry: _retry);
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final tasks = snapshot.data!;
        final collecting = ref.watch(fanboxDownloadsProvider);
        final visible = downloadItemsOf(tasks, collecting: collecting.values)
            .where(
              (item) => switch (_filter) {
                _TaskFilter.all => true,
                _TaskFilter.active => item.state == DownloadItemState.active || item.state == DownloadItemState.collecting,
                _TaskFilter.failed => item.failed > 0,
                _TaskFilter.saved => item.state == DownloadItemState.completed,
              },
            )
            .toList(growable: false);
        if (widget.focusItem case final focus? when visible.any((item) => item.key == focus)) _showFocusedItem();
        final summary = DownloadSummary.fromTasks(tasks);
        return DotsRefreshIndicator(
          onRefresh: widget.onSync,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final inset = AppMetrics.columnPadding(constraints.maxWidth).left;
              return CustomScrollView(
                key: const PageStorageKey('download-tasks'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(inset, 16, inset, 12),
                    sliver: SliverToBoxAdapter(
                      // Sections above the list appear and leave with the
                      // filter and bulk actions; ease the height instead of
                      // jumping the list.
                      child: AnimatedSize(
                        duration: AppMotion.duration(context, AppMotion.expand),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (tasks.isNotEmpty) ...[DownloadSummaryView(summary: summary, showHeading: false), const SizedBox(height: 16)],
                            // A segmented control keeps every filter at a fixed
                            // width (a chip grows a checkmark when selected), and
                            // the bulk actions keep their own slot at the end.
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppSegmentedButton<_TaskFilter>(
                                  showSelectedIcon: false,
                                  segments: [
                                    for (final filter in _TaskFilter.values)
                                      ButtonSegment(
                                        value: filter,
                                        label: Text(switch (filter) {
                                          _TaskFilter.all => labels.total,
                                          _TaskFilter.active => labels.active,
                                          _TaskFilter.failed => labels.failed,
                                          _TaskFilter.saved => labels.saved,
                                        }),
                                      ),
                                  ],
                                  selected: {_filter},
                                  onSelectionChanged: (selection) => setState(() => _filter = selection.single),
                                ),
                                DownloadBulkActions(tasks: tasks),
                              ],
                            ),
                            if (snapshot.hasError) ErrorContent.fromError(error: snapshot.error!, onRetry: _retry),
                            const SizedBox(height: 24),
                            if (visible.isEmpty) const DownloadEmptyState(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(inset, 0, inset, 24 + MediaQuery.paddingOf(context).bottom),
                    sliver: _AnimatedItemList(items: visible, expanded: _expanded, onToggle: _toggle, focusItem: widget.focusItem, focusKey: _focusKey),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Item rows that ease in and out when the stream or filter changes, so
/// clearing completed items or switching filters collapses rows instead of
/// jumping the list. Rows are matched by item key; an unexpected reorder
/// falls back to an immediate rebuild.
class _AnimatedItemList extends StatefulWidget {
  const _AnimatedItemList({required this.items, required this.expanded, required this.onToggle, required this.focusItem, required this.focusKey});

  final List<DownloadItem> items;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;
  final String? focusItem;
  final GlobalKey focusKey;

  @override
  State<_AnimatedItemList> createState() => _AnimatedItemListState();
}

class _AnimatedItemListState extends State<_AnimatedItemList> {
  var _listKey = GlobalKey<SliverAnimatedListState>();
  late List<DownloadItem> _shown = List.of(widget.items);

  @override
  void didUpdateWidget(covariant _AnimatedItemList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.items, widget.items)) return;
    final list = _listKey.currentState;
    final duration = AppMotion.duration(context, AppMotion.expand);
    final next = widget.items;
    final nextKeys = {for (final item in next) item.key};
    if (list == null) {
      _shown = List.of(next);
      return;
    }
    for (var index = _shown.length - 1; index >= 0; index--) {
      if (nextKeys.contains(_shown[index].key)) continue;
      final removed = _shown.removeAt(index);
      list.removeItem(index, (context, animation) => _row(removed, index, animation, interactive: false), duration: duration);
    }
    for (var index = 0; index < next.length; index++) {
      if (index < _shown.length && _shown[index].key == next[index].key) {
        _shown[index] = next[index];
      } else if (!_shown.any((item) => item.key == next[index].key)) {
        _shown.insert(index, next[index]);
        list.insertItem(index, duration: duration);
      } else {
        // Reordered: rebuild without animation rather than guess moves.
        _shown = List.of(next);
        _listKey = GlobalKey<SliverAnimatedListState>();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _shown.length,
      itemBuilder: (context, index, animation) => _row(_shown[index], index, animation),
    );
  }

  Widget _row(DownloadItem item, int index, Animation<double> animation, {bool interactive = true}) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: curved,
        child: IgnorePointer(
          ignoring: !interactive,
          child: Column(
            key: interactive && item.key == widget.focusItem ? widget.focusKey : null,
            children: [
              if (index > 0) const Divider(height: 1),
              DownloadItemCard(
                key: ValueKey<String>(item.key),
                item: item,
                expanded: widget.expanded.contains(item.key),
                onToggle: () => widget.onToggle(item.key),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
