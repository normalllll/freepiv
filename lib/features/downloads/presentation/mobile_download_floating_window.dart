import 'download_bulk_actions.dart';
import 'download_dock_button.dart';
import 'download_flight.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/logic.dart';
import 'package:freepiv/features/downloads/presentation/download_item_widgets.dart';
import 'package:freepiv/features/downloads/presentation/download_task_widgets.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';

class MobileDownloadFloatingWindow extends ConsumerStatefulWidget {
  const MobileDownloadFloatingWindow({required this.child, this.taskStream, super.key});

  final Widget child;
  final Stream<List<DownloadTaskSnapshot>>? taskStream;

  @override
  ConsumerState<MobileDownloadFloatingWindow> createState() => _MobileDownloadFloatingWindowState();
}

class _MobileDownloadFloatingWindowState extends ConsumerState<MobileDownloadFloatingWindow>
    with SingleTickerProviderStateMixin, DownloadLandingBounce<MobileDownloadFloatingWindow>
    implements DownloadFlightTarget {
  static const _buttonSize = 56.0;
  static const _panelMaxWidth = 380.0;
  static const _panelMaxHeight = 430.0;
  static const _edgePadding = 12.0;
  static const _defaultBottomNavigationReserve = 88.0;

  Offset? _position;
  bool _expanded = false;
  final _buttonFocusNode = FocusNode();
  final _closeFocusNode = FocusNode();
  late final _tasks = widget.taskStream ?? downloadManager.watchTasks();

  /// The badge's slot in this layer while the phone layout shows the
  /// floating button, known even before the first task makes it appear.
  Rect? _badgeSlot;

  @override
  void initState() {
    super.initState();
    DownloadFlight.attach(this);
  }

  @override
  Rect? get badgeRect {
    final slot = _badgeSlot;
    final box = mounted ? context.findRenderObject() : null;
    if (slot == null || box is! RenderBox || !box.hasSize) return null;
    return slot.shift(box.localToGlobal(Offset.zero));
  }

  @override
  void land() => bounce();

  @override
  void dispose() {
    DownloadFlight.detach(this);
    _buttonFocusNode.dispose();
    _closeFocusNode.dispose();
    super.dispose();
  }

  void _openPanel() {
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _expanded) _closeFocusNode.requestFocus();
    });
  }

  void _closePanel({bool restoreFocus = true}) {
    if (!_expanded) return;
    setState(() => _expanded = false);
    if (restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_expanded) _buttonFocusNode.requestFocus();
      });
    }
  }

  KeyEventResult _handlePanelKey(FocusNode node, KeyEvent event) {
    if (_expanded && event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      _closePanel();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final collecting = ref.watch(fanboxDownloadsProvider);
    final usesHorizontalLayout = FrostAutoScaffold.usesHorizontalLayoutOf(context);
    if (usesHorizontalLayout) {
      _badgeSlot = null;
      return widget.child;
    }

    return Stack(
      children: [
        ExcludeFocus(excluding: _expanded, child: widget.child),
        Positioned.fill(
          // This layer sits above the app's Navigator, so its tooltips and
          // menus get an overlay of their own here.
          child: Overlay.wrap(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewPadding = MediaQuery.viewPaddingOf(context);
                final windowSize = _windowSizeFor(constraints.biggest);
                final position = _clampedPosition(
                  _position ?? _defaultPosition(constraints.biggest, windowSize, viewPadding),
                  constraints.biggest,
                  windowSize,
                  viewPadding,
                );
                final geometry = downloadDockButtonGeometry(context, size: _buttonSize);
                _badgeSlot = Rect.fromLTWH(
                  position.dx + windowSize.width - 22,
                  position.dy + windowSize.height - geometry.footprint.height,
                  22,
                  geometry.badgeHeight,
                );
                return StreamBuilder<List<DownloadTaskSnapshot>>(
                  stream: _tasks,
                  builder: (context, snapshot) {
                    final tasks = snapshot.data ?? const <DownloadTaskSnapshot>[];

                    final panelTasks = tasks;
                    if (panelTasks.isEmpty && collecting.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final summary = DownloadSummary.fromTasks(panelTasks);
                    return Stack(
                      children: [
                        Positioned.fill(
                          key: const ValueKey<String>('mobile-download-dismiss-layer'),
                          child: IgnorePointer(
                            ignoring: !_expanded,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _closePanel,
                              child: const ColoredBox(color: Colors.transparent),
                            ),
                          ),
                        ),
                        _buildPositionedWindow(context, constraints, summary, panelTasks, downloadItemsOf(panelTasks, collecting: collecting.values)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionedWindow(
    BuildContext context,
    BoxConstraints constraints,
    DownloadSummary summary,
    List<DownloadTaskSnapshot> panelTasks,
    List<DownloadItem> items,
  ) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final windowSize = _windowSizeFor(constraints.biggest);
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.0);
    final panelFits = windowSize.width >= 220 + 120 * (textScale - 1) && windowSize.height >= 220 + 100 * (textScale - 1);
    final position = _clampedPosition(
      _position ?? _defaultPosition(constraints.biggest, windowSize, viewPadding),
      constraints.biggest,
      windowSize,
      viewPadding,
    );

    return Positioned(
      key: const ValueKey<String>('mobile-download-window'),
      left: position.dx,
      top: position.dy,
      width: windowSize.width,
      height: windowSize.height,
      child: _DraggableDownloadWindow(
        expanded: _expanded,
        buttonFocusNode: _buttonFocusNode,
        closeFocusNode: _closeFocusNode,
        onPanelKeyEvent: _handlePanelKey,
        summary: summary,
        tasks: panelTasks,
        items: items,
        onDragDelta: (delta) => _moveBy(delta, constraints.biggest, windowSize, viewPadding),
        onToggleExpanded: () {
          if (!panelFits) {
            _closePanel(restoreFocus: false);
            unawaited(AppRouter.router.push(AppRoute.downloads.path));
          } else if (_expanded) {
            _closePanel();
          } else {
            _openPanel();
          }
        },
        onClose: _closePanel,
        onViewAll: () {
          _closePanel(restoreFocus: false);
          unawaited(AppRouter.router.push(AppRoute.downloads.path));
        },
        onOpenItem: _openItem,
        wrapButton: landingScale,
      ),
    );
  }

  Size _windowSizeFor(Size availableSize) {
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

  void _openItem(DownloadItem item) {
    _closePanel(restoreFocus: false);
    unawaited(AppRouter.router.push(AppLocations.downloads(item: item.key)));
  }
}

class _DraggableDownloadWindow extends StatelessWidget {
  const _DraggableDownloadWindow({
    required this.expanded,
    required this.buttonFocusNode,
    required this.closeFocusNode,
    required this.onPanelKeyEvent,
    required this.summary,
    required this.tasks,
    required this.items,
    required this.onDragDelta,
    required this.onToggleExpanded,
    required this.onClose,
    required this.onViewAll,
    required this.onOpenItem,
    required this.wrapButton,
  });

  final bool expanded;
  final FocusNode buttonFocusNode;
  final FocusNode closeFocusNode;
  final FocusOnKeyEventCallback onPanelKeyEvent;
  final DownloadSummary summary;
  final List<DownloadTaskSnapshot> tasks;
  final List<DownloadItem> items;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onToggleExpanded;
  final VoidCallback onClose;
  final VoidCallback onViewAll;
  final ValueChanged<DownloadItem> onOpenItem;

  /// Wraps the collapsed button, for the landing bounce of a download flight.
  final Widget Function({required Widget child}) wrapButton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !expanded,
            child: FocusScope(
              canRequestFocus: expanded,
              descendantsAreFocusable: expanded,
              onKeyEvent: onPanelKeyEvent,
              // The panel grows out of the button's corner while the button
              // shrinks away into it, and the reverse on closing.
              child: FrostSpringReveal(
                shown: expanded,
                child: RepaintBoundary(
                  child: TickerMode(
                    enabled: expanded,
                    child: _DownloadFloatingPanel(
                      closeFocusNode: closeFocusNode,
                      summary: summary,
                      tasks: tasks,
                      items: items,
                      onDragDelta: onDragDelta,
                      onClose: onClose,
                      onViewAll: onViewAll,
                      onOpenItem: onOpenItem,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          end: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: expanded,
            child: ExcludeFocus(
              excluding: expanded,
              child: FrostSpringReveal(
                shown: !expanded,
                child: wrapButton(
                  child: DownloadDockButton(
                    focusNode: buttonFocusNode,
                    summary: summary,
                    expanded: expanded,
                    size: _MobileDownloadFloatingWindowState._buttonSize,
                    onDragDelta: onDragDelta,
                    onPressed: onToggleExpanded,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DownloadFloatingPanel extends StatelessWidget {
  const _DownloadFloatingPanel({
    required this.closeFocusNode,
    required this.summary,
    required this.tasks,
    required this.items,
    required this.onDragDelta,
    required this.onClose,
    required this.onViewAll,
    required this.onOpenItem,
  });

  final DownloadSummary summary;
  final FocusNode closeFocusNode;
  final List<DownloadTaskSnapshot> tasks;
  final List<DownloadItem> items;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onClose;
  final VoidCallback onViewAll;
  final ValueChanged<DownloadItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FrostSurface(
          role: FrostSurfaceRole.overlay,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DownloadFloatingPanelHeader(summary: summary, tasks: tasks, onDragDelta: onDragDelta, onClose: onClose, closeFocusNode: closeFocusNode),
                const SizedBox(height: 8),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [DownloadItemList(items: items, onOpenItem: onOpenItem, onViewAll: onViewAll)],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: onViewAll,
                    icon: const Icon(Icons.open_in_full_outlined),
                    label: Text(context.t.settings.downloads.viewAll),
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

class _DownloadFloatingPanelHeader extends StatelessWidget {
  const _DownloadFloatingPanelHeader({
    required this.summary,
    required this.tasks,
    required this.onDragDelta,
    required this.onClose,
    required this.closeFocusNode,
  });

  final DownloadSummary summary;
  final List<DownloadTaskSnapshot> tasks;
  final ValueChanged<Offset> onDragDelta;

  final VoidCallback onClose;
  final FocusNode closeFocusNode;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DownloadBulkActions(compact: true, tasks: tasks),
            IconButton(
              focusNode: closeFocusNode,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: const Icon(Icons.close_outlined),
              onPressed: onClose,
            ),
          ],
        );

        if (constraints.maxWidth < 360) {
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
