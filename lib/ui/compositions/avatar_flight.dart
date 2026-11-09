import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// Where the identity avatar is, as the page scrolls.
enum AppAvatarFlightPhase {
  /// With the identity: only the large avatar shows.
  identity,

  /// On its way to the header: only the flying avatar shows.
  flying,

  /// In the header: only the header avatar shows.
  header,
}

/// The page's scroll position turned into where the identity avatar is. The
/// phase changes rarely, so only what depends on it rebuilds; the flying
/// avatar follows the scroll position at paint time.
class AppAvatarFlight {
  AppAvatarFlight._(this._scroll, this._flies);

  final ScrollController _scroll;
  final bool Function() _flies;

  final _stack = GlobalKey(debugLabel: 'avatar flight stack');
  final _chrome = GlobalKey(debugLabel: 'avatar flight chrome');
  final _lead = GlobalKey(debugLabel: 'avatar flight lead');
  final _source = GlobalKey(debugLabel: 'avatar flight source');
  final _slot = GlobalKey(debugLabel: 'avatar flight slot');

  /// Where the avatar is now.
  final phase = ValueNotifier(AppAvatarFlightPhase.identity);

  /// Whether the page has left its top: only then does the header hold a
  /// title, so at rest it can leave its row out.
  final scrolled = ValueNotifier(false);

  /// The identity's top in the page at rest, which the header's row may
  /// overlap once it has come.
  double? _leadTop;

  RenderBox? _box(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize ? box : null;
  }

  static const _tolerance = .5;

  /// The bottom of the header in the page's coordinates.
  double? get _chromeBottom {
    final stack = _box(_stack), chrome = _box(_chrome);
    return stack == null || chrome == null ? null : chrome.localToGlobal(Offset(0, chrome.size.height), ancestor: stack).dy;
  }

  /// The offset the avatar's top reaches the header at (0 when it starts
  /// beside the header's row), and the offset the tabs reach the header at;
  /// both stay put while the page scrolls.
  ({double arrives, double sticks})? get _travel {
    final lead = _box(_lead), source = _box(_source), bottom = _chromeBottom;
    if (lead == null || bottom == null || lead.size.height <= 0) return null;
    final under = (_leadTop ?? bottom) - bottom;
    final sticks = lead.size.height + under;
    if (sticks <= 0) return null;
    final arrives = source == null ? sticks : math.max(0.0, source.localToGlobal(Offset.zero, ancestor: lead).dy + under);
    return (arrives: arrives, sticks: sticks);
  }

  /// After a layout: notes where the identity rests, and goes on from the
  /// header as it now is.
  void settled() {
    if (_scroll.hasClients && _scroll.offset <= 0) {
      final stack = _box(_stack), lead = _box(_lead);
      if (stack != null && lead != null) _leadTop = lead.localToGlobal(Offset.zero, ancestor: stack).dy;
    }
    update();
  }

  void update() {
    if (!_scroll.hasClients) return;
    final offset = _scroll.offset;
    if (scrolled.value != offset > 0) {
      scrolled.value = offset > 0;
      // The header's row comes or goes with the title.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_box(_stack) != null) settled();
      });
    }
    final travel = _travel;
    if (travel == null) return;
    phase.value = offset >= travel.sticks - _tolerance
        ? AppAvatarFlightPhase.header
        : _flies() && offset > travel.arrives
        ? AppAvatarFlightPhase.flying
        : AppAvatarFlightPhase.identity;
  }

  /// The flying avatar's rect in the page's coordinates: where the large
  /// avatar is when it reaches the header, moved to the header's slot so that
  /// it lands exactly when the tabs stick. Null without the page laid out.
  Rect? get flyingRect {
    final stack = _box(_stack), lead = _box(_lead), source = _box(_source), slot = _box(_slot), bottom = _chromeBottom, travel = _travel;
    if (stack == null || lead == null || source == null || slot == null || bottom == null || travel == null || !_scroll.hasClients) return null;
    // Where the avatar was when it took off: at the header's bottom, or where
    // it rests when that is already beside the header's row.
    final top = (_leadTop ?? bottom) + source.localToGlobal(Offset.zero, ancestor: lead).dy - travel.arrives;
    final from = Offset(source.localToGlobal(Offset.zero, ancestor: stack).dx, top) & source.size;
    final to = slot.localToGlobal(Offset.zero, ancestor: stack) & slot.size;
    final span = travel.sticks - travel.arrives;
    final progress = span <= 0 ? 1.0 : ((_scroll.offset - travel.arrives) / span).clamp(0.0, 1.0);
    return Rect.lerp(from, to, progress);
  }

  void _dispose() {
    phase.dispose();
    scrolled.dispose();
  }

  static AppAvatarFlight of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_FlightScope>()!.flight;
}

class _FlightScope extends InheritedWidget {
  const _FlightScope({required this.flight, required this.avatar, required super.child});

  final AppAvatarFlight flight;
  final Widget Function(FrostAvatarSize size) avatar;

