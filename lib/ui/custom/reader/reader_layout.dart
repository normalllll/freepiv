// app-owned: novel reader text
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/ui/custom/reader/reader_line_text.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';

/// How the text is read: one continuous scroll, or turned page by page.
enum ReaderFlow { scroll, paged }

/// One visual line of a text block: [top] is relative to the block's content
/// top (below its top gap); the offsets are the model characters it shows.
@immutable
class ReaderLineBox {
  const ReaderLineBox({required this.top, required this.height, required this.startOffset, required this.endOffset});

  final double top;
  final double height;
  final int startOffset;

  /// Exclusive.
  final int endOffset;
}

/// The space a block takes and, for text, where its visual lines are.
@immutable
class ReaderBlockMetrics {
  const ReaderBlockMetrics({required this.extent, required this.topGap, required this.bottomGap, this.lines = const []});

  /// Everything the block takes, gaps included.
  final double extent;

  /// Space above the content: the chapter gap or the author's blank lines.
  final double topGap;

  /// The paragraph gap below the content.
  final double bottomGap;

  /// Visual lines of a line or title block; empty for other blocks.
  final List<ReaderLineBox> lines;
}

/// Prefix sums of block extents with O(log n) update, query and search.
class _ExtentTree {
  _ExtentTree(List<double> values) : _tree = List<double>.filled(values.length + 1, 0) {
    for (var i = 0; i < values.length; i++) {
      _tree[i + 1] += values[i];
      final parent = (i + 1) + ((i + 1) & -(i + 1));
      if (parent < _tree.length) _tree[parent] += _tree[i + 1];
    }
  }

  final List<double> _tree;

  int get length => _tree.length - 1;

  void add(int index, double delta) {
    for (var i = index + 1; i < _tree.length; i += i & -i) {
      _tree[i] += delta;
    }
  }

  /// Sum of the values before [index].
  double prefix(int index) {
    var sum = 0.0;
    for (var i = math.min(index, length); i > 0; i -= i & -i) {
      sum += _tree[i];
    }
    return sum;
  }

  /// The first index whose running sum (itself included) exceeds [y], or
  /// [length] when none does.
  int search(double y) {
    var position = 0;
    var remaining = y;
    var step = 1;
    while (step * 2 <= length) {
      step *= 2;
    }
    for (; step > 0; step >>= 1) {
      final next = position + step;
      if (next <= length && _tree[next] <= remaining) {
        position = next;
        remaining -= _tree[next];
      }
    }
    return position;
  }
}

/// Vertical layout of a whole text for one typesetting and width: the extent
/// of every block, measured or estimated, and the map between model offsets
/// and pixels.
///
/// Text blocks start as estimates and become exact as they are measured;
/// images take their size from the [ImageSizeStore] at once. Any change of
/// typesetting or width means a new layout.
class ReaderLayout extends ChangeNotifier {
  ReaderLayout({
    required this.model,
    required this.typesetting,
    required this.width,
    required this.flow,
    required this._sizes,
    required this.viewportHeight,
    required this._pageJumpLabel,
  }) : columnWidth = typesetting.columnWidth(width) {
    final count = model.blocks.length;
    _extents = List<double>.filled(count, 0);
    _lineTexts = List<ReaderLineText?>.filled(count, null);
    _metrics = List<ReaderBlockMetrics?>.filled(count, null);
    _imageSizes = List<Size?>.filled(count, null);
    for (var i = 0; i < count; i++) {
      final block = model.blocks[i];
      if (block is NovelLine || block is NovelChapterTitle) {
        _unmeasured++;
        _extents[i] = _estimate(i, block);
      } else {
        _metrics[i] = _fixedMetrics(i, block);
        _extents[i] = _metrics[i]!.extent;
      }
    }
    _tree = _ExtentTree(_extents);
  }

  final ReaderModel model;
  final ReaderTypesetting typesetting;

