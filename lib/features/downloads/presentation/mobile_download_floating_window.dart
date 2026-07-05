import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/presentation/download_task_widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';

class MobileDownloadFloatingWindow extends StatefulWidget {
  const MobileDownloadFloatingWindow({required this.child, super.key});

  final Widget child;

  @override
  State<MobileDownloadFloatingWindow> createState() => _MobileDownloadFloatingWindowState();
}

class _MobileDownloadFloatingWindowState extends State<MobileDownloadFloatingWindow> {
  static const _collapsedSize = Size.square(56);
  static const _panelMaxWidth = 380.0;
  static const _panelMaxHeight = 430.0;
  static const _edgePadding = 12.0;
  static const _defaultBottomNavigationReserve = 88.0;

  final _sessionStartedAt = DateTime.now();
  final _sessionTaskIds = <String>{};
  Offset? _position;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (isDesktopPlatform) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return StreamBuilder<List<DownloadTaskSnapshot>>(
                stream: downloadManager.watchTasks(),
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? const <DownloadTaskSnapshot>[];
                  _rememberSessionTasks(tasks);

                  final panelTasks = [
                    for (final task in tasks)
                      if (_sessionTaskIds.contains(task.id)) task,
                  ];
                  if (panelTasks.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final summary = DownloadSummary.fromTasks(panelTasks);
                  return Stack(
                    children: [
                      if (_expanded)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _expanded = false),
                            child: const ColoredBox(color: Colors.transparent),
                          ),
                        ),
                      _buildPositionedWindow(context, constraints, summary, panelTasks),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPositionedWindow(BuildContext context, BoxConstraints constraints, DownloadSummary summary, List<DownloadTaskSnapshot> panelTasks) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final windowSize = _windowSizeFor(constraints.biggest);
    final position = _clampedPosition(
      _position ?? _defaultPosition(constraints.biggest, windowSize, viewPadding),
      constraints.biggest,
      windowSize,
      viewPadding,
    );

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: windowSize.width,
      height: windowSize.height,
      child: _DraggableDownloadWindow(
        expanded: _expanded,
        summary: summary,
        tasks: panelTasks,
        onDragDelta: (delta) => _moveBy(delta, constraints.biggest, windowSize, viewPadding),
        onToggleExpanded: () => setState(() => _expanded = !_expanded),
        onClose: () => setState(() => _expanded = false),
        onSync: () => unawaited(_syncDownloads()),
        onTaskTap: _openTask,
      ),
    );
  }

  Size _windowSizeFor(Size availableSize) {
    if (!_expanded) {
      return _collapsedSize;
    }

    final width = math.min(_panelMaxWidth, math.max(0.0, availableSize.width - _edgePadding * 2));
    final height = math.min(_panelMaxHeight, math.max(0.0, availableSize.height - _edgePadding * 2));
    return Size(width, height);
  }

  Offset _defaultPosition(Size availableSize, Size windowSize, EdgeInsets viewPadding) {
    final right = viewPadding.right + _edgePadding;
    final bottom = viewPadding.bottom + _edgePadding + _defaultBottomNavigationReserve;
    return Offset(availableSize.width - windowSize.width - right, availableSize.height - windowSize.height - bottom);
  }

  Offset _clampedPosition(Offset position, Size availableSize, Size windowSize, EdgeInsets viewPadding) {
    final minX = viewPadding.left + _edgePadding;
    final minY = viewPadding.top + _edgePadding;
    final maxX = math.max(minX, availableSize.width - windowSize.width - viewPadding.right - _edgePadding);
    final maxY = math.max(minY, availableSize.height - windowSize.height - viewPadding.bottom - _edgePadding);
    return Offset(position.dx.clamp(minX, maxX).toDouble(), position.dy.clamp(minY, maxY).toDouble());
  }

  void _moveBy(Offset delta, Size availableSize, Size windowSize, EdgeInsets viewPadding) {
    setState(() {
      final current = _position ?? _defaultPosition(availableSize, windowSize, viewPadding);
      _position = _clampedPosition(current + delta, availableSize, windowSize, viewPadding);
    });
  }

  void _rememberSessionTasks(List<DownloadTaskSnapshot> tasks) {
    for (final task in tasks) {
      if (!task.createdAt.isBefore(_sessionStartedAt) || _isActiveOrNeedsAttention(task)) {
        _sessionTaskIds.add(task.id);
      }
    }
  }

  Future<void> _syncDownloads() async {
    try {
      await downloadManager.sync();
    } catch (error) {
      AppToast.errorWithCause(t.settings.downloads.syncFailed, error);
    }
  }

  void _openTask(DownloadTaskSnapshot task) {
    setState(() => _expanded = false);
    unawaited(AppRouter.router.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': task.illustId.toString()}));
  }
}

