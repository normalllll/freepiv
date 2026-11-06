import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/logic.dart';
import 'package:freepiv/features/downloads/presentation/download_task_widgets.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/fanbox/widgets.dart';
import 'package:freepiv/features/pixivision/article_images.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

/// Opens the page [source] was downloaded from; a file saved before sources
/// were recorded has none.
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

bool _hasPage(DownloadSource source) => source is! StandaloneSource;

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

/// What kind of source the item is, and who made it where that is known.
/// The [compact] label names the kind alone, or the author of a work.
String _sourceLabel(DownloadSource source, {required bool compact}) {
  final author = source.subtitle?.trim() ?? '';
  final kind = switch (source) {
    ArtworkSource() => null,
    NovelSource() => t.nativeWindow.novel,
    PixivisionSource() => 'pixivision',
    FanboxSource() => 'FANBOX',
    StandaloneSource() => null,
  };
  if (compact) return kind ?? author;
  return [?kind, if (author.isNotEmpty) author].join(' · ');
}

/// A source's picture, fetched the way its source needs: FANBOX through its
/// session, Pixivision with its referrer, the rest as Pixiv images.
class DownloadSourceThumbnail extends StatelessWidget {
  const DownloadSourceThumbnail({required this.source, required this.url, required this.size, super.key});

  final DownloadSource source;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = this.url;
    final placeholder = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(switch (source) {
        ArtworkSource() => Icons.image_outlined,
        NovelSource() => Icons.menu_book_outlined,
        PixivisionSource() => Icons.article_outlined,
        FanboxPostSource() => Icons.collections_outlined,
        FanboxCreatorSource() => Icons.person_outline,
        StandaloneSource() => Icons.insert_drive_file_outlined,
      }, color: colorScheme.onSurfaceVariant),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(FrostRadius.lg),
      child: SizedBox.square(
        dimension: size,
        child: url == null || url.isEmpty
            ? placeholder
            : switch (source) {
                FanboxSource() => FanboxImageView(url, height: size),
                PixivisionSource() => PixivImage(url: url, headers: pixivisionImageHeaders),
                _ => PixivImage(url: url),
              },
      ),
    );
  }
}

/// One item: its picture, name, source, progress and a single action. The
/// floating panel lists these [compact]; the downloads page uses the full
/// size as the head of an expandable item, with [trailing] after the action.
class DownloadItemTile extends ConsumerWidget {
  const DownloadItemTile({required this.item, this.compact = false, this.showTooltips = true, this.trailing, super.key});

  final DownloadItem item;
  final bool compact;
  final bool showTooltips;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tokens = FrostThemeTokens.of(context);
    final progress = item.progress;
    final sourceLabel = _sourceLabel(item.source, compact: compact);
    final onlyTask = item.onlyTask;
    final metadataStyle = textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 8 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DownloadSourceThumbnail(source: item.source, url: item.source.thumbnailUrl ?? onlyTask?.thumbnailUrl, size: compact ? 56 : 60),
          SizedBox(width: compact ? 9 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        downloadItemTitle(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (compact ? textTheme.labelLarge : textTheme.titleSmall)?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(width: 8),
                      Text('${(progress * 100).round()}%', style: textTheme.labelMedium?.copyWith(color: tokens.textPrimary)),
                    ],
                  ],
                ),
                if (!compact && sourceLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(sourceLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: metadataStyle),
                ],
                SizedBox(height: compact ? 4 : 6),
                DownloadProgressIndicator(value: progress, minHeight: compact ? 3 : 5),
                SizedBox(height: compact ? 4 : 6),
                // Status first, then what the source is (in the panel) and the
                // count or size, which is what changes. A collecting creator
                // says only that; files downloading need no word for it in
                // the panel, where the bar already shows it.
                Row(
                  children: [
                    if (onlyTask != null && !item.collecting) ...[
                      DownloadTaskStatusLabel(task: onlyTask, compact: compact),
                      const SizedBox(width: 8),
                    ] else if (!(compact && item.state == DownloadItemState.active)) ...[
                      Text(_itemStatusLabel(item), style: textTheme.labelMedium?.copyWith(color: _itemStatusColor(context, item))),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: [if (compact && sourceLabel.isNotEmpty && !item.collecting) sourceLabel, ?_itemCountLabel(item)].join(' · ')),
                            if (item.failed > 0 && onlyTask == null)
                              TextSpan(
                                text: ' · ${t.settings.downloads.filesFailed(count: item.failed)}',
                                style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: metadataStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 4 : 8),
          _DownloadItemAction(item: item, showTooltips: showTooltips),
          ?trailing,
        ],
      ),
    );
  }
}

