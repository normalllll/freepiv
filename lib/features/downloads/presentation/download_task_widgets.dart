import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';

class DownloadSummaryView extends StatelessWidget {
  const DownloadSummaryView({required this.summary, this.compact = false, super.key});

  final DownloadSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = summary.overallProgress.clamp(0, 1).toDouble();
    final active = summary.queued + summary.running;
    final failures = summary.failed + summary.saveFailed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.download_for_offline_outlined, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_summaryTitle(summary), maxLines: 1, overflow: TextOverflow.ellipsis, style: compact ? textTheme.titleSmall : textTheme.titleMedium),
            ),
            Text('${(progress * 100).round()}%', style: textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: summary.total == 0 ? 0 : progress),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _SummaryPill(icon: Icons.list_alt_outlined, label: '${t.settings.downloads.total}: ${summary.total}'),
            _SummaryPill(icon: Icons.downloading_outlined, label: '${t.settings.downloads.active}: $active'),
            _SummaryPill(icon: Icons.check_circle_outline, label: '${t.settings.downloads.saved}: ${summary.saved}'),
            if (failures > 0) _SummaryPill(icon: Icons.error_outline, label: '${t.settings.downloads.failed}: $failures', color: colorScheme.error),
          ],
        ),
      ],
    );
  }
}

class DownloadTaskList extends StatelessWidget {
  const DownloadTaskList({required this.tasks, this.compact = false, this.maxItems, this.showTooltips = true, this.onTaskTap, super.key});

  final List<DownloadTaskSnapshot> tasks;
  final bool compact;
  final int? maxItems;
  final bool showTooltips;
  final ValueChanged<DownloadTaskSnapshot>? onTaskTap;

  @override
  Widget build(BuildContext context) {
    final visibleTasks = maxItems == null ? tasks : tasks.take(maxItems!).toList(growable: false);
    if (visibleTasks.isEmpty) {
      return _DownloadEmptyState(compact: compact);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < visibleTasks.length; index += 1) ...[
          if (index > 0) const Divider(height: 1),
          DownloadTaskTile(task: visibleTasks[index], compact: compact, showTooltips: showTooltips, onTaskTap: onTaskTap),
        ],
      ],
    );
  }
}

class DownloadTaskTile extends StatelessWidget {
  const DownloadTaskTile({required this.task, this.compact = false, this.showTooltips = true, this.onTaskTap, super.key});

  final DownloadTaskSnapshot task;
  final bool compact;
  final bool showTooltips;
  final ValueChanged<DownloadTaskSnapshot>? onTaskTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = _taskStatusLabel(task);
    final progress = task.progress.clamp(0, 1).toDouble();
    final localPath = task.localPath;
    final error = task.error;

    final child = Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DownloadThumbnail(url: task.thumbnailUrl, compact: compact),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.filename,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: (compact ? textTheme.labelLarge : textTheme.titleSmall)?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(progress * 100).round()}%', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: task.status == DownloadStatus.running || task.totalBytes != null ? progress : null, minHeight: compact ? 3 : 4),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(status, style: textTheme.labelMedium?.copyWith(color: _statusColor(context, task))),
                    Text('${context.t.common.id} ${task.illustId}', style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Text(_bytesLabel(task), style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                if (!compact && error != null && error.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    error,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  ),
                ],
                if (!compact && localPath != null && localPath.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    localPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _DownloadTaskActions(task: task, compact: compact, showTooltips: showTooltips),
        ],
      ),
    );

    final onTaskTap = this.onTaskTap;
    if (onTaskTap == null || !_canOpenIllust(task)) {
      return child;
    }

    return InkWell(onTap: () => onTaskTap(task), child: child);
  }
}

class _DownloadTaskActions extends StatelessWidget {
  const _DownloadTaskActions({required this.task, required this.compact, required this.showTooltips});

  final DownloadTaskSnapshot task;
  final bool compact;
  final bool showTooltips;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (task.status == DownloadStatus.failed) {
      actions.add(
        IconButton(
          tooltip: showTooltips ? t.common.retry : null,
          icon: const Icon(Icons.refresh_outlined),
          onPressed: () => unawaited(_runAction(() => downloadManager.retry(task.id))),
        ),
      );
    }

