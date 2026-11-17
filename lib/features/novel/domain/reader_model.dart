import 'package:freepiv/features/novel/domain/novel_text.dart';

/// A chapter of the text: where its blocks start in the flat list and the
/// range of characters it covers. [title] is null when the text divides
/// only at `[newpage]` or not at all.
class ReaderChapter {
  const ReaderChapter({required this.index, required this.firstBlock, required this.title, required this.startOffset, required this.endOffset});

  final int index;
  final int firstBlock;
  final String? title;
  final int startOffset;

  /// Exclusive: the next chapter's start, or the length of the text.
  final int endOffset;
}

/// The whole text as one list of blocks, with character offsets, chapters
/// and `[newpage]` sections.
///
/// Chapters divide at each chapter title; a text without titles divides at
/// each page break that follows some content; otherwise it is one chapter.
class ReaderModel {
  ReaderModel._(this.blocks, this.chapters, this._offsets, this.totalLength, this._solid, this._breaks, this.imageBlocks);

  factory ReaderModel(List<NovelBlock> blocks) {
    final offsets = List<int>.filled(blocks.length, 0);
    final solid = <int>[];
    final breaks = <int>[];
    final images = <int>[];
    var total = 0;
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      offsets[i] = total;
      final length = block.length;
      if (length > 0) solid.add(i);
      if (block is NovelPageBreak) breaks.add(i);
      if (block is NovelUploadedImage || block is NovelEmbeddedWork) images.add(i);
      total += length;
    }

    bool hasContent(int from, int to) {
      for (var i = from; i < to; i++) {
        if (blocks[i] is NovelLine || blocks[i] is NovelUploadedImage || blocks[i] is NovelEmbeddedWork) return true;
      }
      return false;
    }

    final starts = <(int, String?)>[];
    final titles = [for (var i = 0; i < blocks.length; i++) if (blocks[i] is NovelChapterTitle) i];
    if (titles.isNotEmpty) {
      if (hasContent(0, titles.first)) starts.add((0, null));
      for (final i in titles) {
        starts.add((i, (blocks[i] as NovelChapterTitle).title));
      }
    } else {
      starts.add((0, null));
      for (final i in breaks) {
        if (hasContent(starts.last.$1, i)) starts.add((i, null));
      }
    }

    final chapters = <ReaderChapter>[
      for (var c = 0; c < starts.length; c++)
        ReaderChapter(
          index: c,
          firstBlock: starts[c].$1,
          title: starts[c].$2,
          startOffset: starts[c].$1 < blocks.length ? offsets[starts[c].$1] : total,
          endOffset: c + 1 < starts.length ? offsets[starts[c + 1].$1] : total,
        ),
    ];
    return ReaderModel._(List.unmodifiable(blocks), chapters, offsets, total, solid, breaks, List.unmodifiable(images));
  }

  /// Every block, as parsed.
  final List<NovelBlock> blocks;
  final List<ReaderChapter> chapters;
  final List<int> _offsets;

  /// Indices of the blocks with a length, ascending.
  final List<int> _solid;

  /// Indices of the page breaks, ascending.
  final List<int> _breaks;

  /// Characters in the text.
  final int totalLength;

  /// Indices of the uploaded images and embedded works, ascending.
  final List<int> imageBlocks;

  /// Characters before [block]; out-of-range blocks clamp to the ends.
  int offsetOf(int block) => block < 0 || _offsets.isEmpty ? 0 : (block >= _offsets.length ? totalLength : _offsets[block]);

  int _clamp(int offset) => offset < 0 ? 0 : (offset > totalLength ? totalLength : offset);

  /// The block holding character [offset]: one with a length, the last of
  /// them at the end of the text. 0 when no block has a length.
  int blockAt(int offset) {
    if (_solid.isEmpty) return 0;
    final at = _clamp(offset);
    if (at >= totalLength) return _solid.last;
    var low = 0;
    var high = _solid.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (_offsets[_solid[mid]] <= at) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return _solid[low];
  }

  /// The last chapter starting at or before [offset].
  ReaderChapter chapterAt(int offset) {
    final at = _clamp(offset);
    var found = chapters.first;
    for (final chapter in chapters) {
      if (chapter.startOffset > at) break;
      found = chapter;
    }
    return found;
  }

  /// Sections of the text, divided at each `[newpage]`, as Pixiv counts them.
  int get pageCount => 1 + _breaks.length;

  /// The 1-based section holding character [offset].
  int pageOf(int offset) {
    final at = _clamp(offset);
    var count = 0;
    for (final index in _breaks) {
      if (_offsets[index] > at) break;
      count++;
    }
    return 1 + count;
  }

  /// Where section [page] starts; [page] clamps to the text's sections.
  int offsetOfPage(int page) {
    final clamped = page < 1 ? 1 : (page > pageCount ? pageCount : page);
    return clamped == 1 ? 0 : _offsets[_breaks[clamped - 2]];
  }
}
