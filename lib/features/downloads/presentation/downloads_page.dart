import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/presentation/download_task_widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:go_router/go_router.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: shouldUseDesktopShell ? null : _downloadsAppBar(),
          body: SafeArea(
            top: shouldUseDesktopShell,
            child: Column(
              children: [
                if (shouldUseDesktopShell) _DownloadsHeader(onSync: _syncDownloads),
                Expanded(child: _DownloadsBody(onSync: _syncDownloads)),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _downloadsAppBar() {
    return AppBar(
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
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(t.settings.downloads.tasksTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(tooltip: t.settings.downloads.sync, icon: const Icon(Icons.sync_outlined), onPressed: () => unawaited(onSync())),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadsBody extends StatelessWidget {
  const _DownloadsBody({required this.onSync});

  final Future<void> Function() onSync;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<DownloadSummary>(
      stream: downloadManager.watchSummary(),
      builder: (context, summarySnapshot) {
        final summary =
            summarySnapshot.data ??
            const DownloadSummary(
              illustId: null,
              total: 0,
              queued: 0,
              running: 0,
              downloaded: 0,
              failed: 0,
              cancelled: 0,
              savePending: 0,
              saveFailed: 0,
              saved: 0,
              overallProgress: 0,
            );

        return StreamBuilder<List<DownloadTaskSnapshot>>(
          stream: downloadManager.watchTasks(),
          builder: (context, taskSnapshot) {
            final tasks = taskSnapshot.data ?? const <DownloadTaskSnapshot>[];

            return RefreshIndicator(
              onRefresh: onSync,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Material(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DownloadSummaryView(summary: summary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DownloadTaskList(
                        tasks: tasks,
                        onTaskTap: (task) {
                          context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': task.illustId.toString()});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
