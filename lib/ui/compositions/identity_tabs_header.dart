import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// The head of a profile page as the first sliver
/// of a [NestedScrollView]: the chrome's inset, the identity, then [tabs] on
/// glass. Scrolling takes the identity away under the chrome; the tabs stay
/// pinned below it. [overlap] carries the pinned part to each tab's
/// SliverOverlapInjector.
///
/// The header is one pinned persistent header whose extent follows the
/// measured identity and tabs, so the page scrolls exactly the identity's
/// height before the tabs pin.
class AppIdentityTabsHeader extends StatefulWidget {
  const AppIdentityTabsHeader({required this.overlap, required this.identity, required this.tabs, super.key});

  final SliverOverlapAbsorberHandle overlap;

  /// Laid out at the content column's full width.
  final Widget identity;

  /// Usually a FrostTabBar.
  final Widget tabs;

  @override
  State<AppIdentityTabsHeader> createState() => _AppIdentityTabsHeaderState();
}

class _AppIdentityTabsHeaderState extends State<AppIdentityTabsHeader> {
  double _identity = 0;
  double _tabs = 0;

  void _measured(double identity, double tabs) {
    if (identity == _identity && tabs == _tabs) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _identity = identity;
        _tabs = tabs;
      });
    });
  }

  @override
  Widget build(BuildContext context) => SliverOverlapAbsorber(
    handle: widget.overlap,
    sliver: SliverPersistentHeader(
      pinned: true,
      delegate: _Delegate(
        inset: MediaQuery.paddingOf(context).top,
        identityExtent: _identity,
        tabsExtent: _tabs,
        identity: widget.identity,
        tabs: widget.tabs,
        onMeasured: _measured,
      ),
    ),
  );
}

class _Delegate extends SliverPersistentHeaderDelegate {
  _Delegate({
    required this.inset,
    required this.identityExtent,
    required this.tabsExtent,
    required this.identity,
    required this.tabs,
    required this.onMeasured,
  });

  final double inset, identityExtent, tabsExtent;
  final Widget identity, tabs;
  final void Function(double identity, double tabs) onMeasured;

  @override
  double get minExtent => inset + tabsExtent;

  @override
  double get maxExtent => inset + identityExtent + tabsExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => _HeaderLayout(
    inset: inset,
    shrink: math.min(shrinkOffset, identityExtent),
    onMeasured: onMeasured,
    children: [
      FrostContentColumn(maxWidth: double.infinity, child: identity),
      FrostPinnedChromeGlass(
        opacity: 1,
        corners: FrostPinnedChromeCorners.bottom,
        child: FrostContentColumn(maxWidth: double.infinity, child: tabs),
      ),
    ],
  );

  @override
  bool shouldRebuild(_Delegate oldDelegate) => true;
}

/// Lays the identity below [inset], moved up by [shrink], and the tabs right
/// after it; reports both natural heights. Clips to the header's own extent.
class _HeaderLayout extends MultiChildRenderObjectWidget {
  const _HeaderLayout({required this.inset, required this.shrink, required this.onMeasured, required super.children});

  final double inset, shrink;
  final void Function(double identity, double tabs) onMeasured;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHeaderLayout(inset, shrink, onMeasured);

  @override
  void updateRenderObject(BuildContext context, _RenderHeaderLayout renderObject) => renderObject
    ..inset = inset
    ..shrink = shrink
    ..onMeasured = onMeasured;
}

class _HeaderParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderHeaderLayout extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _HeaderParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _HeaderParentData> {
  _RenderHeaderLayout(this._inset, this._shrink, this.onMeasured);

  double _inset, _shrink;
  void Function(double identity, double tabs) onMeasured;

  set inset(double value) {
    if (value == _inset) return;
    _inset = value;
    markNeedsLayout();
  }

  set shrink(double value) {
    if (value == _shrink) return;
    _shrink = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HeaderParentData) child.parentData = _HeaderParentData();
  }

  @override
  void performLayout() {
    final identity = firstChild!, tabs = childAfter(identity)!;
    final width = BoxConstraints.tightFor(width: constraints.maxWidth);
    identity.layout(width, parentUsesSize: true);
    tabs.layout(width, parentUsesSize: true);
    size = constraints.biggest;
    // The tabs sit after the identity until they reach the bottom of the
    // header, where they stay while the identity slides away under the inset.
    final tabsTop = math.min(_inset + identity.size.height - _shrink, size.height - tabs.size.height);
    (identity.parentData! as _HeaderParentData).offset = Offset(0, tabsTop - identity.size.height);
    (tabs.parentData! as _HeaderParentData).offset = Offset(0, tabsTop);
    onMeasured(identity.size.height, tabs.size.height);
  }

  final _clip = LayerHandle<ClipRectLayer>();

  @override
  void paint(PaintingContext context, Offset offset) {
    _clip.layer = context.pushClipRect(needsCompositing, offset, Offset.zero & size, defaultPaint, oldLayer: _clip.layer);
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}
