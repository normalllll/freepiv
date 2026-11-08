import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/platform/local_files.dart';
import 'package:freepiv/features/downloads/logic.dart';
import 'package:freepiv/features/downloads/presentation/download_entry.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/fanbox_image.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/compositions/sectioned_page.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The downloads page: All (the default: what is in
/// progress, then what is done), In progress (failed and cancelled first,
/// then collecting, downloading and queued) and Completed (by day). Each item is a card that opens in place to its files. Sync is one tap in the
/// header (F5 and pulling down sync too); More retries every failure or
/// clears what is done. Deleting a record never deletes the saved file.
class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({this.focusItem, super.key});

  /// The item to open and bring into view, as the download panel asks when
  /// one of its items is tapped.
  final String? focusItem;

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);
  late final Set<String> _open = {?widget.focusItem};
  final _focusKey = GlobalKey(debugLabel: 'focused download');
  bool _focusPlaced = false;
  bool _focusShown = false;
  bool _syncing = false;
  bool _failedOpen = false;

  /// Failures beyond this fold into one group that opens on demand.
  static const failuresShown = 3;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await downloadManager.sync();
    } catch (error) {
      toastErrorWithCause(t.settings.downloads.syncFailed, error);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _toggle(String key) => setState(() {
    if (!_open.remove(key)) _open.add(key);
  });

  /// Opens the item the page was opened for, on All where every item is,
  /// and brings it into view once it is built.
  void _place(List<DownloadItem> items) {
    final focus = widget.focusItem;
    if (focus == null || _focusPlaced) return;
    final item = items.where((item) => item.key == focus).firstOrNull;
    if (item == null) return;
    _focusPlaced = true;
    if (item.state == DownloadItemState.failed) _failedOpen = true;
  }

  void _reveal() {
    if (_focusShown || widget.focusItem == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focused = _focusKey.currentContext;
      if (!mounted || focused == null || _focusShown) return;
      _focusShown = true;
      unawaited(Scrollable.ensureVisible(focused, duration: FrostMotion.duration(context, FrostMotion.expand), alignment: .1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final labels = t.settings.downloads;
    final tasks = ref.watch(downloadTasksProvider);
    final items = downloadItemsOf(tasks.value ?? const [], collecting: ref.watch(fanboxDownloadsProvider).values);
    _place(items);
    final failed = items.any((item) => item.failed > 0);
    final completed = items.any((item) => item.state == DownloadItemState.completed);
    return AppSectionedPage(
      controller: _tabs,
      header: FrostPageHeader(
        title: FrostText(labels.title),
        actions: [
          FrostToolbarItem.action(
            icon: PivIcons.refreshCw,
            label: labels.sync,
            onPressed: _syncing ? null : () => unawaited(_sync()),
            priority: FrostToolbarPriority.high,
          ),
          FrostToolbarItem.menu(
            label: FrostScope.labelsOf(context).more,
            icon: PivIcons.more,
            showsLabel: false,
            entries: [
              FrostMenuAction(
                labels.retryFailed,
                leading: const FrostGlyph.icon(PivIcons.refreshCw),
                enabled: failed,
                onSelected: () => unawaited(runDownloadAction(downloadManager.retryFailed)),
              ),
              FrostMenuAction(
                labels.clearCompleted,
                leading: const FrostGlyph.icon(PivIcons.trash),
                enabled: completed,
                onSelected: () => unawaited(runDownloadAction(downloadManager.clearCompleted)),
              ),
            ],
          ),
        ],
      ),
      tabs: [
        FrostTab(label: t.downloadsPage.all),
        FrostTab(label: t.downloadsPage.inProgress),
        FrostTab(label: labels.completed),
      ],
      onRefresh: (_) => _sync(),
      slivers: (context, section) {
        if (!tasks.hasValue) {
          if (tasks.error case final error?) {
            return [
              SliverFillRemaining(
                hasScrollBody: false,
                child: FrostErrorContent.fromError(error: error, onRetry: () => ref.invalidate(downloadTasksProvider)),
              ),
            ];
          }
          return [_column(const SliverToBoxAdapter(child: _DownloadsSkeleton()))];
        }
        _reveal();
        return [
          // A later failure to read the records shows above the list it keeps.
          if (tasks.error case final error?)
            _column(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: FrostGap.related),
                  child: FrostCompactMessage.error(error: error, actionLabel: t.common.retry, onAction: () => ref.invalidate(downloadTasksProvider)),
                ),
              ),
            ),
          ...switch (section) {
            0 => _all(context, items),
            1 => _inProgress(context, items),
            _ => _completed(context, items),
          },
        ];
      },
    );
  }

  /// Every item: what is in progress, then what is done by day.
  List<Widget> _all(BuildContext context, List<DownloadItem> items) {
    if (items.isEmpty) return [_empty(context, context.t.downloadsPage.nothingDone)];
    return [
      if (items.any((item) => item.state != DownloadItemState.completed)) ...[
        _heading(context.t.downloadsPage.inProgress),
        ..._inProgress(context, items),
      ],
      if (items.any((item) => item.state == DownloadItemState.completed)) ..._completed(context, items),
    ];
  }

  List<Widget> _inProgress(BuildContext context, List<DownloadItem> items) {
    final t = context.t;
    int rank(DownloadItem item) => switch (item.state) {
      DownloadItemState.failed || DownloadItemState.cancelled => 0,
      DownloadItemState.collecting => 1,
      DownloadItemState.active => item.active > 0 && item.tasks.any((task) => task.status == DownloadStatus.running) ? 2 : 3,
      DownloadItemState.completed => 4,
    };
    final going = items.where((item) => item.state != DownloadItemState.completed).toList()
      ..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : b.askedAt.compareTo(a.askedAt);
      });
    if (going.isEmpty) return [_empty(context, t.downloadsPage.nothingInProgress)];
    final failures = going.where((item) => item.state == DownloadItemState.failed).toList();
    final rest = going.where((item) => item.state != DownloadItemState.failed).toList();
    final fold = failures.length > failuresShown;
    return [
      if (fold)
        _column(
          SliverToBoxAdapter(
            child: FrostSectionHeader.collapsible(
              title: t.downloadsPage.failedGroup(count: failures.length),
              expanded: _failedOpen,
              onExpansionChanged: (open) => setState(() => _failedOpen = open),
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      if (!fold || _failedOpen)
        for (final item in failures) ..._item(context, item),
      for (final item in rest) ..._item(context, item),
    ];
  }

  List<Widget> _completed(BuildContext context, List<DownloadItem> items) {
    final t = context.t;
    final done = items.where((item) => item.state == DownloadItemState.completed).toList()..sort((a, b) => b.askedAt.compareTo(a.askedAt));
    if (done.isEmpty) return [_empty(context, t.downloadsPage.nothingDone)];
    final days = <DateTime, List<DownloadItem>>{};
    for (final item in done) {
      final asked = item.askedAt.toLocal();
      (days[DateTime(asked.year, asked.month, asked.day)] ??= []).add(item);
    }
    return [
      for (final MapEntry(key: day, value: dayItems) in days.entries) ...[
        _heading(formatPixivDate(day.toIso8601String())),
        for (final item in dayItems) ..._item(context, item),
      ],
    ];
  }

  Widget _column(Widget sliver) => FrostSliverContentColumn(maxWidth: double.infinity, sliver: sliver);

  /// A group's title, as far from its first card as the cards are apart.
  Widget _heading(String title) => _column(
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
        child: FrostSectionHeader(title: title),
      ),
    ),
  );

  Widget _empty(BuildContext context, String title) => SliverFillRemaining(
    hasScrollBody: false,
    child: FrostEmptyState(icon: PivIcons.download, title: title, message: context.t.settings.downloads.noTasksMessage),
  );

  /// An item's card, its files inside it while open.
  List<Widget> _item(BuildContext context, DownloadItem item) => [
    _column(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: FrostGap.related),
          child: KeyedSubtree(
            key: item.key == widget.focusItem ? _focusKey : ValueKey(item.key),
            child: DownloadItemCard(item: item, open: _open.contains(item.key), onPressed: () => _toggle(item.key)),
          ),
        ),
      ),
    ),
  ];
}

