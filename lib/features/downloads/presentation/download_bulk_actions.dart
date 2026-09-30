import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';

class DownloadBulkActions extends ConsumerStatefulWidget {
  const DownloadBulkActions({this.compact = false, this.tasks, super.key});

  final bool compact;
  final List<DownloadTaskSnapshot>? tasks;

  @override
  ConsumerState<DownloadBulkActions> createState() => _DownloadBulkActionsState();
}

class _DownloadBulkActionsState extends ConsumerState<DownloadBulkActions> {
  late final _manager = downloadManager;
  late final _tasks = _manager.watchTasks();
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      AppToast.errorWithCause(t.settings.downloads.actionFailed, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks case final tasks?) return _buildActions(context, tasks);
    return StreamBuilder<List<DownloadTaskSnapshot>>(
      stream: _tasks,
      builder: (context, snapshot) => _buildActions(context, snapshot.data ?? const <DownloadTaskSnapshot>[]),
    );
  }

  Widget _buildActions(BuildContext context, List<DownloadTaskSnapshot> tasks) {
    final retry = _busy || !tasks.any((task) => task.needsRetry) ? null : () => _run(_manager.retryFailed);
    final clear = _busy || !tasks.any((task) => task.isCompleted) ? null : () => _run(_manager.clearCompleted);
    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(tooltip: t.settings.downloads.retryFailed, icon: const Icon(Icons.refresh_outlined), onPressed: retry),
          IconButton(tooltip: t.settings.downloads.clearCompleted, icon: const Icon(Icons.playlist_remove_outlined), onPressed: clear),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Quiet actions: enabling or disabling them never changes their size.
        TextButton.icon(label: Text(t.settings.downloads.retryFailed), icon: const Icon(Icons.refresh_outlined), onPressed: retry),
        TextButton.icon(label: Text(t.settings.downloads.clearCompleted), icon: const Icon(Icons.playlist_remove_outlined), onPressed: clear),
      ],
    );
  }
}
