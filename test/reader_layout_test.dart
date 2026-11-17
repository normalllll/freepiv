import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';
import 'package:freepiv/ui/custom/reader/reader_line_text.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';

const _palette = ReaderPalette(
  background: Color(0xFFFFFFFF),
  text: Color(0xFF1F1F1F),
  secondary: Color(0x991F1F1F),
  link: Color(0xFF0B5CAD),
  ruby: Color(0xBF1F1F1F),
  selection: Color(0x4D0B5CAD),
);

// The test font gives every glyph an advance of the font size. With size 10
// and regular margins (28 each side), a width of 256 gives a 200 column that
// holds 20 glyphs per line.
const _width = 256.0;
const _column = 200.0;
const _line = 20.0; // body line: 10 * 2
const _gap = 3.5; // paragraph gap: 10 * 0.35
const _viewport = 600.0;

ReaderTypesetting _typesetting({double textSize = 10, bool indent = false}) => ReaderTypesetting(
  textSize: textSize,
  lineHeight: 2,
  body: TextStyle(fontSize: textSize, height: 2, color: _palette.text),
  chapterTitle: TextStyle(fontSize: textSize * 1.3, fontWeight: FontWeight.w600, height: 1.4, color: _palette.text),
  indent: indent,
  palette: _palette,
);

String _label(int page) => 'P$page';

// Ideographs without punctuation: every boundary is a legal line break.
const _han = '山川河海云风雨雪花鸟虫鱼树林石田月星日光草木';
String _text(int count) => List.generate(count, (i) => _han[i % _han.length]).join();

NovelLine _lineOf(int glyphs, {int blank = 0}) => NovelLine([NovelPlain(_text(glyphs))], blankLinesBefore: blank);
NovelChapterTitle _title(String title) => NovelChapterTitle(title);
const _break = NovelPageBreak();

String _imageUrl(String id) => 'https://example.com/novel/$id.jpg';

// Every size slot holds the same url, so the image's size is looked up under
// that url whichever slot the layout reads.
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

ReaderLayout _layout(
  List<NovelBlock> blocks, {
  ReaderFlow flow = ReaderFlow.scroll,
  ImageSizeStore? sizes,
  double viewportHeight = _viewport,
  double width = _width,
  bool indent = false,
}) => ReaderLayout(
  model: ReaderModel(blocks),
  typesetting: _typesetting(indent: indent),
  width: width,
  flow: flow,
  sizes: sizes ?? MemoryImageSizeStore(),
  viewportHeight: viewportHeight,
  pageJumpLabel: _label,
);

double _titleHeight(String title, {double width = _column}) => ReaderLineText.title(title, _typesetting()).painter(width).height;

int _measuredCount(ReaderLayout layout) => [for (var i = 0; i < layout.blockCount; i++) layout.isMeasured(i)].where((m) => m).length;

// The line box fields have no settled names beyond top and height.
double _lineTop(Object box) => (box as dynamic).top as double;
double _lineHeight(Object box) => (box as dynamic).height as double;

