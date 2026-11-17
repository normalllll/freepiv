// app-owned: novel reader text
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:freepiv/ui/custom/reader/reader_line_text.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';

/// One paragraph (or chapter title) of the body, rendered from [text] with
/// the readings of its rubies painted over their bases.
///
/// Rubies never change the layout: the strut of a ruby line leaves room for
/// them, so the rendered height is the height [ReaderLineText.painter] measures.
class ReaderParagraph extends StatefulWidget {
  const ReaderParagraph({required this.text, required this.typesetting, this.onLink, this.onPageJump, this.firstLine = 0, this.lineCount, super.key});

  final ReaderLineText text;
  final ReaderTypesetting typesetting;
  final ValueChanged<Uri>? onLink;
  final ValueChanged<int>? onPageJump;

  /// Shows only lines `[firstLine, firstLine + lineCount)` of the laid-out
  /// paragraph (for pages); a null [lineCount] shows every line from [firstLine].
  final int firstLine;
  final int? lineCount;

  @override
  State<ReaderParagraph> createState() => _ReaderParagraphState();
}

class _ReaderParagraphState extends State<ReaderParagraph> {
  final _recognizers = <TapGestureRecognizer>[];
  late InlineSpan _span;

  @override
  void initState() {
    super.initState();
    _span = _buildSpan();
  }

  @override
  void didUpdateWidget(ReaderParagraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        (oldWidget.onLink == null) != (widget.onLink == null) ||
        (oldWidget.onPageJump == null) != (widget.onPageJump == null)) {
      _disposeRecognizers();
      _span = _buildSpan();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  /// The text's span with a tap recognizer on each link and page jump leaf
  /// that has a handler. Recognizers do not change the layout.
  InlineSpan _buildSpan() {
    final root = widget.text.span;
    final taps = widget.text.taps;
    if (taps.isEmpty || root is! TextSpan || root.children == null) return root;
    var index = root.text?.length ?? 0;
    final children = <InlineSpan>[];
    for (final child in root.children!) {
      final length = child.toPlainText(includeSemanticsLabels: false).length;
      final tap = taps.where((tap) => tap.start == index && tap.end == index + length).firstOrNull;
      final recognizer = tap == null ? null : _recognizerFor(tap);
      children.add(recognizer == null || child is! TextSpan ? child : TextSpan(text: child.text, style: child.style, recognizer: recognizer));
      index += length;
    }
    return TextSpan(text: root.text, style: root.style, children: children);
  }

  TapGestureRecognizer? _recognizerFor(ReaderTapRange tap) {
    final VoidCallback? onTap;
    if (tap.url case final url?) {
      onTap = widget.onLink == null ? null : () => widget.onLink?.call(url);
    } else if (tap.page case final page?) {
      onTap = widget.onPageJump == null ? null : () => widget.onPageJump?.call(page);
    } else {
      onTap = null;
    }
    if (onTap == null) return null;
    final recognizer = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final typesetting = widget.typesetting;
    final body = typesetting.body;
    final paragraph = DefaultTextStyle(
      style: const TextStyle(),
      child: Text.rich(
        _span,
        // The span root carries its full style (titles derive theirs from the
        // body), so this outer body style changes nothing in the layout.
        style: body,
        strutStyle: text.strut,
        textAlign: text.textAlign,
        textScaler: text.textScaler,
        locale: text.locale,
        textDirection: text.textDirection,
        softWrap: true,
        overflow: TextOverflow.clip,
        textWidthBasis: TextWidthBasis.parent,
        textHeightBehavior: const TextHeightBehavior(),
        selectionColor: typesetting.palette.selection,
      ),
    );
    return _RubyParagraph(
      text: text,
      rubyStyle: TextStyle(
        fontFamily: body.fontFamily,
        fontFamilyFallback: body.fontFamilyFallback,
        fontSize: typesetting.textSize * typesetting.rubyScale,
        height: 1,
        color: typesetting.palette.ruby,
      ),
      textSize: typesetting.textSize,
      firstLine: widget.firstLine,
      lineCount: widget.lineCount,
      // Text joins the selection area; the empty default style, explicit
      // height behaviour and no bold-text override keep the rendered
      // paragraph configured exactly like the measuring painter.
      child: MediaQuery.boldTextOf(context) ? MediaQuery(data: MediaQuery.of(context).copyWith(boldText: false), child: paragraph) : paragraph,
    );
  }
}

class _RubyParagraph extends SingleChildRenderObjectWidget {
  const _RubyParagraph({
    required this.text,
    required this.rubyStyle,
    required this.textSize,
    required this.firstLine,
    required this.lineCount,
    required super.child,
  });

