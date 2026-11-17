import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';
import 'package:freepiv/ui/custom/reader/reader_paginator.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';

const _palette = ReaderPalette(
  background: Color(0xFFFFFFFF),
  text: Color(0xFF1F1F1F),
  secondary: Color(0x991F1F1F),
  link: Color(0xFF0B5CAD),
  ruby: Color(0xBF1F1F1F),
  selection: Color(0x4D0B5CAD),
);

// The test font gives every glyph an advance of the font size. The widths used
// here (56 + 20 * size) leave a column of exactly 20 glyphs per line at any
// size, with a body line of 2 * size.
const _line = 20.0; // body line at size 10
const _gap = 3.5; // paragraph gap at size 10
const _pageHeight = 110.0; // five body lines at size 10
const _eps = 0.01;

ReaderTypesetting _typesetting(double textSize) => ReaderTypesetting(
  textSize: textSize,
  lineHeight: 2,
  body: TextStyle(fontSize: textSize, height: 2, color: _palette.text),
  chapterTitle: TextStyle(fontSize: textSize * 1.3, fontWeight: FontWeight.w600, height: 1.4, color: _palette.text),
  indent: false,
  palette: _palette,
);

// Ideographs without punctuation: every boundary is a legal line break.
const _han = '山川河海云风雨雪花鸟虫鱼树林石田月星日光草木';
String _text(int count) => List.generate(count, (i) => _han[i % _han.length]).join();

NovelLine _lineOf(int glyphs, {int blank = 0}) => NovelLine([NovelPlain(_text(glyphs))], blankLinesBefore: blank);
NovelChapterTitle _title(String title) => NovelChapterTitle(title);
const _break = NovelPageBreak();
const _work = NovelEmbeddedWork('9001', 9001, 1, null);

String _imageUrl(String id) => 'https://example.com/novel/$id.jpg';

NovelUploadedImage _image(String id) {
  final url = _imageUrl(id);
  return NovelUploadedImage(
    id,
    WebviewNovelImage(
      novelImageId: id,
      urls: WebviewNovelImageUrls(size128X128: url, size240Mw: url, size480Mw: url, size1200X1200: url, original: url),
    ),
  );
}

Future<MemoryImageSizeStore> _store(Map<String, Size> sizes) async {
  final store = MemoryImageSizeStore();
  for (final entry in sizes.entries) {
    await store.record(_imageUrl(entry.key), entry.value);
  }
  return store;
}

class _Setup {
  _Setup(List<NovelBlock> blocks, {double pageHeight = _pageHeight, double textSize = 10, ImageSizeStore? sizes})
    : model = ReaderModel(blocks) {
    layout = ReaderLayout(
      model: model,
      typesetting: _typesetting(textSize),
      width: 56 + 20 * textSize,
      flow: ReaderFlow.paged,
      sizes: sizes ?? MemoryImageSizeStore(),
      viewportHeight: pageHeight,
      pageJumpLabel: (page) => 'P$page',
    );
    paginator = ReaderPaginator(layout, pageHeight: pageHeight);
    this.pageHeight = pageHeight;
  }

  final ReaderModel model;
  late final ReaderLayout layout;
  late final ReaderPaginator paginator;
  late final double pageHeight;

  List<ReaderPage> pages(int chapter) => paginator.pagesOfChapter(chapter);
}

// The line box fields have no settled names beyond top and height.
double _boxHeight(Object box) => (box as dynamic).height as double;

List<ReaderTextSlice> _slices(ReaderPage page) => page.items.whereType<ReaderTextSlice>().toList();

