import 'package:freepiv/features/novel/domain/novel_text_parser.dart';

/// A chapter of the text: where its blocks start in the flat list and its
/// title, when the text names one.
class ReaderChapter {
  const ReaderChapter({required this.index, required this.firstBlock, required this.title, required this.startOffset});

  final int index;
  final int firstBlock;
  final String? title;

  /// Characters of the text before it.
  final int startOffset;
}

/// The whole text as one list of blocks read top to bottom,
/// divided into chapters: at each `[chapter:]` marker, or
/// where the text has none, at each `[newpage]`. A text without either is
/// one chapter.
class ReaderModel {
  ReaderModel._(this.blocks, this.chapters, this._offsets, this.totalCharacters);

  factory ReaderModel(List<NovelTextBlock> parsed) {
    final blocks = <NovelTextBlock>[];
    final chapters = <ReaderChapter>[];
    final offsets = <int>[];
    final byChapter = parsed.any((block) => block is NovelTextChapter);
    var characters = 0;
    void startChapter(String? title) => chapters.add(ReaderChapter(index: chapters.length, firstBlock: blocks.length, title: title, startOffset: characters));
    for (final block in parsed) {
      switch (block) {
        case NovelTextChapter(:final title) when byChapter:
          startChapter(title);
        case NovelTextPageBreak() when !byChapter:
          if (blocks.isEmpty) continue;
          startChapter(null);
          blocks.add(block);
          offsets.add(characters);
          continue;
        case _:
          break;
      }
      if (chapters.isEmpty) startChapter(null);
      blocks.add(block);
      offsets.add(characters);
      characters += novelTextBlockCharacterCount(block);
    }
    return ReaderModel._(blocks, chapters, offsets, characters);
  }

  final List<NovelTextBlock> blocks;
  final List<ReaderChapter> chapters;
  final List<int> _offsets;
  final int totalCharacters;

  bool get isEmpty => blocks.isEmpty;

  /// Characters of the text before [block].
  int offsetOf(int block) => block < 0 || _offsets.isEmpty ? 0 : (block >= _offsets.length ? totalCharacters : _offsets[block]);

  /// The block holding character [offset].
  int blockAtOffset(int offset) {
    for (var index = _offsets.length - 1; index >= 0; index--) {
      if (_offsets[index] <= offset) return index;
    }
    return 0;
  }

  /// The chapter [block] is in.
  ReaderChapter chapterOf(int block) {
    for (var index = chapters.length - 1; index >= 0; index--) {
      if (chapters[index].firstBlock <= block) return chapters[index];
    }
    return chapters.first;
  }
}
