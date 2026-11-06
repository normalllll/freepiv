import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/logic.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/downloads/presentation/download_item_widgets.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// Every download record, kept current by the download manager.
final downloadTasksProvider = StreamProvider<List<DownloadTaskSnapshot>>((ref) => downloadManager.watchTasks());

/// What the download entry shows: whether it is there at all, its count and
/// progress, and the items its panel lists.
@immutable
class DownloadActivity {
  const DownloadActivity({required this.items, required this.active, required this.failed, required this.progress});

  static const empty = DownloadActivity(items: [], active: 0, failed: 0, progress: null);

  final List<DownloadItem> items;

  /// Files queued, downloading or waiting to be saved.
  final int active;

  /// Files that failed to download or save.
  final int failed;

  /// The overall progress while anything is active.
  final double? progress;

  /// Shown while there is any record, finished history included, or a creator
  /// is being collected; hidden only without any.
  bool get visible => items.isNotEmpty;

  /// Failures come first; otherwise what is still going.
  int get badge => failed > 0 ? failed : active;

  FrostCountBadgeTone get badgeTone => failed > 0 ? FrostCountBadgeTone.negative : FrostCountBadgeTone.accent;
}

DownloadActivity downloadActivityOf(List<DownloadTaskSnapshot> tasks, {Iterable<({DownloadSource source, int posts})> collecting = const []}) {
  final summary = DownloadSummary.fromTasks(tasks);
  final active = summary.queued + summary.running + summary.savePending;
  return DownloadActivity(
    items: downloadItemsOf(tasks, collecting: collecting),
    active: active,
    failed: summary.failed + summary.saveFailed,
    progress: active > 0 ? summary.overallProgress : null,
  );
}

final downloadActivityProvider = Provider<DownloadActivity>((ref) {
  final tasks = ref.watch(downloadTasksProvider).value ?? const <DownloadTaskSnapshot>[];
  final collecting = ref.watch(fanboxDownloadsProvider).values;
  return downloadActivityOf(tasks, collecting: collecting);
});

/// The shell's download entry ([FrostShell.taskEntry]): the sidebar's last
/// row or the phone layout's floating button, where downloads land.
FrostShellTaskEntry appDownloadTaskEntry(DownloadActivity activity, {required bool revealed}) => FrostShellTaskEntry(
  builder: (context, placement) => DownloadEntryButton(placement: placement),
  visible: activity.visible || revealed,
  initialFloatingPosition: AppSettings.downloadEntryPosition,
  onFloatingPositionChanged: (position) => AppSettings.downloadEntryPosition = position,
);

class DownloadEntryButton extends ConsumerStatefulWidget {
  const DownloadEntryButton({required this.placement, super.key});

  final FrostShellTaskEntryPlacement placement;

  @override
  ConsumerState<DownloadEntryButton> createState() => _DownloadEntryButtonState();
}

class _DownloadEntryButtonState extends ConsumerState<DownloadEntryButton> with SingleTickerProviderStateMixin implements DownloadFlightTarget {
  final _buttonKey = GlobalKey();
  late final _landing = AnimationController(vsync: this, duration: FrostMotion.duration(context, FrostMotion.feedback));

  @override
  void initState() {
    super.initState();
    DownloadFlight.attach(this);
  }

  @override
  void dispose() {
    DownloadFlight.detach(this);
    _landing.dispose();
    super.dispose();
  }

  @override
  Rect? get badgeRect {
    final box = _buttonKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    // The count sits at the icon's top end.
    return Rect.fromCenter(center: Offset(rect.left + 30, rect.top + rect.height / 2 - 8), width: 18, height: 18);
  }

