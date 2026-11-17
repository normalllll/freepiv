import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';

const _palette = ReaderPalette(
  background: Color(0xFFFFFFFF),
  text: Color(0xFF1F1F1F),
  secondary: Color(0x991F1F1F),
  link: Color(0xFF0B5CAD),
  ruby: Color(0xBF1F1F1F),
  selection: Color(0x4D0B5CAD),
);

ReaderTypesetting _typesetting({bool indent = false}) => ReaderTypesetting(
  textSize: 18,
  lineHeight: 1.8,
  body: TextStyle(fontSize: 18, height: 1.8, color: _palette.text),
  chapterTitle: TextStyle(fontSize: 18 * 1.3, fontWeight: FontWeight.w600, height: 1.4, color: _palette.text),
  indent: indent,
  palette: _palette,
);

ReaderLayout _layout(ReaderModel model, {bool indent = false}) => ReaderLayout(
  model: model,
  typesetting: _typesetting(indent: indent),
  width: 720,
  flow: ReaderFlow.scroll,
  sizes: MemoryImageSizeStore(),
  viewportHeight: 900,
  pageJumpLabel: (page) => 'Go to $page',
);

const _sentence = '潮が引いた浜辺には、小さな貝殻がいくつも残されていた。';

/// One line of [count] sentences, a ruby after every [rubyEvery] of them.
NovelLine _line(int count, {int? rubyEvery, bool indented = false}) => NovelLine([
  for (var i = 0; i < count; i++) ...[NovelPlain(_sentence), if (rubyEvery != null && i % rubyEvery == 0) const NovelRuby('海原', 'うなばら')],
], authorIndented: indented);

