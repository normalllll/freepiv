import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
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

// The test font gives every glyph an advance of the font size, so a column of
// 200 holds exactly 20 glyphs at size 10.
ReaderTypesetting _typesetting({
  double textSize = 10,
  double lineHeight = 2,
  bool indent = true,
  double rubyScale = 0.5,
  TextScaler textScaler = TextScaler.noScaling,
  Locale? locale,
}) => ReaderTypesetting(
  textSize: textSize,
  lineHeight: lineHeight,
  textScaler: textScaler,
  body: TextStyle(fontSize: textSize, height: lineHeight, color: _palette.text),
  chapterTitle: TextStyle(fontSize: textSize * 1.3, fontWeight: FontWeight.w600, height: 1.4, color: _palette.text),
  rubyScale: rubyScale,
  indent: indent,
  palette: _palette,
  locale: locale,
);

String _label(int page) => 'Go to section $page';

ReaderLineText _line(List<NovelInline> spans, ReaderTypesetting typesetting, {bool authorIndented = false}) =>
    ReaderLineText.line(NovelLine(spans, authorIndented: authorIndented), typesetting, pageJumpLabel: _label);

// Ideographs without punctuation: every boundary is a legal line break.
const _han = '山川河海云风雨雪花鸟虫鱼树林石田月星日光草木';
String _text(int count) => List.generate(count, (i) => _han[i % _han.length]).join();

/// A leaf of the span tree with the style it is painted in.
typedef _Leaf = ({String text, TextStyle style});

List<_Leaf> _leaves(InlineSpan span, [TextStyle inherited = const TextStyle()]) {
  if (span is! TextSpan) return const [];
  final style = span.style == null ? inherited : inherited.merge(span.style);
  return [
    if (span.text != null) (text: span.text!, style: style),
    for (final child in span.children ?? const <InlineSpan>[]) ..._leaves(child, style),
  ];
}

_Leaf _leafWith(ReaderLineText text, String content) =>
    _leaves(text.span).singleWhere((leaf) => leaf.text == content, orElse: () => fail('no span with exactly "$content"'));

String _rendered(ReaderLineText text) => text.span.toPlainText();

