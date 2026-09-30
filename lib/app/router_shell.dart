import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:freepiv/shared/widgets/app_click_surface.dart';
import 'package:freepiv/app/theme/app_feedback.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/shared/layout/content_viewport.dart';
import 'package:freepiv/shared/layout/shell_navigation_scope.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';
import 'package:freepiv/shared/ui/fp_icon.dart';
import 'package:freepiv/shared/ui/spring_builder.dart';
import 'package:freepiv/shared/ui/layout_crossfade.dart';
import 'package:freepiv/features/downloads/presentation/download_floating_panel.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:go_router/go_router.dart';

class RouterShell extends StatefulWidget {
  const RouterShell({required this.child, required this.canPopListenable, required this.onBack, required this.onResetRightNavigator, super.key});

  final Widget child;
  final ValueListenable<bool> canPopListenable;
  final VoidCallback onBack;
  final VoidCallback onResetRightNavigator;

  @override
  State<RouterShell> createState() => _RouterShellState();
}

class _RouterShellState extends State<RouterShell> with SingleTickerProviderStateMixin {
  late final AnimationController _sidebarProgress = AnimationController(vsync: this);
  final FocusNode _moreButtonFocus = FocusNode(debugLabel: 'More navigation');
  bool _expandedTarget = false;
  final ValueNotifier<({AppRoute route, int sequence})> _primaryReselection = ValueNotifier((route: AppRoute.home, sequence: 0));

  void _toggleExpansion() {
    _expandedTarget = !_expandedTarget;
    // One spring drives the width, the content start, the dock and every
    // label, so they stay in step; a toggle mid-way turns back at the
    // current speed instead of restarting.
    AppMotion.springTo(context, _sidebarProgress, _expandedTarget ? 1.0 : 0.0, AppMotion.standard);
  }

