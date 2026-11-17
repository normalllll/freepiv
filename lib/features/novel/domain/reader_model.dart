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
  ReaderModel._(this.blocks, this.chapters, this._offsets, this.totalLength, this._solid, this._breaks, this.imageBlocks, this._continuations);

  /// A line longer than this many characters is laid out in pieces.
  static const longLine = 4000;

  /// A piece is cut at a sentence end once it holds at least [pieceMin]
  /// characters, and at a character boundary at [pieceMax] when there was none.
  static const pieceMin = 1200;
  static const pieceMax = 2400;

  factory ReaderModel(List<NovelBlock> parsed) {
    final (blocks, continuations) = _inPieces(parsed);
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
    final titles = [
      for (var i = 0; i < blocks.length; i++)
        if (blocks[i] is NovelChapterTitle) i,
    ];
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
    return ReaderModel._(List.unmodifiable(blocks), chapters, offsets, total, solid, breaks, List.unmodifiable(images), continuations);
  }

  /// [parsed] with each line longer than [longLine] cut into consecutive
  /// pieces, and the indices of the pieces that continue the one before. A
  /// piece ends at a sentence end, else at a character boundary that is not
  /// inside a ruby, a link or a page jump. The pieces hold the line's
  /// characters in order, so offsets are the line's own.
  static (List<NovelBlock>, Set<int>) _inPieces(List<NovelBlock> parsed) {
    if (!parsed.any((block) => block is NovelLine && block.length > longLine)) return (parsed, const {});
    final blocks = <NovelBlock>[];
    final continuations = <int>{};
    for (final block in parsed) {
      if (block is! NovelLine || block.length <= longLine) {
        blocks.add(block);
        continue;
      }
      final pieces = _cutLine(block.spans);
      for (var i = 0; i < pieces.length; i++) {
        if (i > 0) continuations.add(blocks.length);
        blocks.add(i == 0 ? NovelLine(pieces[i], blankLinesBefore: block.blankLinesBefore, authorIndented: block.authorIndented) : NovelLine(pieces[i]));
      }
    }
    return (blocks, continuations);
  }

  static const _sentenceEnds = '。！？!?…．.';
  static const _closers = "」』）)】〕”’\"'";

  static List<List<NovelInline>> _cutLine(List<NovelInline> spans) {
    // Where the line may be cut: after a sentence end, and at any boundary.
    final sentences = <int>[];
    final boundaries = <int>[];
    var at = 0;
    for (final span in spans) {
      if (span is NovelPlain) {
        final text = span.text;
        for (var i = 0; i < text.length; i++) {
          boundaries.add(at + i);
          if (_sentenceEnds.contains(text[i]) && (i + 1 >= text.length || !(_sentenceEnds.contains(text[i + 1]) || _closers.contains(text[i + 1])))) {
            sentences.add(at + i + 1);
          } else if (_closers.contains(text[i]) && i > 0 && _sentenceEnds.contains(text[i - 1]) && (i + 1 >= text.length || !_closers.contains(text[i + 1]))) {
            sentences.add(at + i + 1);
          }
        }
      } else {
        boundaries.add(at);
      }
      at += span.length;
    }
    final total = at;
    final cuts = <int>[];
    var start = 0;
    var s = 0;
    var b = 0;
    while (total - start > pieceMax) {
      // The last sentence end in [start + pieceMin, start + pieceMax], else the last boundary up to start + pieceMax.
      var cut = -1;
      while (s < sentences.length && sentences[s] <= start + pieceMax) {
        if (sentences[s] >= start + pieceMin) cut = sentences[s];
        s++;
      }
      if (cut < 0) {
        while (b < boundaries.length && boundaries[b] <= start + pieceMax) {
          b++;
        }
        cut = b > 0 ? boundaries[b - 1] : start + pieceMax;
        // A line that is one unbroken ruby or link cannot be cut: take it whole.
        if (cut <= start) {
          cut = boundaries.firstWhere((boundary) => boundary > start, orElse: () => total);
        }
      }
      cuts.add(cut);
      start = cut;
      // Sentence ends at or before the cut belong to the piece before it.
      s = 0;
      while (s < sentences.length && sentences[s] <= cut) {
        s++;
      }
      b = 0;
      while (b < boundaries.length && boundaries[b] <= cut) {
        b++;
      }
    }
    // Slice the spans at the cuts.
    final pieces = <List<NovelInline>>[];
    var current = <NovelInline>[];
    var position = 0;
    var next = 0;
    for (final span in spans) {
      if (span is NovelPlain) {
        var text = span.text;
        while (next < cuts.length && cuts[next] < position + text.length && cuts[next] > position) {
          final local = cuts[next] - position;
          current.add(NovelPlain(text.substring(0, local)));
          pieces.add(current);
          current = [];
          text = text.substring(local);
          position = cuts[next];
          next++;
        }
        if (text.isNotEmpty) current.add(NovelPlain(text));
        position += text.length;
      } else {
        if (next < cuts.length && cuts[next] == position && current.isNotEmpty) {
          pieces.add(current);
          current = [];
          next++;
        }
        current.add(span);
        position += span.length;
      }
      // A cut that falls exactly at the end of this span.
      if (next < cuts.length && cuts[next] == position) {
        pieces.add(current);
        current = [];
        next++;
      }
    }
    if (current.isNotEmpty) pieces.add(current);
    return pieces;
  }

  /// Indices of the blocks that continue the line of the block before them.
  final Set<int> _continuations;

  /// Whether [block] is a piece that continues the line of the block before it.
  bool continues(int block) => _continuations.contains(block);

  /// Whether the block after [block] continues its line.
  bool isContinuedBy(int block) => _continuations.contains(block + 1);

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
