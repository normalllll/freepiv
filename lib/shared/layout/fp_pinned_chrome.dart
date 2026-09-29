import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/ui/fp_ambient_backdrop.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';

/// A bar pinned over the top of a scrolling body. The body scrolls beneath
/// the bar, and the bar's glass material appears once content is actually
/// underneath it, so a page at rest keeps one continuous backdrop.
///
/// The body receives the bar's height as its top [MediaQuery] padding, which
/// insets the scrollbar; scroll views add [FpChromeSpacer] as their first
/// sliver so the first item starts below the bar.
class FpPinnedChrome extends StatefulWidget {
  const FpPinnedChrome({required this.chrome, required this.body, this.extent, this.estimatedExtent = kToolbarHeight, super.key});

  /// Fixed height of the bar, including any top safe area it covers. When
  /// null the bar is measured, starting from [estimatedExtent].
  final double? extent;
  final double estimatedExtent;
  final Widget chrome;
  final Widget body;

  @override
  State<FpPinnedChrome> createState() => _FpPinnedChromeState();
}

class _FpPinnedChromeState extends State<FpPinnedChrome> {
  /// How much of the glass is showing: it follows the first [_revealDistance]
  /// of scrolling, so the bar stops wherever the finger stops instead of
  /// snapping in at a threshold (docs/MOTION_SPEC.md 6).
  double _coverage = 0;
  double? _measured;

  static const _revealDistance = 24.0;

  bool _handleScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return false;
    final coverage = (metrics.extentBefore / _revealDistance).clamp(0.0, 1.0);
    if (coverage != _coverage) setState(() => _coverage = coverage);
    return false;
  }

  void _handleChromeSize(Size size) {
    if (widget.extent != null || size.height == _measured) return;
    // Layout cannot rebuild the body; apply the new inset on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && size.height != _measured) setState(() => _measured = size.height);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final extent = widget.extent ?? _measured ?? widget.estimatedExtent;
    return Stack(
      children: [
        MediaQuery(
          data: media.copyWith(
            padding: media.padding.copyWith(top: extent),
            viewPadding: media.viewPadding.copyWith(top: extent),
          ),
          // Until the bar is measured the body would sit at the estimated
          // inset and then shift; keep it invisible for that one frame so it
          // first appears at its final position.
          child: Opacity(
            opacity: widget.extent != null || _measured != null ? 1 : 0,
            child: NotificationListener<ScrollNotification>(onNotification: _handleScroll, child: widget.body),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: widget.extent,
          child: _SizeReporter(
            onSize: _handleChromeSize,
            child: PinnedChromeGlass(
              opacity: _coverage,
              // The value already follows the scroll position frame by frame.
              animate: false,
              child: widget.extent != null ? SizedBox.expand(child: widget.chrome) : widget.chrome,
            ),
          ),
        ),
      ],
    );
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter renderObject) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;

  @override
  void performLayout() {
    super.performLayout();
    onSize(size);
  }
}

/// First sliver of a scroll view under [FpPinnedChrome].
class FpChromeSpacer extends StatelessWidget {
  const FpChromeSpacer({super.key});

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).top));
}

/// A page's refresh header preceded by [FpChromeSpacer], for bodies that
/// take a single leading sliver.
Widget chromeSliverHeader(Widget? header) => SliverMainAxisGroup(slivers: [const FpChromeSpacer(), ?header]);

/// Which outer corners a [PinnedChromeGlass] rounds. Bars that are pinned
/// directly above one another share one outline: the upper one rounds its
/// top corners, the lower one its bottom corners.
enum PinnedChromeCorners { all, top, bottom }

/// The glass behind a pinned bar, shown while content passes beneath it,
/// with the bar's own content as [child].
///
/// With the floating desktop sidebar the bar floats the same way: rounded,
/// and inset so it sits the sidebar's margin away from both the sidebar and
/// the window edge. The bar's content keeps its full-width layout but is
/// clipped to the glass shape, so hover highlights never spill past the
/// rounded corners; outside the shape the window background covers whatever
/// scrolls beneath, so no sliver of content shows around the panel.
/// Compact layouts keep an edge-to-edge bar under the status bar.
class PinnedChromeGlass extends StatelessWidget {
  const PinnedChromeGlass({required this.opacity, this.child, this.animate = true, this.corners = PinnedChromeCorners.all, super.key});

