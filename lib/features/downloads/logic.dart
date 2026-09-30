import 'package:freepiv/core/downloads/download_manager.dart';
import 'package:freepiv/core/downloads/download_models.dart';

/// Where an item stands, from the tasks it holds; the downloads list orders
/// and filters items by it.
enum DownloadItemState { collecting, active, failed, cancelled, completed }

/// One source with the tasks downloaded from it: the row the downloads panel
/// and page show for a work, article, novel, FANBOX post or creator.
class DownloadItem {
  const DownloadItem({required this.source, required this.tasks, this.collectedPosts});

  /// Labelled as the newest task saw it.
  final DownloadSource source;

  /// Oldest first, the order the files were asked for.
  final List<DownloadTaskSnapshot> tasks;

  /// For a FANBOX creator still being collected, the posts read so far.
  final int? collectedPosts;

  String get key => source.key;

  bool get collecting => collectedPosts != null;

  int get total => tasks.length;

  int get completed => tasks.where((task) => task.isCompleted).length;

  int get failed => tasks.where((task) => task.needsRetry).length;

  int get active => tasks.where(isActiveDownloadTask).length;

  /// The single file of an item that holds one, shown as the item itself.
  DownloadTaskSnapshot? get onlyTask => tasks.length == 1 ? tasks.single : null;

  /// Null while nothing is known yet: a creator still collecting with no file
  /// queued.
  double? get progress {
    if (tasks.isEmpty) return collecting ? null : 0;
    final sum = tasks.fold<double>(0, (sum, task) => sum + (isFinishedDownloadTask(task) ? 1 : task.progress.clamp(0, 1)));
    return sum / tasks.length;
  }

  DownloadItemState get state {
    if (active > 0) return DownloadItemState.active;
    if (collecting) return DownloadItemState.collecting;
    if (failed > 0) return DownloadItemState.failed;
    if (tasks.isNotEmpty && completed == tasks.length) return DownloadItemState.completed;
    return DownloadItemState.cancelled;
  }

  /// When the item was last asked for, which orders items newest first.
  DateTime get askedAt => tasks.fold(DateTime.fromMillisecondsSinceEpoch(0), (latest, task) => task.createdAt.isAfter(latest) ? task.createdAt : latest);

  /// The files grouped by the part of the source they belong to, in order;
  /// a source without parts is one group under null.
  List<(DownloadPart?, List<DownloadTaskSnapshot>)> get parts {
    final groups = <DownloadPart?, List<DownloadTaskSnapshot>>{};
    for (final task in tasks) {
      (groups[task.part] ??= []).add(task);
    }
    return [for (final MapEntry(:key, :value) in groups.entries) (key, value)];
  }
}

bool isActiveDownloadTask(DownloadTaskSnapshot task) =>
    task.status == DownloadStatus.queued ||
    task.status == DownloadStatus.running ||
    task.status == DownloadStatus.paused ||
    task.saveState == SaveState.pending ||
    task.saveState == SaveState.saving;

bool isFinishedDownloadTask(DownloadTaskSnapshot task) => task.status == DownloadStatus.downloaded || task.saveState == SaveState.saved;

/// [tasks] grouped into items by source, newest first, with [collecting]
/// FANBOX creators that have no file queued yet as items of their own.
List<DownloadItem> downloadItemsOf(List<DownloadTaskSnapshot> tasks, {Iterable<({DownloadSource source, int posts})> collecting = const []}) {
  final bySource = <String, List<DownloadTaskSnapshot>>{};
  for (final task in tasks) {
    (bySource[task.source.key] ??= []).add(task);
  }
  final posts = {for (final entry in collecting) entry.source.key: entry.posts};
  DownloadItem itemOf(List<DownloadTaskSnapshot> group) {
    final ordered = [...group]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return DownloadItem(source: ordered.last.source, tasks: List.unmodifiable(ordered), collectedPosts: posts[ordered.last.source.key]);
  }

  final items = [
    for (final group in bySource.values) itemOf(group),
    for (final entry in collecting)
      if (!bySource.containsKey(entry.source.key)) DownloadItem(source: entry.source, tasks: const [], collectedPosts: entry.posts),
  ];
  // A creator only just being collected has no task yet; it goes first.
  items.sort(
    (a, b) => switch ((a.tasks.isEmpty, b.tasks.isEmpty)) {
      (true, false) => -1,
      (false, true) => 1,
      _ => b.askedAt.compareTo(a.askedAt),
    },
  );
  return items;
}

/// The items the floating panel shows first: those that need watching or a
/// decision (collecting, downloading, failed), then the rest, each newest
/// first.
List<DownloadItem> panelOrder(List<DownloadItem> items) {
  bool urgent(DownloadItem item) => switch (item.state) {
    DownloadItemState.collecting || DownloadItemState.active || DownloadItemState.failed => true,
    DownloadItemState.cancelled || DownloadItemState.completed => false,
  };
  return [...items.where(urgent), ...items.where((item) => !urgent(item))];
}

/// Cancels every unfinished file of [item]; collecting is stopped by the
/// caller, which owns it.
Future<void> cancelDownloadItem(DownloadItem item) async {
  for (final task in item.tasks.where(isActiveDownloadTask)) {
    await downloadManager.cancel(task.id);
  }
}

/// Retries every failed or cancelled file of [item].
Future<void> retryDownloadItem(DownloadItem item) async {
  for (final task in item.tasks) {
    if (task.needsRetry || task.status == DownloadStatus.cancelled) await downloadManager.retry(task.id);
  }
}

/// Removes [item]'s records; files already saved stay where they are.
Future<void> deleteDownloadItem(DownloadItem item) async {
  for (final task in item.tasks) {
    await downloadManager.deleteTask(task.id);
  }
}
