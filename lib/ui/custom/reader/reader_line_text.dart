// app-owned: novel reader text
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';

/// Rendered characters `[start, end)` of a ruby base, with its reading.
@immutable
class ReaderRubyRange {
  const ReaderRubyRange({required this.start, required this.end, required this.reading});

  final int start;
  final int end;
  final String reading;
}

/// Rendered characters `[start, end)` that act on a tap: a link to [url] or
/// a jump to section [page]. Exactly one of the two is set.
@immutable
class ReaderTapRange {
  const ReaderTapRange.link({required this.start, required this.end, required Uri this.url}) : page = null;
  const ReaderTapRange.pageJump({required this.start, required this.end, required int this.page}) : url = null;

  final int start;
  final int end;
  final Uri? url;
  final int? page;
}

/// One run of the rendered string and the model characters it shows. An
/// atomic run shows one model character as several rendered ones; the
/// indent shows a rendered character with no model length. A run of Korean
/// text also holds word joiners with no model length: [joinsBefore] lists
/// the run's model offsets each joiner stands in front of.
class _Run {
  const _Run(this.modelStart, this.modelLength, this.renderedStart, this.renderedLength, {this.atomic = false, this.joinsBefore = const []});

  final int modelStart;
  final int modelLength;
  final int renderedStart;
  final int renderedLength;
  final bool atomic;
  final List<int> joinsBefore;
}

const _ideographicSpace = '　';

/// U+2060 WORD JOINER: no width, and no line break at its place.
const readerWordJoiner = '\u2060';

bool _isHangul(int unit) =>
    (unit >= 0xAC00 && unit <= 0xD7A3) ||
    (unit >= 0x1100 && unit <= 0x11FF) ||
    (unit >= 0x3130 && unit <= 0x318F) ||
    (unit >= 0xA960 && unit <= 0xA97F) ||
    (unit >= 0xD7B0 && unit <= 0xD7FF);

/// [text] with a word joiner between every two consecutive Hangul characters,
/// and the offsets in [text] each joiner stands in front of.
(String, List<int>) _joinHangul(String text) {
  final joins = <int>[];
  final out = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && _isHangul(text.codeUnitAt(i)) && _isHangul(text.codeUnitAt(i - 1))) {
      out.write(readerWordJoiner);
      joins.add(i);
    }
    out.writeCharCode(text.codeUnitAt(i));
  }
  return (out.toString(), joins);
}

/// [text] as it is copied: without the word joiners the reader added.
String readerCopiedText(String text) => text.replaceAll(readerWordJoiner, '');

/// What a [NovelLine] (or a chapter title) shows, with the map between model
/// character offsets and indices in the rendered string.
///
/// The same span, strut, alignment, scaler and locale feed the measuring
/// [painter] and the rendered paragraph, so both break lines identically.
@immutable
class ReaderLineText {
  const ReaderLineText._({
    required this.span,
    required this.strut,
    required this.textAlign,
    required this.rubies,
    required this.taps,
    required this.modelLength,
    required this.textScaler,
    required this.locale,
    required this._runs,
    required this._renderedLength,
  });