  @override
  void dispose() {
    _sidebarProgress.dispose();
    _moreButtonFocus.dispose();
    _primaryReselection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (context, layout, orientation, useHorizontalLayout) {
        final path = GoRouterState.of(context).uri.path;
        final selectedIndex = appDestinationIndexForPath(path);
        final sidebarAvailable = useHorizontalLayout && layout.width >= 1200;
        if (!sidebarAvailable && _expandedTarget) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_expandedTarget) return;
            _expandedTarget = false;
            _sidebarProgress.value = 0;
          });
        }
        final ownsBackControl = useHorizontalLayout;
        final showSidebar = useHorizontalLayout;
        return ValueListenableBuilder<bool>(
          valueListenable: widget.canPopListenable,
          builder: (context, canPop, _) {
            final canGoBack = canPop || _fallbackPath(path) != null;
            void goBack() {
              if (widget.canPopListenable.value) {
                widget.onBack();
              } else if (_fallbackPath(path) case final fallback?) {
                context.go(fallback);
              }
            }

            return ShellNavigationScope(
              ownsBackControl: ownsBackControl,
              canGoBack: canGoBack,
              goBack: goBack,
              primaryReselection: _primaryReselection,
              // Escape is DismissIntent. Menus, dialogs, panels, the search
              // suggestions and the viewers handle it inside their own
              // subtree first; only an unhandled Escape reaches this page-level
              // action, so each press closes exactly one layer.
              child: Actions(
                actions: {DismissIntent: _PageBackAction(canGoBack: () => canGoBack, goBack: goBack)},
                child: LayoutCrossfade(
                  layoutIdentity: useHorizontalLayout,
                  child: Scaffold(
                    // The shell never shrinks for the keyboard: the sidebar, its
                    // download dock and the phone's bottom navigation stay put
                    // (the keyboard covers them). Pages keep avoiding it through
                    // their own Scaffolds, which now see the keyboard inset.
                    resizeToAvoidBottomInset: false,
                    extendBody: !useHorizontalLayout && isMobileNavigationPath(path),
                    body: AnimatedBuilder(
                      animation: _sidebarProgress,
                      builder: (context, _) {
                        final progress = sidebarAvailable ? _sidebarProgress.value : 0.0;
                        final railWidth = lerpDouble(AppMetrics.navigationRailWidth, AppMetrics.navigationExpandedWidth, progress)!;
                        final frame = _SidebarGeometry.frame(context);
                        // Only positioned layers: the Stack must take the body size.
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // The floating sidebar is glass over the ambient
                            // backdrop; pages start beside it so the sidebar never
                            // covers artwork hit targets. The page shares the
                            // sidebar's frame, so the system bars act like the
                            // Windows title bar: backdrop, never page content.
                            // The tree keeps one shape so a fold or resize that
                            // switches layouts keeps page state.
                            Positioned.fill(
                              left: showSidebar ? frame.left + railWidth + _SidebarGeometry.gutter : 0,
                              top: showSidebar ? frame.top : 0,
                              child: MediaQuery.removePadding(
                                context: context,
                                removeLeft: showSidebar,
                                removeTop: showSidebar,
                                child: ContentViewport(
                                  navigationReserve: sidebarAvailable ? AppMetrics.navigationExpandedWidth - railWidth : 0,
                                  child: widget.child,
                                ),
                              ),
                            ),
                            if (showSidebar)
                              Positioned(
                                left: frame.left,
                                top: frame.top,
                                bottom: frame.bottom,
                                width: railWidth,
                                child: _DesktopSidebar(
                                  selectedIndex: selectedIndex,
                                  path: path,
                                  progress: progress,
                                  expandedTarget: _expandedTarget,
                                  canGoBack: canGoBack,
                                  onBack: goBack,
                                  canExpand: sidebarAvailable,
                                  onExpansionToggle: _toggleExpansion,
                                  onDestinationSelected: (index) => _selectIndex(context, index),
                                  onSecondarySelected: (route) => _selectRoute(context, route),
                                  moreButtonFocus: _moreButtonFocus,
                                  translations: context.t,
                                ),
                              ),
                            if (useHorizontalLayout)
                              DesktopDownloadDock(
                                railWidth: showSidebar ? frame.left + railWidth + _SidebarGeometry.margin : 0,
                                buttonCenterX: showSidebar ? frame.left + _DesktopSidebar.iconAxis(progress) : null,
                                bottomOffset: frame.bottom - _SidebarGeometry.margin + _DesktopSidebar.downloadDockBottomOffset,
                              ),
                          ],
                        );
                      },
                    ),
                    bottomNavigationBar: !useHorizontalLayout && isMobileNavigationPath(path)
                        ? _MobileNavBar(
                            selectedIndex: selectedIndex ?? 0,
                            onDestinationSelected: (index) => _selectIndex(context, index),
                            translations: context.t,
                          )
                        : null,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _selectIndex(BuildContext context, int index) {
    final route = appRouteDestinations[index].route;
    if (GoRouterState.of(context).uri.path == route.path && !widget.canPopListenable.value) {
      _primaryReselection.value = (route: route, sequence: _primaryReselection.value.sequence + 1);
      return;
    }
    widget.onResetRightNavigator();
    context.go(route.path);
  }

  void _selectRoute(BuildContext context, AppRoute route) {
    if (GoRouterState.of(context).uri.path == route.path) return;
    context.push(route.path);
  }
}

abstract final class _SidebarGeometry {
  static const margin = 8.0;

  /// Gap between the floating panel and the page's own inset.
  static const gutter = 4.0;

  /// Where the floating sidebar starts from the window's left, top and
  /// bottom edges; the page beside it shares the top edge. System bars and
  /// cutouts lie outside the frame. On Windows the Flutter title bar already
  /// separates the panels from the window edge; elsewhere, where the status
  /// bar has no divider of its own, the panels keep the margin below it too.
  static EdgeInsets frame(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    final topGap = Theme.of(context).platform == TargetPlatform.windows ? 0.0 : margin;
    // System insets are often fractional; whole physical pixels keep the
    // page's pinned glass edges (and joins between them) crisp.
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    double snap(double value) => (value * pixelRatio).roundToDouble() / pixelRatio;
    return EdgeInsets.fromLTRB(snap(safe.left + margin), snap(safe.top + topGap), 0, snap(safe.bottom + margin));
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.path,
    required this.progress,
    required this.expandedTarget,
    required this.canGoBack,
    required this.onBack,
    required this.canExpand,
    required this.onExpansionToggle,
    required this.onDestinationSelected,
    required this.onSecondarySelected,
    required this.moreButtonFocus,
    required this.translations,
  });

  final int? selectedIndex;
  final String path;
  final double progress;
  final bool expandedTarget;
  final bool canGoBack;
  final VoidCallback onBack;
  final bool canExpand;
  final VoidCallback onExpansionToggle;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<AppRoute> onSecondarySelected;
  final FocusNode moreButtonFocus;
  final Translations translations;

  static const downloadDockBottomOffset = 78.0;
  static const _innerPadding = 8.0;

  /// Width of the column the back and expand/collapse buttons are centred in.
  static double _iconColumnWidth(double progress) => lerpDouble(AppMetrics.navigationRailWidth - _innerPadding * 2, 48, progress)!;

  /// Horizontal centre of that column from the sidebar's left edge; the
  /// download dock sits on it so it lines up with the controls above it.
  static double iconAxis(double progress) => _innerPadding + _iconColumnWidth(progress) / 2;

  @override
  Widget build(BuildContext context) {
    return FpSurface(
      role: FpSurfaceRole.chrome,
      borderRadius: BorderRadius.circular(AppMetrics.groupRadius + 4),
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeTop: true,
        removeBottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_innerPadding, 4, _innerPadding, 8),
          child: Column(
            children: [
              SizedBox(
                height: AppMetrics.navigationHeaderHeight,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    // Centred on the rail's icon axis, then on the expanded
                    // row's icon column, like the navigation icons below.
                    width: _iconColumnWidth(progress),
                    child: Center(
                      child: _DesktopSidebarBackButton(canGoBack: canGoBack, onBack: onBack),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _EdgeFadeScrollView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: [
                    for (var index = 0; index < appRouteDestinations.length; index++) ...[
                      if (index > 0) const SizedBox(height: 4),
                      DesktopNavItem(
                        label: appRouteDestinationLabel(translations, appRouteDestinations[index]),
                        fpIcon: appRouteDestinations[index].icon,
                        selected: selectedIndex == index,
                        progress: progress,
                        onTap: () => onDestinationSelected(index),
                      ),
                    ],
                    // Same rhythm as the primary items while collapsed; the
                    // expanded secondary group gets room for its divider.
                    SizedBox(height: lerpDouble(4, 16, progress)),
                    Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        IgnorePointer(
                          ignoring: progress > .25,
                          child: ExcludeFocus(
                            excluding: progress > .25,
                            child: Opacity(
                              opacity: (1 - progress * 4).clamp(0.0, 1.0),
                              child: Builder(
                                builder: (buttonContext) => Focus(
                                  focusNode: moreButtonFocus,
                                  skipTraversal: true,
                                  onKeyEvent: (node, event) {
                                    if (event is! KeyDownEvent ||
                                        (event.logicalKey != LogicalKeyboardKey.enter && event.logicalKey != LogicalKeyboardKey.space)) {
                                      return KeyEventResult.ignored;
                                    }
                                    _showDesktopMore(buttonContext, translations, onSecondarySelected, moreButtonFocus, currentPath: path);
                                    return KeyEventResult.handled;
                                  },
                                  child: DesktopNavItem(
                                    label: translations.navigation.more,
                                    fpIcon: FpIconName.more,
                                    selected: _secondaryRoutes.any((route) => path == route.path || path.startsWith('${route.path}/')),
                                    progress: progress,
                                    onTap: () => _showDesktopMore(buttonContext, translations, onSecondarySelected, moreButtonFocus, currentPath: path),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          ignoring: progress <= .25,
                          child: ExcludeFocus(
                            excluding: progress <= .25,
                            // While collapsed the hidden group takes no
                            // height, so a list that fits never scrolls; it
                            // grows with the sidebar as it expands.
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.topCenter,
                                heightFactor: progress.clamp(0.0, 1.0),
                                child: Opacity(
                                  opacity: ((progress - .25) * 4 / 3).clamp(0.0, 1.0),
                                  child: Column(
                                    children: [
                                      // Secondary destinations get a quiet group
                                      // divider so they do not read as primary.
                                      Divider(height: 1, indent: 12, endIndent: 12, color: FreepivThemeTokens.of(context).line.withValues(alpha: .6)),
                                      const SizedBox(height: 8),
                                      for (final route in _secondaryRoutes) ...[
                                        DesktopNavItem(
                                          label: appRouteNavigationLabel(translations, route),
                                          fpIcon: _secondaryIcon(route),
                                          selected: path == route.path || path.startsWith('${route.path}/'),
                                          progress: progress,
                                          labelOpacity: ((progress - .85) / .15).clamp(0.0, 1.0),
                                          onTap: () => onSecondarySelected(route),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canExpand)
                SizedBox(
                  height: 44,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(
                      width: _iconColumnWidth(progress),
                      child: Center(
                        child: IconButton(
                          tooltip: expandedTarget ? translations.navigation.collapse : translations.navigation.expand,
                          onPressed: onExpansionToggle,
                          icon: Icon(expandedTarget ? Icons.keyboard_double_arrow_left_rounded : Icons.keyboard_double_arrow_right_rounded),
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

/// Short-height windows scroll the navigation list without a scrollbar; the
/// edges fade so clipped items read as more content rather than a cut.
class _EdgeFadeScrollView extends StatefulWidget {
  const _EdgeFadeScrollView({required this.children, this.padding = EdgeInsets.zero});

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  State<_EdgeFadeScrollView> createState() => _EdgeFadeScrollViewState();
}

class _EdgeFadeScrollViewState extends State<_EdgeFadeScrollView> {
  static const _fadeExtent = 20.0;
  bool _fadeTop = false;
  bool _fadeBottom = false;

  bool _update(ScrollMetrics metrics) {
    final top = metrics.extentBefore > 0.5;
    final bottom = metrics.extentAfter > 0.5;
    if (top != _fadeTop || bottom != _fadeBottom) {
      setState(() {
        _fadeTop = top;
        _fadeBottom = bottom;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final list = NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) => _update(notification.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) => _update(notification.metrics),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView(primary: false, padding: widget.padding, children: widget.children),
        ),
      ),
    );
    if (!_fadeTop && !_fadeBottom) return list;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final edge = (_fadeExtent / math.max(1.0, bounds.height)).clamp(0.0, .5);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_fadeTop ? Colors.transparent : Colors.black, Colors.black, Colors.black, _fadeBottom ? Colors.transparent : Colors.black],
          stops: [0, edge, 1 - edge, 1],
        ).createShader(bounds);
      },
      child: list,
    );
  }
}

/// Navigation destination. Collapsed, it is an icon inside an accent pill
/// above a short label; expanded, the pill grows into the full row. One
/// animation progress drives size, positions and the pill so nothing jumps.
class DesktopNavItem extends StatelessWidget {
  const DesktopNavItem({
    required this.label,
    required this.fpIcon,
    required this.selected,
    required this.onTap,
    this.progress = 0,
    this.labelOpacity = 1,
    super.key,
  });

  final String label;
  final FpIconName fpIcon;
  final bool selected;
  final double progress;
  final double labelOpacity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final theme = Theme.of(context);
    final amount = progress.clamp(0.0, 1.0);
    final smallStyle = theme.textTheme.labelSmall;
    final largeStyle = theme.textTheme.labelLarge;
    final collapsedLabel = TextPainter(
      text: TextSpan(text: label, style: smallStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: 60);
    final expandedLabel = TextPainter(
      text: TextSpan(text: label, style: largeStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: 108);
    final collapsedHeight = math.max(62.0, 4 + 32 + 4 + collapsedLabel.height + 8);
    final expandedHeight = math.max(44.0, expandedLabel.height + 16);
    final collapsedTextHeight = collapsedLabel.height;
    final expandedTextHeight = expandedLabel.height;
    collapsedLabel.dispose();
    expandedLabel.dispose();
    final height = lerpDouble(collapsedHeight, expandedHeight, amount)!;
    final ink = selected ? tokens.selectionInk : tokens.textSecondary;
    final labelStyle = TextStyle.lerp(smallStyle, largeStyle, amount)?.copyWith(
      color: selected ? Color.lerp(tokens.textPrimary, tokens.selectionInk, amount) : tokens.textSecondary,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    );

    // Labels are always visible, so the item carries no duplicate tooltip.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AppClickSurface(
        feedback: AppClickFeedback.artwork,
        borderRadius: BorderRadius.circular(AppMetrics.controlRadius),
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Hover is read from the surface itself, so no second copy of it
            // can outlive the pointer that set it.
            final hovered = AppClickSurface.hoveredOf(context);
            final pillColor = selected ? tokens.selectionFill : appButtonStateLayer(tokens, {if (hovered) WidgetState.hovered}, AppFeedbackRole.quiet);
            final width = constraints.maxWidth;
            final collapsedPill = Rect.fromLTWH((width - 52) / 2, 4, 52, 32);
            final pill = Rect.lerp(collapsedPill, Offset.zero & Size(width, height), amount)!;
            return SizedBox(
              width: double.infinity,
              height: height,
              child: Stack(
                children: [
                  Positioned.fromRect(
                    rect: pill,
                    child: AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.hover),
                      curve: AppMotion.hoverCurve,
                      decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(lerpDouble(16, AppMetrics.controlRadius, amount)!)),
                    ),
                  ),
                  Positioned(
                    left: lerpDouble(width / 2 - 11, 13, amount)!,
                    top: lerpDouble(9, (height - 22) / 2, amount)!,
                    child: FpIcon(fpIcon, size: 22, color: ink),
                  ),
                  Positioned(
                    left: lerpDouble(0, 46, amount)!,
                    top: lerpDouble(40, (height - expandedTextHeight) / 2, amount)!,
                    width: lerpDouble(width, math.max(0, width - 52), amount)!,
                    height: lerpDouble(collapsedTextHeight, expandedTextHeight, amount),
                    child: Opacity(
                      opacity: labelOpacity,
                      child: Align(
                        alignment: Alignment.lerp(Alignment.topCenter, Alignment.centerLeft, amount)!,
                        child: Text(
                          label,
                          maxLines: amount >= .999 ? null : 1,
                          overflow: amount >= .999 ? TextOverflow.visible : TextOverflow.ellipsis,
                          textAlign: amount < .5 ? TextAlign.center : TextAlign.start,
                          style: labelStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MobileNavBar extends StatelessWidget {
  const _MobileNavBar({required this.selectedIndex, required this.onDestinationSelected, required this.translations});

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Translations translations;

  @override
  Widget build(BuildContext context) {
    return FpSurface(
      role: FpSurfaceRole.chrome,
      borderRadius: BorderRadius.zero,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labels = [for (final destination in appRouteDestinations) appRouteDestinationLabel(translations, destination)];
            final style = (Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 12)).copyWith(height: 1, fontWeight: FontWeight.w700);
            final labelWidth = math.max(1.0, constraints.maxWidth / appRouteDestinations.length - 8);
            final labelHeight = labels
                .map((label) {
                  final painter = TextPainter(
                    text: TextSpan(text: label, style: style),
                    textDirection: Directionality.of(context),
                    textAlign: TextAlign.center,
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout(maxWidth: labelWidth);
                  final height = painter.height;
                  painter.dispose();
                  return height;
                })
                .reduce(math.max);
            return SizedBox(
              height: math.max(64, 8 + 30 + 4 + labelHeight + 8),
              child: Row(
                children: [
                  for (var index = 0; index < appRouteDestinations.length; index++)
                    Expanded(
                      child: _MobileNavItem(
                        label: labels[index],
                        labelHeight: labelHeight,
                        icon: appRouteDestinations[index].icon,
                        selected: selectedIndex == index,
                        onTap: () => onDestinationSelected(index),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({required this.label, required this.labelHeight, required this.icon, required this.selected, required this.onTap});

  final String label;
  final double labelHeight;
  final FpIconName icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final duration = AppMotion.duration(context, AppMotion.hover);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AppClickSurface(
        feedback: AppClickFeedback.artwork,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpringBuilder(
                value: selected ? 56 : 40,
                spring: AppMotion.snappy,
                builder: (context, width, child) => SizedBox(width: width, height: 30, child: child),
                child: AnimatedContainer(
                  duration: duration,
                  decoration: BoxDecoration(
                    color: selected ? tokens.selectionFill : tokens.selectionFill.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(child: FpIcon(icon, size: 22, color: selected ? tokens.selectionInk : tokens.textSecondary)),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: labelHeight,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      height: 1,
                      color: selected ? tokens.textPrimary : tokens.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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

class _DesktopSidebarBackButton extends StatelessWidget {
  const _DesktopSidebarBackButton({required this.canGoBack, required this.onBack});

  final bool canGoBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: canGoBack ? onBack : null,
      icon: const FpIcon(FpIconName.arrowLeft),
    );
  }
}

String? _fallbackPath(String path) {
  if (isMobileNavigationPath(path)) return null;
  final segments = Uri(path: path).pathSegments;
  if (segments.length >= 3 && segments.first == 'illust') return '/illust/${segments[1]}';
  if (segments.length >= 3 && segments.first == 'novel') return '/novel/${segments[1]}';
  if (segments.length >= 2 && segments.first == 'fanbox') return AppRoute.fanbox.path;
  if (segments.length >= 2 && segments.first == 'pixivision') return AppRoute.pixivision.path;
  if (segments.length >= 2 && segments.first == 'me') return AppRoute.me.path;
  if (segments.length >= 2 && segments.first == 'search') return AppRoute.search.path;
  return AppRoute.home.path;
}

const _secondaryRoutes = [AppRoute.fanbox, AppRoute.pixivision, AppRoute.downloads, AppRoute.settings, AppRoute.about];

FpIconName _secondaryIcon(AppRoute route) => switch (route) {
  AppRoute.fanbox => FpIconName.heart,
  AppRoute.pixivision => FpIconName.newspaper,
  AppRoute.downloads => FpIconName.download,
  AppRoute.settings => FpIconName.settings,
  AppRoute.about => FpIconName.info,
  _ => FpIconName.more,
};

Future<void> _showDesktopMore(
  BuildContext context,
  Translations translations,
  ValueChanged<AppRoute> onSelected,
  FocusNode buttonFocus, {
  required String currentPath,
}) async {
  buttonFocus.requestFocus();
  final button = context.findRenderObject() as RenderBox?;
  final overlay = Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
  if (button == null || overlay == null) return;
  final buttonRect = Rect.fromPoints(
    button.localToGlobal(Offset.zero, ancestor: overlay),
    button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
  );
  final route = await showDialog<AppRoute>(
    context: context,
    animationStyle: AnimationStyle(duration: AppMotion.page),
    useRootNavigator: false,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    requestFocus: true,
    builder: (dialogContext) => LayoutBuilder(
      builder: (dialogContext, constraints) {
        const margin = 8.0;
        final width = math.min(240.0, constraints.maxWidth - margin * 2);
        const itemHeight = AppMetrics.compactTargetHeight;
        const padding = 6.0;
        final height = math.min(_secondaryRoutes.length * itemHeight + padding * 2, constraints.maxHeight - margin * 2);
        // The shell pads the page by the sidebar; anchor beside the sidebar.
        final left = (buttonRect.right + margin * 2).clamp(margin, constraints.maxWidth - width - margin);
        final top = buttonRect.top.clamp(margin, constraints.maxHeight - height - margin);

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              // Grows out of the More button like the other menus
              // (docs/MOTION_SPEC.md 8); the dialog route supplies the fade.
              child: ScaleTransition(
                alignment: AlignmentDirectional.topStart.resolve(Directionality.of(dialogContext)),
                scale: MediaQuery.disableAnimationsOf(dialogContext)
                    ? kAlwaysCompleteAnimation
                    : ModalRoute.of(
                        dialogContext,
                      )!.animation!.drive(CurveTween(curve: SpringCurve(AppMotion.snappy, AppMotion.page))).drive(Tween(begin: .94, end: 1.0)),
                child: FpSurface(
                  role: FpSurfaceRole.overlay,
                  borderRadius: BorderRadius.circular(AppMetrics.groupRadius),
                  child: FocusTraversalGroup(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (index, destination) in _secondaryRoutes.indexed)
                            SizedBox(
                              height: itemHeight,
                              child: TextButton.icon(
                                autofocus: index == 0,
                                onPressed: () => Navigator.of(dialogContext).pop(destination),
                                icon: FpIcon(_secondaryIcon(destination)),
                                label: Text(appRouteNavigationLabel(translations, destination)),
                                style: TextButton.styleFrom(
                                  alignment: AlignmentDirectional.centerStart,
                                  // The page on screen is marked, since More itself
                                  // is lit while it is one of these.
                                  backgroundColor: _isCurrent(destination, currentPath) ? FreepivThemeTokens.of(dialogContext).selectionFill : null,
                                  foregroundColor: _isCurrent(destination, currentPath)
                                      ? FreepivThemeTokens.of(dialogContext).selectionInk
                                      : Theme.of(dialogContext).colorScheme.onSurface,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.standard,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.controlRadius - padding + 2)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
  if (context.mounted) buttonFocus.requestFocus();
  if (route != null && context.mounted) onSelected(route);
}

bool _isCurrent(AppRoute route, String path) => path == route.path || path.startsWith('${route.path}/');

/// Page-level Escape: leave a focused text field first, then go back one
/// page. Top-level pages have nowhere to go, so the key is left unhandled.
class _PageBackAction extends Action<DismissIntent> {
  _PageBackAction({required this.canGoBack, required this.goBack});

  final bool Function() canGoBack;
  final VoidCallback goBack;

  bool get _editing => FocusManager.instance.primaryFocus?.context?.findAncestorStateOfType<EditableTextState>() != null;

  @override
  bool isEnabled(DismissIntent intent) => _editing || canGoBack();

  @override
  Object? invoke(DismissIntent intent) {
    if (_editing) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      goBack();
    }
    return null;
  }
}
