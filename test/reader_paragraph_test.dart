import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/ui/custom/reader/reader_line_text.dart';
import 'package:freepiv/ui/custom/reader/reader_paragraph.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';

const _palette = ReaderPalette(
  background: Color(0xFFFFFFFF),
  text: Color(0xFF1F1F1F),
  secondary: Color(0x991F1F1F),
  link: Color(0xFF0B5CAD),
  ruby: Color(0xBF1F1F1F),
  selection: Color(0x4D0B5CAD),
);

ReaderTypesetting _typesetting({double lineHeight = 1.8, TextScaler textScaler = TextScaler.noScaling}) => ReaderTypesetting(
  textSize: 10,
  lineHeight: lineHeight,
  textScaler: textScaler,
  body: TextStyle(fontSize: 10, height: lineHeight, color: _palette.text),
  chapterTitle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4, color: _palette.text),
  palette: _palette,
);

const _han = '山川河海云风雨雪花鸟虫鱼树林石田月星日光草木';
String _text(int count) => List.generate(count, (i) => _han[i % _han.length]).join();

final _url = Uri.parse('https://example.com/a');

ReaderLineText _plain(ReaderTypesetting typesetting) =>
    ReaderLineText.line(NovelLine([NovelPlain(_text(73))]), typesetting, pageJumpLabel: (page) => 'Go to $page');

ReaderLineText _withRuby(ReaderTypesetting typesetting) => ReaderLineText.line(
  NovelLine([
    NovelPlain(_text(17)),
    const NovelRuby('潮汐', 'ちょうせき'),
    NovelPlain(_text(30)),
    NovelLink('主页', _url),
    const NovelPageJump(4),
    const NovelRuby('黄昏', 'たそがれ'),
  ]),
  typesetting,
  pageJumpLabel: (page) => 'Go to $page',
);

Future<RenderParagraph> _pump(WidgetTester tester, Widget paragraph, double width) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: paragraph),
      ),
    ),
  );
  return tester.renderObject<RenderParagraph>(find.byType(RichText));
}

void main() {
  for (final (name, build) in [('plain', _plain), ('ruby', _withRuby)]) {
    for (final scaler in [TextScaler.noScaling, const TextScaler.linear(1.3)]) {
      testWidgets('a $name paragraph renders as tall as it measures at several widths (scale ${scaler.scale(1)})', (tester) async {
        final typesetting = _typesetting(textScaler: scaler);
        final text = build(typesetting);
        for (final width in [97.0, 160.0, 200.0, 333.0, 640.0]) {
          final paragraph = await _pump(tester, ReaderParagraph(text: text, typesetting: typesetting), width);
          final measured = text.painter(width).height;
          expect(paragraph.size.height, measured, reason: 'width $width');
          expect(tester.getSize(find.byType(ReaderParagraph)).height, measured, reason: 'width $width');
        }
      });
    }
  }

  testWidgets('ruby lines keep their strut height', (tester) async {
    final typesetting = _typesetting();
    final text = _withRuby(typesetting);
    final painter = text.painter(200);
    // 1.0 + 2 * (0.5 + 0.1) = 2.2 at size 10.
    final lines = readerVisualLines(painter);
    expect(lines.length, greaterThan(1));
    for (final line in lines) {
      expect(line.height, 22);
    }
    final paragraph = await _pump(tester, ReaderParagraph(text: text, typesetting: typesetting), 200);
    expect(paragraph.size.height, 22.0 * lines.length);
  });

  testWidgets('a line window is as tall as the lines it shows', (tester) async {
    final typesetting = _typesetting();
    final text = _withRuby(typesetting);
    final lines = readerVisualLines(text.painter(100));
    expect(lines.length, greaterThan(3));
    await _pump(tester, ReaderParagraph(text: text, typesetting: typesetting, firstLine: 1, lineCount: 2), 100);
    expect(tester.getSize(find.byType(ReaderParagraph)).height, lines[1].height + lines[2].height);
    await _pump(tester, ReaderParagraph(text: text, typesetting: typesetting, firstLine: 2), 100);
    final rest = lines.skip(2).fold(0.0, (sum, line) => sum + line.height);
    expect(tester.getSize(find.byType(ReaderParagraph)).height, rest);
  });

  testWidgets('taps on a link and a page jump call their handlers', (tester) async {
    final typesetting = _typesetting();
    final text = ReaderLineText.line(
      NovelLine([NovelLink('主页', _url), const NovelPlain('和'), const NovelPageJump(4)]),
      typesetting,
      pageJumpLabel: (page) => 'P$page',
    );
    Uri? link;
    int? page;
    final paragraph = await _pump(
      tester,
      ReaderParagraph(text: text, typesetting: typesetting, onLink: (url) => link = url, onPageJump: (value) => page = value),
      300,
    );
    Offset centreOf(int start, int end) {
      final box = paragraph.getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end)).first.toRect();
      return paragraph.localToGlobal(box.center);
    }

    final linkTap = text.taps[0];
    final jumpTap = text.taps[1];
    await tester.tapAt(centreOf(linkTap.start, linkTap.end));
    expect(link, _url);
    await tester.tapAt(centreOf(jumpTap.start, jumpTap.end));
    expect(page, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paints the readings without changing the layout', (tester) async {
    final typesetting = _typesetting();
    final text = _withRuby(typesetting);
    await _pump(tester, ReaderParagraph(text: text, typesetting: typesetting), 200);
    // Paints the base text first, then one paragraph per reading piece.
    expect(
      find.byType(ReaderParagraph),
      paints
        ..paragraph()
        ..paragraph()
        ..paragraph(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a ruby base of surrogate pairs split across lines splits its reading by character', (tester) async {
    final typesetting = _typesetting();
    // The indent and seven glyphs, then a base of four supplementary
    // ideographs: two end the first line of ten, two start the second.
    final text = ReaderLineText.line(NovelLine([NovelPlain(_text(7)), const NovelRuby('𠮷𠮷𠮷𠮷', 'よしのや')]), typesetting, pageJumpLabel: (page) => '$page');
    final paragraph = await _pump(tester, ReaderParagraph(text: text, typesetting: typesetting), 100);
    final ruby = text.rubies.single;
    final rows = paragraph.getBoxesForSelection(TextSelection(baseOffset: ruby.start, extentOffset: ruby.end)).map((box) => box.top).toSet();
    expect(rows, hasLength(2), reason: 'the base is split across two lines');
    // Each half of the reading (two glyphs of 5) is centred over its two base
    // glyphs: x 80-100 on the first line (22 tall), x 0-20 on the second.
    expect(
      find.byType(ReaderParagraph),
      paints
        ..paragraph()
        ..paragraph(offset: const Offset(85, 0.5))
        ..paragraph(offset: const Offset(5, 22.5)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a window counts a page jump label wrapping over several rows as one line', (tester) async {
    final typesetting = _typesetting();
    final text = ReaderLineText.line(
      const NovelLine([NovelPlain('前'), NovelPageJump(3), NovelPlain('山川河海云风雨雪')]),
      typesetting,
      pageJumpLabel: (page) => 'Go to section $page of this text',
    );
    final lines = text.linesOf(text.painter(60));
    expect(readerVisualLines(text.painter(60)).length, greaterThan(lines.length));
    for (var i = 0; i < lines.length; i++) {
      await _pump(tester, ReaderParagraph(text: text, typesetting: typesetting, firstLine: i, lineCount: 1), 60);
      expect(tester.getSize(find.byType(ReaderParagraph)).height, lines[i].height, reason: 'line $i');
    }
  });
}
