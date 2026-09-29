import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/shared/layout/fp_collapsing_header.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/downloads/presentation/fanbox_download_tasks.dart';
import 'package:freepiv/features/downloads/presentation/download_bulk_actions.dart';
import 'package:freepiv/shared/widgets/constrained_segmented_button.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/widgets/refresh_dots.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/presentation/download_task_widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/layout/fp_page_header.dart';
import 'package:go_router/go_router.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

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
                  if (useHorizontalLayout) _DownloadsHeader(onSync: _syncDownloads),

                  Expanded(child: _DownloadsBody(onSync: _syncDownloads)),
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

class _DownloadsHeader extends StatelessWidget {
  const _DownloadsHeader({required this.onSync});

  final Future<void> Function() onSync;

  @override
  Widget build(BuildContext context) {
    // Same column as the task list below, directly on the backdrop.
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = AppMetrics.columnPadding(constraints.maxWidth).left;
        return Padding(
          padding: EdgeInsets.fromLTRB(inset, AppMetrics.sectionHeadingGap, inset - 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(t.settings.downloads.tasksTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(tooltip: t.settings.downloads.sync, icon: const Icon(Icons.sync_outlined), onPressed: () => unawaited(onSync())),
            ],
          ),
        );
      },
    );
  }
}

enum _TaskFilter { all, active, failed, saved }

class _DownloadsBody extends ConsumerStatefulWidget {
  const _DownloadsBody({required this.onSync});
  final Future<void> Function() onSync;
  @override
  ConsumerState<_DownloadsBody> createState() => _DownloadsBodyState();
}

class _DownloadsBodyState extends ConsumerState<_DownloadsBody> {
  late Stream<List<DownloadTaskSnapshot>> _tasks = downloadManager.watchTasks();
  _TaskFilter _filter = _TaskFilter.all;

  void _retry() => setState(() => _tasks = downloadManager.watchTasks());

  @override
  Widget build(BuildContext context) {
    final fanbox = ref.watch(fanboxDownloadsProvider);
    final labels = context.t.settings.downloads;
    return StreamBuilder<List<DownloadTaskSnapshot>>(
      stream: _tasks,
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return ErrorContent.fromError(error: snapshot.error!, onRetry: _retry);
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final tasks = snapshot.data!;
        final visible = tasks
            .where(
              (task) => switch (_filter) {
                _TaskFilter.all => true,
                _TaskFilter.active => task.status == DownloadStatus.running || task.status == DownloadStatus.queued,
                _TaskFilter.failed => task.needsRetry,
                _TaskFilter.saved => task.isCompleted,
              },
            )
            .toList(growable: false);
        final showFanbox =
            fanbox.visible &&
            switch (_filter) {
              _TaskFilter.all => true,
              _TaskFilter.active => fanbox.running,
              _TaskFilter.failed => fanbox.error != null,
              _TaskFilter.saved => !fanbox.running && !fanbox.cancelled && fanbox.error == null && fanbox.completed == fanbox.total,
            };
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
                                const DownloadBulkActions(),
                              ],
                            ),
                            if (snapshot.hasError) ErrorContent.fromError(error: snapshot.error!, onRetry: _retry),
                            if (showFanbox) ...[const SizedBox(height: 24), const FanboxDownloadTasks()],
                            if (visible.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text('Pixiv', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                            ],
                            if (visible.isEmpty && !showFanbox) const DownloadTaskList(tasks: []),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(inset, 0, inset, 24 + MediaQuery.paddingOf(context).bottom),
                    sliver: _AnimatedTaskList(
                      tasks: visible,
                      onOpenWork: (work) => context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': '${work.illustId}'}),
                    ),
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

/// Task rows that ease in and out when the stream or filter changes, so
/// clearing completed tasks or switching filters collapses rows instead of
/// jumping the list. Rows are matched by task id; an unexpected reorder falls
/// back to an immediate rebuild.
class _AnimatedTaskList extends StatefulWidget {
  const _AnimatedTaskList({required this.tasks, required this.onOpenWork});

  final List<DownloadTaskSnapshot> tasks;
  final ValueChanged<ArtworkPage> onOpenWork;

  @override
  State<_AnimatedTaskList> createState() => _AnimatedTaskListState();
}

class _AnimatedTaskListState extends State<_AnimatedTaskList> {
  var _listKey = GlobalKey<SliverAnimatedListState>();
  late List<DownloadTaskSnapshot> _shown = List.of(widget.tasks);

  @override
  void didUpdateWidget(covariant _AnimatedTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.tasks, widget.tasks)) return;
    final list = _listKey.currentState;
    final duration = AppMotion.duration(context, AppMotion.expand);
    final next = widget.tasks;
    final nextIds = {for (final task in next) task.id};
    if (list == null) {
      _shown = List.of(next);
      return;
    }
    for (var index = _shown.length - 1; index >= 0; index--) {
      if (nextIds.contains(_shown[index].id)) continue;
      final removed = _shown.removeAt(index);
      list.removeItem(index, (context, animation) => _row(removed, index, animation, interactive: false), duration: duration);
    }
    for (var index = 0; index < next.length; index++) {
      if (index < _shown.length && _shown[index].id == next[index].id) {
        _shown[index] = next[index];
      } else if (!_shown.any((task) => task.id == next[index].id)) {
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

  Widget _row(DownloadTaskSnapshot task, int index, Animation<double> animation, {bool interactive = true}) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: curved,
        child: IgnorePointer(
          ignoring: !interactive,
          child: Column(
            children: [
              if (index > 0) const Divider(height: 1),
              DownloadTaskTile(key: ValueKey(task.id), task: task, onOpenWork: widget.onOpenWork),
            ],
          ),
        ),
      ),
    );
  }
}