/// Runs a download action; a failure says so in a toast.
Future<void> runDownloadAction(Future<void> Function() action) async {
  try {
    await action();
  } catch (error) {
    toastErrorWithCause(t.settings.downloads.actionFailed, error);
  }
}

FrostTaskStatus _status(DownloadItemState state) => switch (state) {
  DownloadItemState.active || DownloadItemState.collecting => FrostTaskStatus.running,
  DownloadItemState.failed => FrostTaskStatus.failed,
  DownloadItemState.completed => FrostTaskStatus.completed,
  DownloadItemState.cancelled => FrostTaskStatus.cancelled,
};

/// A source's picture: FANBOX through its session, Pixivision with its
/// referrer, the rest as Pixiv images.
class DownloadThumbnail extends StatelessWidget {
  const DownloadThumbnail({required this.source, required this.url, this.size = FrostThumbnailSize.small, super.key});

  final DownloadSource source;
  final String? url;
  final FrostThumbnailSize size;

  static const _pixivisionReferer = {'Referer': 'https://www.pixivision.net/'};

  @override
  Widget build(BuildContext context) => FrostThumbnail(
    size: size,
    semanticLabel: source.title ?? '',
    image: switch (source) {
      FanboxSource() => AppFanboxImage(url: url, aspectRatio: 1, radius: 0),
      PixivisionSource() => AppPixivImage(url: url ?? '', aspectRatio: 1, radius: 0, headers: _pixivisionReferer),
      _ => AppPixivImage(url: url ?? '', aspectRatio: 1, radius: 0),
    },
  );
}

