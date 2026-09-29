import 'package:freepiv/shared/widgets/app_click_surface.dart';
import 'package:freepiv/app/theme/app_feedback.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'dart:math' as math;

import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';
import 'package:freepiv/shared/widgets/rounded_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

double appFieldHeight(BuildContext context) => AppMetrics.fieldHeight(context);

class AppSelectItem<T> {
  const AppSelectItem({required this.value, required this.label, this.icon, this.content});

  final T value;
  final String label;
  final IconData? icon;
  final Widget? content;
}

typedef AppMenuTriggerBuilder = Widget Function(BuildContext context, FocusNode focusNode, VoidCallback toggle);

/// MenuAnchor whose trigger takes focus when it opens the menu. A pointer
/// click does not focus a button, and without focus in the anchor Escape and
/// the arrow keys never reach the open menu. Closing returns focus to the
/// trigger, which is already where it is.
class AppMenuAnchor extends StatefulWidget {
  const AppMenuAnchor({required this.menuChildren, required this.builder, this.alignmentOffset, super.key});

  final List<Widget> menuChildren;
  final AppMenuTriggerBuilder builder;
  final Offset? alignmentOffset;

  @override
  State<AppMenuAnchor> createState() => _AppMenuAnchorState();
}

class _AppMenuAnchorState extends State<AppMenuAnchor> with SingleTickerProviderStateMixin {
  final _controller = MenuController();
  final _focusNode = FocusNode(debugLabel: 'Menu trigger');
  final _menuFocus = FocusScopeNode(debugLabel: 'Menu');

  /// 0 closed, 1 open; a spring, so reopening mid-close turns back smoothly.
  late final AnimationController _reveal = AnimationController.unbounded(vsync: this);
  bool _closing = false;

  @override
  void dispose() {
    _reveal.dispose();
    _menuFocus.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _tickersEnabled => TickerMode.valuesOf(context).enabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A subtree whose tickers stop (a collapsing download panel) cannot run
    // the closing spring; its open menu closes at once instead of freezing
    // half-shrunk on screen.
    if (!_tickersEnabled && _controller.isOpen) _controller.close();
  }

  void _toggle() {
    if (_controller.isOpen && !_closing) {
      _controller.close();
      return;
    }
    _focusNode.requestFocus();
    _controller.open();
  }

  @override
  Widget build(BuildContext context) {
    // The menu grows out of its anchor on a spring and shrinks back into it,
    // on the glass overlay material (docs/MOTION_SPEC.md 8); the framework's
    // own menu animation has fixed Material timings.
    return RawMenuAnchor(
      controller: _controller,
      childFocusNode: _focusNode,
      onOpenRequested: (position, showOverlay) {
        _closing = false;
        showOverlay();
        AppMotion.springTo(context, _reveal, 1, AppMotion.standard);
      },
      onCloseRequested: (hideOverlay) {
        if (!_tickersEnabled) {
          _closing = false;
          _reveal.value = 0;
          hideOverlay();
          return;
        }
        _closing = true;
        AppMotion.springTo(context, _reveal, 0, AppMotion.snappy).orCancel.then((_) {
          if (mounted && _closing) {
            _closing = false;
            hideOverlay();
          }
        }, onError: (_) {});
      },
      overlayBuilder: (overlayContext, info) => _AnchoredMenu(
        info: info,
        offset: widget.alignmentOffset ?? Offset.zero,
        reveal: _reveal,
        closing: () => _closing,
        focusNode: _menuFocus,
        onDismiss: _controller.close,
        children: widget.menuChildren,
      ),
      builder: (context, controller, _) => widget.builder(context, _focusNode, _toggle),
    );
  }
}

/// Lets the items of an open [AppMenuAnchor] close it.
class _AppMenuScope extends InheritedWidget {
  const _AppMenuScope({required this.close, required super.child});

  final VoidCallback close;

  @override
  bool updateShouldNotify(_AppMenuScope oldWidget) => close != oldWidget.close;
}