/// A text whose chapters, breaks, long paragraphs, images and cards exercise
/// every rule of the paginator.
Future<_Setup> _mixed({double textSize = 10, double pageHeight = _pageHeight, bool media = true}) async {
  final store = await _store({'1': const Size(200, 200), '2': const Size(400, 100)});
  final blocks = <NovelBlock>[
    _title('序章'),
    _lineOf(130, blank: 1),
    _lineOf(35),
    _lineOf(61, blank: 2),
    _break,
    _lineOf(45),
    if (media) _image('1'),
    _lineOf(19),
    _title('第二章'),
    _lineOf(250),
    _lineOf(35),
    if (media) _image('2'),
    _title('第三章'),
    _lineOf(19),
    _break,
    _break,
    _lineOf(77, blank: 3),
    if (media) _work,
    _lineOf(41),
  ];
  return _Setup(blocks, sizes: store, textSize: textSize, pageHeight: pageHeight);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pages of a chapter', () {
    test('a paragraph that does not fit continues on the next page from the next line', () {
      final setup = _Setup([_lineOf(130)]);
      final pages = setup.pages(0);
      expect(pages, hasLength(2));

      final first = _slices(pages[0]).single;
      expect((first.block, first.firstLine, first.lineCount), (0, 0, 5));
      expect(first.height, closeTo(5 * _line, _eps));
      final second = _slices(pages[1]).single;
      expect((second.block, second.firstLine, second.lineCount), (0, 5, 2));
      expect(second.height, closeTo(2 * _line, _eps));
      expect(second.top, closeTo(0, _eps));

      expect((pages[0].startOffset, pages[0].endOffset), (0, 100));
      expect((pages[1].startOffset, pages[1].endOffset), (100, 130));
    });

    test('splits a paragraph between two others at the line that does not fit', () {
      // 4 lines + gap = 83.5, then 26.5 left: one line of the next paragraph fits.
      final setup = _Setup([_lineOf(80), _lineOf(40)]);
      final pages = setup.pages(0);
      expect(pages, hasLength(2));
      final onFirst = _slices(pages[0]);
      expect(onFirst.map((s) => (s.block, s.firstLine, s.lineCount)), [(0, 0, 4), (1, 0, 1)]);
      expect(onFirst[1].top, closeTo(4 * _line + _gap, _eps));
      final onSecond = _slices(pages[1]).single;
      expect((onSecond.block, onSecond.firstLine, onSecond.lineCount), (1, 1, 1));
      expect(onSecond.top, closeTo(0, _eps));
      expect(pages[0].endOffset, 80 + 20);
      expect(pages[1].startOffset, 80 + 20);
    });

    test('drops the top gap of a paragraph that starts a page', () {
      // The first paragraph fills the page; the second has a blank line above it.
      final setup = _Setup([_lineOf(100), _lineOf(40, blank: 1)]);
      final pages = setup.pages(0);
      expect(pages, hasLength(2));
      final slice = _slices(pages[1]).single;
      expect(slice.block, 1);
      expect(slice.firstLine, 0);
      expect(slice.lineCount, 2);
      expect(slice.top, closeTo(0, _eps));
    });

    test('drops the top gap of the first paragraph of the first page', () {
      final setup = _Setup([_lineOf(40, blank: 3)]);
      expect(_slices(setup.pages(0).single).single.top, closeTo(0, _eps));
    });

    test('keeps the top gap of a paragraph in the middle of a page', () {
      final setup = _Setup([_lineOf(19), _lineOf(19, blank: 1)]);
      final slices = _slices(setup.pages(0).single);
      expect(slices, hasLength(2));
      // The paragraph starts after the first one and its blank line, but never overlaps the first.
      expect(slices[1].top, greaterThanOrEqualTo(_line + _gap - _eps));
    });

    test('never splits a visual line: pages end at the start of a visual line', () async {
      final setup = await _mixed();
      for (final chapter in setup.model.chapters) {
        final pages = setup.pages(chapter.index);
        for (final page in pages.take(pages.length - 1)) {
          final boundary = page.endOffset;
          if (setup.model.blocks[setup.model.blockAt(boundary)] is! NovelLine) continue;
          expect(
            setup.layout.offsetAtPixel(setup.layout.pixelOfOffset(boundary)),
            boundary,
            reason: 'page ${chapter.index}/${page.index} ends inside a visual line',
          );
        }
      }
    });

    test('slices cover every line of every text block exactly once, in order', () async {
      final setup = await _mixed();
      final covered = <int, List<(int, int)>>{};
      for (final chapter in setup.model.chapters) {
        for (final page in setup.pages(chapter.index)) {
          for (final slice in _slices(page)) {
            (covered[slice.block] ??= []).add((slice.firstLine, slice.lineCount));
          }
        }
      }
      for (var block = 0; block < setup.model.blocks.length; block++) {
        final source = setup.model.blocks[block];
        if (source is! NovelLine && source is! NovelChapterTitle) continue;
        final lines = setup.layout.metricsOf(block).lines.length;
        var next = 0;
        for (final (first, count) in covered[block] ?? const <(int, int)>[]) {
          expect(first, next, reason: 'block $block continues where it stopped');
          expect(count, greaterThan(0));
          next += count;
        }
        expect(next, lines, reason: 'block $block shows all of its lines');
      }
    });

    test('a slice is as tall as the visual lines it shows', () async {
      final setup = await _mixed();
      for (final chapter in setup.model.chapters) {
        for (final page in setup.pages(chapter.index)) {
          for (final slice in _slices(page)) {
            final lines = setup.layout.metricsOf(slice.block).lines;
            var height = 0.0;
            for (var i = slice.firstLine; i < slice.firstLine + slice.lineCount; i++) {
              height += _boxHeight(lines[i]);
            }
            expect(slice.height, closeTo(height, _eps), reason: 'block ${slice.block} lines from ${slice.firstLine}');
          }
        }
      }
    });

    test('items stay in order, do not overlap and fit inside the page', () async {
      final setup = await _mixed();
      for (final chapter in setup.model.chapters) {
        for (final page in setup.pages(chapter.index)) {
          var bottom = 0.0;
          var block = -1;
          for (final item in page.items) {
            expect(item.top, greaterThanOrEqualTo(bottom - _eps), reason: 'page ${page.chapter}/${page.index}');
            expect(item.block, greaterThanOrEqualTo(block));
            bottom = item.top + item.height;
            block = item.block;
          }
          expect(bottom, lessThanOrEqualTo(setup.pageHeight + _eps), reason: 'page ${page.chapter}/${page.index}');
        }
      }
    });

    test('a page uses its space: the next line would not have fit', () {
      // 130 glyphs, 5 lines per page: the first page holds exactly the 5 that fit in 110.
      final setup = _Setup([_lineOf(130)]);
      final page = setup.pages(0).first;
      final bottom = _slices(page).single.top + _slices(page).single.height;
      expect(bottom + _line, greaterThan(setup.pageHeight));
    });
  });

  group('chapters and page breaks', () {
    test('a chapter starts on a new page and its first item is its title without top gap', () {
      final setup = _Setup([_title('一'), _lineOf(35), _title('二'), _lineOf(35)]);
      expect(setup.model.chapters, hasLength(2));
      final second = setup.pages(1);
      expect(second.first.chapter, 1);
      expect(second.first.index, 0);
      expect(second.first.startOffset, setup.model.chapters[1].startOffset);
      final first = second.first.items.first;
      expect(first, isA<ReaderTextSlice>());
      expect(first.block, 2);
      expect(first.top, closeTo(0, _eps));
    });

    test('chapters never share a page', () async {
      final setup = await _mixed();
      for (final chapter in setup.model.chapters) {
        final firstBlock = chapter.firstBlock;
        final endBlock = chapter.index + 1 < setup.model.chapters.length ? setup.model.chapters[chapter.index + 1].firstBlock : setup.model.blocks.length;
        for (final page in setup.pages(chapter.index)) {
          for (final item in page.items) {
            expect(item.block, inInclusiveRange(firstBlock, endBlock - 1), reason: 'page ${page.chapter}/${page.index}');
          }
        }
      }
    });

    test('a page break inside a chapter starts a new page', () {
      final setup = _Setup([_title('一'), _lineOf(19), _break, _lineOf(19)]);
      expect(setup.model.chapters, hasLength(1));
      final pages = setup.pages(0);
      expect(pages, hasLength(2));
      expect(pages[0].items.map((i) => i.block), [0, 1]);
      expect(pages[1].items.map((i) => i.block), [3]);
      expect(pages[1].startOffset, pages[0].endOffset);
      expect(pages[1].items.first.top, closeTo(0, _eps));
    });

    test('a page break right after a chapter title does not start a new page', () {
      final setup = _Setup([_title('一'), _break, _lineOf(19)]);
      final pages = setup.pages(0);
      expect(pages, hasLength(1));
      expect(pages[0].items.map((i) => i.block), [0, 2]);
    });

    test('a page break on an empty page does not create an empty page', () {
      final setup = _Setup([_title('一'), _lineOf(19), _break, _break, _lineOf(19)]);
      final pages = setup.pages(0);
      expect(pages, hasLength(2));
      for (final page in pages) {
        expect(page.startOffset, lessThan(page.endOffset));
        expect(page.items, isNotEmpty);
      }
    });

    test('several page breaks in a row make one page start', () {
      final setup = _Setup([_title('一'), _lineOf(19), _break, _break, _break, _lineOf(19), _break, _lineOf(19)]);
      expect(setup.pages(0), hasLength(3));
    });

    test('a chapter that begins with a page break does not begin with an empty page', () {
      // Without titles the text divides at page breaks, so the second chapter starts at the break.
      final setup = _Setup([_lineOf(19), _break, _lineOf(19)]);
      expect(setup.model.chapters, hasLength(2));
      final pages = setup.pages(1);
      expect(pages, hasLength(1));
      expect(pages.single.items.map((i) => i.block), [2]);
      expect(pages.single.startOffset, lessThan(pages.single.endOffset));
    });
  });

  group('images and cards', () {
    test('an image that does not fit the rest of the page starts the next one', () async {
      final store = await _store({'1': const Size(200, 200)}); // 200 tall at the column width
      final setup = _Setup([_lineOf(35), _image('1')], pageHeight: 220, sizes: store);
      final pages = setup.pages(0);
      expect(pages, hasLength(2));
      expect(pages[0].items.map((i) => i.block), [0]);
      final item = pages[1].items.single;
      expect(item, isA<ReaderBlockItem>());
      expect(item.block, 1);
      expect(item.top, closeTo(0, _eps));
      expect((item as ReaderBlockItem).scale, 1);
      expect(pages[0].endOffset, 35);
      expect((pages[1].startOffset, pages[1].endOffset), (35, 36));
    });

    test('an image that fits stays on the page below the text', () async {
      final store = await _store({'1': const Size(200, 50)});
      final setup = _Setup([_lineOf(35), _image('1')], pageHeight: 220, sizes: store);
      final page = setup.pages(0).single;
      expect(page.items.map((i) => i.block), [0, 1]);
      final item = page.items[1] as ReaderBlockItem;
      expect(item.scale, 1);
      expect(item.top, greaterThanOrEqualTo(2 * _line - _eps));
      expect(item.top + item.height, lessThanOrEqualTo(220 + _eps));
    });

    test('an image taller than a page is scaled to the page height', () async {
      final store = await _store({'1': const Size(100, 500)}); // 1000 tall at the column width
      final setup = _Setup([_image('1')], pageHeight: 220, sizes: store);
      final page = setup.pages(0).single;
      final item = page.items.single as ReaderBlockItem;
      // Scaled by pageHeight over its height, with or without the paragraph gap.
      expect(item.scale, inInclusiveRange(220 / (1000 + _gap) - 1e-6, 220 / 1000 + 1e-6));
      expect(item.scale, lessThan(1));
      expect(item.top, closeTo(0, _eps));
      expect(item.height, lessThanOrEqualTo(220 + _eps));
    });

    test('an oversize image goes to a page of its own', () async {
      final store = await _store({'1': const Size(100, 500)});
      final setup = _Setup([_lineOf(19), _image('1'), _lineOf(19)], pageHeight: 220, sizes: store);
      final pages = setup.pages(0);
      expect(pages.map((p) => p.items.map((i) => i.block).toList()), [
        [0],
        [1],
        [2],
      ]);
    });

    test('an embedded card taller than the page is scaled to fit', () {
      final setup = _Setup([_work], pageHeight: 100);
      final item = setup.pages(0).single.items.single as ReaderBlockItem;
      expect(item.scale, inInclusiveRange(100 / (112 + _gap) - 1e-6, 100 / 112 + 1e-6));
      expect(item.height, lessThanOrEqualTo(100 + _eps));
    });

    test('an embedded card that does not fit the rest of the page starts the next one', () {
      final setup = _Setup([_lineOf(35), _work], pageHeight: 150);
      final pages = setup.pages(0);
      expect(pages, hasLength(2));
      expect(pages[1].items.single.block, 1);
      expect((pages[1].items.single as ReaderBlockItem).scale, 1);
    });

    test('an embedded card that fits stays unscaled on the page', () {
      final setup = _Setup([_lineOf(35), _work], pageHeight: 200);
      final page = setup.pages(0).single;
      expect(page.items.map((i) => i.block), [0, 1]);
      expect((page.items[1] as ReaderBlockItem).scale, 1);
    });

    test('items after an oversize image start a new page', () async {
      final store = await _store({'1': const Size(100, 500)});
      final setup = _Setup([_image('1'), _lineOf(19)], pageHeight: 220, sizes: store);
      expect(setup.pages(0), hasLength(2));
    });
  });

  group('page ranges', () {
    test('pages cover their chapter contiguously', () async {
      final setup = await _mixed();
      for (final chapter in setup.model.chapters) {
        final pages = setup.pages(chapter.index);
        expect(pages, isNotEmpty);
        expect(pages.first.startOffset, chapter.startOffset, reason: 'chapter ${chapter.index} start');
        expect(pages.last.endOffset, chapter.endOffset, reason: 'chapter ${chapter.index} end');
        for (var i = 0; i < pages.length; i++) {
          expect(pages[i].chapter, chapter.index);
          expect(pages[i].index, i);
          expect(pages[i].startOffset, lessThan(pages[i].endOffset), reason: 'page ${chapter.index}/$i is not empty');
          if (i > 0) expect(pages[i].startOffset, pages[i - 1].endOffset, reason: 'page ${chapter.index}/$i follows the previous page');
        }
      }
    });

    test('every page of a non-empty chapter shows something', () async {
      final setup = await _mixed();
      for (final chapter in setup.model.chapters) {
        for (final page in setup.pages(chapter.index)) {
          expect(page.items, isNotEmpty, reason: 'page ${chapter.index}/${page.index}');
        }
      }
    });

    test('the pages of a chapter are measured fully', () async {
      final setup = await _mixed();
      final chapter = setup.model.chapters[1];
      setup.pages(1);
      final end = setup.model.chapters[2].firstBlock;
      for (var block = chapter.firstBlock; block < end; block++) {
        final source = setup.model.blocks[block];
        if (source is NovelLine || source is NovelChapterTitle) {
          expect(setup.layout.isMeasured(block), isTrue, reason: 'block $block');
        }
      }
    });

    test('an empty text has one empty page', () {
      final setup = _Setup(const []);
      final pages = setup.pages(0);
      expect(pages, hasLength(1));
      expect((pages.single.startOffset, pages.single.endOffset), (0, 0));
    });
  });

  group('pageAt', () {
    test('finds every page from its start offset', () async {
      final setup = await _mixed();
      for (final chapter in setup.model.chapters) {
        for (final page in setup.pages(chapter.index)) {
          final ref = setup.paginator.pageAt(page.startOffset);
          expect((ref.chapter, ref.index), (page.chapter, page.index), reason: 'page ${page.chapter}/${page.index}');
        }
      }
    });

    test('the end of the text is on the last page of the last chapter', () async {
      final setup = await _mixed();
      final last = setup.model.chapters.last.index;
      final ref = setup.paginator.pageAt(setup.model.totalLength);
      expect(ref.chapter, last);
      expect(ref.index, setup.pages(last).length - 1);
    });

    test('works on a fresh paginator and agrees with the pages after they exist', () async {
      final setup = await _mixed();
      final refs = [for (var o = 0; o <= setup.model.totalLength; o++) setup.paginator.pageAt(o)];
      for (var offset = 0; offset < setup.model.totalLength; offset++) {
        final page = setup.pages(refs[offset].chapter)[refs[offset].index];
        expect(page.startOffset, lessThanOrEqualTo(offset), reason: 'offset $offset');
        expect(offset, lessThan(page.endOffset), reason: 'offset $offset');
      }
    });

    test('offset to page to start offset to page gives the same page', () async {
      final setup = await _mixed();
      for (var offset = 0; offset < setup.model.totalLength; offset += 3) {
        final ref = setup.paginator.pageAt(offset);
        final page = setup.pages(ref.chapter)[ref.index];
        expect(page.chapter, ref.chapter);
        expect(page.index, ref.index);
        final again = setup.paginator.pageAt(page.startOffset);
        expect((again.chapter, again.index), (ref.chapter, ref.index), reason: 'offset $offset');
      }
    });

    test('the page of an offset belongs to the chapter of that offset', () async {
      final setup = await _mixed();
      for (var offset = 0; offset < setup.model.totalLength; offset += 5) {
        expect(setup.paginator.pageAt(offset).chapter, setup.model.chapterAt(offset).index, reason: 'offset $offset');
      }
    });

    test('an empty text has its page at offset 0', () {
      final ref = _Setup(const []).paginator.pageAt(0);
      expect((ref.chapter, ref.index), (0, 0));
    });
  });

  group('a rebuilt layout', () {
    test('keeps the page of an offset containing it after the text size grows', () async {
      for (final textSize in [10.0, 12.0, 14.0, 18.0]) {
        final setup = await _mixed(textSize: textSize, pageHeight: 150);
        for (var offset = 0; offset < setup.model.totalLength; offset += 4) {
          final ref = setup.paginator.pageAt(offset);
          final page = setup.pages(ref.chapter)[ref.index];
          expect(page.startOffset, lessThanOrEqualTo(offset), reason: 'size $textSize offset $offset');
          expect(offset, lessThan(page.endOffset), reason: 'size $textSize offset $offset');
        }
      }
    });

    test('a larger text size makes a long chapter longer', () async {
      final small = await _mixed(pageHeight: 150, media: false);
      final large = await _mixed(textSize: 14, pageHeight: 150, media: false);
      expect(large.pages(1).length, greaterThan(small.pages(1).length));
    });

    test('the offset of a page of the old layout is found in the new one', () async {
      final small = await _mixed(media: false);
      final large = await _mixed(textSize: 14, media: false);
      final page = small.pages(1)[2];
      final offset = page.startOffset + 10;
      final ref = large.paginator.pageAt(offset);
      final found = large.pages(ref.chapter)[ref.index];
      expect(found.startOffset, lessThanOrEqualTo(offset));
      expect(offset, lessThan(found.endOffset));
    });
  });

  group('spreads', () {
    // 22 lines of 20 glyphs, five lines per page: pages of 5, 5, 5, 5 and 2 lines.
    test('pair pages two by two and leave an odd last page alone', () {
      final setup = _Setup([_lineOf(440)]);
      expect(setup.pages(0), hasLength(5));
      final spreads = setup.paginator.spreadsOfChapter(0);
      expect(spreads, hasLength(3));
      expect(spreads.map((s) => s.left.index), [0, 2, 4]);
      expect(spreads.map((s) => s.right?.index), [1, 3, null]);
    });

    test('pair every page when the count is even', () {
      final setup = _Setup([_lineOf(360)]);
      expect(setup.pages(0), hasLength(4));
      final spreads = setup.paginator.spreadsOfChapter(0);
      expect(spreads.map((s) => (s.left.index, s.right?.index)), [(0, 1), (2, 3)]);
    });

    test('a chapter of one page is one spread with no right page', () {
      final setup = _Setup([_lineOf(50)]);
      final spreads = setup.paginator.spreadsOfChapter(0);
      expect(spreads, hasLength(1));
      expect(spreads.single.left.index, 0);
      expect(spreads.single.right, isNull);
    });

    test('hold the pages of the chapter', () {
      final setup = _Setup([_lineOf(440)]);
      final pages = setup.pages(0);
      final spreads = setup.paginator.spreadsOfChapter(0);
      expect(spreads.first.left.startOffset, pages[0].startOffset);
      expect(spreads.first.right!.startOffset, pages[1].startOffset);
      expect(spreads.last.left.startOffset, pages[4].startOffset);
      expect(spreads.last.left.chapter, 0);
    });

    test('never mix chapters', () async {
      final setup = await _mixed();
      for (final chapter in setup.model.chapters) {
        for (final spread in setup.paginator.spreadsOfChapter(chapter.index)) {
          expect(spread.left.chapter, chapter.index);
          if (spread.right != null) expect(spread.right!.chapter, chapter.index);
        }
      }
    });
  });
}
