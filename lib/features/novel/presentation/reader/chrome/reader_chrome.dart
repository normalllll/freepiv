import 'dart:async';

import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// Whether the reader's bars are shown, and why.
///
/// The reader opens hidden. A tap in the middle, a menu key or an entry of
/// the pieces over the text shows both bars with a scrim over the text; a tap
/// on the scrim, a turn of the page, scrolling or starting auto scroll hides
/// them. With a mouse, the pointer near the top or bottom edge shows that bar
/// alone and it goes again [hideDelay] after the pointer has left it. A press
/// that starts on a bar keeps it until the press ends, so a drag on it (the
/// progress thumb) may wander off the bar without the bar going under it.
class ReaderChromeController extends ChangeNotifier {
  ReaderChromeController({this.hideDelay = const Duration(seconds: 2)});

  /// How long a bar shown by the pointer stays once the pointer left it.
  final Duration hideDelay;

  /// How close to an edge the pointer reveals that edge's bar.
  static const edgeReveal = 48.0;

  bool _shown = false;
  bool _topBarHosted = false;
  bool _disposed = false;
  _Edge? _peek;
  bool _overBar = false;

  /// Presses that started on a bar and have not ended.
  int _pressesOnBar = 0;
  Timer? _timer;

  /// Whether the pointer keeps a bar that the pointer showed.
  bool get _held => _overBar || _pressesOnBar > 0;

  /// Both bars and the scrim.
  bool get shown => _shown;

  bool get topVisible => _shown || _peek == _Edge.top;
  bool get bottomVisible => _shown || _peek == _Edge.bottom;

  /// Whether the top bar is shown elsewhere (the title row), so the reader's
  /// own area does not draw one.
  bool get topBarHosted => _topBarHosted;

  set topBarHosted(bool value) {
    if (_topBarHosted == value || _disposed) return;
    _topBarHosted = value;
    notifyListeners();
  }

  /// Whether any bar is on show.
  bool get anyVisible => topVisible || bottomVisible;

  void show() {
    _cancelTimer();
    _peek = null;
    if (_shown) return;
    _shown = true;
    notifyListeners();
  }

  void hide() {
    _cancelTimer();
    if (!_shown && _peek == null) return;
    _shown = false;
    _peek = null;
    _overBar = false;
    _pressesOnBar = 0;
    notifyListeners();
  }

  void toggle() => _shown ? hide() : show();

  /// The mouse is at [position] in an area of [size].
  void pointerMoved(Offset position, Size size) {
    if (_shown) return;
    final edge = position.dy <= edgeReveal
        ? _Edge.top
        : position.dy >= size.height - edgeReveal
        ? _Edge.bottom
        : null;
    if (edge != null) {
      _cancelTimer();
      if (_peek != edge) {
        _peek = edge;
        notifyListeners();
      }
    } else if (_peek != null && !_held) {
      _scheduleHide();
    }
  }

  /// The mouse left the area.
  void pointerLeft() {
    if (_peek != null && !_held) _scheduleHide();
  }

  /// The pointer reached the top bar where it lives outside the reader's own
  /// area (the title row of a page that has the whole window): that edge's bar
  /// shows while the pointer is over it.
  void topBarEntered() {
    _overBar = true;
    _cancelTimer();
    if (_shown || _peek == _Edge.top) return;
    _peek = _Edge.top;
    notifyListeners();
  }

  /// The mouse entered or left a bar.
  void barHovered(bool over) {
    _overBar = over;
    if (over) {
      _cancelTimer();
    } else if (_peek != null && !_held) {
      _scheduleHide();
    }
  }

  /// A press started on a bar ([down]), or such a press ended.
  void barPressed(bool down) {
    if (down) {
      _pressesOnBar++;
      _cancelTimer();
      return;
    }
    if (_pressesOnBar > 0) _pressesOnBar--;
    if (_peek != null && !_held) _scheduleHide();
  }

