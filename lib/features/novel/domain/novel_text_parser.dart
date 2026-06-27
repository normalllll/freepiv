sealed class NovelTextBlock {
  const NovelTextBlock();
}

final class NovelTextParagraph extends NovelTextBlock {
  const NovelTextParagraph(this.text);

  final String text;
}

final class NovelTextChapter extends NovelTextBlock {
  const NovelTextChapter(this.title);

  final String title;
}

final class NovelTextPageBreak extends NovelTextBlock {
  const NovelTextPageBreak();
}

final class NovelTextSegment {
  const NovelTextSegment({required this.index, required this.blocks, required this.startOffset, required this.endOffset, required this.chapterTitle});

  final int index;
  final List<NovelTextBlock> blocks;
  final int startOffset;
  final int endOffset;
  final String? chapterTitle;

  int get charCount => endOffset - startOffset;
}

List<NovelTextBlock> parseNovelText(String value) {
  final blocks = <NovelTextBlock>[];
  final paragraph = StringBuffer();
  final lines = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final markerPattern = RegExp(r'\[(chapter|newpage|pixivimage|uploadedimage)(?::([^\]]*))?\]');

  void flushParagraph() {
    final text = paragraph.toString().trimRight();
    paragraph.clear();
    if (text.trim().isNotEmpty) {
      blocks.add(NovelTextParagraph(_normalizeInlineNovelText(text)));
    }
  }

  for (final line in lines) {
    if (line.trim().isEmpty) {
      flushParagraph();
      continue;
    }

    var cursor = 0;
    final matches = markerPattern.allMatches(line).toList();
    if (matches.isEmpty) {
      if (paragraph.isNotEmpty) {
        paragraph.write('\n');
      }
      paragraph.write(line);
      continue;
    }

    for (final match in matches) {
      final before = line.substring(cursor, match.start);
      if (before.trim().isNotEmpty) {
        if (paragraph.isNotEmpty) {
          paragraph.write('\n');
        }
        paragraph.write(before);
      }

      flushParagraph();

      final kind = match.group(1);
      final payload = (match.group(2) ?? '').trim();
      if (kind == 'chapter' && payload.isNotEmpty) {
        blocks.add(NovelTextChapter(payload));
      } else if (kind == 'newpage') {
        blocks.add(const NovelTextPageBreak());
      }

      cursor = match.end;
    }

    final rest = line.substring(cursor);
    if (rest.trim().isNotEmpty) {
      if (paragraph.isNotEmpty) {
        paragraph.write('\n');
      }
      paragraph.write(rest);
    }
  }

  flushParagraph();
  return blocks;
}

List<NovelTextSegment> segmentNovelTextBlocks(List<NovelTextBlock> blocks, {int targetCharacters = 1400, int maxParagraphCharacters = 760}) {
  final target = targetCharacters < 420 ? 420 : targetCharacters;
  final maxParagraph = maxParagraphCharacters < 260 ? 260 : maxParagraphCharacters;
  final segments = <NovelTextSegment>[];
  final currentBlocks = <NovelTextBlock>[];

  var currentCharCount = 0;
  var totalOffset = 0;
  var segmentStartOffset = 0;
  String? activeChapterTitle;
  String? segmentChapterTitle;

  void flushSegment() {
    if (currentBlocks.isEmpty) {
      segmentStartOffset = totalOffset;
      segmentChapterTitle = activeChapterTitle;
      return;
    }

    segments.add(
      NovelTextSegment(
        index: segments.length,
        blocks: List<NovelTextBlock>.unmodifiable(currentBlocks),
        startOffset: segmentStartOffset,
        endOffset: totalOffset,
        chapterTitle: segmentChapterTitle,
      ),
    );
    currentBlocks.clear();
    currentCharCount = 0;
    segmentStartOffset = totalOffset;
    segmentChapterTitle = activeChapterTitle;
  }

  void addBlock(NovelTextBlock block) {
    segmentChapterTitle ??= activeChapterTitle;
    currentBlocks.add(block);
    final blockChars = novelTextBlockCharacterCount(block);
    currentCharCount += blockChars;
    totalOffset += blockChars;
  }

  for (final block in blocks) {
    switch (block) {
      case NovelTextPageBreak():
        flushSegment();
      case NovelTextChapter(:final title):
        if (currentBlocks.isNotEmpty) {
          flushSegment();
        }
        activeChapterTitle = title;
        segmentChapterTitle = title;
        addBlock(block);
      case NovelTextParagraph():
        final paragraphBlocks = _splitLongParagraph(block, maxParagraph);
        for (final paragraphBlock in paragraphBlocks) {
          final blockChars = novelTextBlockCharacterCount(paragraphBlock);
          if (currentBlocks.isNotEmpty && currentCharCount + blockChars > target) {
            flushSegment();
          }
          addBlock(paragraphBlock);
          if (currentCharCount >= target) {
            flushSegment();
          }
        }
    }
  }

  flushSegment();
  return segments;
}

int novelTextBlockCharacterCount(NovelTextBlock block) {
  return switch (block) {
    NovelTextParagraph(:final text) => text.trim().length,
    NovelTextChapter(:final title) => title.trim().length,
    NovelTextPageBreak() => 0,
  };
}

String _normalizeInlineNovelText(String value) {
  return value
      .replaceAllMapped(RegExp(r'\[\[rb:([^\s\]]+)\s*>\s*([^\]]+)\]\]'), (match) => match.group(1) ?? '')
      .replaceAllMapped(RegExp(r'\[\[jumpuri:([^\s\]]+)\s*>\s*([^\]]+)\]\]'), (match) => match.group(2) ?? match.group(1) ?? '')
      .replaceAll(RegExp(r'\[(pixivimage|uploadedimage):[^\]]+\]'), '')
      .trimRight();
}

List<NovelTextParagraph> _splitLongParagraph(NovelTextParagraph block, int maxCharacters) {
  final text = block.text.trimRight();
  if (text.length <= maxCharacters) {
    return [NovelTextParagraph(text)];
  }

  final paragraphs = <NovelTextParagraph>[];
  final buffer = StringBuffer();

  void flush() {
    final value = buffer.toString().trimRight();
    buffer.clear();
    if (value.trim().isNotEmpty) {
      paragraphs.add(NovelTextParagraph(value));
    }
  }

  for (final rune in text.runes) {
    buffer.write(String.fromCharCode(rune));
    final length = buffer.length;
    if (length >= maxCharacters && _isComfortableSplitRune(rune)) {
      flush();
    } else if (length >= maxCharacters + 140) {
      flush();
    }
  }

  flush();
  return paragraphs;
}

bool _isComfortableSplitRune(int rune) {
  return switch (rune) {
    0x0A || // Newline.
    0x2E || // .
    0x21 || // !
    0x3F || // ?
    0x3002 || // 。
    0xFF01 || // ！
    0xFF1F || // ？
    0x2026 => true, // …
    _ => false,
  };
}