/// A saved file's path, or null while it has none.
String? _savedPath(DownloadTaskSnapshot task) => task.localPath?.isNotEmpty ?? false ? task.localPath : null;

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// When something was asked for, in local time.
String downloadTimeLabel(DateTime time) {
  final local = time.toLocal();
  return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} ${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

/// One item as a card: its picture, name, a line of what it is and where it
/// stands, and its files inside the same card once open. A finished item has
/// Open, Show in folder (desktop) and Open work; anything else its one action.
/// The same actions and Delete are in More and the context menu; touch swipes
/// to the main ones.
class DownloadItemCard extends ConsumerWidget {
  const DownloadItemCard({required this.item, required this.open, required this.onPressed, super.key});

  final DownloadItem item;
  final bool open;
  final VoidCallback onPressed;

  /// Narrower cards put the finished item's buttons under its text.
  static const buttonsBesideFrom = 720.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final labels = t.settings.downloads;
    final source = item.source;
    final router = GoRouter.of(context);
    final author = source.subtitle?.trim() ?? '';
    final kind = switch (source) {
      NovelSource() => t.nativeWindow.novel,
      PixivisionSource() => 'pixivision',
      FanboxSource() => 'FANBOX',
      ArtworkSource() || StandaloneSource() => null,
    };
    final size = item.tasks.fold<int>(0, (sum, task) => sum + task.receivedBytes);
    final detail = [
      ?kind,
      if (author.isNotEmpty) author,
      if (item.tasks.length > 1) labels.filesCount(count: item.tasks.length),
      if (size > 0) formatByteSize(size),
      downloadTimeLabel(item.askedAt),
      ?switch (item.state) {
        DownloadItemState.collecting => labels.collectingPosts(count: item.collectedPosts ?? 0),
        DownloadItemState.failed => labels.filesFailed(count: item.failed),
        DownloadItemState.cancelled => labels.cancelled,
        // One file's progress is its bar.
        DownloadItemState.active => item.total > 1 ? labels.filesProgress(done: item.completed, total: item.total) : null,
        DownloadItemState.completed => labels.saved,
      },
    ].join(' · ');
    final primary = switch (item.state) {
      DownloadItemState.active || DownloadItemState.collecting => FrostTaskAction(
        label: labels.cancel,
        icon: PivIcons.close,
        onPressed: () {
          if (source case FanboxCreatorSource(:final creatorId)) ref.read(fanboxDownloadsProvider.notifier).stopCollecting(creatorId);
          unawaited(runDownloadAction(() => cancelDownloadItem(item)));
        },
      ),
      DownloadItemState.failed || DownloadItemState.cancelled => FrostTaskAction(
        label: t.common.retry,
        icon: PivIcons.refreshCw,
        onPressed: () => unawaited(runDownloadAction(() => retryDownloadItem(item))),
      ),
      DownloadItemState.completed => null,
    };
    final saved = isDesktopPlatform ? item.tasks.map(_savedPath).nonNulls.firstOrNull : null;
    final actions = <({String label, FrostIconData icon, VoidCallback onPressed})>[
      if (saved != null) ...[
        (label: labels.open, icon: PivIcons.externalLink, onPressed: () => unawaited(runDownloadAction(() => openLocalFile(saved)))),
        (label: labels.showInFolder, icon: PivIcons.folder, onPressed: () => unawaited(runDownloadAction(() => revealLocalFile(saved)))),
      ],
      if (source is! StandaloneSource) (label: labels.openWork, icon: PivIcons.images, onPressed: () => openDownloadSource(router, source)),
    ];
    final menu = <FrostMenuEntry>[
      FrostMenuAction(open ? labels.collapseItem : labels.expandItem, onSelected: onPressed),
      for (final action in actions) FrostMenuAction(action.label, leading: FrostGlyph.icon(action.icon), onSelected: action.onPressed),
      FrostMenuAction(
        labels.deleteItem,
        leading: const FrostGlyph.icon(PivIcons.trash),
        destructive: true,
        onSelected: () => unawaited(runDownloadAction(() => deleteDownloadItem(item))),
      ),
    ];
    final more = FrostMenuAnchor(
      entries: menu,
      builder: (context, focusNode, toggle) =>
          FrostButton.icon(icon: PivIcons.more, label: FrostScope.labelsOf(context).more, size: FrostControlSize.compact, onPressed: toggle),
    );
    final buttons = item.state == DownloadItemState.completed
        ? [for (final action in actions) FrostButton(label: action.label, icon: action.icon, size: FrostControlSize.compact, onPressed: action.onPressed)]
        : const <Widget>[];
    return FrostSurface(
      role: FrostSurfaceRole.module,
      edge: FrostSurfaceEdge.none,
      elevated: false,
      borderRadius: BorderRadius.circular(FrostRadius.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final beside = constraints.maxWidth >= buttonsBesideFrom;
          final inset = FrostGap.of(context).rowInset;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostSwipeActions(
                showsPointerActions: false,
                trailing: [
                  if (primary case final primary?) FrostSwipeAction(label: primary.label, icon: primary.icon, onPressed: primary.onPressed),
                  FrostSwipeAction(
                    label: labels.deleteItem,
                    icon: PivIcons.trash,
                    tone: FrostSwipeTone.destructive,
                    onPressed: () => unawaited(runDownloadAction(() => deleteDownloadItem(item))),
                  ),
                ],
                child: FrostTaskRow(
                  title: downloadItemTitle(item),
                  contentTitle: true,
                  status: _status(item.state),
                  progress: item.state == DownloadItemState.active ? item.progress : null,
                  detail: detail,
                  // The inset is the card's, inside the row so its highlight fills the card.
                  thumbnail: Padding(
                    padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
                    child: DownloadThumbnail(source: source, url: source.thumbnailUrl ?? item.onlyTask?.thumbnailUrl, size: FrostThumbnailSize.regular),
                  ),
                  actions: [?primary],
                  trailing: Row(mainAxisSize: MainAxisSize.min, spacing: FrostGap.inline, children: [if (beside) ...buttons, more]),
                  onPressed: onPressed,
                  contextMenu: menu,
                ),
              ),
              if (!beside && buttons.isNotEmpty)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: inset, end: inset, bottom: FrostGap.related),
                  child: Wrap(spacing: FrostGap.inline, runSpacing: FrostGap.inline, alignment: WrapAlignment.end, children: buttons),
                ),
              FrostPresence(
                visible: open,
                effect: FrostPresenceEffect.expand,
                alignment: AlignmentDirectional.topStart,
                child: DownloadItemFilesView(item: item),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// An item's files, flat inside its card: failed and going in full, the first
/// queued ones with a way to the rest; a finished item lists its files, one
/// still going folds the finished ones under a row. A FANBOX creator's by post.
class DownloadItemFilesView extends StatefulWidget {
  const DownloadItemFilesView({required this.item, super.key});

  final DownloadItem item;

  /// Queued files shown before Show all.
  static const queuedShown = 3;

  @override
  State<DownloadItemFilesView> createState() => _DownloadItemFilesViewState();
}

class _DownloadItemFilesViewState extends State<DownloadItemFilesView> {
  bool _allQueued = false;
  bool _doneOpen = false;

  @override
  Widget build(BuildContext context) {
    final labels = context.t.settings.downloads;
    final parts = widget.item.parts;
    final finished = widget.item.state == DownloadItemState.completed;
    final inset = EdgeInsets.symmetric(horizontal: FrostGap.of(context).rowInset);
    Widget lines(Iterable<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) ...[const FrostDivider(), row],
      ],
    );
    Widget files(List<DownloadTaskSnapshot> tasks) {
      if (finished) return lines([for (final task in tasks) DownloadFileRow(task: task)]);
      final failed = tasks.where((task) => task.needsRetry || task.status == DownloadStatus.cancelled).toList();
      final going = tasks
          .where((task) => task.status == DownloadStatus.running || task.saveState == SaveState.saving || task.saveState == SaveState.pending)
          .toList();
      final queued = tasks.where((task) => task.status == DownloadStatus.queued || task.status == DownloadStatus.paused).toList();
      final done = tasks.where((task) => !failed.contains(task) && !going.contains(task) && !queued.contains(task)).toList();
      final shownQueued = _allQueued ? queued : queued.take(DownloadItemFilesView.queuedShown).toList();
      return lines([
        for (final task in [...failed, ...going, ...shownQueued]) DownloadFileRow(task: task),
        if (shownQueued.length < queued.length)
          Padding(
            padding: inset,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FrostButton.quiet(
                label: labels.showAll(count: queued.length),
                edgeAlignment: FrostButtonEdgeAlignment.start,
                onPressed: () => setState(() => _allQueued = true),
              ),
            ),
          ),
        if (done.isNotEmpty)
          FrostListRow(
            title: '${labels.saved} · ${done.length}',
            accessory: FrostRowAccessory.chevron,
            onPressed: () => setState(() => _doneOpen = !_doneOpen),
          ),
        if (done.isNotEmpty && _doneOpen)
          for (final task in done) DownloadFileRow(task: task),
      ]);
    }

    if (parts.length == 1 && parts.single.$1 == null) return files(widget.item.tasks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (part, tasks) in parts) ...[
          const FrostDivider(),
          Padding(
            padding: inset,
            child: FrostSectionHeader(title: part?.title ?? ''),
          ),
          files(tasks),
        ],
      ],
    );
  }
}

