import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';

class DownloadSummaryView extends StatelessWidget {
  const DownloadSummaryView({required this.summary, this.compact = false, this.showHeading = true, this.trailing, super.key});

  final DownloadSummary summary;
  final bool compact;
  final bool showHeading;

  /// Actions placed at the end of the heading row.
  final Widget? trailing;

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
        if (showHeading) ...[
          Row(
            children: [
              Icon(Icons.download_for_offline_outlined, color: FrostThemeTokens.of(context).textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _summaryTitle(summary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compact ? textTheme.titleSmall : textTheme.titleMedium,
                ),
              ),
              Text('${(progress * 100).round()}%', maxLines: 1, softWrap: false, style: textTheme.labelLarge),
              if (trailing case final trailing?) ...[const SizedBox(width: 4), trailing],
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
        ],
        if (summary.total > 0) ...[DownloadProgressIndicator(value: summary.total == 0 ? 0 : progress, minHeight: compact ? 5 : 6), const SizedBox(height: 8)],
        if (compact)
          // One quiet metadata line; only failures draw attention.
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      '${t.settings.downloads.total} ${summary.total} · ${t.settings.downloads.active} $active · ${t.settings.downloads.saved} ${summary.saved}',
                ),
                if (failures > 0)
                  TextSpan(
                    text: ' · ${t.settings.downloads.failed} $failures',
                    style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            maxLines: 2,
            style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          )
        else
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

/// One file of a download item: its name, status, size and progress, with
/// the error that stopped it. [detailed] adds where it was saved, for an
/// item of a single file.
class DownloadFileRow extends StatelessWidget {
  const DownloadFileRow({required this.task, this.detailed = false, this.showTooltips = true, super.key});

  final DownloadTaskSnapshot task;
  final bool detailed;
  final bool showTooltips;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = task.progress.clamp(0, 1).toDouble();
    final active = task.status == DownloadStatus.running || task.status == DownloadStatus.queued;
    final localPath = task.localPath;
    final error = task.error;

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    task.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  // Status first, then the size, which is what changes while
                  // the file downloads.
                  Row(
                    children: [
                      DownloadTaskStatusLabel(task: task, compact: true),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          downloadBytesLabel(task),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  _AnimatedTaskDetail(
                    visible: active,
                    child: DownloadProgressIndicator(value: task.status == DownloadStatus.running || task.totalBytes != null ? progress : null, minHeight: 3),
                  ),
                  _AnimatedTaskDetail(
                    visible: error != null && error.isNotEmpty,
                    child: Text(
                      error ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    ),
                  ),
                  _AnimatedTaskDetail(
                    visible: detailed && localPath != null && localPath.isNotEmpty,
                    child: Text(
                      localPath ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DownloadTaskActions(task: task, showTooltips: showTooltips),
          ],
        ),
      ),
    );
  }
}

/// A file's own actions: retry or cancel while there is one, and a menu to
/// delete its record or read its log.
class DownloadTaskActions extends StatelessWidget {
  const DownloadTaskActions({required this.task, this.showTooltips = true, super.key});

  final DownloadTaskSnapshot task;
  final bool showTooltips;

  @override
  Widget build(BuildContext context) {
    final primaryAction = _primaryActionFor(task, showTooltips: showTooltips);
    // The primary slot only exists while there is an action (cancel or
    // retry); it eases closed when a task finishes instead of leaving a gap
    // before the menu button.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: FrostMotion.duration(context, FrostMotion.expand),
          curve: Curves.easeInOutCubic,
          child: AnimatedSwitcher(
            duration: FrostMotion.duration(context, FrostMotion.hover),
            child: primaryAction == null
                ? const SizedBox.shrink()
                : SizedBox.square(key: primaryAction.key, dimension: FrostMetrics.compactTargetHeight, child: primaryAction),
          ),
        ),
        FrostMenuAnchor(
          menuChildren: [
            FrostMenuItem(
              autofocus: true,
              onPressed: () => unawaited(_runAction(() => downloadManager.deleteTask(task.id))),
              leadingIcon: const Icon(Icons.delete_outline),
              child: Text(t.settings.downloads.deleteTask),
            ),
            if (task.log != null && task.log!.isNotEmpty)
              FrostMenuItem(
                onPressed: () => showDownloadTaskLog(context, task),
                leadingIcon: const Icon(Icons.article_outlined),
                child: Text(t.common.viewLog),
              ),
          ],
          builder: (context, focusNode, toggle) => IconButton(
            focusNode: focusNode,
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onPressed: toggle,
            icon: const Icon(Icons.more_horiz),
            constraints: const BoxConstraints.tightFor(width: FrostMetrics.compactTargetHeight, height: FrostMetrics.compactTargetHeight),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget? _primaryActionFor(DownloadTaskSnapshot task, {required bool showTooltips}) {
    if (task.status == DownloadStatus.failed) {
      return DownloadTaskAction(
        key: const ValueKey<String>('retry'),
        tooltip: showTooltips ? t.common.retry : null,
        icon: const Icon(Icons.refresh_outlined),
        onPressed: () => unawaited(_runAction(() => downloadManager.retry(task.id))),
      );
    }

    if (task.status == DownloadStatus.downloaded && task.saveState == SaveState.failed) {
      return DownloadTaskAction(
        key: const ValueKey<String>('retry-save'),
        tooltip: showTooltips ? t.common.retry : null,
        icon: const Icon(Icons.refresh_outlined),
        onPressed: () => unawaited(_runAction(() => downloadManager.retry(task.id))),
      );
    }

    if (task.status == DownloadStatus.running || task.status == DownloadStatus.queued) {
      return DownloadTaskAction(
        key: const ValueKey<String>('cancel'),
        tooltip: showTooltips ? t.settings.downloads.cancel : null,
        icon: const Icon(Icons.close_outlined),
        onPressed: () => unawaited(_runAction(() => downloadManager.cancel(task.id))),
      );
    }

    return null;
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      toastErrorWithCause(t.settings.downloads.actionFailed, error);
    }
  }
}

void showDownloadTaskLog(BuildContext context, DownloadTaskSnapshot task) {
  final log = task.log;
  if (log == null || log.isEmpty) {
    return;
  }

  showFrostDialog<void>(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(t.common.viewLog, style: Theme.of(context).textTheme.titleMedium),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 460),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                'jobId=${task.id}\n'
                'origin=${switch (task.origin) {
                  ArtworkPage(:final illustId, :final pageIndex) => 'illust $illustId page $pageIndex',
                  ContentFile(:final address) => 'file $address',
                }}\n'
                'filename=${task.filename}\n'
                'status=${task.status.name}\n'
                'saveState=${task.saveState.name}\n'
                'localPath=${task.localPath ?? '<null>'}\n'
                'galleryAssetId=${task.galleryAssetId ?? '<null>'}\n\n'
                '$log',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: log));
              Navigator.of(context).pop();
            },
            child: Text(t.common.copy(label: t.common.viewLog)),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(MaterialLocalizations.of(context).closeButtonTooltip)),
        ],
      );
    },
  );
}

