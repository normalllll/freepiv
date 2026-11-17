import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';

NovelBlock _line(String text) => NovelLine([NovelPlain(text)]);
const _pb = NovelPageBreak();
NovelBlock _title(String t) => NovelChapterTitle(t);
const _up = NovelUploadedImage('1', null);
const _emb = NovelEmbeddedWork('1', 1, 1, null);

/// Chapter summary: index/firstBlock/title/start-end.
List<String> _chapters(ReaderModel m) =>
    m.chapters.map((c) => '${c.index}/${c.firstBlock}/${c.title}/${c.startOffset}-${c.endOffset}').toList();

void main() {
  group('offsets', () {
    // lengths: 3, 2, 0, 1, 1, 1
    final blocks = [_line('abc'), _title('xy'), _pb, _up, _emb, _line('d')];
    final m = ReaderModel(blocks);

    test('keeps every block unchanged and in order', () {
      expect(m.blocks, hasLength(blocks.length));
      for (var i = 0; i < blocks.length; i++) {
        expect(m.blocks[i], same(blocks[i]));
      }
    });

    test('totalLength is the sum of block lengths', () {
      expect(m.totalLength, 8);
    });

    test('offsetOf is the characters before the block', () {
      expect([for (var i = 0; i < blocks.length; i++) m.offsetOf(i)], [0, 3, 5, 5, 6, 7]);
    });

    test('offsetOf clamps below 0 and at or past the end', () {
      expect(m.offsetOf(-1), 0);
      expect(m.offsetOf(-100), 0);
      expect(m.offsetOf(blocks.length), 8);
      expect(m.offsetOf(blocks.length + 50), 8);
    });
  });

  group('blockAt', () {
    final m = ReaderModel([_line('abc'), _pb, _line('de')]); // 0..3, zero, 3..5

    test('returns the block whose range contains the offset', () {
      expect(m.blockAt(0), 0);
      expect(m.blockAt(2), 0);
    });

    test('a boundary offset belongs to the block that starts there, skipping zero-length blocks', () {
      expect(m.blockAt(3), 2);
      expect(m.blockAt(4), 2);
    });

    test('at totalLength returns the last block with length > 0', () {
      expect(m.blockAt(5), 2);
      expect(ReaderModel([_line('a'), _line('b'), _pb]).blockAt(2), 1);
    });

    test('clamps out-of-range offsets', () {
      expect(m.blockAt(-5), 0);
      expect(m.blockAt(999), 2);
    });

    test('leading zero-length blocks are skipped', () {
      expect(ReaderModel([_pb, _pb, _line('a')]).blockAt(0), 2);
    });

    test('images count as one character', () {
      final im = ReaderModel([_line('ab'), _up, _emb]);
      expect(im.blockAt(2), 1);
      expect(im.blockAt(3), 2);
      expect(im.blockAt(4), 2);
    });

    test('empty model and models without length return 0', () {
      expect(ReaderModel([]).blockAt(0), 0);
      expect(ReaderModel([]).blockAt(10), 0);
      expect(ReaderModel([_pb, _pb]).blockAt(0), 0);
    });
  });

  group('chapters by title', () {
    test('untitled leading content forms chapter 0, then one chapter per title', () {
      final m = ReaderModel([_line('pre'), _title('A'), _line('x'), _title('B'), _line('y')]);
      expect(_chapters(m), ['0/0/null/0-3', '1/1/A/3-5', '2/3/B/5-7']);
    });

    test('without leading content the first title is chapter 0', () {
      final m = ReaderModel([_title('A'), _line('x'), _title('B'), _line('y')]);
      expect(_chapters(m), ['0/0/A/0-2', '1/2/B/2-4']);
    });

    test('leading page breaks alone do not form an untitled chapter', () {
      final m = ReaderModel([_pb, _title('A'), _line('x')]);
      expect(_chapters(m), ['0/1/A/0-2']);
    });

    test('a leading image forms an untitled chapter', () {
      final m = ReaderModel([_up, _title('A'), _line('x')]);
      expect(_chapters(m), ['0/0/null/0-1', '1/1/A/1-3']);
      final e = ReaderModel([_emb, _title('A')]);
      expect(_chapters(e), ['0/0/null/0-1', '1/1/A/1-2']);
    });

    test('consecutive titles each start a chapter', () {
      final m = ReaderModel([_title('A'), _title('B'), _line('x')]);
      expect(_chapters(m), ['0/0/A/0-1', '1/1/B/1-3']);
    });

    test('titles divide chapters; page breaks do not', () {
      final m = ReaderModel([_line('a'), _pb, _title('T'), _line('b'), _pb, _line('c')]);
      expect(_chapters(m), ['0/0/null/0-1', '1/2/T/1-4']);
    });
  });

  group('chapters by page break', () {
    test('each page break after content starts a chapter with null title', () {
      final m = ReaderModel([_line('a'), _pb, _line('bb'), _pb, _line('c')]);
      expect(_chapters(m), ['0/0/null/0-1', '1/1/null/1-3', '2/3/null/3-4']);
    });

    test('a leading page break is ignored', () {
      final m = ReaderModel([_pb, _line('a'), _pb, _line('b')]);
      expect(_chapters(m), ['0/0/null/0-1', '1/2/null/1-2']);
    });

    test('only leading page breaks give a single chapter', () {
      final m = ReaderModel([_pb, _pb, _line('abc')]);
      expect(_chapters(m), ['0/0/null/0-3']);
    });

    test('an image before the break counts as content', () {
      expect(_chapters(ReaderModel([_up, _pb, _line('a')])), ['0/0/null/0-1', '1/1/null/1-2']);
      expect(_chapters(ReaderModel([_emb, _pb, _line('a')])), ['0/0/null/0-1', '1/1/null/1-2']);
    });
  });

  group('single and empty chapters', () {
    test('no titles or page breaks gives one chapter', () {
      final m = ReaderModel([_line('ab'), _line('c'), _up]);
      expect(_chapters(m), ['0/0/null/0-4']);
    });

    test('empty text gives one empty chapter', () {
      final m = ReaderModel([]);
      expect(m.chapters, hasLength(1));
      expect(m.chapters.single.index, 0);
      expect(m.chapters.single.firstBlock, 0);
      expect(m.chapters.single.title, isNull);
      expect(m.chapters.single.startOffset, 0);
      expect(m.chapters.single.endOffset, 0);
      expect(m.totalLength, 0);
    });
  });

  group('chapter end offsets', () {
    test('endOffset is the next start offset, the last is totalLength', () {
      final m = ReaderModel([_line('pre'), _title('A'), _line('x'), _title('B'), _line('y')]);
      for (var i = 0; i < m.chapters.length - 1; i++) {
        expect(m.chapters[i].endOffset, m.chapters[i + 1].startOffset);
      }
      expect(m.chapters.last.endOffset, m.totalLength);
    });
  });

  group('chapterAt', () {
    final m = ReaderModel([_line('pre'), _title('A'), _line('x'), _title('B'), _line('y')]); // starts 0, 3, 5; total 7

    test('returns the last chapter starting at or before the offset', () {
      expect(m.chapterAt(0).index, 0);
      expect(m.chapterAt(2).index, 0);
      expect(m.chapterAt(3).index, 1);
      expect(m.chapterAt(4).index, 1);
      expect(m.chapterAt(5).index, 2);
      expect(m.chapterAt(7).index, 2);
    });

    test('clamps out-of-range offsets', () {
      expect(m.chapterAt(-4).index, 0);
      expect(m.chapterAt(1000).index, 2);
    });

    test('empty model returns its only chapter', () {
      expect(ReaderModel([]).chapterAt(0).index, 0);
    });
  });

  group('pages', () {
    // lengths 2, 0, 2, 0, 1: breaks at offsets 2 and 4
    final m = ReaderModel([_line('ab'), _pb, _line('cd'), _pb, _line('e')]);

    test('pageCount is 1 + number of page breaks', () {
      expect(m.pageCount, 3);
      expect(ReaderModel([]).pageCount, 1);
      expect(ReaderModel([_line('a')]).pageCount, 1);
      expect(ReaderModel([_pb, _line('a')]).pageCount, 2);
    });

    test('pageOf counts breaks at or before the offset, 1-based', () {
      expect(m.pageOf(0), 1);
      expect(m.pageOf(1), 1);
      expect(m.pageOf(2), 2);
      expect(m.pageOf(3), 2);
      expect(m.pageOf(4), 3);
      expect(m.pageOf(5), 3);
      expect(m.pageOf(999), 3);
    });

    test('offsetOfPage is 0 for page 1, else the offset of the previous break', () {
      expect(m.offsetOfPage(1), 0);
      expect(m.offsetOfPage(2), 2);
      expect(m.offsetOfPage(3), 4);
    });

    test('offsetOfPage clamps the page to 1..pageCount', () {
      expect(m.offsetOfPage(0), 0);
      expect(m.offsetOfPage(-7), 0);
      expect(m.offsetOfPage(4), 4);
      expect(m.offsetOfPage(99), 4);
    });

    test('a leading page break makes offset 0 page 2', () {
      final lead = ReaderModel([_pb, _line('a')]);
      expect(lead.pageOf(0), 2);
      expect(lead.offsetOfPage(1), 0);
      expect(lead.offsetOfPage(2), 0);
    });

    test('without page breaks everything is page 1', () {
      final one = ReaderModel([_line('abc')]);
      expect(one.pageOf(0), 1);
      expect(one.pageOf(3), 1);
      expect(one.offsetOfPage(1), 0);
      expect(one.offsetOfPage(5), 0);
    });

    test('empty model', () {
      final e = ReaderModel([]);
      expect(e.pageOf(0), 1);
      expect(e.offsetOfPage(1), 0);
      expect(e.offsetOfPage(3), 0);
    });
  });

  group('imageBlocks', () {
    test('lists uploaded images and embedded works in ascending order', () {
      final m = ReaderModel([_line('a'), _up, _line('b'), _emb, _pb, _up, _title('t')]);
      expect(m.imageBlocks, [1, 3, 5]);
    });

    test('is empty without images', () {
      expect(ReaderModel([_line('a'), _pb]).imageBlocks, isEmpty);
      expect(ReaderModel([]).imageBlocks, isEmpty);
    });
  });
}
