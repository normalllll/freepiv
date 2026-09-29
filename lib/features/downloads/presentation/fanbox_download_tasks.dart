import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';

DownloadSummary combinedDownloadSummary(DownloadSummary pixiv, FanboxDownloadProgress fanbox) {
  final count = fanbox.visible ? (fanbox.total == 0 ? 1 : fanbox.total) : 0;
  return DownloadSummary(
    illustId: null,
    total: pixiv.total + count,
    queued: pixiv.queued + (fanbox.running ? (count - fanbox.completed - 1).clamp(0, count) : 0),
    running: pixiv.running + (fanbox.running ? 1 : 0),
    downloaded: pixiv.downloaded + fanbox.completed,
    failed: pixiv.failed + (fanbox.error == null ? 0 : 1),
    cancelled: pixiv.cancelled + (fanbox.cancelled ? count - fanbox.completed : 0),
    savePending: pixiv.savePending,
    saveFailed: pixiv.saveFailed,
    saved: pixiv.saved + fanbox.completed,
    overallProgress: pixiv.total + count == 0 ? 0 : (pixiv.overallProgress * pixiv.total + fanbox.completed) / (pixiv.total + count),
  );
}

class FanboxDownloadTasks extends ConsumerWidget {
  const FanboxDownloadTasks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(fanboxDownloadsProvider);
    if (!progress.visible) return const SizedBox.shrink();

    final translations = context.t.fanbox;
    final complete = !progress.running && !progress.cancelled && progress.error == null && progress.completed == progress.total;
    final status = progress.error != null
        ? translations.downloadFailed
        : progress.cancelled
        ? context.t.settings.downloads.cancelled
        : complete
        ? translations.downloadFinished
        : progress.running && progress.total == 0
        ? translations.downloadPreparing
        : translations.downloadProgress(done: progress.completed, total: progress.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('FANBOX', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FpSurface(
          role: FpSurfaceRole.glassPanel,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      progress.error != null
                          ? Icons.error_outline
                          : progress.cancelled
                          ? Icons.stop_circle_outlined
                          : complete
                          ? Icons.check_circle_outline
                          : Icons.downloading_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(status, style: Theme.of(context).textTheme.titleSmall)),
                    if (progress.running)
                      IconButton(
                        tooltip: translations.cancelDownload,
                        onPressed: () => ref.read(fanboxDownloadsProvider.notifier).cancel(),
                        icon: const Icon(Icons.stop_outlined),
                      )
                    else if (progress.error != null || progress.cancelled)
                      IconButton(
                        tooltip: translations.retry,
                        onPressed: () => ref.read(fanboxDownloadsProvider.notifier).retry(),
                        icon: const Icon(Icons.refresh_outlined),
                      )
                    else if (complete)
                      IconButton(
                        tooltip: context.t.settings.downloads.clearCompleted,
                        onPressed: () => ref.read(fanboxDownloadsProvider.notifier).clearCompleted(),
                        icon: const Icon(Icons.close_outlined),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(
                    value: progress.total == 0 ? null : progress.completed / progress.total,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (progress.files.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(translations.downloadProgress(done: progress.completed, total: progress.total)),
                    children: [
                      for (var index = 0; index < progress.files.length; index++)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(index < progress.completed ? Icons.check_circle_outline : Icons.schedule_outlined, size: 20),
                          title: Text(progress.files[index], maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