/// One file: its name, size and state or error; on desktop Open and Show in
/// folder once saved, otherwise retry or cancel; a menu to read its log or
/// delete its record.
class DownloadFileRow extends StatelessWidget {
  const DownloadFileRow({required this.task, super.key});

  final DownloadTaskSnapshot task;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final labels = t.settings.downloads;
    final error = task.error?.trim() ?? '';
    final status = switch (task) {
      _ when task.needsRetry => FrostTaskStatus.failed,
      _ when task.status == DownloadStatus.cancelled => FrostTaskStatus.cancelled,
      _ when task.status == DownloadStatus.queued => FrostTaskStatus.queued,
      _ when task.status == DownloadStatus.paused => FrostTaskStatus.paused,
      _ when task.isCompleted => FrostTaskStatus.completed,
      _ => FrostTaskStatus.running,
    };
    final retryable = (task.needsRetry || task.status == DownloadStatus.cancelled) && !isGeneratedDownload(task.origin);
    final cancellable = task.status == DownloadStatus.queued || task.status == DownloadStatus.running;
    final saved = isDesktopPlatform && task.isCompleted ? _savedPath(task) : null;
    return FrostTaskRow(
      title: task.filename,
      contentTitle: true,
      status: status,
      progress: task.status == DownloadStatus.running ? task.progress.clamp(0, 1).toDouble() : null,
      detail: [downloadBytesLabel(task), if (error.isNotEmpty) error else downloadTaskStatusLabel(task)].join(' · '),
      actions: [
        if (saved != null) ...[
          FrostTaskAction(label: labels.open, icon: PivIcons.externalLink, onPressed: () => unawaited(runDownloadAction(() => openLocalFile(saved)))),
          FrostTaskAction(label: labels.showInFolder, icon: PivIcons.folder, onPressed: () => unawaited(runDownloadAction(() => revealLocalFile(saved)))),
        ],
        if (retryable)
          FrostTaskAction(label: t.common.retry, icon: PivIcons.refreshCw, onPressed: () => unawaited(runDownloadAction(() => downloadManager.retry(task.id)))),
        if (cancellable)
          FrostTaskAction(label: labels.cancel, icon: PivIcons.close, onPressed: () => unawaited(runDownloadAction(() => downloadManager.cancel(task.id)))),
      ],
      contextMenu: [
        if (task.log?.isNotEmpty ?? false)
          FrostMenuAction(t.common.viewLog, leading: const FrostGlyph.icon(PivIcons.code), onSelected: () => unawaited(showDownloadLog(context, task))),
        FrostMenuAction(
          labels.deleteTask,
          leading: const FrostGlyph.icon(PivIcons.trash),
          destructive: true,
          onSelected: () => unawaited(runDownloadAction(() => downloadManager.deleteTask(task.id))),
        ),
      ],
    );
  }
}

