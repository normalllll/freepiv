import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/dev/sample_novel_text.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';
import 'package:freepiv/ui/custom/reader/reader_line_text.dart';
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

const _typesetting = ReaderTypesetting(
  textSize: 10,
  lineHeight: 2,
  body: TextStyle(fontSize: 10, height: 2),
  chapterTitle: TextStyle(fontSize: 13, height: 1.4),
  indent: false,
  palette: _palette,
);

// Regular margins of 28 leave a column of 60: six glyphs per line.
const _narrow = 56.0 + 60;

String _longLabel(int page) => 'Go to section $page of this text';

ReaderLayout _layout(List<NovelBlock> blocks, {ReaderFlow flow = ReaderFlow.scroll, ImageSizeStore? sizes, double width = _narrow}) => ReaderLayout(
  model: ReaderModel(blocks),
  typesetting: _typesetting,
  width: width,
  flow: flow,
  sizes: sizes ?? MemoryImageSizeStore(),
  viewportHeight: 600,
  pageJumpLabel: _longLabel,
);

const _jumpLine = NovelLine([NovelPlain('前'), NovelPageJump(3), NovelPlain('山川河海云风雨雪')]);

const _han = '山川河海云风雨雪花鸟虫鱼树林石田月星日光草木';
String _text(int count) => List.generate(count, (i) => _han[i % _han.length]).join();

NovelUploadedImage _image(String url) => NovelUploadedImage(
  '1',
  WebviewNovelImage(
    novelImageId: '1',
    urls: WebviewNovelImageUrls(size128X128: url, size240Mw: url, size480Mw: url, size1200X1200: url, original: url),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a page jump label wrapping over several lines', () {
    test('wraps over at least three visual lines in this column', () {
      final text = ReaderLineText.line(_jumpLine, _typesetting, pageJumpLabel: _longLabel);
      final visual = readerVisualLines(text.painter(60));
      final lines = text.linesOf(text.painter(60));
      expect(visual.length - lines.length, greaterThanOrEqualTo(2), reason: 'rows inside the label join the line before them');
    });

    test('every line box shows at least one model character', () {
      final layout = _layout([_jumpLine]);
      final lines = layout.metricsOf(0).lines;
      for (final line in lines) {
        expect(line.startOffset, lessThan(line.endOffset));
      }
      expect(lines.first.startOffset, 0);
      expect(lines.last.endOffset, _jumpLine.length);
      for (var i = 1; i < lines.length; i++) {
        expect(lines[i].startOffset, lines[i - 1].endOffset);
        expect(lines[i].top, closeTo(lines[i - 1].top + lines[i - 1].height, 0.01));
      }
    });

    test('line boxes still add up to the block extent', () {
      final layout = _layout([_jumpLine]);
      final metrics = layout.metricsOf(0);
      final last = metrics.lines.last;
      expect(metrics.topGap + last.top + last.height + metrics.bottomGap, closeTo(metrics.extent, 0.01));
    });

    test('the jump offset is on the line its label continues on and round trips', () {
      final layout = _layout([_jumpLine]);
      final lines = layout.metricsOf(0).lines;
      final jumpLine = lines.firstWhere((line) => line.startOffset <= 1 && 1 < line.endOffset);
      expect(layout.pixelOfOffset(1), closeTo(jumpLine.top, 0.01));
      for (var offset = 0; offset < _jumpLine.length; offset++) {
        final pixel = layout.pixelOfOffset(offset);
        final start = layout.offsetAtPixel(pixel + 1);
        expect(start, lessThanOrEqualTo(offset));
        expect(layout.pixelOfOffset(start), closeTo(pixel, 0.01), reason: 'offset $offset');
      }
    });

    test('pages in a small page height are never empty', () {
      final layout = _layout([
        _jumpLine,
        _jumpLine,
        const NovelLine([NovelPlain('山川')]),
      ], flow: ReaderFlow.paged);
      final pages = ReaderPaginator(layout, pageHeight: 25).pagesOfChapter(0);
      for (final page in pages) {
        expect(page.startOffset, lessThan(page.endOffset), reason: 'page ${page.index}');
      }
    });
  });

  group('unusable image sizes', () {
    for (final size in [Size.zero, const Size(0, 100), const Size(100, 0), const Size(-4, 8), const Size(double.nan, 10), const Size(10, double.infinity)]) {
      test('$size is ignored', () {
        const url = 'https://example.com/novel/1.jpg';
        final sizes = MemoryImageSizeStore();
        final layout = _layout(
          [
            const NovelLine([NovelPlain('山川')]),
            _image(url),
            const NovelLine([NovelPlain('河海')]),
          ],
          sizes: sizes,
          width: 256,
        );
        final extent = layout.extentOf(1);
        final total = layout.totalExtent;
        var notified = 0;
        layout.addListener(() => notified++);
        expect(layout.updateImageSize(1, size, anchorBlock: 2), 0);
        expect(layout.extentOf(1), extent);
        expect(layout.totalExtent, total);
        expect(layout.topOf(2).isFinite, isTrue);
        expect(sizes.sizeOf(url), isNull);
        expect(notified, 0);
      });
    }
  });

  test('measureSome finishes with an anchor that moves on every call', () {
    final blocks = <NovelBlock>[
      for (var c = 0; c < 6; c++) ...[
        NovelChapterTitle('章$c'),
        for (var i = 0; i < 40; i++) NovelLine([NovelPlain(_text(10 + i))]),
      ],
    ];
    final layout = _layout(blocks, width: 256);
    var calls = 0;
    while (!layout.measureSome((calls * 37) % blocks.length, Duration.zero)) {
      calls++;
      expect(calls, lessThan(blocks.length * 2));
    }
    for (var i = 0; i < blocks.length; i++) {
      expect(layout.isMeasured(i), isTrue, reason: 'block $i');
    }
  });

  test('every line top maps back to its own line, however the text was measured', () {
    // Fractional line heights make the prefix sums round.
    const typesetting = ReaderTypesetting(
      textSize: 17,
      lineHeight: 1.83,
      body: TextStyle(fontSize: 17, height: 1.83),
      chapterTitle: TextStyle(fontSize: 22.1, height: 1.4),
      palette: _palette,
    );
    final layout = ReaderLayout(
      model: ReaderModel(parseNovelText(sampleLongNovelText())),
      typesetting: typesetting,
      width: 733.3,
      flow: ReaderFlow.scroll,
      sizes: MemoryImageSizeStore(),
      viewportHeight: 701.7,
      pageJumpLabel: _longLabel,
    );
    final blocks = layout.blockCount;
    // Measure in a scattered order, so blocks above any checked one are a mix of measured and estimated.
    for (var i = 0; i < blocks; i += 7) {
      layout.metricsOf((i * 131) % blocks);
    }
    var checked = 0;
    for (var block = blocks ~/ 2; block < blocks ~/ 2 + 400; block++) {
      for (final line in layout.metricsOf(block).lines) {
        expect(layout.offsetAtPixel(layout.pixelOfOffset(line.startOffset)), line.startOffset, reason: 'block $block');
        checked++;
      }
    }
    expect(checked, greaterThan(400));
  });
}