  final ReaderLineText text;
  final TextStyle rubyStyle;
  final double textSize;
  final int firstLine;
  final int? lineCount;

  @override
  _RenderRubyParagraph createRenderObject(BuildContext context) =>
      _RenderRubyParagraph(text: text, rubyStyle: rubyStyle, textSize: textSize, firstLine: firstLine, lineCount: lineCount);

  @override
  void updateRenderObject(BuildContext context, _RenderRubyParagraph renderObject) {
    renderObject
      ..text = text
      ..rubyStyle = rubyStyle
      ..textSize = textSize
      ..firstLine = firstLine
      ..lineCount = lineCount;
  }
}

/// A reading laid out and placed relative to the paragraph's top left.
class _PlacedReading {
  _PlacedReading(this.painter, this.offset);

  final TextPainter painter;
  final Offset offset;
}

/// Lays the paragraph out whole, shows the window of lines asked for and
/// paints the ruby readings after the paragraph.
class _RenderRubyParagraph extends RenderProxyBox {
  _RenderRubyParagraph({required this._text, required this._rubyStyle, required this._textSize, required this._firstLine, required this._lineCount});

  ReaderLineText _text;
  set text(ReaderLineText value) {
    if (identical(value, _text)) return;
    _text = value;
    markNeedsLayout();
  }

  TextStyle _rubyStyle;
  set rubyStyle(TextStyle value) {
    if (value == _rubyStyle) return;
    _rubyStyle = value;
    _clearReadings();
    markNeedsPaint();
  }

  double _textSize;
  set textSize(double value) {
    if (value == _textSize) return;
    _textSize = value;
    _clearReadings();
    markNeedsPaint();
  }

  int _firstLine;
  set firstLine(int value) {
    if (value == _firstLine) return;
    _firstLine = value;
    markNeedsLayout();
  }

  int? _lineCount;
  set lineCount(int? value) {
    if (value == _lineCount) return;
    _lineCount = value;
    markNeedsLayout();
  }

  /// How far the paragraph is shifted up to show the first line of the window.
  double _windowTop = 0;
  bool _windowed = false;
  List<_PlacedReading>? _readings;

  /// The text's lines at [_linesWidth], kept across layouts of the same text.
  List<ReaderTextLine>? _lines;
  ReaderLineText? _linesText;
  double _linesWidth = 0;

  List<ReaderTextLine> _textLines(double width) {
    if (_lines != null && identical(_linesText, _text) && _linesWidth == width) return _lines!;
    final painter = _text.painter(width);
    final lines = _text.linesOf(painter);
    painter.dispose();
    _linesText = _text;
    _linesWidth = width;
    return _lines = lines;
  }

  /// The rendered paragraph, which a selection area or another wrapper may
  /// hold below the child rather than be.
  RenderParagraph? get _paragraph {
    RenderParagraph? found;
    void visit(RenderObject node) {
      if (found != null) return;
      if (node is RenderParagraph) {
        found = node;
        return;
      }
      node.visitChildren(visit);
    }

    if (child case final child?) visit(child);
    return found;
  }

  void _clearReadings() {
    for (final reading in _readings ?? const <_PlacedReading>[]) {
      reading.painter.dispose();
    }
    _readings = null;
  }

  @override
  void detach() {
    _clearReadings();
    super.detach();
  }

  @override
  void dispose() {
    _clearReadings();
    super.dispose();
  }

  @override
  void performLayout() {
    _clearReadings();
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(BoxConstraints(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth), parentUsesSize: true);
    _windowed = _firstLine > 0 || _lineCount != null;
    if (!_windowed) {
      _windowTop = 0;
      size = constraints.constrain(child.size);
      return;
    }
    final lines = _textLines(constraints.maxWidth);
    final first = _firstLine.clamp(0, lines.length);
    final end = _lineCount == null ? lines.length : math.min(lines.length, first + _lineCount!);
    var top = 0.0;
    for (var i = 0; i < first; i++) {
      top += lines[i].height;
    }
    var height = 0.0;
    for (var i = first; i < end; i++) {
      height += lines[i].height;
    }
    _windowTop = top;
    size = constraints.constrain(Size(child.size.width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    if (!_windowed) {
      _paintContent(context, offset);
      return;
    }
    layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) => _paintContent(context, offset.translate(0, -_windowTop)),
      oldLayer: layer as ClipRectLayer?,
    );
  }