/// A file's log in a dialog, ready to copy.
Future<void> showDownloadLog(BuildContext context, DownloadTaskSnapshot task) => showFrostDialog<void>(
  context: context,
  builder: (context) => FrostDialog(
    title: context.t.common.viewLog,
    size: FrostDialogSize.wide,
    actions: [FrostDialogAction(label: FrostScope.labelsOf(context).close, value: null, isDefault: true)],
    content: FrostCodeBlock(
      wrap: FrostCodeWrap.anywhere,
      text:
          'jobId=${task.id}\n'
          'origin=${switch (task.origin) {
            ArtworkPage(:final illustId, :final pageIndex) => 'illust $illustId page $pageIndex',
            ContentFile(:final address) => 'file $address',
          }}\n'
          'filename=${task.filename}\n'
          'status=${task.status.name}\n'
          'saveState=${task.saveState.name}\n'
          'localPath=${task.localPath ?? '<null>'}\n\n'
          '${task.log}',
    ),
  ),
);

/// Opens the page a download came from.
void openDownloadSource(GoRouter router, DownloadSource source) {
  final opened = switch (source) {
    ArtworkSource(:final illustId) => router.push(AppLocations.illust(illustId)),
    NovelSource(:final novelId) => router.push(AppLocations.novel(novelId)),
    PixivisionSource(:final url) => router.push(AppLocations.pixivisionArticle(url)),
    FanboxPostSource(:final postId) => router.push(AppLocations.fanboxPost(postId)),
    FanboxCreatorSource(:final creatorId) => router.push(AppLocations.fanboxCreator(creatorId)),
    StandaloneSource() => null,
  };
  if (opened != null) unawaited(opened);
}

