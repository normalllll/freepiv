import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';

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
    final t = context.t.fanbox;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('FANBOX'),
          subtitle: Text(
            progress.error != null
                ? t.downloadFailed
                : progress.running && progress.total == 0
                ? t.downloadPreparing
                : t.downloadProgress(done: progress.completed, total: progress.total),
          ),
          trailing: progress.running
              ? IconButton(tooltip: t.cancelDownload, onPressed: () => ref.read(fanboxDownloadsProvider.notifier).cancel(), icon: const Icon(Icons.stop))
              : IconButton(tooltip: t.retry, onPressed: () => ref.read(fanboxDownloadsProvider.notifier).retry(), icon: const Icon(Icons.refresh)),
        ),
        SizedBox(
          height: 4,
          child: progress.running
              ? progress.total == 0
                    ? const LoadingSkeletonBlock(width: double.infinity, height: 4)
                    : LinearProgressIndicator(value: progress.completed / progress.total)
              : null,
        ),
        for (var index = 0; index < progress.files.length; index++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              index < progress.completed
                  ? Icons.check_circle_outline
                  : progress.cancelled
                  ? Icons.stop_circle_outlined
                  : progress.error != null && index == progress.completed
                  ? Icons.error_outline
                  : Icons.schedule,
            ),
            title: Text(progress.files[index], maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        const Divider(),
      ],
    );
  }
}