String _plain(NovelLine line) => line.spans
    .map(
      (span) => switch (span) {
        NovelPlain(:final text) => text,
        NovelRuby(:final base) => base,
        NovelLink(:final text) => text,
        NovelPageJump() => '#',
      },
    )
    .join();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('model', () {
    test('a line up to the threshold stays one block', () {
      final line = NovelLine([NovelPlain('あ' * ReaderModel.longLine)]);
      final model = ReaderModel([line]);
      expect(model.blocks, hasLength(1));
      expect(model.continues(0), isFalse);
    });

    test('a longer line becomes pieces that hold its characters in order, with its offsets', () {
      final line = _line(4000, rubyEvery: 7);
      final model = ReaderModel([line]);
      expect(model.blocks.length, greaterThan(20));
      expect(model.totalLength, line.length);
      final pieces = model.blocks.cast<NovelLine>();
      expect(pieces.map(_plain).join(), _plain(line), reason: 'no character lost or repeated');
      var offset = 0;
      for (final (i, piece) in pieces.indexed) {
        expect(model.offsetOf(i), offset, reason: 'piece $i starts where the one before ended');
        offset += piece.length;
        expect(piece.length, lessThanOrEqualTo(ReaderModel.pieceMax), reason: 'piece $i');
        expect(model.continues(i), i > 0);
      }
    });

    test('pieces end at sentence ends where the line has them', () {
      final pieces = ReaderModel([_line(4000)]).blocks.cast<NovelLine>();
      for (final piece in pieces.take(pieces.length - 1)) {
        expect(_plain(piece).endsWith('。'), isTrue);
      }
    });

    test('a line without sentence ends is cut at a character boundary', () {
      final model = ReaderModel([
        NovelLine([NovelPlain('あ' * 10000)]),
      ]);
      expect(model.blocks.length, greaterThan(3));
      expect(model.totalLength, 10000);
    });

    test('a ruby, a link and a page jump are never split', () {
      final spans = <NovelInline>[
        for (var i = 0; i < 3000; i++) ...[
          NovelPlain('あいうえお' * 2),
          if (i % 3 == 0) NovelRuby('山' * 30, 'やま' * 30),
          if (i % 5 == 0) NovelLink('リンク' * 10, Uri.parse('https://example.com/$i')),
          if (i % 7 == 0) const NovelPageJump(2),
        ],
      ];
      final model = ReaderModel([NovelLine(spans)]);
      final pieces = model.blocks.cast<NovelLine>();
      expect(pieces.length, greaterThan(10));
      int count<T extends NovelInline>(Iterable<NovelLine> lines) => lines.expand((line) => line.spans).whereType<T>().length;
      expect(count<NovelRuby>(pieces), count<NovelRuby>([NovelLine(spans)]));
      expect(count<NovelLink>(pieces), count<NovelLink>([NovelLine(spans)]));
      expect(count<NovelPageJump>(pieces), count<NovelPageJump>([NovelLine(spans)]));
      for (final ruby in pieces.expand((piece) => piece.spans).whereType<NovelRuby>()) {
        expect(ruby.base, '山' * 30, reason: 'the whole base');
      }
    });

    test('the first piece keeps the line\'s blank lines and indent, the others have none of either', () {
      final line = NovelLine(_line(4000).spans, blankLinesBefore: 3, authorIndented: true);
      final pieces = ReaderModel([line]).blocks.cast<NovelLine>();
      expect(pieces.first.blankLinesBefore, 3);
      expect(pieces.first.authorIndented, isTrue);
      for (final piece in pieces.skip(1)) {
        expect(piece.blankLinesBefore, 0);
      }
    });
  });

  group('layout', () {
    test('pieces join with no gap and no indent, and the last one keeps the paragraph gap', () {
      final model = ReaderModel([_line(1000), _line(1)]);
      final pieces = model.blocks.length - 1;
      final layout = _layout(model, indent: true);
      expect(pieces, greaterThan(2));
      for (var i = 0; i < pieces; i++) {
        final metrics = layout.metricsOf(i);
        expect(metrics.bottomGap, i == pieces - 1 ? greaterThan(0) : 0, reason: 'piece $i');
        expect(metrics.topGap, 0);
        if (i + 1 < pieces) expect(layout.topOf(i + 1), closeTo(layout.topOf(i) + metrics.extent, 1e-6), reason: 'no space at the join after piece $i');
      }
      final joined = layout.lineTextOf(1)!;
      final first = layout.lineTextOf(0)!;
      expect(first.span.toPlainText(), startsWith('　'), reason: 'the paragraph is indented');
      expect(joined.span.toPlainText(), isNot(startsWith('　')), reason: 'a continuation is not');
    });

    test('offsets and pixels round trip across the joins', () {
      final model = ReaderModel([_line(1000, rubyEvery: 4)]);
      final layout = _layout(model);
      expect(model.blocks.length, greaterThan(2));
      for (var block = 0; block < model.blocks.length; block++) {
        final start = model.offsetOf(block);
        final pixel = layout.pixelOfOffset(start);
        expect(layout.offsetAtPixel(pixel), start, reason: 'the start of piece $block');
        expect(pixel, closeTo(layout.topOf(block), 1e-6), reason: 'piece $block starts at its top');
        if (block > 0) {
          final before = layout.pixelOfOffset(start - 1);
          expect(before, lessThan(pixel), reason: 'the character before the join is above it');
          expect(layout.offsetAtPixel(pixel - 1), lessThan(start), reason: 'a pixel above the join reads the piece before');
        }
      }
      final end = model.totalLength - 1;
      expect(layout.offsetAtPixel(layout.pixelOfOffset(end)), lessThanOrEqualTo(end));
    });

    test('the first screen of a 100k line is measured in pieces, quickly', () {
      final line = _line(100000 ~/ _sentence.length);
      expect(line.length, greaterThanOrEqualTo(99000));


      final model = ReaderModel([line]);
      final watch = Stopwatch()..start();
      final layout = _layout(model);
      var block = 0;
      while (block < layout.blockCount && (block == 0 || layout.topOf(block) < 900)) {
        layout.metricsOf(block);
        block++;
      }
      watch.stop();

      expect(watch.elapsed, lessThan(const Duration(milliseconds: 300)), reason: 'the budget the normal texts meet');
      expect(block, lessThan(model.blocks.length), reason: 'not every piece was measured');
    });
  });
}