  /// The available width; the text column is [columnWidth].
  final double width;
  final ReaderFlow flow;
  final double viewportHeight;
  final double columnWidth;
  final ImageSizeStore _sizes;
  final String Function(int page) _pageJumpLabel;

  late final List<double> _extents;
  late final List<ReaderLineText?> _lineTexts;
  late final List<ReaderBlockMetrics?> _metrics;

  /// Sizes reported for images, which win over the store.
  late final List<Size?> _imageSizes;
  late final _ExtentTree _tree;
  int _unmeasured = 0;

  /// The measuring order for the last anchor asked about.
  _MeasuringOrder? _order;

  int get blockCount => _extents.length;

  /// Measured or estimated, including the gaps that belong to the block.
  double extentOf(int block) => _extents[block];

  /// Always true for blocks that are not lines or titles.
  bool isMeasured(int block) => _metrics[block] != null;

  double topOf(int block) => _tree.prefix(block);

  double get totalExtent => _tree.prefix(blockCount);

  /// The block holding pixel [y]; clamps to the first and last block.
  ///
  /// The tree's search subtracts from [y] in another order than [topOf] adds,
  /// so at a block's exact top the two can round apart; the result is settled
  /// against [topOf], which [pixelOfOffset] uses, so a pixel it returns maps
  /// back to its own block.
  int blockAtPixel(double y) {
    if (blockCount == 0) return 0;
    if (y < 0) return 0;
    var block = math.min(_tree.search(y), blockCount - 1);
    while (block + 1 < blockCount && topOf(block + 1) <= y) {
      block++;
    }
    while (block > 0 && topOf(block) > y) {
      block--;
    }
    return block;
  }

  /// The text of a measured line or title block.
  ReaderLineText? lineTextOf(int block) => _metrics[block] == null ? null : _lineTexts[block];

  /// Measures [block] first when it is not measured yet.
  ReaderBlockMetrics metricsOf(int block) => _metrics[block] ?? _measure(block);

  /// The top of the visual line holding [offset]; measures that block.
  double pixelOfOffset(int offset) {
    if (blockCount == 0) return 0;
    final at = offset.clamp(0, model.totalLength);
    final block = model.blockAt(at);
    final metrics = metricsOf(block);
    final top = topOf(block) + metrics.topGap;
    final lines = metrics.lines;
    if (lines.isEmpty) return top;
    return top + lines[_lineAt(lines, at)].top;
  }

  /// The model offset of the first character of the visual line at [y].
  int offsetAtPixel(double y) {
    if (blockCount == 0) return 0;
    final block = blockAtPixel(y);
    // Measuring a block moves only the blocks below it.
    final metrics = metricsOf(block);
    // Line tops summed exactly as pixelOfOffset sums them, so its pixels map
    // back to their own lines.
    final top = topOf(block) + metrics.topGap;
    final lines = metrics.lines;
    if (y < top || lines.isEmpty) return model.offsetOf(block);
    var found = 0;
    for (var i = 1; i < lines.length; i++) {
      if (top + lines[i].top > y) break;
      found = i;
    }
    return lines[found].startOffset;
  }

  /// Measures blocks outward from [anchorBlock], its chapter first, until
  /// [budget] runs out (always at least one). True when everything is measured.
  bool measureSome(int anchorBlock, Duration budget) {
    if (_unmeasured == 0) return true;
    final order = _measuringOrder(anchorBlock);
    final watch = Stopwatch()..start();
    var measured = false;
    for (var block = order.next(); block != null; block = order.next()) {
      if (_metrics[block] != null) continue;
      _measure(block, notify: false);
      measured = true;
      if (watch.elapsed >= budget) break;
    }
    if (measured) notifyListeners();
    return _unmeasured == 0;
  }

