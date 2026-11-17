import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/ui/custom/reader/reader_line_text.dart';
import 'package:freepiv/ui/custom/reader/reader_text.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';

import 'support/frost_test_app.dart';

const _palette = ReaderPalette(
  background: Color(0xFFFFFFFF),
  text: Color(0xFF1F1F1F),
  secondary: Color(0x991F1F1F),
  link: Color(0xFF0B5CAD),
  ruby: Color(0xBF1F1F1F),
  selection: Color(0x4D0B5CAD),
);

ReaderTypesetting _typesetting({bool joinsHangul = true, bool indent = true}) => ReaderTypesetting(
  textSize: 10,
  lineHeight: 2,
  body: TextStyle(fontSize: 10, height: 2, color: _palette.text),
  chapterTitle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4, color: _palette.text),
  indent: indent,
  palette: _palette,
  joinsHangul: joinsHangul,
);

ReaderLineText _line(List<NovelInline> spans, {ReaderTypesetting? typesetting}) =>
    ReaderLineText.line(NovelLine(spans), typesetting ?? _typesetting(), pageJumpLabel: (page) => 'Go to $page');

String _rendered(ReaderLineText text) => text.span.toPlainText(includeSemanticsLabels: false);

const _joiner = readerWordJoiner;

void main() {
  group('Korean words', () {
    test('consecutive Hangul characters are joined and spaces are not', () {
      final text = _line(const [NovelPlain('한국어 문장, ok 하나')], typesetting: _typesetting(indent: false));
      expect(_rendered(text), '한$_joiner국$_joiner어 문$_joiner장, ok 하$_joiner나');
    });

    test('nothing is joined for other languages', () {
      final text = _line(const [NovelPlain('한국어')], typesetting: _typesetting(joinsHangul: false, indent: false));
      expect(_rendered(text), '한국어');
    });

    test('joiners have no model length and the offsets map across them', () {
      final text = _line(const [NovelPlain('한국어 문장')], typesetting: _typesetting(indent: false));
      expect(text.modelLength, 6);
      // 한 ⁠ 국 ⁠ 어 ␠ 문 ⁠ 장
      expect([for (var model = 0; model <= 6; model++) text.renderedIndexOf(model)], [0, 2, 4, 5, 6, 8, 9]);
      expect([for (var rendered = 0; rendered <= 9; rendered++) text.modelOffsetOf(rendered)], [0, 1, 1, 2, 2, 3, 4, 5, 5, 6]);
    });

    test('the offsets stay right after the indent, a ruby and a link', () {
      final text = _line([const NovelPlain('안녕'), NovelRuby('하세요', 'x'), NovelLink('링크입니다', Uri.parse('https://example.com'))]);
      expect(text.modelLength, 2 + 3 + 5);
      for (var model = 0; model <= text.modelLength; model++) {
        expect(text.modelOffsetOf(text.renderedIndexOf(model)), model, reason: 'model offset $model');
      }
      final link = text.taps.single;
      expect(_rendered(text).substring(link.start, link.end), '링$_joiner크$_joiner입$_joiner니$_joiner다');
    });

    test('a joined word does not break inside, a space does', () {
      // 20 glyphs per line at size 10 in the test font.
      final text = _line(const [NovelPlain('가나다라마바사아자차 카타파하거너더러머버서어저처')], typesetting: _typesetting(indent: false));
      final painter = text.painter(200);
      final lines = text.linesOf(painter);
      expect(lines.length, greaterThan(1));
      final rendered = _rendered(text);
      expect(rendered.substring(lines[1].renderedStart).startsWith('카'), isTrue, reason: 'the second word starts the second line, whole');
    });
  });

  testWidgets('copying a selection leaves the joiners out', (tester) async {
    final text = _line(const [NovelPlain('한국어 문장')], typesetting: _typesetting(indent: false));
    final area = GlobalKey();
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(
      frostTestApp(
        home: ReaderSelectableText(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              key: area,
              width: 200,
              child: ReaderParagraph(text: text, typesetting: _typesetting(indent: false)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final region = tester.state<SelectableRegionState>(find.byType(SelectableRegion));
    region.selectAll(SelectionChangedCause.toolbar);
    await tester.pump();
    Actions.invoke(tester.element(find.byType(ReaderParagraph)), CopySelectionTextIntent.copy);
    await tester.pump();
    expect(copied, '한국어 문장');
  });
}