  /// [continuation] is a piece that goes on from the line before it: it has no indent of its own.
  factory ReaderLineText.line(NovelLine line, ReaderTypesetting typesetting, {required String Function(int page) pageJumpLabel, bool continuation = false}) {
    final palette = typesetting.palette;
    final children = <InlineSpan>[];
    final runs = <_Run>[];
    final rubies = <ReaderRubyRange>[];
    final taps = <ReaderTapRange>[];
    var model = 0;
    var rendered = 0;
    var hasRuby = false;

    void add(String text, int modelLength, {TextStyle? style, bool atomic = false, bool words = false}) {
      var joins = const <int>[];
      if (words && typesetting.joinsHangul) (text, joins) = _joinHangul(text);
      children.add(TextSpan(text: text, style: style));
      runs.add(_Run(model, modelLength, rendered, text.length, atomic: atomic, joinsBefore: joins));
      model += modelLength;
      rendered += text.length;
    }

    if (typesetting.indent && !line.authorIndented && !continuation) add(_ideographicSpace, 0);
    for (final span in line.spans) {
      switch (span) {
        case NovelPlain(:final text):
          if (text.isNotEmpty) add(text, text.length, words: true);
        case NovelRuby(:final base, :final reading):
          hasRuby = true;
          rubies.add(ReaderRubyRange(start: rendered, end: rendered + base.length, reading: reading));
          add(base, base.length);
        case NovelLink(:final text, :final url):
          final start = rendered;
          add(
            text,
            text.length,
            style: TextStyle(color: palette.link, decoration: TextDecoration.underline, decorationColor: palette.link),
            words: true,
          );
          taps.add(ReaderTapRange.link(start: start, end: rendered, url: url));
        case NovelPageJump(:final page):
          final label = pageJumpLabel(page);
          taps.add(ReaderTapRange.pageJump(start: rendered, end: rendered + label.length, page: page));
          add(label, 1, style: TextStyle(color: palette.link), atomic: true);
      }
    }

    final body = typesetting.body;
    // Ruby lines leave at least the reading and a tenth of the size in the
    // half-leading above each line.
    final height = hasRuby ? math.max(typesetting.lineHeight, 1.0 + 2 * (typesetting.rubyScale + 0.1)) : typesetting.lineHeight;
    return ReaderLineText._(
      span: TextSpan(style: body, children: children),
      strut: StrutStyle(
        fontFamily: body.fontFamily,
        fontFamilyFallback: body.fontFamilyFallback,
        fontSize: typesetting.textSize,
        height: height,
        leadingDistribution: TextLeadingDistribution.even,
        forceStrutHeight: true,
      ),
      textAlign: TextAlign.start,
      rubies: List.unmodifiable(rubies),
      taps: List.unmodifiable(taps),
      modelLength: model,
      textScaler: typesetting.textScaler,
      locale: typesetting.locale,
      runs: runs,
      renderedLength: rendered,
    );
  }

  factory ReaderLineText.title(String title, ReaderTypesetting typesetting) {
    final style = typesetting.chapterTitle;
    return ReaderLineText._(
      span: TextSpan(style: style, text: title),
      strut: StrutStyle(
        fontFamily: style.fontFamily,
        fontFamilyFallback: style.fontFamilyFallback,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        height: style.height,
        leadingDistribution: TextLeadingDistribution.even,
        forceStrutHeight: true,
      ),
      textAlign: TextAlign.start,
      rubies: const [],
      taps: const [],
      modelLength: title.length,
      textScaler: typesetting.textScaler,
      locale: typesetting.locale,
      runs: [_Run(0, title.length, 0, title.length)],
      renderedLength: title.length,
    );
  }

  /// A root [TextSpan] whose children are the leaves in rendered order;
  /// links and page jumps are leaves of their own.
  final InlineSpan span;
  final StrutStyle strut;
  final TextAlign textAlign;
  final List<ReaderRubyRange> rubies;
  final List<ReaderTapRange> taps;

  /// Equals the block's length.
  final int modelLength;
  final TextScaler textScaler;
  final Locale? locale;
  final List<_Run> _runs;
  final int _renderedLength;

  TextDirection get textDirection => TextDirection.ltr;

  /// The rendered index of model [modelOffset] within the block; the end of
  /// the block maps to the end of the rendered string.
  @visibleForTesting
  int renderedIndexOf(int modelOffset) {
    if (modelOffset >= modelLength) return _renderedLength;
    final at = math.max(0, modelOffset);
    for (final run in _runs) {
      if (run.modelLength == 0 || at >= run.modelStart + run.modelLength) continue;
      if (run.atomic) return run.renderedStart;
      final within = at - run.modelStart;
      return run.renderedStart + within + run.joinsBefore.where((join) => join <= within).length;
    }
    return _renderedLength;
  }