  @override
  bool updateShouldNotify(_FlightScope oldWidget) => avatar != oldWidget.avatar;
}

/// A profile page whose large avatar flies into its header as the identity
/// scrolls away. [child] is the page's FrostPinnedChrome, using [AppFlightChrome],
/// [AppFlightLead], [AppFlightAvatar] and [AppFlightTitle]. The flying avatar
/// is painted above it and never takes a press.
class AppAvatarFlightHost extends StatefulWidget {
  const AppAvatarFlightHost({required this.controller, required this.avatar, required this.child, super.key});

  /// The NestedScrollView's outer controller.
  final ScrollController controller;

  /// The avatar at a size, from the same image at every size.
  final Widget Function(FrostAvatarSize size) avatar;
  final Widget child;

  @override
  State<AppAvatarFlightHost> createState() => _AppAvatarFlightHostState();
}

class _AppAvatarFlightHostState extends State<AppAvatarFlightHost> {
  late final _flight = AppAvatarFlight._(widget.controller, () => !MediaQuery.disableAnimationsOf(context));

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_flight.update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_flight.update);
    _flight._dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The header and identity may have moved with the window.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _flight.settled();
    });
    return _FlightScope(
      flight: _flight,
      avatar: widget.avatar,
      child: Stack(
        key: _flight._stack,
        fit: StackFit.expand,
        children: [
          widget.child,
          ValueListenableBuilder(
            valueListenable: _flight.phase,
            builder: (context, phase, flying) => phase == AppAvatarFlightPhase.flying ? flying! : const SizedBox.shrink(),
            child: Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Flow(delegate: _FlyingAvatarDelegate(_flight, widget.controller), children: [widget.avatar(_largeSize)]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _largeSize = FrostAvatarSize.xxlarge;
const _largeExtent = 72.0;
const _headerSize = FrostAvatarSize.small;

class _FlyingAvatarDelegate extends FlowDelegate {
  _FlyingAvatarDelegate(this.flight, ScrollController scroll) : super(repaint: scroll);

  final AppAvatarFlight flight;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) => BoxConstraints.tight(const Size.square(_largeExtent));

  @override
  void paintChildren(FlowPaintingContext context) {
    final rect = flight.flyingRect;
    if (rect == null) return;
    final scale = rect.width / _largeExtent;
    context.paintChild(0, transform: Matrix4.translationValues(rect.left, rect.top, 0)..scaleByDouble(scale, scale, 1, 1));
  }

  @override
  bool shouldRepaint(_FlyingAvatarDelegate oldDelegate) => oldDelegate.flight != flight;
}

/// The page header, measured so the flight knows where it ends. It holds
/// [title] once the page has left its top, so that at rest it can leave its
/// row out and the identity starts at the top of the page.
class AppFlightChrome extends StatelessWidget {
  const AppFlightChrome({required this.title, super.key});

  /// Usually an [AppFlightTitle]; null while there is nothing to name.
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    final flight = AppAvatarFlight.of(context);
    return KeyedSubtree(
      key: flight._chrome,
      child: ValueListenableBuilder(
        valueListenable: flight.scrolled,
        builder: (context, scrolled, _) => FrostPageHeader(title: scrolled ? title : null),
      ),
    );
  }
}

/// The identity above the tabs, whose height is the distance to sticking.
class AppFlightLead extends StatelessWidget {
  const AppFlightLead({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: AppAvatarFlight.of(context)._lead, child: child);
}

/// The identity's large avatar, hidden while it flies but keeping its place.
class AppFlightAvatar extends StatelessWidget {
  const AppFlightAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final flight = AppAvatarFlight.of(context);
    final scope = context.dependOnInheritedWidgetOfExactType<_FlightScope>()!;
    return ValueListenableBuilder(
      valueListenable: flight.phase,
      child: scope.avatar(_largeSize),
      builder: (context, phase, avatar) => Visibility(
        key: flight._source,
        visible: phase != AppAvatarFlightPhase.flying,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: avatar!,
      ),
    );
  }
}

/// The header's title: a small avatar and the name. Both keep their place
/// from the start, so the slot can be measured, and show when the identity
/// has gone.
class AppFlightTitle extends StatelessWidget {
  const AppFlightTitle({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final flight = AppAvatarFlight.of(context);
    final scope = context.dependOnInheritedWidgetOfExactType<_FlightScope>()!;
    return ValueListenableBuilder(
      valueListenable: flight.phase,
      builder: (context, phase, _) {
        final arrived = phase == AppAvatarFlightPhase.header;
        Widget shown(Widget child) => Visibility(visible: arrived, maintainSize: true, maintainAnimation: true, maintainState: true, child: child);
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FrostGap.related,
          children: [
            KeyedSubtree(key: flight._slot, child: shown(scope.avatar(_headerSize))),
            Flexible(child: shown(FrostText(name, content: true, maxLines: 1, overflow: TextOverflow.ellipsis))),
          ],
        );
      },
    );
  }
}
