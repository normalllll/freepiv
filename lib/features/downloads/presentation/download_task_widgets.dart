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
        const SizedBox(height: 12),
        _AnimatedRoundedProgressIndicator(value: summary.total == 0 ? 0 : progress, minHeight: compact ? 5 : 6),
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

    final child = AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DownloadThumbnail(url: task.thumbnailUrl, compact: compact),
            SizedBox(width: compact ? 9 : 12),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (compact ? textTheme.labelLarge : textTheme.titleSmall)?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(progress * 100).round()}%', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
                    ],
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  _AnimatedRoundedProgressIndicator(
                    value: task.status == DownloadStatus.running || task.totalBytes != null ? progress : null,
                    minHeight: compact ? 3 : 5,
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _AnimatedStatusLabel(task: task, status: status, compact: compact),
                      Text('${context.t.common.id} ${task.illustId}', style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      Text(_bytesLabel(task), style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  _AnimatedTaskDetailText(
                    visible: !compact && error != null && error.isNotEmpty,
                    text: error ?? '',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    maxLines: 2,
                  ),
                  _AnimatedTaskDetailText(
                    visible: !compact && localPath != null && localPath.isNotEmpty,
                    text: localPath ?? '',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            SizedBox(width: compact ? 4 : 8),
            _DownloadTaskActions(task: task, compact: compact, showTooltips: showTooltips),
          ],
        ),
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
    final actionSize = compact ? 24.0 : 30.0;
    final primaryAction = _primaryActionFor(task, showTooltips: showTooltips);

    return SizedBox(
      width: actionSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: actionSize,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: _fadeScaleTransition,
              child: primaryAction ?? SizedBox.square(key: const ValueKey<String>('empty-action'), dimension: actionSize),
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          SizedBox.square(
            dimension: actionSize,
            child: _SmallActionIcon(
              key: const ValueKey<String>('delete'),
              tooltip: showTooltips ? t.settings.downloads.deleteTask : null,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => unawaited(_runAction(() => downloadManager.deleteTask(task.id))),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _primaryActionFor(DownloadTaskSnapshot task, {required bool showTooltips}) {
    if (task.status == DownloadStatus.failed) {
      return _SmallActionIcon(
        key: const ValueKey<String>('retry'),
        tooltip: showTooltips ? t.common.retry : null,
        icon: const Icon(Icons.refresh_outlined),
        onPressed: () => unawaited(_runAction(() => downloadManager.retry(task.id))),
      );
    }

    if (task.status == DownloadStatus.downloaded && task.saveState == SaveState.failed) {
      return _SmallActionIcon(
        key: const ValueKey<String>('retry-save'),
        tooltip: showTooltips ? t.settings.downloads.retrySave : null,
        icon: const Icon(Icons.save_as_outlined),
        onPressed: () => unawaited(_runAction(() => downloadManager.retrySave(task.id))),
      );
    }

    if (task.status == DownloadStatus.running || task.status == DownloadStatus.queued) {
      return _SmallActionIcon(
        key: const ValueKey<String>('cancel'),
        tooltip: showTooltips ? t.settings.downloads.cancel : null,
        icon: const Icon(Icons.close_outlined),
        onPressed: () => unawaited(_runAction(() => downloadManager.cancel(task.id))),
      );
    }

    return null;
  }

  Widget _fadeScaleTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1).animate(animation), child: child),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      AppToast.errorWithCause(t.settings.downloads.actionFailed, error);
    }
  }
}

class _SmallActionIcon extends StatelessWidget {
  const _SmallActionIcon({required this.icon, required this.onPressed, this.tooltip, super.key});

  final Widget icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final child = InkResponse(
      onTap: onPressed,
      radius: 15,
      containedInkWell: false,
      child: IconTheme.merge(
        data: IconThemeData(size: 18, color: colorScheme.onSurfaceVariant),
        child: Center(child: icon),
      ),
    );

    final tooltip = this.tooltip;
    return tooltip == null ? child : Tooltip(message: tooltip, child: child);
  }
}

class _AnimatedRoundedProgressIndicator extends StatelessWidget {
  const _AnimatedRoundedProgressIndicator({required this.value, required this.minHeight});

  final double? value;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(minHeight / 2);

    return ClipRRect(
      borderRadius: borderRadius,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: value == null
            ? LinearProgressIndicator(key: const ValueKey<String>('indeterminate'), minHeight: minHeight, borderRadius: borderRadius)
            : TweenAnimationBuilder<double>(
                key: const ValueKey<String>('determinate'),
                tween: Tween<double>(end: value!.clamp(0, 1).toDouble()),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, child) {
                  return LinearProgressIndicator(value: animatedValue, minHeight: minHeight, borderRadius: borderRadius);
                },
              ),
      ),
    );
  }
}

class _AnimatedStatusLabel extends StatelessWidget {
  const _AnimatedStatusLabel({required this.task, required this.status, required this.compact});

  final DownloadTaskSnapshot task;
  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: compact ? 52 : 68),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 170),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          status,
          key: ValueKey<String>('${task.status.name}-${task.saveState.name}'),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: _statusColor(context, task)),
        ),
      ),
    );
  }
}

class _AnimatedTaskDetailText extends StatelessWidget {
  const _AnimatedTaskDetailText({required this.visible, required this.text, required this.style, this.maxLines = 1});

  final bool visible;
  final String text;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.topCenter,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: visible
          ? Padding(
              key: ValueKey<String>(text),
              padding: const EdgeInsets.only(top: 6),
              child: Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: style),
            )
          : const SizedBox.shrink(key: ValueKey<String>('empty-detail')),
    );
  }
}

class _DownloadThumbnail extends StatelessWidget {
  const _DownloadThumbnail({required this.url, required this.compact});

  final String? url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 50.0;
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