    if (task.status == DownloadStatus.downloaded && task.saveState == SaveState.failed) {
      actions.add(
        IconButton(
          tooltip: showTooltips ? t.settings.downloads.retrySave : null,
          icon: const Icon(Icons.save_as_outlined),
          onPressed: () => unawaited(_runAction(() => downloadManager.retrySave(task.id))),
        ),
      );
    }

    if (task.status == DownloadStatus.running || task.status == DownloadStatus.queued) {
      actions.add(
        IconButton(
          tooltip: showTooltips ? t.settings.downloads.cancel : null,
          icon: const Icon(Icons.close_outlined),
          onPressed: () => unawaited(_runAction(() => downloadManager.cancel(task.id))),
        ),
      );
    }

    if (actions.isEmpty) {
      return SizedBox(width: compact ? 0 : 40);
    }

    return Column(mainAxisSize: MainAxisSize.min, children: actions);
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      AppToast.errorWithCause(t.settings.downloads.actionFailed, error);
    }
  }
}

class _DownloadThumbnail extends StatelessWidget {
  const _DownloadThumbnail({required this.url, required this.compact});

  final String? url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 44.0 : 56.0;
    final url = this.url;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null || url.isEmpty
            ? ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant),
              )
            : PixivImage(url: url, fit: BoxFit.cover),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
      ],
    );
  }
}

class _DownloadEmptyState extends StatelessWidget {
  const _DownloadEmptyState({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 16 : 40, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_done_outlined, size: compact ? 28 : 44, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(t.settings.downloads.noTasks, style: Theme.of(context).textTheme.titleSmall),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              t.settings.downloads.noTasksMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

String _summaryTitle(DownloadSummary summary) {
  if (summary.total == 0) {
    return t.settings.downloads.tasksTitle;
  }
  if (summary.running > 0 || summary.queued > 0) {
    return t.settings.downloads.downloading;
  }
  if (summary.failed > 0 || summary.saveFailed > 0) {
    return t.settings.downloads.needsAttention;
  }
  return t.settings.downloads.completed;
}

String _taskStatusLabel(DownloadTaskSnapshot task) {
  if (task.status == DownloadStatus.downloaded) {
    return switch (task.saveState) {
      SaveState.pending => t.settings.downloads.savePending,
      SaveState.saving => t.settings.downloads.saving,
      SaveState.saved => t.settings.downloads.saved,
      SaveState.failed => t.settings.downloads.saveFailed,
      SaveState.none => t.settings.downloads.downloaded,
    };
  }

  return switch (task.status) {
    DownloadStatus.queued => t.settings.downloads.queued,
    DownloadStatus.running => t.settings.downloads.running,
    DownloadStatus.paused => t.settings.downloads.paused,
    DownloadStatus.downloaded => t.settings.downloads.downloaded,
    DownloadStatus.failed => t.settings.downloads.failed,
    DownloadStatus.cancelled => t.settings.downloads.cancelled,
  };
}

Color _statusColor(BuildContext context, DownloadTaskSnapshot task) {
  final colorScheme = Theme.of(context).colorScheme;
  if (task.status == DownloadStatus.failed || task.saveState == SaveState.failed) {
    return colorScheme.error;
  }
  if (task.status == DownloadStatus.running || task.saveState == SaveState.saving) {
    return colorScheme.primary;
  }
  if (task.saveState == SaveState.saved) {
    return colorScheme.tertiary;
  }
  return colorScheme.onSurfaceVariant;
}

String _bytesLabel(DownloadTaskSnapshot task) {
  final total = task.totalBytes;
  final received = _formatBytes(task.receivedBytes);
  if (total == null || total <= 0) {
    return received;
  }
  return '$received / ${_formatBytes(total)}';
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0.00 B';

  const units = ['B', 'KB', 'MB', 'GB'];
  final exponent = math.min((math.log(bytes) / math.log(1024)).floor(), units.length - 1);
  final value = bytes / math.pow(1024, exponent);
  return '${value.toStringAsFixed(2)} ${units[exponent]}';
}

bool _canOpenIllust(DownloadTaskSnapshot task) {
  return task.status == DownloadStatus.downloaded || task.saveState == SaveState.saved;
}