/// An item of an [AppMenuAnchor] menu: a [MenuItemButton] that closes its menu
/// (with the menu's shrink animation) before its action runs. Material's own
/// close-on-activate only reaches Material's MenuAnchor.
class AppMenuItem extends StatelessWidget {
  const AppMenuItem({
    required this.onPressed,
    required this.child,
    this.leadingIcon,
    this.trailingIcon,
    this.style,
    this.autofocus = false,
    this.overflowAxis = Axis.horizontal,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final ButtonStyle? style;
  final bool autofocus;
  final Axis overflowAxis;

  @override
  Widget build(BuildContext context) {
    final onPressed = this.onPressed;
    return MenuItemButton(
      onPressed: onPressed == null
          ? null
          : () {
              context.getInheritedWidgetOfExactType<_AppMenuScope>()?.close();
              onPressed();
            },
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      style: style,
      autofocus: autofocus,
      overflowAxis: overflowAxis,
      child: child,
    );
  }
}

/// The open menu of an [AppMenuAnchor]: below the anchor (above when there is
/// no room), kept inside the overlay, as a glass panel that scales in from
/// the anchor's side.
class _AnchoredMenu extends StatelessWidget {
  const _AnchoredMenu({
    required this.info,
    required this.offset,
    required this.reveal,
    required this.closing,
    required this.focusNode,
    required this.onDismiss,
    required this.children,
  });

  final RawMenuOverlayInfo info;
  final Offset offset;
  final Animation<double> reveal;
  final bool Function() closing;
  final FocusScopeNode focusNode;
  final VoidCallback onDismiss;
  final List<Widget> children;

  static const _margin = 8.0;

  @override
  Widget build(BuildContext context) {
    final anchor = info.anchorRect;
    final room = info.overlaySize;
    final below = room.height - anchor.bottom >= anchor.top || room.height - anchor.bottom >= 240;
    return CustomSingleChildLayout(
      delegate: _AnchoredMenuLayout(anchor: anchor, offset: offset, below: below, margin: _margin),
      child: TapRegion(
        groupId: info.tapRegionGroupId,
        onTapOutside: (_) => onDismiss(),
        child: FocusScope(
          node: focusNode,
          child: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
              SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
              SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
            },
            child: Actions(
              actions: {DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => onDismiss())},
              child: _AppMenuScope(
                close: onDismiss,
                child: MenuReveal(
                  reveal: reveal,
                  closing: closing,
                  alignment: below ? AlignmentDirectional.topStart : AlignmentDirectional.bottomStart,
                  child: FpSurface(
                    role: FpSurfaceRole.overlay,
                    borderRadius: BorderRadius.circular(AppMetrics.groupRadius),
                    child: SingleChildScrollView(
                      child: IntrinsicWidth(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnchoredMenuLayout extends SingleChildLayoutDelegate {
  const _AnchoredMenuLayout({required this.anchor, required this.offset, required this.below, required this.margin});

  final Rect anchor;
  final Offset offset;
  final bool below;
  final double margin;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final room = below ? constraints.maxHeight - anchor.bottom - offset.dy - margin : anchor.top - offset.dy - margin;
    return BoxConstraints(maxWidth: math.max(0, constraints.maxWidth - margin * 2), maxHeight: math.max(0, room));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = (anchor.left + offset.dx).clamp(margin, math.max(margin, size.width - childSize.width - margin)).toDouble();
    final top = below ? anchor.bottom + offset.dy : anchor.top - offset.dy - childSize.height;
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_AnchoredMenuLayout oldDelegate) =>
      anchor != oldDelegate.anchor || offset != oldDelegate.offset || below != oldDelegate.below || margin != oldDelegate.margin;
}

/// Scales a menu panel in from its anchor side (0.94 → 1) and fades it, with
/// [reveal] running 0 → 1. While [closing] it no longer takes input.
class MenuReveal extends StatelessWidget {
  const MenuReveal({required this.reveal, required this.closing, required this.alignment, required this.child, super.key});

  final Animation<double> reveal;
  final bool Function() closing;
  final AlignmentGeometry alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, child) {
        final progress = reveal.value.clamp(0.0, 1.0);
        final shut = closing();
        return IgnorePointer(
          ignoring: shut,
          child: ExcludeFocus(
            excluding: shut,
            child: ExcludeSemantics(
              excluding: shut,
              child: Opacity(
                opacity: progress,
                child: Transform.scale(scale: .94 + .06 * progress, alignment: alignment.resolve(Directionality.of(context)), child: child),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// The page-level value picker: the current value as a quiet text button with
/// a chevron, opening an anchored menu whose current item carries a check.
/// Shared by FANBOX collections, Pixivision categories and ranking modes.
///
/// Labels are never shortened: the button sizes to its label and the menu to
/// its longest item (200–360). At supported text sizes both stay on one line;
/// only when an accessibility text size leaves too little room does the label
/// wrap, and it is never cut off with an ellipsis.
class AppValueMenuButton<T> extends StatelessWidget {
  const AppValueMenuButton({required this.value, required this.items, required this.onSelected, this.iconOnly = false, super.key});

  final T value;
  final List<AppSelectItem<T>> items;
  final ValueChanged<T> onSelected;

  /// Show the current item's [AppSelectItem.icon] instead of its label, for
  /// rows without room for the label; the label stays as tooltip and
  /// semantics, and the menu lists every label in full.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final current = items.firstWhere((item) => item.value == value, orElse: () => items.first);
    final label = current.label;
    return AppMenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        for (final item in items)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 360),
            child: AppMenuItem(
              onPressed: item.value == value ? null : () => onSelected(item.value),
              // Labels wrap only when an accessibility text size leaves no room.
              overflowAxis: Axis.vertical,
              leadingIcon: item.icon == null ? null : Icon(item.icon, size: AppMetrics.iconSize),
              trailingIcon: SizedBox.square(dimension: 18, child: item.value == value ? Icon(Icons.check_rounded, size: 18, color: tokens.selectionInk) : null),
              child: Text(item.label),
            ),
          ),
      ],
      builder: (context, focusNode, toggle) {
        final trigger = TextButton(
          focusNode: focusNode,
          onPressed: toggle,
          style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: iconOnly ? 8 : 12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconOnly && current.icon != null) Icon(current.icon, size: AppMetrics.iconSize, semanticLabel: label) else Flexible(child: Text(label)),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ],
          ),
        );
        return iconOnly ? Tooltip(message: label, excludeFromSemantics: true, child: trigger) : trigger;
      },
    );
  }
}

/// Rounded custom menu trigger without PopupMenuButton's enclosing InkWell.
class AppMenuButton<T> extends StatelessWidget {
  const AppMenuButton({required this.child, required this.items, required this.value, required this.onSelected, this.tooltip, super.key});
  final Widget child;
  final List<AppSelectItem<T>> items;
  final T value;
  final ValueChanged<T> onSelected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final menu = AppMenuAnchor(
      menuChildren: [
        for (final item in items)
          AppMenuItem(
            autofocus: item.value == value,
            onPressed: () => onSelected(item.value),
            trailingIcon: item.value == value ? Icon(Icons.check_rounded, color: tokens.keyGraphicOn(tokens.surfaceRaised)) : null,
            child: item.content ?? Text(item.label),
          ),
      ],
      builder: (context, focusNode, toggle) => AppClickSurface(focusNode: focusNode, onTap: toggle, child: child),
    );
    return tooltip == null ? menu : Tooltip(message: tooltip!, child: menu);
  }
}

class AppSelect<T> extends StatefulWidget {
  const AppSelect({required this.value, required this.items, required this.onChanged, this.label, this.autofocus = false, this.borderColor, super.key});

  final String? label;
  final T? value;
  final List<AppSelectItem<T>> items;
  final ValueChanged<T> onChanged;
  final bool autofocus;
  final Color? borderColor;

  @override
  State<AppSelect<T>> createState() => _AppSelectState<T>();
}

class _AppSelectState<T> extends State<AppSelect<T>> with SingleTickerProviderStateMixin {
  bool _open = false;
  bool _closing = false;
  bool _focused = false;
  final MenuController _menuController = MenuController();
  final FocusNode _triggerFocus = FocusNode();
  final FocusScopeNode _menuFocus = FocusScopeNode();
  late final AnimationController _menuAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 180),
  );

  @override
  void dispose() {
    _menuAnimation.dispose();
    _menuFocus.dispose();
    _triggerFocus.dispose();
    super.dispose();
  }

  void _toggleMenu(MenuController controller) {
    if (_closing) {
      _closing = false;
      _menuAnimation.forward();
      _menuFocus.requestFocus();
    } else if (controller.isOpen) {
      controller.close();
    } else {
      controller.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = FreepivThemeTokens.of(context);
    AppSelectItem<T>? selected;
    for (final item in widget.items) {
      if (item.value == widget.value) {
        selected = item;
        break;
      }
    }

    final select = LayoutBuilder(
      builder: (context, constraints) {
        final fieldHeight = appFieldHeight(context);
        final itemHeight = fieldHeight;
        final labelStyle = theme.textTheme.bodyMedium;
        var labelWidth = 0.0;
        for (final item in widget.items) {
          final painter = TextPainter(
            text: TextSpan(text: item.label, style: labelStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          labelWidth = math.max(
            labelWidth,
            painter.width +
                (switch (item.icon) {
                  null => 0,
                  _ => 26,
                }),
          );
          painter.dispose();
        }
        // Allow the popup to fit its labels even when the field is narrow.
        final menuWidth = math.min(MediaQuery.sizeOf(context).width - 24, math.max(constraints.maxWidth, labelWidth.ceilToDouble() + 72));
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        _menuAnimation.duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 240);
        _menuAnimation.reverseDuration = reduceMotion ? Duration.zero : const Duration(milliseconds: 180);
        return RawMenuAnchor(
          controller: _menuController,
          childFocusNode: _triggerFocus,
          onOpen: () => setState(() => _open = true),
          onClose: () => setState(() => _open = false),
          onOpenRequested: (position, showOverlay) {
            _closing = false;
            showOverlay();
            _menuAnimation.forward();
          },
          onCloseRequested: (hideOverlay) {
            _closing = true;
            _triggerFocus.requestFocus();
            _menuAnimation.reverse().then((_) {
              if (mounted && _closing && _menuAnimation.isDismissed) {
                _closing = false;
                hideOverlay();
              }
            });
          },
          overlayBuilder: (overlayContext, info) {
            final viewWidth = info.overlaySize.width;
            final viewHeight = info.overlaySize.height;
            final menuHeight = math.min(320.0, math.min(widget.items.length * itemHeight, math.max(0.0, viewHeight - 16))).toDouble();
            final left = info.anchorRect.left.clamp(8.0, math.max(8.0, viewWidth - menuWidth - 8)).toDouble();
            final below = info.anchorRect.bottom + menuHeight <= viewHeight - 8;
            final top = below ? info.anchorRect.bottom : math.max(8.0, info.anchorRect.top - menuHeight);
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  width: menuWidth,
                  child: TapRegion(
                    groupId: info.tapRegionGroupId,
                    onTapOutside: (_) => _menuController.close(),
                    child: FocusScope(
                      node: _menuFocus,
                      child: Actions(
                        actions: {
                          DismissIntent: CallbackAction<DismissIntent>(
                            onInvoke: (_) {
                              _menuController.close();
                              return null;
                            },
                          ),
                        },
                        child: Shortcuts(
                          shortcuts: const {
                            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
                            SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
                            SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
                          },
                          child: AnimatedBuilder(
                            animation: _menuAnimation,
                            builder: (context, child) {
                              final progress = _closing
                                  ? 1 - Curves.easeInCubic.transform(1 - _menuAnimation.value)
                                  : Curves.easeOutCubic.transform(_menuAnimation.value);
                              return IgnorePointer(
                                ignoring: _closing,
                                child: ExcludeFocus(
                                  excluding: _closing,
                                  child: ExcludeSemantics(
                                    excluding: _closing,
                                    child: Opacity(
                                      opacity: progress,
                                      child: Transform.translate(offset: Offset(0, (1 - progress) * (below ? 4 : -4)), child: child),
                                    ),
                                  ),
                                ),
                              );
                            },
                            // The outline sits outside the clip: a stroke
                            // clipped by its own shape looks jagged at corners.
                            child: DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(
                                border: Border.all(color: tokens.line),
                                borderRadius: BorderRadius.circular(AppMetrics.groupRadius),
                              ),
                              child: Material(
                                color: tokens.surfaceRaised,
                                elevation: 4,
                                shadowColor: Colors.black.withValues(alpha: .18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMetrics.groupRadius)),
                                clipBehavior: Clip.antiAlias,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: menuHeight),
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        for (final item in widget.items)
                                          SizedBox(
                                            width: menuWidth,
                                            child: MenuItemButton(
                                              autofocus: item.value == widget.value,
                                              clipBehavior: Clip.antiAlias,
                                              onPressed: () {
                                                _menuController.close();
                                                widget.onChanged(item.value);
                                              },
                                              style: ButtonStyle(
                                                minimumSize: WidgetStatePropertyAll(Size(0, itemHeight)),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                visualDensity: VisualDensity.standard,
                                                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
                                                backgroundColor: WidgetStateProperty.resolveWith(
                                                  (states) => appButtonRestingSurface(
                                                    tokens,
                                                    states,
                                                    resting: item.value == widget.value ? colors.primaryContainer : Colors.transparent,
                                                  ),
                                                ),
                                                foregroundColor: WidgetStatePropertyAll(
                                                  item.value == widget.value ? colors.onPrimaryContainer : colors.onSurface,
                                                ),
                                                shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
                                              ),
                                              trailingIcon: item.value == widget.value ? const Icon(Icons.check_rounded, size: 18) : const SizedBox(width: 18),
                                              leadingIcon: switch (item.icon) {
                                                null => null,
                                                _ => Icon(item.icon, size: 18),
                                              },
                                              child:
                                                  item.content ??
                                                  ConstrainedBox(
                                                    constraints: BoxConstraints(maxWidth: math.max(0, menuWidth - (item.icon == null ? 80 : 104))),
                                                    child: Text(item.label, style: labelStyle, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
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
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          builder: (context, controller, child) {
            final keyboardFocused = appShowsFocus({if (_focused) WidgetState.focused});
            return Focus(
              focusNode: _triggerFocus,
              autofocus: widget.autofocus,
              descendantsAreFocusable: false,
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space) {
                  _toggleMenu(controller);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              onFocusChange: (value) => setState(() => _focused = value),
              child: AppRoundedSurface(
                color: _open ? tokens.surfaceRaised : tokens.surfaceMuted,
                borderColor: widget.borderColor ?? (keyboardFocused ? tokens.focus : colors.outline),
                borderWidth: widget.borderColor == null && keyboardFocused ? AppMetrics.focusBorderWidth : 1,
                child: AppClickSurface(
                  feedback: AppClickFeedback.quiet,
                  borderRadius: BorderRadius.circular(AppMetrics.controlRadius),
                  onTap: () => _toggleMenu(controller),
                  child: ConstrainedBox(
                    constraints: BoxConstraints.tightFor(width: constraints.maxWidth, height: fieldHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          if (selected?.icon != null) ...[Icon(selected!.icon, size: 18, color: colors.onSurfaceVariant), const SizedBox(width: 8)],
                          Expanded(
                            child:
                                selected?.content ??
                                Text(
                                  selected?.label ?? '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                          ),
                          AnimatedRotation(
                            turns: _open ? 0.5 : 0,
                            duration: AppMotion.duration(context, AppMotion.feedback),
                            child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    final label = widget.label;
    if (label == null) return select;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 7),
        select,
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    this.height,
    this.focusNode,
    this.readOnly = false,
    this.label,
    this.controller,
    this.scrollController,
    this.hintText,
    this.leading,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.monospace = false,
    this.obscureText = false,
    this.autofocus = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.onTapOutside,
    super.key,
  });

  final String? label;
  final TextEditingController? controller;
  final double? height;
  final FocusNode? focusNode;
  final bool readOnly;
  final ScrollController? scrollController;
  final String? hintText;
  final IconData? leading;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool monospace;
  final bool obscureText;
  final bool autofocus;
  final int minLines;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final VoidCallback? onTap;
  final TapRegionCallback? onTapOutside;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = FreepivThemeTokens.of(context);
    final field = SizedBox(
      height: height,
      child: TextField(
        autofocus: autofocus,
        focusNode: focusNode,
        readOnly: readOnly,
        controller: controller,
        scrollController: scrollController,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        minLines: minLines,
        maxLines: maxLines,
        textAlignVertical: switch (height) {
          null => null,
          _ => TextAlignVertical.center,
        },
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onEditingComplete: onEditingComplete,
        onTap: onTap,
        onTapOutside: onTapOutside,
        style: theme.textTheme.bodyMedium?.copyWith(fontFamily: monospace ? 'monospace' : null),
        decoration: InputDecoration(
          hintText: hintText,
          isDense: false,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: switch (height) {
              null => 12,
              _ => 4,
            },
          ),
          errorText: errorText,
          prefixIcon: switch (leading) {
            null => null,
            _ => Icon(leading, size: 18),
          },
          suffixIcon: switch (trailing) {
            null => null,
            _ => Padding(padding: const EdgeInsets.only(right: 8), child: trailing),
          },
          suffixIconConstraints: switch (trailing) {
            null => null,
            _ => BoxConstraints(minHeight: height ?? 36),
          },
          filled: true,
          fillColor: enabled ? tokens.surfaceMuted : tokens.surface,
        ),
      ),
    );
    final label = this.label;
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 7),
        field,
      ],
    );
  }
}
