// app-owned: novel reader text
import 'package:flutter/foundation.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';

/// A page by its chapter and its index within the chapter.
@immutable
class ReaderPageRef {
  const ReaderPageRef({required this.chapter, required this.index});

  final int chapter;
  final int index;
}

/// One page of a chapter: the model characters `[startOffset, endOffset)`
/// it shows and what it paints, top to bottom.
@immutable
class ReaderPage {
  const ReaderPage({required this.chapter, required this.index, required this.startOffset, required this.endOffset, required this.items});

  final int chapter;
  final int index;
  final int startOffset;
  final int endOffset;
  final List<ReaderPageItem> items;
}

/// Two facing pages; an odd last page stands alone.
@immutable
class ReaderSpread {
  const ReaderSpread({required this.left, this.right});

  final ReaderPage left;
  final ReaderPage? right;
}

/// Something a page paints at [top], [height] tall, from [block].
sealed class ReaderPageItem {
  const ReaderPageItem();

  double get top;
  double get height;
  int get block;
}

/// Lines `[firstLine, firstLine + lineCount)` of a line or title block.
/// [top] is the top of the first shown line.
final class ReaderTextSlice extends ReaderPageItem {
  const ReaderTextSlice({required this.block, required this.top, required this.height, required this.firstLine, required this.lineCount});

  @override
  final int block;
  @override
  final double top;
  @override
  final double height;
  final int firstLine;
  final int lineCount;
}

/// An image or embedded work drawn at [scale] (at most 1); [height] is the
/// scaled content without the paragraph gap.
final class ReaderBlockItem extends ReaderPageItem {
  const ReaderBlockItem({required this.block, required this.top, required this.height, required this.scale});

  @override
  final int block;
  @override
  final double top;
  @override
  final double height;
  final double scale;
}

/// Lays chapters of a paged [ReaderLayout] out on pages [pageHeight] tall.
///
/// A page never splits a visual line; chapters and page breaks start new
/// pages; an image or card that does not fit moves to the next page and one
/// taller than a page is scaled to fit a page of its own. Pages of a chapter
/// are contiguous and cover it.
class ReaderPaginator {
  ReaderPaginator(this.layout, {required this.pageHeight}) : assert(layout.flow == ReaderFlow.paged);

  final ReaderLayout layout;
  final double pageHeight;
  final _pages = <int, List<ReaderPage>>{};
  final _spreads = <int, List<ReaderSpread>>{};

  /// Measures the chapter fully the first time; later calls return the same list.
  List<ReaderPage> pagesOfChapter(int chapter) => _pages[chapter] ??= _paginate(chapter);

  /// Forgets every page, after the layout changed under them (a picture's
  /// size arrived); the next use paginates again.
  void invalidate() {
    _pages.clear();
    _spreads.clear();
  }

  /// The page holding [offset]; the end of the text is on the last page.
  ReaderPageRef pageAt(int offset) {
    final model = layout.model;
    final chapter = model.chapters.isEmpty ? 0 : model.chapterAt(offset).index;
    final pages = pagesOfChapter(chapter);
    var low = 0;
    var high = pages.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (pages[mid].startOffset <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return ReaderPageRef(chapter: chapter, index: low);
  }

  /// Cached like [pagesOfChapter].
  List<ReaderSpread> spreadsOfChapter(int chapter) => _spreads[chapter] ??= List.unmodifiable(_pair(pagesOfChapter(chapter)));

  static List<ReaderSpread> _pair(List<ReaderPage> pages) => [
    for (var i = 0; i < pages.length; i += 2) ReaderSpread(left: pages[i], right: i + 1 < pages.length ? pages[i + 1] : null),
  ];

  (int, int) _blockRange(int chapter) {
    final chapters = layout.model.chapters;
    if (chapters.isEmpty || chapter >= chapters.length) return (0, layout.blockCount);
    final first = chapters[chapter].firstBlock;
    final end = chapter + 1 < chapters.length ? chapters[chapter + 1].firstBlock : layout.blockCount;
    return (first, end);
  }

  List<ReaderPage> _paginate(int chapter) {
    final model = layout.model;
    final (firstBlock, endBlock) = _blockRange(chapter);
    final chapterStart = model.chapters.isEmpty ? 0 : model.chapters[chapter].startOffset;
    final chapterEnd = model.chapters.isEmpty ? model.totalLength : model.chapters[chapter].endOffset;

    final pages = <ReaderPage>[];
    var items = <ReaderPageItem>[];
    var pageStart = chapterStart;
    // Where the next item may start: below the last item and its gap.
    var cursor = 0.0;
    var breakPending = false;
    var lastIsTitle = false;

    void closePage(int nextStart) {
      pages.add(ReaderPage(chapter: chapter, index: pages.length, startOffset: pageStart, endOffset: nextStart, items: List.unmodifiable(items)));
      items = <ReaderPageItem>[];
      pageStart = nextStart;
      cursor = 0;
      lastIsTitle = false;
    }

    /// Honours a pending page break before content starting at [offset].
    void beforeContent(int offset) {
      if (breakPending && items.isNotEmpty && !lastIsTitle) closePage(offset);
      breakPending = false;
    }

    for (var block = firstBlock; block < endBlock; block++) {
      final source = model.blocks[block];
      final metrics = layout.metricsOf(block);
      switch (source) {
        case NovelPageBreak():
          breakPending = true;
        case NovelLine() || NovelChapterTitle():
          final lines = metrics.lines;
          if (lines.isEmpty) continue;
          beforeContent(lines.first.startOffset);
          var first = 0;
          while (first < lines.length) {
            // The top gap belongs above the block's first line, and only
            // when that line does not start a page.
            final gap = first == 0 && items.isNotEmpty ? metrics.topGap : 0.0;
            final top = cursor + gap;
            var count = 0;
            var height = 0.0;
            while (first + count < lines.length && top + height + lines[first + count].height <= pageHeight + 1e-6) {
              height += lines[first + count].height;
              count++;
            }
            if (count == 0 && items.isEmpty) {
              // A line taller than a page still goes on one.
              height = lines[first].height;
              count = 1;
            }
            if (count == 0) {
              closePage(lines[first].startOffset);
              continue;
            }
            items.add(ReaderTextSlice(block: block, top: top, height: height, firstLine: first, lineCount: count));
            lastIsTitle = source is NovelChapterTitle;
            cursor = top + height;
            first += count;
            if (first < lines.length) closePage(lines[first].startOffset);
          }
          cursor += metrics.bottomGap;
        case NovelUploadedImage() || NovelEmbeddedWork():
          final offset = model.offsetOf(block);
          beforeContent(offset);
          final content = metrics.extent - metrics.bottomGap;
          if (content > pageHeight) {
            if (items.isNotEmpty) closePage(offset);
            items.add(ReaderBlockItem(block: block, top: 0, height: pageHeight, scale: pageHeight / content));
            lastIsTitle = false;
            // Nothing shares the page with it.
            cursor = double.infinity;
            continue;
          }
          if (items.isNotEmpty && cursor + content > pageHeight + 1e-6) closePage(offset);
          items.add(ReaderBlockItem(block: block, top: cursor, height: content, scale: 1));
          lastIsTitle = false;
          cursor += content + metrics.bottomGap;
      }
    }
    // A pending page break at the chapter's end starts no page.
    pages.add(ReaderPage(chapter: chapter, index: pages.length, startOffset: pageStart, endOffset: chapterEnd, items: List.unmodifiable(items)));
    return List.unmodifiable(pages);
  }
}