// The range classes have no settled field names beyond start/end; the
// accessors below are the only place the test depends on them.
int _start(Object range) => (range as dynamic).start as int;
int _end(Object range) => (range as dynamic).end as int;
String _reading(Object ruby) => (ruby as dynamic).reading as String;
Object? _tapUrl(Object tap) => (tap as dynamic).url as Object?;
Object? _tapPage(Object tap) => (tap as dynamic).page as Object?;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final url = Uri.parse('https://example.com/author');

  group('rendered string', () {
    test('plain text without indent renders as written', () {
      final text = _line(const [NovelPlain('海风吹过渔网')], _typesetting(indent: false));
      expect(_rendered(text), '海风吹过渔网');
    });

    test('ruby renders its base only', () {
      final text = _line(const [NovelPlain('前'), NovelRuby('潮汐', 'ちょうせき'), NovelPlain('后')], _typesetting(indent: false));
      expect(_rendered(text), '前潮汐后');
    });

    test('link renders its text in the link colour, underlined', () {
      final text = _line([const NovelPlain('看'), NovelLink('作者主页', url), const NovelPlain('吧')], _typesetting(indent: false));
      expect(_rendered(text), '看作者主页吧');
      final leaf = _leafWith(text, '作者主页');
      expect(leaf.style.color, _palette.link);
      expect(leaf.style.decoration, TextDecoration.underline);
    });

    test('page jump renders the label for its page in the link colour', () {
      final text = _line(const [NovelPlain('去'), NovelPageJump(3), NovelPlain('吧')], _typesetting(indent: false));
      expect(_rendered(text), '去Go to section 3吧');
      expect(_leafWith(text, 'Go to section 3').style.color, _palette.link);
    });

    test('plain text keeps the body colour', () {
      final text = _line(const [NovelPlain('海风')], _typesetting(indent: false));
      expect(_leafWith(text, '海风').style.color, _palette.text);
    });

    test('starts with one ideographic space when indent is on and the author did not indent', () {
      final text = _line(const [NovelPlain('海风吹过')], _typesetting());
      expect(_rendered(text), '　海风吹过');
    });

    test('adds no indent when indent is off', () {
      final text = _line(const [NovelPlain('海风吹过')], _typesetting(indent: false));
      expect(_rendered(text), '海风吹过');
    });

    test('keeps an author indent as written and never doubles it', () {
      final one = _line(const [NovelPlain('　海风吹过')], _typesetting(), authorIndented: true);
      expect(_rendered(one), '　海风吹过');
      final two = _line(const [NovelPlain('　　海风吹过')], _typesetting(), authorIndented: true);
      expect(_rendered(two), '　　海风吹过');
    });

    test('keeps an author indent as written when indent is off', () {
      final text = _line(const [NovelPlain('　海风吹过')], _typesetting(indent: false), authorIndented: true);
      expect(_rendered(text), '　海风吹过');
    });

    test('a line that starts with a ruby is still indented', () {
      final text = _line(const [NovelRuby('潮汐', 'ちょうせき'), NovelPlain('来了')], _typesetting());
      expect(_rendered(text), '　潮汐来了');
    });

    test('title renders its text without indent', () {
      final text = ReaderLineText.title('第一章　黄昏', _typesetting());
      expect(_rendered(text), '第一章　黄昏');
    });

    test('lines and titles align to the start', () {
      expect(_line(const [NovelPlain('海风')], _typesetting()).textAlign, TextAlign.start);
      expect(ReaderLineText.title('黄昏', _typesetting()).textAlign, TextAlign.start);
    });

    test('line text has no ruby or tap ranges when it has no ruby, link or page jump', () {
      final text = _line(const [NovelPlain('海风吹过')], _typesetting());
      expect(text.rubies, isEmpty);
      expect(text.taps, isEmpty);
    });
  });

  group('model length', () {
    test('equals the block length for a line with every inline type', () {
      final block = NovelLine([const NovelPlain('前'), const NovelRuby('潮汐', 'ちょうせき'), NovelLink('主页', url), const NovelPageJump(2), const NovelPlain('后')]);
      for (final indent in [true, false]) {
        final text = ReaderLineText.line(block, _typesetting(indent: indent), pageJumpLabel: _label);
        expect(text.modelLength, block.length, reason: 'indent=$indent');
        expect(text.modelLength, 1 + 2 + 2 + 1 + 1);
      }
    });

    test('equals the block length for an author indented line', () {
      const block = NovelLine([NovelPlain('　　海风')], authorIndented: true);
      final text = ReaderLineText.line(block, _typesetting(), pageJumpLabel: _label);
      expect(text.modelLength, block.length);
    });

    test('equals the title length for a title', () {
      expect(ReaderLineText.title('第一章　黄昏', _typesetting()).modelLength, const NovelChapterTitle('第一章　黄昏').length);
    });

    test('is not changed by the indent', () {
      expect(_line(const [NovelPlain('海风吹过')], _typesetting()).modelLength, 4);
    });
  });

  group('offset mapping', () {
    test('is the identity for plain text without indent', () {
      final text = _line(const [NovelPlain('海风吹过')], _typesetting(indent: false));
      for (var i = 0; i <= 4; i++) {
        expect(text.renderedIndexOf(i), i);
        expect(text.modelOffsetOf(i), i);
      }
    });

    test('shifts rendered indices by the indent', () {
      final text = _line(const [NovelPlain('海风吹过')], _typesetting());
      for (var i = 0; i < 4; i++) {
        expect(text.renderedIndexOf(i), i + 1, reason: 'model offset $i');
        expect(text.modelOffsetOf(i + 1), i, reason: 'rendered index ${i + 1}');
      }
    });

    test('maps the indent character to the start of the line', () {
      final text = _line(const [NovelPlain('海风吹过')], _typesetting());
      expect(text.modelOffsetOf(0), 0);
    });

    test('maps the end of the line to the end of the rendered string', () {
      for (final indent in [true, false]) {
        final text = _line(const [NovelPlain('海风吹过')], _typesetting(indent: indent));
        expect(text.renderedIndexOf(text.modelLength), _rendered(text).length, reason: 'indent=$indent');
      }
    });

    test('does not shift the offsets of an author indented line', () {
      final text = _line(const [NovelPlain('　海风吹过')], _typesetting(), authorIndented: true);
      for (var i = 0; i < 5; i++) {
        expect(text.renderedIndexOf(i), i);
        expect(text.modelOffsetOf(i), i);
      }
    });

    test('counts only the base of a ruby', () {
      final text = _line(const [NovelPlain('前'), NovelRuby('潮汐', 'ちょうせき'), NovelPlain('后')], _typesetting(indent: false));
      expect([for (var i = 0; i <= 4; i++) text.renderedIndexOf(i)], [0, 1, 2, 3, 4]);
      expect([for (var i = 0; i < 4; i++) text.modelOffsetOf(i)], [0, 1, 2, 3]);
    });

    test('a page jump is one model character spread over its whole label', () {
      final text = _line(const [NovelPlain('ab'), NovelPageJump(2), NovelPlain('cd')], _typesetting(indent: false));
      final label = _label(2);
      expect(_rendered(text), 'ab${label}cd');
      expect(text.modelLength, 5);

      expect(text.renderedIndexOf(0), 0);
      expect(text.renderedIndexOf(1), 1);
      expect(text.renderedIndexOf(2), 2, reason: 'the jump starts where its label starts');
      expect(text.renderedIndexOf(3), 2 + label.length, reason: 'the text after the jump starts after its label');
      expect(text.renderedIndexOf(4), 2 + label.length + 1);

      for (var i = 2; i < 2 + label.length; i++) {
        expect(text.modelOffsetOf(i), 2, reason: 'rendered index $i is inside the label');
      }
      expect(text.modelOffsetOf(1), 1);
      expect(text.modelOffsetOf(2 + label.length), 3);
      expect(text.modelOffsetOf(2 + label.length + 1), 4);
    });

    test('a page jump label maps every index to the jump with an indent too', () {
      final text = _line(const [NovelPageJump(12), NovelPlain('x')], _typesetting());
      final label = _label(12);
      expect(_rendered(text), '　${label}x');
      expect(text.renderedIndexOf(0), 1);
      for (var i = 1; i < 1 + label.length; i++) {
        expect(text.modelOffsetOf(i), 0, reason: 'rendered index $i is inside the label');
      }
      expect(text.modelOffsetOf(1 + label.length), 1);
    });

    test('round trips every model offset of a line with every inline type', () {
      final block = NovelLine([
        const NovelPlain('前'),
        const NovelRuby('潮汐', 'ちょうせき'),
        NovelLink('主页', url),
        const NovelPageJump(2),
        const NovelPlain('后面'),
        const NovelPageJump(10),
      ]);
      for (final indent in [true, false]) {
        final text = ReaderLineText.line(block, _typesetting(indent: indent), pageJumpLabel: _label);
        for (var offset = 0; offset < block.length; offset++) {
          expect(text.modelOffsetOf(text.renderedIndexOf(offset)), offset, reason: 'indent=$indent offset=$offset');
        }
      }
    });

    test('maps rendered indices back monotonically and into the model range', () {
      final block = NovelLine([const NovelPlain('前'), const NovelPageJump(2), const NovelPlain('后')]);
      final text = ReaderLineText.line(block, _typesetting(), pageJumpLabel: _label);
      var previous = 0;
      for (var index = 0; index < _rendered(text).length; index++) {
        final offset = text.modelOffsetOf(index);
        expect(offset, inInclusiveRange(0, block.length - 1), reason: 'rendered index $index');
        expect(offset, greaterThanOrEqualTo(previous), reason: 'rendered index $index');
        previous = offset;
      }
    });

    test('maps title offsets one to one', () {
      final text = ReaderLineText.title('第一章　黄昏', _typesetting());
      for (var i = 0; i <= 6; i++) {
        expect(text.renderedIndexOf(i), i);
        expect(text.modelOffsetOf(i), i);
      }
    });
  });

  group('ruby and tap ranges', () {
    test('records the rendered range and reading of a ruby base', () {
      final text = _line(const [NovelPlain('前'), NovelRuby('潮汐', 'ちょうせき'), NovelPlain('后')], _typesetting(indent: false));
      expect(text.rubies, hasLength(1));
      final ruby = text.rubies.single;
      expect(_start(ruby), 1);
      expect(_end(ruby), 3);
      expect(_reading(ruby), 'ちょうせき');
      expect(_rendered(text).substring(_start(ruby), _end(ruby)), '潮汐');
    });

    test('shifts ruby ranges by the indent', () {
      final text = _line(const [NovelPlain('前'), NovelRuby('潮汐', 'ちょうせき')], _typesetting());
      final ruby = text.rubies.single;
      expect(_start(ruby), 2);
      expect(_end(ruby), 4);
      expect(_rendered(text).substring(_start(ruby), _end(ruby)), '潮汐');
    });

    test('records several rubies in text order', () {
      final text = _line(const [NovelRuby('潮汐', 'ちょうせき'), NovelPlain('和'), NovelRuby('渔网', 'ぎょもう')], _typesetting(indent: false));
      expect(text.rubies, hasLength(2));
      expect([for (final r in text.rubies) (_start(r), _end(r), _reading(r))], [(0, 2, 'ちょうせき'), (3, 5, 'ぎょもう')]);
    });

    test('a ruby after a page jump starts after the whole label', () {
      final text = _line(const [NovelPageJump(2), NovelRuby('潮汐', 'ちょうせき')], _typesetting(indent: false));
      final ruby = text.rubies.single;
      expect(_start(ruby), _label(2).length);
      expect(_end(ruby), _label(2).length + 2);
    });

    test('records the rendered range and target of a link', () {
      final text = _line([const NovelPlain('看'), NovelLink('作者主页', url), const NovelPlain('吧')], _typesetting(indent: false));
      expect(text.taps, hasLength(1));
      final tap = text.taps.single;
      expect(_start(tap), 1);
      expect(_end(tap), 5);
      expect(_tapUrl(tap), url);
      expect(_rendered(text).substring(_start(tap), _end(tap)), '作者主页');
    });

    test('records the rendered range and page of a page jump', () {
      final text = _line(const [NovelPlain('去'), NovelPageJump(3), NovelPlain('吧')], _typesetting());
      expect(text.taps, hasLength(1));
      final tap = text.taps.single;
      expect(_start(tap), 2);
      expect(_end(tap), 2 + _label(3).length);
      expect(_tapPage(tap), 3);
      expect(_rendered(text).substring(_start(tap), _end(tap)), _label(3));
    });

    test('records link and page jump ranges in text order without overlap', () {
      final text = _line([NovelLink('主页', url), const NovelPlain('和'), const NovelPageJump(4)], _typesetting(indent: false));
      expect(text.taps, hasLength(2));
      final first = text.taps[0];
      final second = text.taps[1];
      expect((_start(first), _end(first)), (0, 2));
      expect(_tapUrl(first), url);
      expect((_start(second), _end(second)), (3, 3 + _label(4).length));
      expect(_tapPage(second), 4);
    });

    test('a ruby is not a tap range and a link is not a ruby range', () {
      final text = _line([const NovelRuby('潮汐', 'ちょうせき'), NovelLink('主页', url)], _typesetting(indent: false));
      expect(text.rubies, hasLength(1));
      expect(text.taps, hasLength(1));
    });
  });

  group('strut', () {
    test('forces the line height for a line without ruby', () {
      final text = _line(const [NovelPlain('海风吹过')], _typesetting(lineHeight: 1.8));
      expect(text.strut.forceStrutHeight, isTrue);
      expect(text.strut.height, 1.8);
      expect(text.strut.leadingDistribution, TextLeadingDistribution.even);
    });

    test('keeps the line height for a ruby line when it is already tall enough', () {
      final text = _line(const [NovelRuby('潮汐', 'ちょうせき')], _typesetting(lineHeight: 2.5));
      expect(text.strut.height, closeTo(2.5, 1e-9));
      expect(text.strut.forceStrutHeight, isTrue);
      expect(text.strut.leadingDistribution, TextLeadingDistribution.even);
    });

    test('grows a ruby line to leave room for the reading above it', () {
      // 1.0 + 2 * (0.5 + 0.1) = 2.2
      for (final lineHeight in [1.55, 1.8, 2.0, 2.05]) {
        final text = _line(const [NovelPlain('前'), NovelRuby('潮汐', 'ちょうせき')], _typesetting(lineHeight: lineHeight));
        expect(text.strut.height, closeTo(2.2, 1e-9), reason: 'lineHeight=$lineHeight');
      }
    });

    test('derives the ruby line height from the ruby scale', () {
      // 1.0 + 2 * (0.4 + 0.1) = 2.0 > 1.8
      final text = _line(const [NovelRuby('潮汐', 'ちょうせき')], _typesetting(lineHeight: 1.8, rubyScale: 0.4));
      expect(text.strut.height, closeTo(2.0, 1e-9));
    });

    test('a line without ruby next to one with ruby keeps the plain height', () {
      final plain = _line(const [NovelPlain('海风吹过')], _typesetting(lineHeight: 1.55));
      final ruby = _line(const [NovelRuby('潮汐', 'ちょうせき')], _typesetting(lineHeight: 1.55));
      expect(plain.strut.height, 1.55);
      expect(ruby.strut.height, closeTo(2.2, 1e-9));
    });

    test('a title forces its strut height', () {
      expect(ReaderLineText.title('黄昏', _typesetting()).strut.forceStrutHeight, isTrue);
    });
  });

  group('painter', () {
    test('height is the number of visual lines times the line height', () {
      // 35 glyphs of 10 at width 200: 2 lines of 20.
      final text = _line([NovelPlain(_text(35))], _typesetting(indent: false));
      expect(text.painter(200).height, closeTo(40, 0.01));
      expect(text.painter(200).computeLineMetrics(), hasLength(2));
    });

    test('a single line is one line height tall', () {
      final text = _line([NovelPlain(_text(19))], _typesetting(indent: false));
      expect(text.painter(200).height, closeTo(20, 0.01));
    });

    test('a full line does not wrap', () {
      final text = _line([NovelPlain(_text(20))], _typesetting(indent: false));
      expect(text.painter(200).computeLineMetrics(), hasLength(1));
    });

    test('the indent takes one glyph of the first line', () {
      expect(_line([NovelPlain(_text(40))], _typesetting(indent: false)).painter(200).computeLineMetrics(), hasLength(2));
      expect(_line([NovelPlain(_text(40))], _typesetting()).painter(200).computeLineMetrics(), hasLength(3));
      expect(_line([NovelPlain(_text(40))], _typesetting()).painter(200).height, closeTo(60, 0.01));
    });

    test('a narrower width wraps into more lines', () {
      final text = _line([NovelPlain(_text(35))], _typesetting(indent: false));
      expect(text.painter(100).height, closeTo(80, 0.01));
    });

    test('ruby lines are as tall as their strut', () {
      // Ruby strut height 2.2 at size 10: 22 per line, 2 lines.
      final text = _line([NovelPlain(_text(30)), const NovelRuby('潮汐', 'ちょうせき')], _typesetting(indent: false));
      expect(text.painter(200).computeLineMetrics(), hasLength(2));
      expect(text.painter(200).height, closeTo(44, 0.01));
    });

    test('a ruby line is taller than the same text without ruby', () {
      final plain = _line([NovelPlain(_text(35))], _typesetting(indent: false)).painter(200).height;
      final ruby = _line([NovelPlain(_text(33)), const NovelRuby('潮汐', 'ちょうせき')], _typesetting(indent: false)).painter(200).height;
      expect(ruby, greaterThan(plain));
    });

    test('applies the text scaler', () {
      // Scaled glyphs are 20 wide: 10 per line, 4 lines of 40.
      final text = _line([NovelPlain(_text(35))], _typesetting(indent: false, textScaler: const TextScaler.linear(2)));
      expect(text.painter(200).height, closeTo(160, 0.01));
    });

    test('is configured like the rendered paragraph', () {
      const locale = Locale('ja');
      final typesetting = _typesetting(locale: locale, textScaler: const TextScaler.linear(1.5));
      final text = _line(const [NovelPlain('海风吹过'), NovelRuby('潮汐', 'ちょうせき')], typesetting);
      final painter = text.painter(300);
      expect(painter.text, text.span);
      expect(painter.strutStyle, text.strut);
      expect(painter.textAlign, text.textAlign);
      expect(painter.textScaler, typesetting.textScaler);
      expect(painter.locale, locale);
      expect(painter.textDirection, TextDirection.ltr);
    });

    test('lays out at the given width', () {
      final painter = _line([NovelPlain(_text(35))], _typesetting(indent: false)).painter(200);
      expect(painter.width, lessThanOrEqualTo(200));
      expect(painter.height, greaterThan(0));
    });

    test('a title is one title line tall', () {
      final painter = ReaderLineText.title('第一章', _typesetting()).painter(200);
      expect(painter.height, closeTo((13 * 1.4).roundToDouble(), 0.1));
    });

    test('a title wraps at the width', () {
      // 13 per glyph: 15 per line at width 200 -> 20 glyphs need 2 lines.
      final painter = ReaderLineText.title(_text(20), _typesetting()).painter(200);
      expect(painter.computeLineMetrics(), hasLength(2));
    });
  });
}