  final double opacity;
  final Widget? child;

  /// Ease [opacity] changes; pass false when it already follows scrolling.
  final bool animate;
  final PinnedChromeCorners corners;

  /// Gap between floating panels and between a panel and the window edge.
  static const floatingMargin = 8.0;

  /// The page already starts this far to the right of the sidebar.
  static const _sidebarGutter = 4.0;

  static const _insets = EdgeInsetsDirectional.only(start: floatingMargin - _sidebarGutter, end: floatingMargin);

  /// How far the glass sits inside the bar's edges: the floating margins on
  /// desktop, none on compact edge-to-edge bars. Content anchored to the
  /// bar's ends (a back or action button, a title) adds this to its usual
  /// inset so it keeps the same distance from the glass edge as it would
  /// from a screen edge. Rows already on the content column need nothing.
  static EdgeInsetsDirectional insetsOf(BuildContext context) => AutoScaffold.usesHorizontalLayoutOf(context) ? _insets : EdgeInsetsDirectional.zero;

  BorderRadius get _radius {
    const radius = Radius.circular(AppMetrics.groupRadius + 4);
    return switch (corners) {
      PinnedChromeCorners.all => const BorderRadius.all(radius),
      PinnedChromeCorners.top => const BorderRadius.vertical(top: radius),
      PinnedChromeCorners.bottom => const BorderRadius.vertical(bottom: radius),
    };
  }

  @override
  Widget build(BuildContext context) {
    final floating = AutoScaffold.usesHorizontalLayoutOf(context);
    final Widget material;
    if (floating) {
      final shape = _InsetShape(insets: _insets.resolve(Directionality.of(context)), borderRadius: _radius);
      material = Stack(
        fit: StackFit.expand,
        children: [
          // Window background around the panel, so content scrolling under
          // the bar does not peek through the margins and corner cut-outs.
          ClipPath(clipper: shape.outside(), child: const FpAmbientBackdrop()),
          Padding(
            padding: _insets,
            child: FpSurface(
              role: FpSurfaceRole.chrome,
              borderRadius: _radius,
              join: switch (corners) {
                PinnedChromeCorners.all => FpSurfaceJoin.none,
                PinnedChromeCorners.top => FpSurfaceJoin.below,
                PinnedChromeCorners.bottom => FpSurfaceJoin.above,
              },
              child: const SizedBox.expand(),
            ),
          ),
        ],
      );
      final layer = IgnorePointer(
        child: animate
            ? AnimatedOpacity(opacity: opacity, duration: AppMotion.duration(context, AppMotion.hover), child: material)
            : Opacity(opacity: opacity, child: material),
      );
      return Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: layer),
          if (child case final child?) ClipPath(clipper: shape, child: child),
        ],
      );
    }
    material = const FpSurface(
      role: FpSurfaceRole.chrome,
      borderRadius: BorderRadius.zero,
      edge: FpSurfaceEdge.none,
      elevated: false,
      child: SizedBox.expand(),
    );
    final layer = IgnorePointer(
      child: animate
          ? AnimatedOpacity(opacity: opacity, duration: AppMotion.duration(context, AppMotion.hover), child: material)
          : Opacity(opacity: opacity, child: material),
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(child: layer),
        ?child,
      ],
    );
  }
}

/// The floating glass shape: the bar's rect inset by [insets], rounded by
/// [borderRadius]. [outside] clips to everything in the bar except it.
class _InsetShape extends CustomClipper<Path> {
  const _InsetShape({required this.insets, required this.borderRadius, this.inverse = false});

  final EdgeInsets insets;
  final BorderRadius borderRadius;
  final bool inverse;

  _InsetShape outside() => _InsetShape(insets: insets, borderRadius: borderRadius, inverse: true);

  @override
  Path getClip(Size size) {
    final panel = Path()..addRRect(borderRadius.toRRect(insets.deflateRect(Offset.zero & size)));
    if (!inverse) return panel;
    return Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), panel);
  }

  @override
  bool shouldReclip(_InsetShape oldClipper) => insets != oldClipper.insets || borderRadius != oldClipper.borderRadius || inverse != oldClipper.inverse;
}
