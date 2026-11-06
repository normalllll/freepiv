import 'dart:math' as math;
import 'download_bulk_actions.dart';
import 'download_dock_button.dart';
import 'download_flight.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/features/downloads/logic.dart';
import 'package:freepiv/features/downloads/presentation/download_item_widgets.dart';
import 'package:freepiv/features/downloads/presentation/download_task_widgets.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

class DesktopDownloadDock extends ConsumerStatefulWidget {
  const DesktopDownloadDock({required this.railWidth, this.buttonCenterX, this.bottomOffset = 16, this.taskStream, super.key});

  final double railWidth;

  /// Where the button's centre sits, so it shares the sidebar's icon axis
  /// with the controls above it instead of centring across the sidebar.
  final double? buttonCenterX;
  final double bottomOffset;
  final Stream<List<DownloadTaskSnapshot>>? taskStream;

  @override
  ConsumerState<DesktopDownloadDock> createState() => _DesktopDownloadDockState();
}

class _DesktopDownloadDockState extends ConsumerState<DesktopDownloadDock>
    with SingleTickerProviderStateMixin, DownloadLandingBounce<DesktopDownloadDock>
    implements DownloadFlightTarget {
  static const _panelWidth = 420.0;
  static const _panelHeight = 420.0;

  bool _expanded = false;
  final _buttonFocusNode = FocusNode();
  final _closeFocusNode = FocusNode();
  late final _tasks = widget.taskStream ?? downloadManager.watchTasks();

  /// The badge's slot in this layer, known even before the button appears
  /// for the first task, so a flight can aim for it.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const buttonSize = 52.0;
        final buttonLeft = math.max(0.0, (widget.buttonCenterX ?? widget.railWidth / 2) - buttonSize / 2);
        final geometry = downloadDockButtonGeometry(context);
        final buttonRight = buttonLeft + geometry.footprint.width;
        _badgeSlot = Rect.fromLTWH(buttonRight - 22, constraints.maxHeight - widget.bottomOffset - geometry.footprint.height, 22, geometry.badgeHeight);
        final panelLeft = math.max(widget.railWidth + 12, buttonRight + 12);
        final panelWidth = math.min(_panelWidth, math.max(0.0, constraints.maxWidth - panelLeft - 12));
        final panelHeight = math.min(_panelHeight, math.max(0.0, constraints.maxHeight - widget.bottomOffset - 12));
        final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.0);
        final panelFits = panelWidth >= 220 + 140 * (textScale - 1) && panelHeight >= 220 + 80 * (textScale - 1);
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
                  key: const ValueKey<String>('desktop-download-dismiss-layer'),
                  child: IgnorePointer(
                    ignoring: !_expanded,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closePanel,
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                ),
                Positioned(
                  key: const ValueKey<String>('desktop-download-button'),
                  left: buttonLeft,
                  bottom: widget.bottomOffset,
                  child: landingScale(
                    child: DownloadDockButton(
                      focusNode: _buttonFocusNode,
                      summary: summary,
                      expanded: _expanded,
                      onPressed: () {
                        if (!panelFits) {
                          _closePanel(restoreFocus: false);
                          context.push(AppRoute.downloads.path);
                        } else if (_expanded) {
                          _closePanel();
                        } else {
                          _openPanel();
                        }
                      },
                    ),
                  ),
                ),
                if (panelFits)
                  Positioned(
                    key: const ValueKey<String>('desktop-download-panel'),
                    left: panelLeft,
                    bottom: widget.bottomOffset,
                    width: panelWidth,
                    // Sized by its content up to the available height; it grows
                    // upward from the dock button.
                    child: IgnorePointer(
                      ignoring: !_expanded,
                      child: FocusScope(
                        canRequestFocus: _expanded,
                        descendantsAreFocusable: _expanded,
                        onKeyEvent: _handlePanelKey,
                        // Grows out of the dock button and shrinks back into it.
                        child: FrostSpringReveal(
                          shown: _expanded,
                          child: RepaintBoundary(
                            child: TickerMode(
                              enabled: _expanded,
                              child: _DownloadDockPanel(
                                maxHeight: panelHeight,
                                closeFocusNode: _closeFocusNode,
                                summary: summary,
                                tasks: panelTasks,
                                items: downloadItemsOf(panelTasks, collecting: collecting.values),
                                onClose: _closePanel,
                                onViewAll: () {
                                  _closePanel(restoreFocus: false);
                                  context.push(AppRoute.downloads.path);
                                },
                                onOpenItem: (item) {
                                  _closePanel(restoreFocus: false);
                                  context.push(AppLocations.downloads(item: item.key));
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DownloadDockPanel extends StatelessWidget {
  const _DownloadDockPanel({
    required this.maxHeight,
    required this.summary,
    required this.tasks,
    required this.items,
    required this.onClose,
    required this.onViewAll,
    required this.onOpenItem,
    required this.closeFocusNode,
  });

  final double maxHeight;
  final DownloadSummary summary;
  final List<DownloadTaskSnapshot> tasks;
  final List<DownloadItem> items;
  final VoidCallback onClose;
  final FocusNode closeFocusNode;
  final VoidCallback onViewAll;
  final ValueChanged<DownloadItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    final tokens = FrostThemeTokens.of(context);
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
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: FrostSurface(
        role: FrostSurfaceRole.overlay,
        borderRadius: BorderRadius.circular(FrostRadius.xl + 4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title, progress and actions share one heading row, so the
              // progress bar spans the panel instead of stopping at buttons.
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: DownloadSummaryView(summary: summary, compact: true, trailing: actions),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, endIndent: 8, color: tokens.line.withValues(alpha: .6)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [DownloadItemList(items: items, onOpenItem: onOpenItem, onViewAll: onViewAll)],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(onPressed: onViewAll, icon: const Icon(Icons.open_in_full_outlined), label: Text(context.t.settings.downloads.viewAll)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