  /// The model offset within the block of rendered [renderedIndex]; inside
  /// an atomic run it is that run's model start.
  int modelOffsetOf(int renderedIndex) {
    if (renderedIndex >= _renderedLength) return modelLength;
    final at = math.max(0, renderedIndex);
    for (final run in _runs) {
      if (at >= run.renderedStart + run.renderedLength) continue;
      if (run.atomic || run.modelLength == 0) return run.modelStart;
      final within = at - run.renderedStart;
      // The joiner at rendered offset `join + index` is not a model character.
      var joiners = 0;
      for (final (index, join) in run.joinsBefore.indexed) {
        if (join + index < within) joiners++;
      }
      return run.modelStart + within - joiners;
    }
    return modelLength;
  }

  /// A painter laid out at [width], configured like the rendered paragraph.
  TextPainter painter(double width) =>
      TextPainter(text: span, strutStyle: strut, textAlign: textAlign, textScaler: textScaler, locale: locale, textDirection: textDirection)
        ..layout(maxWidth: width);

  /// The lines of [painter] (laid out from this text) as the reader counts
  /// them: a visual line that starts at the same model offset as the one
  /// before it (inside a page jump label wrapping over several lines) joins
  /// that line, so every line but those of an empty text shows at least one
  /// model character.
  List<ReaderTextLine> linesOf(TextPainter painter) {
    final visual = readerVisualLines(painter);
    final lines = <({double top, double height, int renderedStart, int start})>[];
    for (var i = 0; i < visual.length; i++) {
      final box = visual[i];
      final renderedStart = i == 0 ? 0 : math.min(painter.getPositionForOffset(Offset(0, box.top + box.height / 2)).offset, _renderedLength);
      final start = i == 0 ? 0 : modelOffsetOf(renderedStart);
      if (lines.isNotEmpty && start <= lines.last.start) {
        final last = lines.removeLast();
        lines.add((top: last.top, height: box.top + box.height - last.top, renderedStart: last.renderedStart, start: last.start));
      } else {
        lines.add((top: box.top, height: box.height, renderedStart: renderedStart, start: start));
      }
    }
    return [
      for (var i = 0; i < lines.length; i++)
        ReaderTextLine(
          top: lines[i].top,
          height: lines[i].height,
          renderedStart: lines[i].renderedStart,
          renderedEnd: i + 1 < lines.length ? lines[i + 1].renderedStart : _renderedLength,
          start: lines[i].start,
          end: i + 1 < lines.length ? lines[i + 1].start : modelLength,
        ),
    ];
  }
}

/// One line of a laid-out [ReaderLineText]: its box relative to the text's
/// top, its rendered characters `[renderedStart, renderedEnd)` and the model
/// offsets `[start, end)` within the block it shows.
@immutable
class ReaderTextLine {
  const ReaderTextLine({
    required this.top,
    required this.height,
    required this.renderedStart,
    required this.renderedEnd,
    required this.start,
    required this.end,
  });

  final double top;
  final double height;
  final int renderedStart;
  final int renderedEnd;
  final int start;
  final int end;
}

/// The top and height of each visual line of a laid-out [painter].
///
/// [LineMetrics.height] reports the run's own height, not a forced strut's,
/// so lines are placed from the distance between their baselines (every
/// line shares one strut) and the last one ends at the painter's height.
List<({double top, double height})> readerVisualLines(TextPainter painter) {
  final metrics = painter.computeLineMetrics();
  if (metrics.isEmpty) return const [];
  final first = metrics.first.baseline;
  final tops = [for (final line in metrics) line.baseline - first];
  return [for (var i = 0; i < tops.length; i++) (top: tops[i], height: (i + 1 < tops.length ? tops[i + 1] : painter.height) - tops[i])];
}