class _DraggableDownloadWindow extends StatelessWidget {
  const _DraggableDownloadWindow({
    required this.expanded,
    required this.summary,
    required this.tasks,
    required this.onDragDelta,
    required this.onToggleExpanded,
    required this.onClose,
    required this.onSync,
    required this.onTaskTap,
  });

  final bool expanded;
  final DownloadSummary summary;
  final List<DownloadTaskSnapshot> tasks;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onToggleExpanded;
  final VoidCallback onClose;
  final VoidCallback onSync;
  final ValueChanged<DownloadTaskSnapshot> onTaskTap;

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return _DownloadFloatingPanel(summary: summary, tasks: tasks, onDragDelta: onDragDelta, onClose: onClose, onSync: onSync, onTaskTap: onTaskTap);
    }

    return _DownloadFloatingButton(summary: summary, onDragDelta: onDragDelta, onPressed: onToggleExpanded);
  }
}

class _DownloadFloatingButton extends StatelessWidget {
  const _DownloadFloatingButton({required this.summary, required this.onDragDelta, required this.onPressed});

  final DownloadSummary summary;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = summary.queued + summary.running + summary.savePending;
    final failures = summary.failed + summary.saveFailed;
    final badgeLabel = failures > 0
        ? failures.toString()
        : active > 0
        ? active.toString()
        : summary.total.toString();
    final badgeColor = failures > 0 ? colorScheme.error : colorScheme.primary;

    return GestureDetector(
      onPanUpdate: (details) => onDragDelta(details.delta),
      child: Material(
        color: colorScheme.primaryContainer,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.22),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Icon(Icons.downloading_outlined, color: colorScheme.onPrimaryContainer)),
              PositionedDirectional(
                end: -1,
                top: -1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          badgeLabel,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadFloatingPanel extends StatelessWidget {
  const _DownloadFloatingPanel({
    required this.summary,
    required this.tasks,
    required this.onDragDelta,
    required this.onClose,
    required this.onSync,
    required this.onTaskTap,
  });

  final DownloadSummary summary;
  final List<DownloadTaskSnapshot> tasks;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onClose;
  final VoidCallback onSync;
  final ValueChanged<DownloadTaskSnapshot> onTaskTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 180 || constraints.maxHeight < 160) {
          return _DownloadFloatingPanelFallback(summary: summary, onDragDelta: onDragDelta, onClose: onClose);
        }

        final colorScheme = Theme.of(context).colorScheme;
        return Material(
          elevation: 14,
          color: colorScheme.surface,
          shadowColor: Colors.black.withValues(alpha: 0.24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DownloadFloatingPanelHeader(summary: summary, onDragDelta: onDragDelta, onSync: onSync, onClose: onClose),
                const SizedBox(height: 8),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: DownloadTaskList(tasks: tasks, compact: true, showTooltips: false, onTaskTap: onTaskTap),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DownloadFloatingPanelFallback extends StatelessWidget {
  const _DownloadFloatingPanelFallback({required this.summary, required this.onDragDelta, required this.onClose});

  final DownloadSummary summary;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = summary.queued + summary.running + summary.savePending;
    final failures = summary.failed + summary.saveFailed;
    final badgeLabel = failures > 0
        ? failures.toString()
        : active > 0
        ? active.toString()
        : summary.total.toString();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => onDragDelta(details.delta),
      onTap: onClose,
      child: Material(
        color: colorScheme.primaryContainer,
        shape: const CircleBorder(),
        elevation: 6,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: Icon(Icons.downloading_outlined, color: colorScheme.onPrimaryContainer)),
            PositionedDirectional(
              end: -1,
              top: -1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: failures > 0 ? colorScheme.error : colorScheme.primary, shape: BoxShape.circle),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        badgeLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadFloatingPanelHeader extends StatelessWidget {
  const _DownloadFloatingPanelHeader({required this.summary, required this.onDragDelta, required this.onSync, required this.onClose});

  final DownloadSummary summary;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onSync;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.sync_outlined), onPressed: onSync),
            IconButton(icon: const Icon(Icons.close_outlined), onPressed: onClose),
          ],
        );

        if (constraints.maxWidth < 240) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) => onDragDelta(details.delta),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator_outlined, color: colorScheme.onSurfaceVariant),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FittedBox(fit: BoxFit.scaleDown, child: actions),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DownloadSummaryView(summary: summary, compact: true),
            ],
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) => onDragDelta(details.delta),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.drag_indicator_outlined, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: DownloadSummaryView(summary: summary, compact: true)),
              Padding(padding: const EdgeInsetsDirectional.only(start: 12, bottom: 28), child: actions),
            ],
          ),
        );
      },
    );
  }
}

bool _isActiveOrNeedsAttention(DownloadTaskSnapshot task) {
  return task.status == DownloadStatus.queued ||
      task.status == DownloadStatus.running ||
      task.status == DownloadStatus.failed ||
      task.saveState == SaveState.pending ||
      task.saveState == SaveState.saving ||
      task.saveState == SaveState.failed;
}