String _itemStatusLabel(DownloadItem item) {
  final labels = t.settings.downloads;
  return switch (item.state) {
    DownloadItemState.active => labels.running,
    DownloadItemState.collecting => labels.collectingPosts(count: item.collectedPosts ?? 0),
    DownloadItemState.failed => labels.failed,
    DownloadItemState.cancelled => labels.cancelled,
    DownloadItemState.completed => labels.saved,
  };
}

Color _itemStatusColor(BuildContext context, DownloadItem item) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (item.state) {
    DownloadItemState.failed => colorScheme.error,
    DownloadItemState.active || DownloadItemState.collecting || DownloadItemState.completed => FrostThemeTokens.of(context).textPrimary,
    DownloadItemState.cancelled => colorScheme.onSurfaceVariant,
  };
}

/// "3 / 7 files" for an item of several files, the size for one file.
String? _itemCountLabel(DownloadItem item) {
  if (item.onlyTask case final task? when !item.collecting) return downloadBytesLabel(task);
  if (item.tasks.isEmpty) return null;
  return t.settings.downloads.filesProgress(done: item.completed, total: item.total);
}

/// The item's one action: stop it while it runs or collects, retry it when
/// something failed or was cancelled, clear it once everything is saved.
class _DownloadItemAction extends ConsumerWidget {
  const _DownloadItemAction({required this.item, required this.showTooltips});

  final DownloadItem item;
  final bool showTooltips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = t.settings.downloads;
    final action = switch (item.state) {
      DownloadItemState.active || DownloadItemState.collecting => DownloadTaskAction(
        key: const ValueKey<String>('cancel'),
        tooltip: showTooltips ? labels.cancel : null,
        icon: const Icon(Icons.close_rounded),
        onPressed: () {
          if (item.source case FanboxCreatorSource(:final creatorId)) ref.read(fanboxDownloadsProvider.notifier).stopCollecting(creatorId);
          unawaited(_run(() => cancelDownloadItem(item)));
        },
      ),
      DownloadItemState.failed || DownloadItemState.cancelled => DownloadTaskAction(
        key: const ValueKey<String>('retry'),
        tooltip: showTooltips ? t.common.retry : null,
        icon: const Icon(Icons.refresh_outlined),
        onPressed: () => unawaited(_run(() => retryDownloadItem(item))),
      ),
      DownloadItemState.completed => DownloadTaskAction(
        key: const ValueKey<String>('clear'),
        tooltip: showTooltips ? labels.clearItem : null,
        icon: const Icon(Icons.playlist_remove_outlined),
        onPressed: () => unawaited(_run(() => deleteDownloadItem(item))),
      ),
    };
    return SizedBox.square(
      dimension: FrostDensity.of(context).targetHeight,
      child: AnimatedSwitcher(duration: FrostMotion.duration(context, FrostMotion.hover), child: action),
    );
  }
}

Future<void> _run(Future<void> Function() action) async {
  try {
    await action();
  } catch (error) {
    toastErrorWithCause(t.settings.downloads.actionFailed, error);
  }
}

/// The floating panel's items: those needing attention first, at most
/// [maxItems], then a way to the rest on the downloads page. A tap opens the
/// item there.
class DownloadItemList extends StatelessWidget {
  const DownloadItemList({required this.items, required this.onOpenItem, required this.onViewAll, this.maxItems = 4, super.key});

