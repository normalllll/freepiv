import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps focus visible for keyboard navigation without leaving rings after a
/// pointer click. Applies equally to a tablet keyboard and a desktop touchscreen.
class AppInputFeedback extends StatefulWidget {
  const AppInputFeedback({required this.child, super.key});

  final Widget child;

  @override
  State<AppInputFeedback> createState() => _AppInputFeedbackState();
}

class _AppInputFeedbackState extends State<AppInputFeedback> {
  static _AppInputFeedbackState? _owner;
  late final FocusHighlightStrategy _previousStrategy;

  @override
  void initState() {
    super.initState();
    _previousStrategy = _owner?._previousStrategy ?? FocusManager.instance.highlightStrategy;
    _owner = this;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    }
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        {
          LogicalKeyboardKey.tab,
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.space,
        }.contains(event.logicalKey)) {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    }
    return false;
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    HardwareKeyboard.instance.removeHandler(_onKey);
    // Notifying InkWell listeners while the widget tree is being unmounted is
    // unsafe. A replacement scope also takes ownership before this runs.
    scheduleMicrotask(() {
      if (!identical(_owner, this)) return;
      _owner = null;
      FocusManager.instance.highlightStrategy = _previousStrategy;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
