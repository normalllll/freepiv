import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'fanbox_download_tasks.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/presentation/download_task_widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:go_router/go_router.dart';

class DesktopDownloadDock extends ConsumerStatefulWidget {
  const DesktopDownloadDock({required this.railWidth, this.bottomOffset = 16, super.key});

  final double railWidth;
  final double bottomOffset;

  @override
  ConsumerState<DesktopDownloadDock> createState() => _DesktopDownloadDockState();
}

class _DesktopDownloadDockState extends ConsumerState<DesktopDownloadDock> {
  static const _panelWidth = 420.0;
  static const _panelHeight = 420.0;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final fanbox = ref.watch(fanboxDownloadsProvider);
    return StreamBuilder<List<DownloadTaskSnapshot>>(
      stream: downloadManager.watchTasks(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? const <DownloadTaskSnapshot>[];

        final panelTasks = tasks;
        if (panelTasks.isEmpty && !fanbox.visible) {
          return const SizedBox.shrink();
        }

        final summary = combinedDownloadSummary(DownloadSummary.fromTasks(panelTasks), fanbox);

        return Stack(
          children: [
            Positioned.fill(
              key: const ValueKey<String>('desktop-download-dismiss-layer'),
              child: IgnorePointer(
                ignoring: !_expanded,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = false),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              key: const ValueKey<String>('desktop-download-button'),
              left: 0,
              bottom: widget.bottomOffset,
              width: widget.railWidth,
              child: Center(
                child: _DownloadDockButton(summary: summary, expanded: _expanded, onPressed: () => setState(() => _expanded = !_expanded)),
              ),
            ),
            Positioned(
              key: const ValueKey<String>('desktop-download-panel'),
              left: widget.railWidth + 12,
              bottom: widget.bottomOffset,
              width: _panelWidth,
              height: _panelHeight,
              child: IgnorePointer(
                ignoring: !_expanded,
                child: AnimatedOpacity(
                  opacity: _expanded ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: _expanded ? 1 : 0.96,
                    alignment: Alignment.bottomLeft,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: _DownloadDockPanel(
                      summary: summary,
                      tasks: panelTasks,
                      onClose: () => setState(() => _expanded = false),
                      onSync: () => unawaited(_syncDownloads()),
                      onTaskTap: (task) {
                        setState(() => _expanded = false);
                        context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': task.illustId.toString()});
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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

class _DownloadDockButton extends StatelessWidget {
  const _DownloadDockButton({required this.summary, required this.expanded, required this.onPressed});

  final DownloadSummary summary;
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = summary.queued + summary.running + summary.savePending;
    final failures = summary.failed + summary.saveFailed;
    final badgeLabel = failures > 0
        ? failures.toString()
        : active > 0
        ? active.toString()
        : summary.total.toString();
    final badgeColor = failures > 0 ? colorScheme.error : colorScheme.primary;

    return Material(
      color: expanded ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh,
      shape: const CircleBorder(),
      elevation: expanded ? 4 : 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 52,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(Icons.downloading_outlined, color: expanded ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
                ),
              ),
              PositionedDirectional(
                end: -2,
                top: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          badgeLabel,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadDockPanel extends StatelessWidget {
  const _DownloadDockPanel({required this.summary, required this.tasks, required this.onClose, required this.onSync, required this.onTaskTap});

  final DownloadSummary summary;
  final List<DownloadTaskSnapshot> tasks;
  final VoidCallback onClose;
  final VoidCallback onSync;
  final ValueChanged<DownloadTaskSnapshot> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 12,
      color: colorScheme.surface,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: DownloadSummaryView(summary: summary, compact: true)),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 14, bottom: 28),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.sync_outlined), onPressed: onSync),
                      IconButton(icon: const Icon(Icons.close_outlined), onPressed: onClose),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AnimatedSize(duration: Duration(milliseconds: 180), alignment: Alignment.topCenter, child: FanboxDownloadTasks()),
                    if (tasks.isNotEmpty) ...[const Text('Pixiv'), DownloadTaskList(tasks: tasks, compact: true, showTooltips: false, onTaskTap: onTaskTap)],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