  @override
  void land() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_landing.forward(from: 0));
  }

  Widget _button({required VoidCallback onPressed}) {
    final activity = ref.watch(downloadActivityProvider);
    return ScaleTransition(
      scale: TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 1),
      ]).animate(CurvedAnimation(parent: _landing, curve: Curves.easeOut)),
      child: KeyedSubtree(
        key: _buttonKey,
        child: FrostShellTaskButton(
          icon: PivIcons.download,
          label: context.t.navigation.downloads,
          badge: activity.badge,
          badgeTone: activity.badgeTone,
          progress: activity.progress,
          onPressed: onPressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.placement == FrostShellTaskEntryPlacement.sidebar) {
      return FrostPopover(
        title: context.t.navigation.downloads,
        builder: (context, focusNode, toggle) => _button(onPressed: toggle),
        contentBuilder: (context, close) => DownloadEntryPanel(onClose: close),
      );
    }
    // The floating panel the phone layout should open is not in Frost yet
    // (freepiv-20261107-floating-task-panel); a sheet shows the same panel.
    return _button(
      onPressed: () => showFrostSheet<void>(
        context: context,
        title: context.t.navigation.downloads,
        builder: (sheetContext) => DownloadEntryPanel(onClose: () => Navigator.of(sheetContext).pop()),
      ),
    );
  }
}

/// The entry's panel: a summary, bulk actions, the first items needing
/// attention and the way to the downloads page. Closing it never cancels.
class DownloadEntryPanel extends ConsumerWidget {
  const DownloadEntryPanel({required this.onClose, super.key});

  static const shownItems = 4;

  final VoidCallback onClose;

  /// Collecting, active and failed items first, then the rest, newest first.
  static List<DownloadItem> ordered(List<DownloadItem> items) {
    int rank(DownloadItem item) => switch (item.state) {
      DownloadItemState.collecting => 0,
      DownloadItemState.active => 1,
      DownloadItemState.failed => 2,
      _ => 3,
    };
    return [...items]..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : b.askedAt.compareTo(a.askedAt);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final activity = ref.watch(downloadActivityProvider);
    final items = ordered(activity.items);
    void open(String location) {
      onClose();
      GoRouter.of(context).push(location);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FrostText(
                t.downloadEntry.summary(active: activity.active, failed: activity.failed),
                role: FrostTextRole.footnote,
                tone: FrostTextTone.secondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (activity.failed > 0) FrostButton.quiet(label: t.downloadEntry.retryFailed, onPressed: () => unawaited(downloadManager.retryFailed())),
            if (items.any((item) => item.state == DownloadItemState.completed))
              FrostButton.quiet(label: t.downloadEntry.clearCompleted, onPressed: () => unawaited(downloadManager.clearCompleted())),
          ],
        ),
        for (final item in items.take(shownItems))
          FrostTaskRow(
            key: ValueKey(item.key),
            title: downloadItemTitle(item),
            contentTitle: true,
            status: switch (item.state) {
              DownloadItemState.active || DownloadItemState.collecting => FrostTaskStatus.running,
              DownloadItemState.failed => FrostTaskStatus.failed,
              DownloadItemState.completed => FrostTaskStatus.completed,
              DownloadItemState.cancelled => FrostTaskStatus.cancelled,
            },
            progress: item.state == DownloadItemState.active ? item.progress : null,
            detail: switch (item.state) {
              DownloadItemState.collecting => t.settings.downloads.collectingPosts(count: item.collectedPosts ?? 0),
              DownloadItemState.failed => t.settings.downloads.filesFailed(count: item.failed),
              _ => t.settings.downloads.filesProgress(done: item.completed, total: item.total),
            },
            thumbnail: DownloadSourceThumbnail(source: item.source, url: item.source.thumbnailUrl ?? item.onlyTask?.thumbnailUrl, size: 40),
            actions: [
              if (item.state == DownloadItemState.failed && item.tasks.any((task) => task.needsRetry && !isGeneratedDownload(task.origin)))
                FrostTaskAction(
                  label: t.common.retry,
                  icon: PivIcons.refreshCw,
                  onPressed: () {
                    for (final task in item.tasks.where((task) => task.needsRetry && !isGeneratedDownload(task.origin))) {
                      unawaited(downloadManager.retry(task.id));
                    }
                  },
                ),
            ],
            onPressed: () => open(AppLocations.downloads(item: item.key)),
          ),
        if (items.length > shownItems)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FrostGap.inline),
            child: FrostText(
              t.downloadEntry.more(count: items.length - shownItems),
              role: FrostTextRole.footnote,
              tone: FrostTextTone.secondary,
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FrostButton.quiet(label: t.downloadEntry.viewAll, onPressed: () => open(AppRoute.downloads.path)),
        ),
      ],
    );
  }
}
