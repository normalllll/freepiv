import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';

/// Native tabs with a spring for click-driven indicator motion. The supplied
/// controller remains the sole owner of content selection and page dragging.
class AppTabBar extends StatefulWidget implements PreferredSizeWidget {
  const AppTabBar({
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.tabAlignment,
    this.dividerColor,
    this.labelPadding,
    this.onTap,
    super.key,
  });

  final List<Widget> tabs;
  final TabController? controller;
  final bool isScrollable;
  final TabAlignment? tabAlignment;
  final Color? dividerColor;
  final EdgeInsetsGeometry? labelPadding;
  final ValueChanged<int>? onTap;

  @override
  Size get preferredSize => TabBar(tabs: tabs).preferredSize;

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar> with TickerProviderStateMixin {
  _IndicatorTabController? _visual;

  void _bindController() {
    final source = widget.controller ?? DefaultTabController.of(context);
    if (_visual?.source != source) {
      _visual?.dispose();
      _visual = _IndicatorTabController(source: source, vsync: this, context: () => context);
    }
    _visual!.reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindController();
  }

  @override
  void didUpdateWidget(AppTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bindController();
  }

  @override
  void dispose() {
    _visual?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TabBar(
    controller: _visual,
    tabs: widget.tabs,
    isScrollable: widget.isScrollable,
    tabAlignment: widget.tabAlignment,
    dividerColor: widget.dividerColor,
    labelPadding: widget.labelPadding,
    onTap: widget.onTap,
    // Let Flutter derive each label's actual bounds, including RTL and
    // horizontal scrolling. Only the progress fed to that geometry changes.
    indicatorAnimation: TabIndicatorAnimation.linear,
  );
}

class _IndicatorTabController extends TabController {
  _IndicatorTabController({required this.source, required super.vsync, required this.context})
    : _motion = AnimationController.unbounded(vsync: vsync, value: source.animation!.value),
      _lastIndex = source.index,
      super(length: source.length, initialIndex: source.index) {
    source.addListener(_selectionChanged);
    source.animation!.addListener(_sourceProgressChanged);
    // A bar can appear while its content controller is already moving (for
    // example after a responsive header rebuild). No new index notification
    // will arrive, so explicitly adopt the in-flight selection's target.
    if (source.indexIsChanging) AppMotion.springTo(context(), _motion, source.index.toDouble(), AppMotion.snappy);
  }

  final TabController source;
  final BuildContext Function() context;
  final AnimationController _motion;
  int _lastIndex;
  bool _dragging = false;
  bool _reduceMotion = false;

  set reduceMotion(bool value) {
    _reduceMotion = value;
    if (value) _motion.value = source.index.toDouble();
  }

  void _selectionChanged() {
    if (_lastIndex != source.index) {
      _lastIndex = source.index;
      if (_dragging && !source.indexIsChanging) {
        _motion.value = source.animation!.value;
      } else {
        _dragging = false;
        AppMotion.springTo(context(), _motion, source.index.toDouble(), AppMotion.snappy);
      }
    }
    notifyListeners();
  }

  void _sourceProgressChanged() {
    if (source.indexIsChanging) return;
    final progress = source.animation!.value;
    // PageView gestures drive this continuously. An index assignment or a
    // zero-duration animateTo is handled by the selection listener instead.
    if (progress != source.index || _dragging) {
      _dragging = progress != source.index;
      _motion.value = _reduceMotion ? source.index.toDouble() : progress;
    }
  }

  @override
  Animation<double> get animation => _motion.view;
  @override
  Duration get animationDuration => source.animationDuration;
  @override
  int get index => source.index;
  @override
  set index(int value) => source.index = value;
  @override
  int get previousIndex => source.previousIndex;
  @override
  bool get indexIsChanging => source.indexIsChanging;
  @override
  double get offset => source.offset;
  @override
  set offset(double value) => source.offset = value;
  @override
  void animateTo(int value, {Duration? duration, Curve curve = Curves.ease}) {
    _dragging = false;
    source.animateTo(value, duration: _reduceMotion ? Duration.zero : duration, curve: curve);
  }

  @override
  void dispose() {
    source.removeListener(_selectionChanged);
    source.animation?.removeListener(_sourceProgressChanged);
    _motion.dispose();
    super.dispose();
  }
}