  void _scheduleHide() {
    if (_timer?.isActive ?? false) return;
    _timer = Timer(hideDelay, () {
      _timer = null;
      if (_peek == null || _held) return;
      _peek = null;
      notifyListeners();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimer();
    super.dispose();
  }
}

enum _Edge { top, bottom }

/// The reader's bars over [child]: the top bar and the bottom panel, a scrim
/// over the text while both are shown, and the pointer reaching for either
/// edge. The pieces know nothing of when they show; this does. The top one
/// gives way when the controller says it is hosted elsewhere (the title row).
class ReaderChrome extends StatelessWidget {
  const ReaderChrome({required this.controller, required this.child, required this.topBar, required this.bottomPanel, super.key});

  final ReaderChromeController controller;
  final Widget child;
  final Widget topBar;
  final Widget bottomPanel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => MouseRegion(
        onHover: (event) => controller.pointerMoved(event.localPosition, constraints.biggest),
        onExit: (_) => controller.pointerLeft(),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Stack(
            children: [
              Positioned.fill(child: child),
              Positioned.fill(child: _Scrim(controller: controller)),
              if (!controller.topBarHosted) _ChromeBar(top: true, controller: controller, child: topBar),
              _ChromeBar(top: false, controller: controller, child: bottomPanel),
            ],
          ),
        ),
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.controller});

  final ReaderChromeController controller;

  @override
  Widget build(BuildContext context) {
    final duration = FrostMotion.duration(context, FrostMotion.reveal);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final shown = controller.shown;
        return IgnorePointer(
          ignoring: !shown,
          child: AnimatedOpacity(
            opacity: shown ? 1 : 0,
            duration: duration,
            // Scrolling over the scrim, by drag or wheel, hides the bars like a tap does.
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) controller.hide();
              },
              child: GestureDetector(
                key: const ValueKey('reader-scrim'),
                behavior: HitTestBehavior.opaque,
                onTap: controller.hide,
                onVerticalDragStart: (_) => controller.hide(),
                // The scrim of Frost's modal surfaces.
                child: ColoredBox(color: FrostThemeTokens.of(context).onMediaScrim, child: const SizedBox.expand()),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A bar at the top or bottom edge, sliding and fading in and out. While it
/// is away its content is not built, so what it shows is not kept up to date
/// for nobody.
class _ChromeBar extends StatefulWidget {
  const _ChromeBar({required this.top, required this.controller, required this.child});

  final bool top;
  final ReaderChromeController controller;
  final Widget child;

  @override
  State<_ChromeBar> createState() => _ChromeBarState();
}

class _ChromeBarState extends State<_ChromeBar> {
  bool _visible = false;

  /// Whether the content is mounted: while visible and until the hide ends.
  bool _mounted = false;

  bool get _wants => widget.top ? widget.controller.topVisible : widget.controller.bottomVisible;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _visible = _mounted = _wants;
  }

  @override
  void didUpdateWidget(_ChromeBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final wants = _wants;
    if (wants == _visible) return;
    setState(() {
      _visible = wants;
      if (wants) {
        _mounted = true;
      } else if (FrostMotion.duration(context, FrostMotion.reveal) == Duration.zero) {
        _mounted = false;
      }
    });
  }

  void _slideEnded() {
    if (!_visible && _mounted) setState(() => _mounted = false);
  }

  @override
  Widget build(BuildContext context) {
    final duration = FrostMotion.duration(context, FrostMotion.reveal);
    final top = widget.top;
    return Positioned(
      left: 0,
      right: 0,
      top: top ? 0 : null,
      bottom: top ? null : 0,
      child: IgnorePointer(
        ignoring: !_visible,
        child: ExcludeFocus(
          excluding: !_visible,
          child: ExcludeSemantics(
            excluding: !_visible,
            child: MouseRegion(
              onEnter: (_) => widget.controller.barHovered(true),
              onExit: (_) => widget.controller.barHovered(false),
              child: Listener(
                onPointerDown: (_) => widget.controller.barPressed(true),
                onPointerUp: (_) => widget.controller.barPressed(false),
                onPointerCancel: (_) => widget.controller.barPressed(false),
                child: AnimatedSlide(
                  offset: _visible ? Offset.zero : Offset(0, top ? -1 : 1),
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  onEnd: _slideEnded,
                  child: AnimatedOpacity(
                    opacity: _visible ? 1 : 0,
                    duration: duration,
                    child: _mounted ? widget.child : const SizedBox(width: double.infinity),
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

/// Marks the reader's own area, as against the shell's title row, which hosts
/// the top bar when the page has the whole window.
class ReaderPageScope extends InheritedWidget {
  const ReaderPageScope({required super.child, super.key});

  static bool contains(BuildContext context) => context.getInheritedWidgetOfExactType<ReaderPageScope>() != null;

  @override
  bool updateShouldNotify(ReaderPageScope oldWidget) => false;
}