  void _paintContent(PaintingContext context, Offset offset) {
    context.paintChild(child!, offset);
    final readings = _readings ??= _placeReadings();
    if (readings.isEmpty) return;
    final canvas = context.canvas;
    for (final reading in readings) {
      reading.painter.paint(canvas, offset + reading.offset);
    }
  }

  /// Each reading centred over its base on every line the base occupies; a
  /// base split across lines gets the reading split by base length.
  List<_PlacedReading> _placeReadings() {
    final paragraph = _paragraph;
    if (paragraph == null || _text.rubies.isEmpty) return const [];
    final scaler = paragraph.textScaler;
    final em = scaler.scale(_textSize);
    final placed = <_PlacedReading>[];
    final rendered = _text.span.toPlainText(includeSemanticsLabels: false);
    for (final ruby in _text.rubies) {
      final lines = _lineRects(paragraph, ruby.start, ruby.end, rendered);
      if (lines.isEmpty) continue;
      // Split by code points, so a surrogate pair is never cut in two.
      final reading = ruby.reading.runes.toList();
      final baseLength = rendered.substring(ruby.start, ruby.end).runes.length;
      var before = 0;
      for (final (rect, characters) in lines) {
        final from = (reading.length * before / baseLength).round();
        before += characters;
        final to = (reading.length * before / baseLength).round();
        if (to <= from) continue;
        final painter = TextPainter(
          text: TextSpan(text: String.fromCharCodes(reading, from, to), style: _rubyStyle),
          textScaler: scaler,
          textDirection: TextDirection.ltr,
          locale: paragraph.locale,
          maxLines: 1,
        )..layout();
        final maxLeft = math.max(0.0, size.width - painter.width);
        final left = (rect.center.dx - painter.width / 2).clamp(0.0, maxLeft);
        // The glyphs fill the middle em of the line; the reading sits in the
        // half-leading above them with a small gap.
        final glyphTop = rect.top + (rect.height - em) / 2;
        final top = glyphTop - em * 0.05 - painter.height;
        placed.add(_PlacedReading(painter, Offset(left, top)));
      }
    }
    return placed;
  }

  /// The union of the base's glyph boxes on each line it occupies, with the
  /// number of base code points on that line. Boxes span the whole line height.
  List<(Rect, int)> _lineRects(RenderParagraph paragraph, int start, int end, String rendered) {
    List<Rect> rowsOf(int from, int to) => _groupByLine(
      paragraph.getBoxesForSelection(
        TextSelection(baseOffset: from, extentOffset: to),
        boxHeightStyle: ui.BoxHeightStyle.strut,
      ),
    );

    final whole = rowsOf(start, end);
    if (whole.length <= 1) {
      return [for (final rect in whole) (rect, rendered.substring(start, end).runes.length)];
    }
    // A base split across lines: measure the part on each line, as line
    // boundaries never fall inside a character.
    final lines = <(Rect, int)>[];
    for (final line in _textLines(constraints.maxWidth)) {
      final from = math.max(start, line.renderedStart);
      final to = math.min(end, line.renderedEnd);
      if (from >= to) continue;
      final rows = rowsOf(from, to);
      if (rows.isEmpty) continue;
      lines.add((rows.reduce((a, b) => a.expandToInclude(b)), rendered.substring(from, to).runes.length));
    }
    return lines;
  }

  static List<Rect> _groupByLine(List<TextBox> boxes) {
    final lines = <Rect>[];
    for (final box in boxes) {
      final rect = box.toRect();
      if (lines.isNotEmpty && (lines.last.top - rect.top).abs() < 0.5) {
        lines.last = lines.last.expandToInclude(rect);
      } else {
        lines.add(rect);
      }
    }
    return lines;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: Offset(0, -_windowTop),
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, -_windowTop, 0, 1);
  }
}