  /// Records an image's real size (also into the store) and returns how far
  /// the top of [anchorBlock] moved.
  double updateImageSize(int block, Size size, {required int anchorBlock}) {
    final source = model.blocks[block];
    if (source is! NovelUploadedImage) return 0;
    // Same rule as the store: an unusable size would poison the extents.
    if (!size.width.isFinite || !size.height.isFinite || size.width <= 0 || size.height <= 0) return 0;
    final url = source.image == null ? null : novelTextImageUrl(source.image!);
    if (url != null) _sizes.record(url, size);
    _imageSizes[block] = size;
    final metrics = _fixedMetrics(block, source);
    _metrics[block] = metrics;
    final delta = metrics.extent - _extents[block];
    if (delta == 0) return 0;
    _setExtent(block, metrics.extent);
    notifyListeners();
    return block < anchorBlock ? delta : 0;
  }

  void _setExtent(int block, double extent) {
    final delta = extent - _extents[block];
    if (delta == 0) return;
    _extents[block] = extent;
    _tree.add(block, delta);
  }

  /// The index of the line of [lines] holding absolute [offset].
  static int _lineAt(List<ReaderLineBox> lines, int offset) {
    var low = 0;
    var high = lines.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (lines[mid].startOffset <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  double _topGapOf(int index, NovelBlock block) => switch (block) {
    // One blank line is the ordinary paragraph break; each further one adds a line.
    NovelLine(:final blankLinesBefore) => math.min(math.max(blankLinesBefore - 1, 0), 3) * typesetting.blankLinePx,
    NovelChapterTitle() => index == 0 ? 0 : typesetting.chapterTopGap,
    _ => 0,
  };

  /// A piece followed by the rest of its line has no gap below.
  double _bottomGapOf(int index, NovelBlock block) => switch (block) {
    NovelChapterTitle() => typesetting.chapterBottomGap,
    NovelPageBreak() => 0,
    NovelLine() when model.isContinuedBy(index) => 0,
    _ => typesetting.paragraphGap,
  };

  /// Whole lines of glyphs of the body (or title) size across the column.
  double _estimate(int index, NovelBlock block) {
    final scaled = typesetting.textScaler.scale(typesetting.textSize);
    final column = math.max(1.0, columnWidth);
    final (int length, double glyph, double linePx) = switch (block) {
      NovelChapterTitle(:final title) => (
        title.length,
        scaled * ReaderTypesetting.chapterScale,
        scaled * ReaderTypesetting.chapterScale * ReaderTypesetting.chapterLineHeight,
      ),
      NovelLine() => (_renderedLengthOf(index, block), scaled, typesetting.bodyLinePx),
      _ => (0, 0.0, 0.0),
    };
    final lines = math.max(1, (length * glyph / column).ceil());
    return _topGapOf(index, block) + lines * linePx + _bottomGapOf(index, block);
  }

  int _renderedLengthOf(int index, NovelLine line) {
    var length = typesetting.indent && !line.authorIndented && !model.continues(index) ? 1 : 0;
    for (final span in line.spans) {
      length += switch (span) {
        NovelPageJump(:final page) => _pageJumpLabel(page).length,
        _ => span.length,
      };
    }
    return length;
  }

  /// Metrics of a block that is not text; known without measuring.
  ReaderBlockMetrics _fixedMetrics(int index, NovelBlock block) {
    final gap = typesetting.paragraphGap;
    return switch (block) {
      NovelPageBreak() => ReaderBlockMetrics(extent: flow == ReaderFlow.paged ? 0 : typesetting.pageBreakExtent, topGap: 0, bottomGap: 0),
      NovelUploadedImage() => ReaderBlockMetrics(extent: _imageHeight(index, block) + gap, topGap: 0, bottomGap: gap),
      NovelEmbeddedWork() => ReaderBlockMetrics(extent: typesetting.embeddedWorkExtent + gap, topGap: 0, bottomGap: gap),
      NovelLine() || NovelChapterTitle() => throw ArgumentError.value(block, 'block', 'text blocks are measured'),
    };
  }

  /// The column wide at the image's ratio; capped below the viewport when scrolling.
  double _imageHeight(int index, NovelUploadedImage block) {
    final url = block.image == null ? null : novelTextImageUrl(block.image!);
    final size = _imageSizes[index] ?? (url == null ? null : _sizes.sizeOf(url)) ?? novelImageFallbackSize;
    final height = columnWidth * size.height / size.width;
    return flow == ReaderFlow.scroll ? math.min(height, viewportHeight * 0.9) : height;
  }

  ReaderBlockMetrics _measure(int index, {bool notify = true}) {
    final block = model.blocks[index];
    final text = switch (block) {
      NovelLine() => ReaderLineText.line(block, typesetting, pageJumpLabel: _pageJumpLabel, continuation: model.continues(index)),
      NovelChapterTitle(:final title) => ReaderLineText.title(title, typesetting),
      _ => null,
    };
    if (text == null) return _metrics[index] ??= _fixedMetrics(index, block);
    final painter = text.painter(columnWidth);
    final start = model.offsetOf(index);
    final lines = [
      for (final line in text.linesOf(painter)) ReaderLineBox(top: line.top, height: line.height, startOffset: start + line.start, endOffset: start + line.end),
    ];
    final height = painter.height;
    painter.dispose();
    final topGap = _topGapOf(index, block);
    final bottomGap = _bottomGapOf(index, block);
    final metrics = ReaderBlockMetrics(extent: topGap + height + bottomGap, topGap: topGap, bottomGap: bottomGap, lines: List.unmodifiable(lines));
    _metrics[index] = metrics;
    _lineTexts[index] = text;
    _unmeasured--;
    _setExtent(index, metrics.extent);
    if (notify) notifyListeners();
    return metrics;
  }

  /// The anchor's chapter outward from the anchor, then the rest of the text
  /// outward from that chapter. Kept while the anchor stays.
  _MeasuringOrder _measuringOrder(int anchorBlock) {
    final anchor = math.max(0, math.min(anchorBlock, blockCount - 1));
    if (_order case final order? when order.anchor == anchor) return order;
    final chapters = model.chapters;
    var chapterStart = 0;
    var chapterEnd = blockCount;
    for (var c = 0; c < chapters.length; c++) {
      if (chapters[c].firstBlock > anchor) break;
      chapterStart = chapters[c].firstBlock;
      chapterEnd = c + 1 < chapters.length ? chapters[c + 1].firstBlock : blockCount;
    }
    return _order = _MeasuringOrder(anchor, chapterStart, chapterEnd, blockCount);
  }
}

/// Blocks outward from [anchor], generated as they are asked for: first
/// within the chapter `[chapterStart, chapterEnd)`, alternating after and
/// before the anchor, then the rest of the text alternating after and before
/// the chapter.
class _MeasuringOrder {
  _MeasuringOrder(this.anchor, this.chapterStart, this.chapterEnd, this.blockCount) : _after = anchor, _before = anchor - 1;

  final int anchor;
  final int chapterStart;
  final int chapterEnd;
  final int blockCount;
  int _after;
  int _before;
  bool _inChapter = true;
  bool _afterNext = true;

  /// The next block, or null when every block has been given.
  int? next() {
    while (true) {
      final low = _inChapter ? chapterStart : 0;
      final high = _inChapter ? chapterEnd : blockCount;
      final canAfter = _after < high;
      final canBefore = _before >= low;
      if (!canAfter && !canBefore) {
        if (!_inChapter) return null;
        _inChapter = false;
        _after = chapterEnd;
        _before = chapterStart - 1;
        _afterNext = true;
        continue;
      }
      final takeAfter = canAfter && (_afterNext || !canBefore);
      _afterNext = !takeAfter;
      return takeAfter ? _after++ : _before--;
    }
  }
}