class DownloadTaskAction extends StatelessWidget {
  const DownloadTaskAction({required this.icon, required this.onPressed, this.tooltip, super.key});

  final Widget icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final child = FrostClickSurface(
      onTap: onPressed,

      child: IconTheme.merge(
        data: IconThemeData(size: 18, color: colorScheme.onSurfaceVariant),
        child: Center(child: icon),
      ),
    );

    final tooltip = this.tooltip;
    final target = SizedBox.square(dimension: FrostMetrics.compactTargetHeight, child: child);
    return tooltip == null ? target : Tooltip(message: tooltip, child: target);
  }
}

class DownloadProgressIndicator extends StatelessWidget {
  const DownloadProgressIndicator({required this.value, required this.minHeight, super.key});

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
            ? FrostSkeletonBlock(key: const ValueKey<String>('indeterminate'), width: double.infinity, height: minHeight)
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

/// A file's status, which slides in when it changes.
class DownloadTaskStatusLabel extends StatelessWidget {
  const DownloadTaskStatusLabel({required this.task, this.compact = false, super.key});

  final DownloadTaskSnapshot task;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: compact ? 52 : 68),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 170),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        // Keep the status on the text's start edge instead of centring it.
        layoutBuilder: (current, previous) => Stack(alignment: AlignmentDirectional.centerStart, children: [...previous, ?current]),
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
          downloadTaskStatusLabel(task),
          key: ValueKey<String>('${task.status.name}-${task.saveState.name}'),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: downloadTaskStatusColor(context, task)),
        ),
      ),
    );
  }
}

/// A detail under a file (progress, error, path) that eases in and out with
/// its own height.
class _AnimatedTaskDetail extends StatelessWidget {
  const _AnimatedTaskDetail({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      // Paths and errors read from the text's start edge, never centred.
      layoutBuilder: (current, previous) => Stack(alignment: AlignmentDirectional.topStart, children: [...previous, ?current]),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          alignment: AlignmentDirectional.topStart,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: visible
          ? Padding(
              key: const ValueKey<String>('detail'),
              padding: const EdgeInsets.only(top: 6),
              child: SizedBox(width: double.infinity, child: child),
            )
          : const SizedBox.shrink(key: ValueKey<String>('empty-detail')),
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

class DownloadEmptyState extends StatelessWidget {
  const DownloadEmptyState({this.compact = false, super.key});

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

String downloadTaskStatusLabel(DownloadTaskSnapshot task) {
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

Color downloadTaskStatusColor(BuildContext context, DownloadTaskSnapshot task) {
  final colorScheme = Theme.of(context).colorScheme;
  if (task.status == DownloadStatus.failed || task.saveState == SaveState.failed) {
    return colorScheme.error;
  }
  if (task.status == DownloadStatus.running || task.saveState == SaveState.saving || task.saveState == SaveState.saved) {
    return FrostThemeTokens.of(context).textPrimary;
  }
  return colorScheme.onSurfaceVariant;
}

String downloadBytesLabel(DownloadTaskSnapshot task) {
  final total = task.totalBytes;
  final received = formatByteSize(task.receivedBytes);
  if (total == null || total <= 0 || task.receivedBytes >= total) {
    return received;
  }
  return '$received / ${formatByteSize(total)}';
}