const _eps = 0.01;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('extents', () {
    test('a line is its blank lines, its text and the paragraph gap', () {
      final layout = _layout([_lineOf(35)]);
      layout.metricsOf(0);
      expect(layout.extentOf(0), closeTo(2 * _line + _gap, _eps));
    });

    test('each blank line beyond the first adds one body line', () {
      final layout = _layout([_lineOf(35, blank: 1), _lineOf(35, blank: 2)]);
      layout.metricsOf(0);
      layout.metricsOf(1);
      expect(layout.extentOf(0), closeTo(2 * _line + _gap, _eps), reason: 'one blank line is the paragraph break');
      expect(layout.extentOf(1), closeTo(_line + 2 * _line + _gap, _eps));
    });

    test('blank lines beyond the first are counted at most three times', () {
      final layout = _layout([_lineOf(35, blank: 4), _lineOf(35, blank: 7)]);
      layout.metricsOf(0);
      layout.metricsOf(1);
      expect(layout.extentOf(1), closeTo(layout.extentOf(0), _eps));
      expect(layout.extentOf(1), closeTo(3 * _line + 2 * _line + _gap, _eps));
    });

    test('the first block of the text, a chapter title, has no top gap', () {
      final layout = _layout([_title('黄昏'), _lineOf(19)]);
      layout.metricsOf(0);
      expect(layout.extentOf(0), closeTo(_titleHeight('黄昏') + _line, _eps));
      expect(layout.metricsOf(0).topGap, closeTo(0, _eps));
      expect(layout.metricsOf(0).bottomGap, closeTo(_line, _eps));
    });

    test('a later chapter title adds two body lines above and one below', () {
      final layout = _layout([_lineOf(19), _title('夜航')]);
      layout.metricsOf(1);
      expect(layout.extentOf(1), closeTo(2 * _line + _titleHeight('夜航') + _line, _eps));
      expect(layout.metricsOf(1).topGap, closeTo(2 * _line, _eps));
      expect(layout.metricsOf(1).bottomGap, closeTo(_line, _eps));
    });

    test('a page break is two body lines in scroll flow', () {
      final layout = _layout([_title('黄昏'), _lineOf(19), _break, _lineOf(19)]);
      expect(layout.extentOf(2), closeTo(2 * _line, _eps));
    });

    test('a page break takes no space in paged flow', () {
      final layout = _layout([_title('黄昏'), _lineOf(19), _break, _lineOf(19)], flow: ReaderFlow.paged);
      expect(layout.extentOf(2), 0);
    });

    test('an uploaded image is the column wide at the size ratio from the store, plus the paragraph gap', () async {
      final sizes = MemoryImageSizeStore();
      await sizes.record(_imageUrl('1'), const Size(800, 1200));
      final layout = _layout([_lineOf(19), _image('1')], sizes: sizes);
      expect(layout.extentOf(1), closeTo(_column * 1200 / 800 + _gap, _eps));
    });

    test('a landscape image is shorter than the column is wide', () async {
      final sizes = MemoryImageSizeStore();
      await sizes.record(_imageUrl('1'), const Size(1200, 675));
      final layout = _layout([_image('1')], sizes: sizes);
      expect(layout.extentOf(0), closeTo(_column * 675 / 1200 + _gap, _eps));
    });

    test('an image with no stored size uses the fallback size', () {
      final layout = _layout([_image('1')]);
      expect(layout.extentOf(0), closeTo(_column * novelImageFallbackSize.height / novelImageFallbackSize.width + _gap, _eps));
    });

    test('an image the novel does not list uses the fallback size', () {
      final layout = _layout([const NovelUploadedImage('9', null)]);
      expect(layout.extentOf(0), closeTo(_column * novelImageFallbackSize.height / novelImageFallbackSize.width + _gap, _eps));
    });

    test('a tall image is capped at nine tenths of the viewport in scroll flow', () async {
      final sizes = MemoryImageSizeStore();
      await sizes.record(_imageUrl('1'), const Size(400, 1600)); // 800 tall at the column width
      final layout = _layout([_image('1')], sizes: sizes, viewportHeight: 600);
      expect(layout.extentOf(0), closeTo(600 * 0.9 + _gap, _eps));
    });

    test('the cap follows the viewport height', () async {
      final sizes = MemoryImageSizeStore();
      await sizes.record(_imageUrl('1'), const Size(400, 1600));
      expect(_layout([_image('1')], sizes: sizes, viewportHeight: 1000).extentOf(0), closeTo(800 + _gap, _eps));
      expect(_layout([_image('1')], sizes: sizes, viewportHeight: 400).extentOf(0), closeTo(400 * 0.9 + _gap, _eps));
    });

    test('an image is not capped in paged flow', () async {
      final sizes = MemoryImageSizeStore();
      await sizes.record(_imageUrl('1'), const Size(400, 1600));
      final layout = _layout([_image('1')], sizes: sizes, flow: ReaderFlow.paged);
      expect(layout.extentOf(0), closeTo(800 + _gap, _eps));
    });

    test('an embedded work is a fixed card height plus the paragraph gap', () {
      final layout = _layout([const NovelEmbeddedWork('9001', 9001, 1, null), _lineOf(19)]);
      expect(layout.extentOf(0), closeTo(112 + _gap, _eps));
    });

    test('an embedded work has the same extent in paged flow', () {
      final layout = _layout([const NovelEmbeddedWork('9001', 9001, 1, null)], flow: ReaderFlow.paged);
      expect(layout.extentOf(0), closeTo(112 + _gap, _eps));
    });

    test('the column is capped at 36 text sizes on a wide viewport', () async {
      final sizes = MemoryImageSizeStore();
      await sizes.record(_imageUrl('1'), const Size(500, 500));
      final layout = _layout([_image('1'), _lineOf(40)], sizes: sizes, width: 1000, viewportHeight: 2000);
      expect(layout.extentOf(0), closeTo(360 + _gap, _eps));
      layout.metricsOf(1);
      // 36 glyphs per line: 40 glyphs wrap into 2 lines.
      expect(layout.extentOf(1), closeTo(2 * _line + _gap, _eps));
    });

    test('block count is the number of blocks of the model', () {
      expect(_layout([_lineOf(5), _break, _lineOf(5)]).blockCount, 3);
    });
  });

  group('estimates and measuring', () {
    test('text blocks are unmeasured until asked', () {
      final layout = _layout([_title('黄昏'), _lineOf(35), _lineOf(10)]);
      expect([for (var i = 0; i < 3; i++) layout.isMeasured(i)], [false, false, false]);
      expect([for (var i = 0; i < 3; i++) layout.lineTextOf(i)], [null, null, null]);
    });

    test('estimates a line as the ceiling of its glyph width over the column, in body lines', () {
      // 35 glyphs: ceil(350 / 200) = 2; 41 glyphs: ceil(410 / 200) = 3.
      final layout = _layout([_lineOf(35), _lineOf(41, blank: 1), _lineOf(19)]);
      expect(layout.extentOf(0), closeTo(2 * _line + _gap, _eps));
      expect(layout.extentOf(1), closeTo(3 * _line + _gap, _eps));
      expect(layout.extentOf(2), closeTo(_line + _gap, _eps));
      expect(layout.isMeasured(0), isFalse);
    });

    test('an estimate is replaced by the exact extent once measured', () {
      // A ruby line is taller than the estimate: 2 lines of 22 instead of 2 of 20.
      final blocks = [
        NovelLine([NovelPlain(_text(33)), const NovelRuby('潮汐', 'ちょうせき')]),
        _lineOf(19),
      ];
      final layout = _layout(blocks);
      expect(layout.extentOf(0), closeTo(2 * _line + _gap, _eps), reason: 'estimate');
      final before = layout.totalExtent;
      layout.metricsOf(0);
      expect(layout.isMeasured(0), isTrue);
      expect(layout.extentOf(0), closeTo(2 * 22 + _gap, _eps), reason: 'exact');
      expect(layout.totalExtent, closeTo(before + 4, _eps));
    });

    test('metricsOf measures synchronously and reports the gaps and visual lines', () {
      final layout = _layout([_lineOf(35, blank: 2)]);
      final metrics = layout.metricsOf(0);
      expect(layout.isMeasured(0), isTrue);
      expect(metrics.extent, layout.extentOf(0));
      expect(metrics.topGap, closeTo(_line, _eps));
      expect(metrics.bottomGap, closeTo(_gap, _eps));
      expect(metrics.lines, hasLength(2));
      expect([for (final box in metrics.lines) _lineTop(box)], [closeTo(0, _eps), closeTo(_line, _eps)]);
      expect([for (final box in metrics.lines) _lineHeight(box)], [closeTo(_line, _eps), closeTo(_line, _eps)]);
    });

    test('metrics add up to the extent', () {
      final layout = _layout([_lineOf(61, blank: 1)]);
      final metrics = layout.metricsOf(0);
      final contentHeight = _lineTop(metrics.lines.last) + _lineHeight(metrics.lines.last);
      expect(metrics.topGap + contentHeight + metrics.bottomGap, closeTo(metrics.extent, _eps));
    });

    test('lineTextOf gives the measured line text and the title text', () {
      final layout = _layout([_title('黄昏'), _lineOf(35)]);
      layout.metricsOf(0);
      layout.metricsOf(1);
      expect(layout.lineTextOf(0)!.span.toPlainText(), '黄昏');
      expect(layout.lineTextOf(1)!.span.toPlainText(), _text(35));
      expect(layout.lineTextOf(1)!.modelLength, 35);
    });

    test('lineTextOf is null for blocks that are not lines or titles', () {
      final layout = _layout([_lineOf(5), _break, _image('1'), const NovelEmbeddedWork('9001', 9001, 1, null)]);
      for (var i = 1; i < 4; i++) {
        layout.metricsOf(i);
        expect(layout.lineTextOf(i), isNull, reason: 'block $i');
      }
    });

    test('uses the page jump label for lines', () {
      final layout = _layout([
        const NovelLine([NovelPlain('去'), NovelPageJump(3)]),
      ]);
      layout.metricsOf(0);
      expect(layout.lineTextOf(0)!.span.toPlainText(), '去P3');
    });

    test('measureSome measures everything within a generous budget and reports it', () {
      final layout = _layout([
        for (var c = 0; c < 4; c++) ...[_title('章$c'), for (var i = 0; i < 20; i++) _lineOf(35 + i)],
      ]);
      expect(layout.measureSome(0, const Duration(seconds: 30)), isTrue);
      for (var i = 0; i < layout.blockCount; i++) {
        expect(layout.isMeasured(i), isTrue, reason: 'block $i');
      }
    });

    test('measureSome with no time still gets there over repeated calls', () {
      final layout = _layout([for (var i = 0; i < 300; i++) _lineOf(10 + i % 70)]);
      var calls = 0;
      while (!layout.measureSome(150, Duration.zero)) {
        calls++;
        expect(calls, lessThan(5000), reason: 'measureSome made no progress');
      }
      for (var i = 0; i < layout.blockCount; i++) {
        expect(layout.isMeasured(i), isTrue, reason: 'block $i');
      }
    });

    test('measureSome keeps returning true once everything is measured', () {
      final layout = _layout([_lineOf(35), _lineOf(10)]);
      expect(layout.measureSome(0, const Duration(seconds: 30)), isTrue);
      expect(layout.measureSome(1, Duration.zero), isTrue);
    });

    test('measureSome measures the anchor chapter before any other', () {
      final blocks = <NovelBlock>[
        for (var c = 0; c < 3; c++) ...[_title('章$c'), for (var i = 0; i < 15; i++) _lineOf(30 + i)],
      ];
      final model = ReaderModel(blocks);
      final chapter = model.chapters[1];
      final anchorBlock = chapter.firstBlock + 5;
      final chapterBlocks = [for (var i = chapter.firstBlock; i < model.chapters[2].firstBlock; i++) i];
      final layout = _layout(blocks);
      var calls = 0;
      while (!layout.measureSome(anchorBlock, Duration.zero)) {
        final anchorDone = chapterBlocks.every(layout.isMeasured);
        if (!anchorDone) {
          for (var i = 0; i < layout.blockCount; i++) {
            if (!chapterBlocks.contains(i)) {
              expect(layout.isMeasured(i), isFalse, reason: 'block $i measured before the anchor chapter was');
            }
          }
        }
        calls++;
        expect(calls, lessThan(5000));
      }
    });

    test('measureSome notifies listeners', () {
      final layout = _layout([_lineOf(35), _lineOf(10)]);
      var notified = 0;
      layout.addListener(() => notified++);
      layout.measureSome(0, const Duration(seconds: 30));
      expect(notified, greaterThan(0));
    });
  });

  group('positions', () {
    final blocks = [_lineOf(35), _lineOf(19), _lineOf(61, blank: 2), _lineOf(20), _lineOf(5)];

    test('topOf is the sum of the extents above', () {
      final layout = _layout(blocks);
      var sum = 0.0;
      for (var i = 0; i < layout.blockCount; i++) {
        expect(layout.topOf(i), closeTo(sum, _eps), reason: 'block $i');
        sum += layout.extentOf(i);
      }
      expect(layout.totalExtent, closeTo(sum, _eps));
    });

    test('topOf the first block is 0 and the last block ends at the total extent', () {
      final layout = _layout(blocks);
      expect(layout.topOf(0), 0);
      expect(layout.topOf(4) + layout.extentOf(4), closeTo(layout.totalExtent, _eps));
    });

    test('positions follow measured extents', () {
      final layout = _layout([
        NovelLine([NovelPlain(_text(33)), const NovelRuby('潮汐', 'ちょうせき')]),
        _lineOf(19),
      ]);
      layout.metricsOf(0);
      expect(layout.topOf(1), closeTo(2 * 22 + _gap, _eps));
      expect(layout.totalExtent, closeTo(layout.topOf(1) + _line + _gap, _eps));
    });

    test('blockAtPixel finds the block holding a pixel', () {
      final layout = _layout(blocks);
      for (var i = 0; i < layout.blockCount; i++) {
        expect(layout.blockAtPixel(layout.topOf(i)), i, reason: 'top of block $i');
        expect(layout.blockAtPixel(layout.topOf(i) + layout.extentOf(i) / 2), i, reason: 'middle of block $i');
        expect(layout.blockAtPixel(layout.topOf(i) + layout.extentOf(i) - 0.1), i, reason: 'bottom of block $i');
      }
    });

    test('blockAtPixel clamps to the first and last block', () {
      final layout = _layout(blocks);
      expect(layout.blockAtPixel(-50), 0);
      expect(layout.blockAtPixel(layout.totalExtent), 4);
      expect(layout.blockAtPixel(layout.totalExtent + 500), 4);
    });
  });

  group('offsets and pixels', () {
    // 35 glyphs (2 lines), 19 (1 line), 61 (4 lines), 20 (1 line).
    final blocks = [_lineOf(35), _lineOf(19), _lineOf(61, blank: 2), _lineOf(20)];

    int lineStart(ReaderModel model, int offset) {
      final block = model.blockAt(offset);
      final start = model.offsetOf(block);
      return start + (offset - start) ~/ 20 * 20;
    }

    test('pixelOfOffset is the top of the visual line holding the offset', () {
      final layout = _layout(blocks);
      expect(layout.pixelOfOffset(0), closeTo(0, _eps));
      expect(layout.pixelOfOffset(19), closeTo(0, _eps));
      expect(layout.pixelOfOffset(20), closeTo(_line, _eps));
      expect(layout.pixelOfOffset(34), closeTo(_line, _eps));
      expect(layout.pixelOfOffset(35), closeTo(layout.topOf(1), _eps));
    });

    test('pixelOfOffset skips the blank lines above a line', () {
      final layout = _layout(blocks);
      const block = 2;
      final start = ReaderModel(blocks).offsetOf(block);
      expect(layout.pixelOfOffset(start), closeTo(layout.topOf(block) + _line, _eps));
      expect(layout.pixelOfOffset(start + 45), closeTo(layout.topOf(block) + _line + 2 * _line, _eps));
    });

    test('pixelOfOffset measures the block it is asked about', () {
      final layout = _layout(blocks);
      final start = ReaderModel(blocks).offsetOf(3);
      expect(layout.isMeasured(3), isFalse);
      layout.pixelOfOffset(start);
      expect(layout.isMeasured(3), isTrue);
    });

    test('offsetAtPixel is the first character of the visual line at the pixel', () {
      final layout = _layout(blocks);
      expect(layout.offsetAtPixel(0), 0);
      expect(layout.offsetAtPixel(_line - 1), 0);
      expect(layout.offsetAtPixel(_line), 20);
      expect(layout.offsetAtPixel(2 * _line - 1), 20);
      expect(layout.offsetAtPixel(layout.topOf(1) + 3), 35);
    });

    test('offsetAtPixel inside a later line of a paragraph with blank lines above', () {
      final layout = _layout(blocks);
      final model = ReaderModel(blocks);
      final start = model.offsetOf(2);
      final top = layout.topOf(2) + _line; // content top, below one blank line
      expect(layout.offsetAtPixel(top + 1), start);
      expect(layout.offsetAtPixel(top + _line + 1), start + 20);
      expect(layout.offsetAtPixel(top + 3 * _line + 1), start + 60);
    });

    test('offsetAtPixel clamps above and below the text', () {
      final layout = _layout(blocks);
      final model = ReaderModel(blocks);
      expect(layout.offsetAtPixel(-30), 0);
      expect(layout.offsetAtPixel(layout.totalExtent + 100), lineStart(model, model.totalLength - 1));
    });

    test('every offset round trips to the start of its visual line', () {
      final layout = _layout(blocks);
      final model = ReaderModel(blocks);
      for (var offset = 0; offset < model.totalLength; offset++) {
        final pixel = layout.pixelOfOffset(offset);
        expect(layout.offsetAtPixel(pixel), lineStart(model, offset), reason: 'offset $offset at the line top');
        expect(layout.offsetAtPixel(pixel + _line / 2), lineStart(model, offset), reason: 'offset $offset inside the line');
        expect(layout.pixelOfOffset(lineStart(model, offset)), closeTo(pixel, _eps), reason: 'offset $offset');
      }
    });

    test('consecutive visual lines are one line height apart', () {
      final layout = _layout(blocks);
      final start = ReaderModel(blocks).offsetOf(2);
      for (var line = 1; line < 4; line++) {
        expect(
          layout.pixelOfOffset(start + line * 20) - layout.pixelOfOffset(start + (line - 1) * 20),
          closeTo(_line, _eps),
          reason: 'line $line',
        );
      }
    });

    test('round trips every offset once titles, ruby lines and everything else are measured', () {
      final mixed = <NovelBlock>[
        _title('序章'),
        _lineOf(35),
        NovelLine([NovelPlain(_text(33)), const NovelRuby('潮汐', 'ちょうせき')], blankLinesBefore: 1),
        _lineOf(61),
        _title('第二章'),
        _lineOf(19, blank: 3),
        _image('1'),
        _lineOf(45),
      ];
      final layout = _layout(mixed);
      final model = ReaderModel(mixed);
      expect(layout.measureSome(0, const Duration(seconds: 30)), isTrue);

      int lineStartOf(int offset) {
        final block = model.blockAt(offset);
        final start = model.offsetOf(block);
        if (mixed[block] is! NovelLine) return start;
        return start + (offset - start) ~/ 20 * 20;
      }

      for (var offset = 0; offset < model.totalLength; offset++) {
        final pixel = layout.pixelOfOffset(offset);
        expect(layout.offsetAtPixel(pixel), lineStartOf(offset), reason: 'offset $offset');
        expect(layout.offsetAtPixel(pixel + 1), lineStartOf(offset), reason: 'offset $offset one pixel into the line');
      }
    });

    test('later lines have larger pixels', () {
      final layout = _layout(blocks);
      var previous = -1.0;
      for (var offset = 0; offset < ReaderModel(blocks).totalLength; offset += 20) {
        final pixel = layout.pixelOfOffset(offset);
        expect(pixel, greaterThan(previous), reason: 'offset $offset');
        previous = pixel;
      }
    });
  });

  group('image sizes', () {
    final blocks = [_lineOf(35), _image('1'), _lineOf(35)];
    final fallbackExtent = _column * novelImageFallbackSize.height / novelImageFallbackSize.width + _gap;

    test('an image below the anchor does not move it', () {
      final layout = _layout(blocks);
      final anchorTop = layout.topOf(0);
      final shift = layout.updateImageSize(1, const Size(400, 400), anchorBlock: 0);
      expect(shift, 0);
      expect(layout.topOf(0), anchorTop);
      expect(layout.extentOf(1), closeTo(_column + _gap, _eps));
    });

    test('an image above the anchor moves it by the height change', () {
      final layout = _layout(blocks);
      final anchorTop = layout.topOf(2);
      final shift = layout.updateImageSize(1, const Size(400, 400), anchorBlock: 2);
      expect(shift, closeTo(_column + _gap - fallbackExtent, _eps));
      expect(layout.topOf(2) - anchorTop, closeTo(shift, _eps));
    });

    test('a taller image pushes the anchor down by a positive shift', () {
      final layout = _layout(blocks, viewportHeight: 4000);
      final anchorTop = layout.topOf(2);
      final shift = layout.updateImageSize(1, const Size(100, 400), anchorBlock: 2); // 800 tall
      expect(shift, closeTo(800 + _gap - fallbackExtent, _eps));
      expect(shift, greaterThan(0));
      expect(layout.topOf(2) - anchorTop, closeTo(shift, _eps));
    });

    test('the shift counts the scroll flow cap', () {
      final layout = _layout(blocks);
      final shift = layout.updateImageSize(1, const Size(100, 400), anchorBlock: 2);
      expect(shift, closeTo(_viewport * 0.9 + _gap - fallbackExtent, _eps));
    });

    test('the anchor itself does not move', () {
      final layout = _layout(blocks);
      final shift = layout.updateImageSize(1, const Size(400, 400), anchorBlock: 1);
      expect(shift, 0);
    });

    test('an unchanged size does not shift anything', () {
      final layout = _layout(blocks);
      layout.updateImageSize(1, const Size(400, 400), anchorBlock: 2);
      expect(layout.updateImageSize(1, const Size(400, 400), anchorBlock: 2), closeTo(0, _eps));
    });

    test('the new size is written to the store under the image url', () {
      final sizes = MemoryImageSizeStore();
      final layout = _layout(blocks, sizes: sizes);
      expect(sizes.sizeOf(_imageUrl('1')), isNull);
      layout.updateImageSize(1, const Size(400, 600), anchorBlock: 0);
      expect(sizes.sizeOf(_imageUrl('1')), const Size(400, 600));
    });

    test('a layout built afterwards uses the recorded size', () {
      final sizes = MemoryImageSizeStore();
      _layout(blocks, sizes: sizes).updateImageSize(1, const Size(400, 600), anchorBlock: 0);
      expect(_layout(blocks, sizes: sizes).extentOf(1), closeTo(_column * 600 / 400 + _gap, _eps));
    });

    test('notifies listeners', () {
      final layout = _layout(blocks);
      var notified = 0;
      layout.addListener(() => notified++);
      layout.updateImageSize(1, const Size(400, 400), anchorBlock: 0);
      expect(notified, greaterThan(0));
    });
  });

  group('a long text', () {
    const count = 10000;
    // Glyph counts 35, 19 and 61 give 2, 1 and 4 lines; estimates are exact for them.
    final blocks = [for (var i = 0; i < count; i++) _lineOf(const [35, 19, 61][i % 3])];

    test('topOf, blockAtPixel and pixelOfOffset work without measuring the whole text', () {
      final layout = _layout(blocks);
      final model = ReaderModel(blocks);
      expect(layout.blockCount, count);

      final top = layout.topOf(7322);
      expect(layout.blockAtPixel(top + 1), 7322);
      expect(layout.blockAtPixel(layout.topOf(6000) + 1), 6000);
      expect(layout.blockAtPixel(layout.topOf(9999) + 1), 9999);
      expect(layout.blockAtPixel(layout.totalExtent + 10), count - 1);

      final offset = model.offsetOf(7322) + 45; // third visual line of a 61 glyph paragraph
      expect(layout.pixelOfOffset(offset), closeTo(top + 2 * _line, _eps));
      expect(layout.offsetAtPixel(top + 2 * _line + 1), model.offsetOf(7322) + 40);

      expect(layout.isMeasured(7322), isTrue);
      expect(_measuredCount(layout), lessThan(50), reason: 'only the blocks that were asked about may be measured');
    });

    test('total extent and tops agree with the extents', () {
      final layout = _layout(blocks);
      var sum = 0.0;
      for (var i = 0; i < count; i++) {
        if (i % 997 == 0) expect(layout.topOf(i), closeTo(sum, 0.5), reason: 'block $i');
        sum += layout.extentOf(i);
      }
      expect(layout.totalExtent, closeTo(sum, 0.5));
    });

    test('an image update far above the anchor shifts by one height change only', () {
      final withImage = [...blocks.take(100), _image('1'), ...blocks.skip(100)];
      final layout = _layout(withImage);
      final anchorTop = layout.topOf(9000);
      final shift = layout.updateImageSize(100, const Size(400, 400), anchorBlock: 9000);
      final fallbackExtent = _column * novelImageFallbackSize.height / novelImageFallbackSize.width + _gap;
      expect(shift, closeTo(_column + _gap - fallbackExtent, _eps));
      expect(layout.topOf(9000) - anchorTop, closeTo(shift, _eps));
      expect(_measuredCount(layout), lessThan(50));
    });
  });
}