/// The item's name: the source's title, or what identifies it when the title
/// was never known.
String downloadItemTitle(DownloadItem item) {
  final title = item.source.title?.trim() ?? '';
  if (title.isNotEmpty) return title;
  return switch (item.source) {
    ArtworkSource(:final illustId) => t.nativeWindow.workFallback(type: t.nativeWindow.illust, id: '$illustId'),
    NovelSource(:final novelId) => t.nativeWindow.workFallback(type: t.nativeWindow.novel, id: '$novelId'),
    _ => item.tasks.firstOrNull?.filename ?? item.source.id,
  };
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

String downloadBytesLabel(DownloadTaskSnapshot task) {
  final total = task.totalBytes;
  final received = formatByteSize(task.receivedBytes);
  if (total == null || total <= 0 || task.receivedBytes >= total) {
    return received;
  }
  return '$received / ${formatByteSize(total)}';
}

/// The list while the records are read: a day's heading, then cards with
/// their picture.
class _DownloadsSkeleton extends StatelessWidget {
  const _DownloadsSkeleton();

  @override
  Widget build(BuildContext context) {
    final cards = appSkeletonCount(context, shortestExtent: FrostControlSize.regular.height(context));
    return appBones(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostGap.related,
        children: [
          const FrostSectionHeader(title: '2026-01-01'),
          for (var index = 0; index < cards; index++)
            FrostSurface(
              role: FrostSurfaceRole.module,
              edge: FrostSurfaceEdge.none,
              elevated: false,
              borderRadius: BorderRadius.circular(FrostRadius.lg),
              child: FrostTaskRow(
                title: 'A work title',
                status: FrostTaskStatus.completed,
                detail: 'Sample artist · 2026-01-01 12:00',
                thumbnail: Padding(
                  padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
                  child: FrostThumbnail(semanticLabel: '', image: FrostMediaFrame.skeleton(aspectRatio: 1, radius: 0)),
                ),
                actions: [FrostTaskAction(icon: PivIcons.folder, label: 'Open', onPressed: () {})],
              ),
            ),
        ],
      ),
    );
  }
}