  final List<DownloadItem> items;
  final ValueChanged<DownloadItem> onOpenItem;
  final VoidCallback onViewAll;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const DownloadEmptyState(compact: true);
    final ordered = panelOrder(items);
    final shown = ordered.take(maxItems).toList(growable: false);
    final hidden = ordered.length - shown.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, item) in shown.indexed) ...[
          if (index > 0) const Divider(height: 1),
          FrostClickSurface(
            key: ValueKey<String>(item.key),
            onTap: () => onOpenItem(item),
            child: DownloadItemTile(item: item, compact: true, showTooltips: false),
          ),
        ],
        if (hidden > 0)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.chevron_right_rounded),
              label: Text(t.settings.downloads.moreItems(count: hidden)),
            ),
          ),
      ],
    );
  }
}

/// An item on the downloads page: its head, which opens and closes its
/// files, and a menu for the item as a whole.
class DownloadItemCard extends StatelessWidget {
  const DownloadItemCard({required this.item, required this.expanded, required this.onToggle, super.key});

  final DownloadItem item;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final labels = t.settings.downloads;
    final savedPath = item.tasks.map((task) => task.localPath).nonNulls.where((path) => path.isNotEmpty && !path.startsWith('content:')).firstOrNull;
    final menu = FrostMenuAnchor(
      entries: [
        if (_hasPage(item.source))
          FrostMenuAction(
            labels.openSource,
            onSelected: () => openDownloadSource(GoRouter.of(context), item.source),
            leading: FrostGlyph.icon(const FrostIconData.glyph(Icons.open_in_new_rounded)),
          ),
        if (isDesktopPlatform && savedPath != null)
          FrostMenuAction(
            labels.openFolder,
            onSelected: () => unawaited(_run(() => launchUrl(Uri.file(p.dirname(savedPath))))),
            leading: FrostGlyph.icon(const FrostIconData.glyph(Icons.folder_open_outlined)),
          ),
        if (item.tasks.isNotEmpty)
          FrostMenuAction(
            labels.deleteItem,
            onSelected: () => unawaited(_run(() => deleteDownloadItem(item))),
            leading: FrostGlyph.icon(const FrostIconData.glyph(Icons.delete_outline)),
          ),
      ],
      builder: (context, focusNode, toggle) => IconButton(
        focusNode: focusNode,
        tooltip: MaterialLocalizations.of(context).showMenuTooltip,
        onPressed: toggle,
        icon: const Icon(Icons.more_horiz),
        constraints: BoxConstraints.tightFor(width: FrostDensity.of(context).targetHeight, height: FrostDensity.of(context).targetHeight),
        padding: EdgeInsets.zero,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: expanded,
          hint: expanded ? labels.collapseItem : labels.expandItem,
          child: FrostClickSurface(
            onTap: item.tasks.isEmpty ? null : onToggle,
            child: DownloadItemTile(item: item, trailing: menu),
          ),
        ),
        AnimatedSize(
          duration: FrostMotion.duration(context, FrostMotion.expand),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: expanded && item.tasks.isNotEmpty
              ? Padding(
                  // Files sit under the item's text, past its picture.
                  padding: const EdgeInsetsDirectional.only(start: 80, bottom: 8),
                  child: DownloadItemFiles(item: item),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// An item's files. One file shows in full; several are grouped by status
/// (failed and downloading always shown, waiting files a few at a time,
/// saved ones folded), and a creator's by post, each post opening to its
/// files.
class DownloadItemFiles extends StatefulWidget {
  const DownloadItemFiles({required this.item, super.key});

  final DownloadItem item;

  @override
  State<DownloadItemFiles> createState() => _DownloadItemFilesState();
}

class _DownloadItemFilesState extends State<DownloadItemFiles> {
  final _openParts = <String>{};

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item.onlyTask case final task?) return DownloadFileRow(task: task, detailed: true);
    final parts = item.parts;
    if (parts.length == 1 && parts.single.$1 == null) return _StatusGroups(tasks: item.tasks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (part, tasks) in parts) ...[
          _PartHeader(
            title: part?.title ?? '',
            tasks: tasks,
            open: _openParts.contains(part?.id ?? ''),
            onToggle: () => setState(() {
              final id = part?.id ?? '';
              if (!_openParts.remove(id)) _openParts.add(id);
            }),
          ),
          AnimatedSize(
            duration: FrostMotion.duration(context, FrostMotion.expand),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _openParts.contains(part?.id ?? '')
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: _StatusGroups(tasks: tasks),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ],
    );
  }
}

/// A post of a creator: its title and how many of its files are saved.
class _PartHeader extends StatelessWidget {
  const _PartHeader({required this.title, required this.tasks, required this.open, required this.onToggle});

  final String title;
  final List<DownloadTaskSnapshot> tasks;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final saved = tasks.where((task) => task.isCompleted).length;
    final failed = tasks.where((task) => task.needsRetry).length;
    return FrostClickSurface(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Icon(
              failed > 0
                  ? Icons.error_outline
                  : saved == tasks.length
                  ? Icons.check_circle_outline
                  : Icons.downloading_outlined,
              size: 18,
              color: failed > 0 ? colorScheme.error : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              t.settings.downloads.filesProgress(done: saved, total: tasks.length),
              style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            AnimatedRotation(
              turns: open ? .5 : 0,
              duration: FrostMotion.duration(context, FrostMotion.expand),
              child: Icon(Icons.expand_more_rounded, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Files by status: failed and downloading in full, a few waiting ones with
/// the rest behind "show all", saved and cancelled ones folded.
class _StatusGroups extends StatefulWidget {
  const _StatusGroups({required this.tasks});

  final List<DownloadTaskSnapshot> tasks;

  @override
  State<_StatusGroups> createState() => _StatusGroupsState();
}

class _StatusGroupsState extends State<_StatusGroups> {
  static const _waitingShown = 3;
  bool _allWaiting = false;
  bool _savedOpen = false;

  @override
  Widget build(BuildContext context) {
    final labels = t.settings.downloads;
    final tasks = widget.tasks;
    final failed = tasks.where((task) => task.needsRetry).toList(growable: false);
    final waiting = tasks.where((task) => task.status == DownloadStatus.queued).toList(growable: false);
    final running = tasks.where((task) => isActiveDownloadTask(task) && task.status != DownloadStatus.queued).toList(growable: false);
    final done = tasks.where((task) => !task.needsRetry && !isActiveDownloadTask(task)).toList(growable: false);
    final shownWaiting = _allWaiting ? waiting : waiting.take(_waitingShown).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failed.isNotEmpty) ...[_GroupLabel(label: labels.failed, count: failed.length, error: true), for (final task in failed) _file(task)],
        if (running.isNotEmpty) ...[_GroupLabel(label: labels.running, count: running.length), for (final task in running) _file(task)],
        if (waiting.isNotEmpty) ...[
          _GroupLabel(label: labels.queued, count: waiting.length),
          for (final task in shownWaiting) _file(task),
          if (shownWaiting.length < waiting.length)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() => _allWaiting = true),
                child: Text(labels.showAll(count: waiting.length)),
              ),
            ),
        ],
        if (done.isNotEmpty) ...[
          _GroupLabel(label: labels.completed, count: done.length, open: _savedOpen, onToggle: () => setState(() => _savedOpen = !_savedOpen)),
          AnimatedSize(
            duration: FrostMotion.duration(context, FrostMotion.expand),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _savedOpen
                ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final task in done) _file(task)])
                : const SizedBox(width: double.infinity),
          ),
        ],
      ],
    );
  }

  Widget _file(DownloadTaskSnapshot task) => DownloadFileRow(key: ValueKey<String>(task.id), task: task);
}

/// A status group's heading; the saved group opens and closes from it.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label, required this.count, this.error = false, this.open, this.onToggle});

  final String label;
  final int count;
  final bool error;
  final bool? open;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: error ? colorScheme.error : colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600);
    final open = this.open;
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
      child: Row(
        children: [
          Text('$label · $count', style: style),
          if (open != null)
            AnimatedRotation(
              turns: open ? .5 : 0,
              duration: FrostMotion.duration(context, FrostMotion.expand),
              child: Icon(Icons.expand_more_rounded, size: 18, color: style?.color),
            ),
        ],
      ),
    );
    final onToggle = this.onToggle;
    return onToggle == null ? row : FrostClickSurface(onTap: onToggle, child: row);
  }
}
