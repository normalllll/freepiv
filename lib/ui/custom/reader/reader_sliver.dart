// app-owned: novel reader scroll layout
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';

/// A [SliverVariedExtentList] whose offsets come from the layout's prefix
/// sums instead of walking every block, and which measures the blocks it is
/// about to show before laying them out.
class ReaderSliver extends SliverVariedExtentList {
  ReaderSliver({required this.layout, required IndexedWidgetBuilder itemBuilder, super.key})
    : super.builder(
        itemCount: layout.blockCount,
        itemExtentBuilder: (index, _) => index < layout.blockCount ? layout.extentOf(index) : null,
        itemBuilder: itemBuilder,
        addAutomaticKeepAlives: false,
      );

  final ReaderLayout layout;

  @override
  RenderSliverVariedExtentList createRenderObject(BuildContext context) =>
      _RenderReaderSliver(childManager: context as SliverMultiBoxAdaptorElement, itemExtentBuilder: itemExtentBuilder, layout: layout);

  @override
  void updateRenderObject(BuildContext context, RenderSliverVariedExtentList renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderReaderSliver).readerLayout = layout;
  }
}

class _RenderReaderSliver extends RenderSliverVariedExtentList {
  _RenderReaderSliver({required super.childManager, required super.itemExtentBuilder, required this._layout});

  ReaderLayout _layout;
  bool _inLayout = false;

  set readerLayout(ReaderLayout value) {
    if (identical(value, _layout)) return;
    if (attached) _layout.removeListener(_layoutChanged);
    _layout = value;
    if (attached) _layout.addListener(_layoutChanged);
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _layout.addListener(_layoutChanged);
  }

  @override
  void detach() {
    _layout.removeListener(_layoutChanged);
    super.detach();
  }

  void _layoutChanged() {
    if (!_inLayout) markNeedsLayout();
  }

  @override
  double indexToLayoutOffset(double itemExtent, int index) => _layout.topOf(index.clamp(0, _layout.blockCount));

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset, double itemExtent) => scrollOffset <= 0 ? 0 : _layout.blockAtPixel(scrollOffset);

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) => scrollOffset <= 0 ? 0 : _layout.blockAtPixel(scrollOffset);

  @override
  double computeMaxScrollOffset(SliverConstraints constraints, double itemExtent) => _layout.totalExtent;

  @override
  double estimateMaxScrollOffset(SliverConstraints constraints, {int? firstIndex, int? lastIndex, double? leadingScrollOffset, double? trailingScrollOffset}) =>
      _layout.totalExtent;

  @override
  void performLayout() {
    _inLayout = true;
    try {
      final correction = _measureVisible();
      if (correction != 0) {
        geometry = SliverGeometry(scrollOffsetCorrection: correction);
        return;
      }
      super.performLayout();
    } finally {
      _inLayout = false;
    }
  }

  /// Measures the blocks about to be shown. Blocks wholly above the reading
  /// line move it when they change; that move comes back as a correction, so
  /// the reading line keeps its text.
  double _measureVisible() {
    final layout = _layout;
    if (layout.blockCount == 0) return 0;
    final readingLine = constraints.scrollOffset;
    final start = math.max(0.0, readingLine + constraints.cacheOrigin);
    final end = readingLine + constraints.cacheOrigin + constraints.remainingCacheExtent;
    var correction = 0.0;
    for (var block = layout.blockAtPixel(start); block < layout.blockCount && layout.topOf(block) < end + correction; block++) {
      if (layout.isMeasured(block)) continue;
      final top = layout.topOf(block);
      final before = layout.extentOf(block);
      layout.metricsOf(block);
      if (top + before <= readingLine + correction) correction += layout.extentOf(block) - before;
    }
    return correction;
  }
}
