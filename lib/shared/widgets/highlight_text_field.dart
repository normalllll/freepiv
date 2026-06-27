import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HighlightRule {
  const HighlightRule({required this.pattern, required this.style});

  final RegExp pattern;
  final TextStyle style;

  @override
  bool operator ==(Object other) {
    return other is HighlightRule &&
        other.pattern.pattern == pattern.pattern &&
        other.pattern.isCaseSensitive == pattern.isCaseSensitive &&
        other.pattern.isMultiLine == pattern.isMultiLine &&
        other.pattern.isUnicode == pattern.isUnicode &&
        other.pattern.isDotAll == pattern.isDotAll &&
        other.style == style;
  }

  @override
  int get hashCode => Object.hash(pattern.pattern, pattern.isCaseSensitive, pattern.isMultiLine, pattern.isUnicode, pattern.isDotAll, style);
}

class HighlightTextEditingController extends TextEditingController {
  HighlightTextEditingController({super.text, List<HighlightRule> rules = const []}) : _rules = List.of(rules);

  List<HighlightRule> _rules;

  List<HighlightRule> get rules => List.unmodifiable(_rules);

  set rules(List<HighlightRule> value) {
    _rules = List.of(value);
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final ranges = _highlightRanges(text);
    final composing = value.composing;
    final hasComposing = withComposing && composing.isValid && !composing.isCollapsed;

    if (ranges.isEmpty && !hasComposing) {
      return TextSpan(style: style, text: text);
    }

    final children = <TextSpan>[];
    var index = 0;
    while (index < text.length) {
      final nextBoundary = _nextBoundary(index, text.length, ranges, hasComposing ? composing : null);
      final highlightStyle = _styleFor(index, ranges);
      final composingStyle = hasComposing && index >= composing.start && index < composing.end ? const TextStyle(decoration: TextDecoration.underline) : null;
      final segmentStyle = highlightStyle == null ? composingStyle : highlightStyle.merge(composingStyle);

      children.add(TextSpan(text: text.substring(index, nextBoundary), style: segmentStyle));
      index = nextBoundary;
    }

    return TextSpan(style: style, children: children);
  }

  List<_HighlightRange> _highlightRanges(String text) {
    if (_rules.isEmpty || text.isEmpty) {
      return const [];
    }

    final ranges = <_HighlightRange>[];
    for (final match in RegExp(r'\S+(?=\s)').allMatches(text)) {
      final word = match.group(0);
      if (word == null) {
        continue;
      }

      for (final rule in _rules) {
        if (rule.pattern.hasMatch(word)) {
          ranges.add(_HighlightRange(match.start, match.end, rule.style));
          break;
        }
      }
    }

    return ranges;
  }

  TextStyle? _styleFor(int offset, List<_HighlightRange> ranges) {
    for (final range in ranges) {
      if (offset >= range.start && offset < range.end) {
        return range.style;
      }
    }
    return null;
  }

  int _nextBoundary(int offset, int textLength, List<_HighlightRange> ranges, TextRange? composing) {
    var boundary = textLength;
    for (final range in ranges) {
      if (range.start > offset && range.start < boundary) {
        boundary = range.start;
      }
      if (range.end > offset && range.end < boundary) {
        boundary = range.end;
      }
    }

    if (composing != null) {
      if (composing.start > offset && composing.start < boundary) {
        boundary = composing.start;
      }
      if (composing.end > offset && composing.end < boundary) {
        boundary = composing.end;
      }
    }

    return boundary;
  }
}

class HighlightTextField extends StatefulWidget {
  const HighlightTextField({
    required this.controller,
    required this.rules,
    super.key,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.onTapOutside,
    this.maxLines = 1,
    this.style,
    this.decoration,
  });

  final HighlightTextEditingController controller;
  final List<HighlightRule> rules;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TapRegionCallback? onTapOutside;
  final int? maxLines;
  final TextStyle? style;
  final InputDecoration? decoration;

  @override
  State<HighlightTextField> createState() => _HighlightTextFieldState();
}

class _HighlightTextFieldState extends State<HighlightTextField> {
  @override
  void initState() {
    super.initState();
    _syncRules();
  }

  @override
  void didUpdateWidget(covariant HighlightTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRules();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: widget.autofocus,
      controller: widget.controller,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onTapOutside: widget.onTapOutside,
      maxLines: widget.maxLines,
      style: widget.style,
      decoration: widget.decoration,
    );
  }

  void _syncRules() {
    if (!listEquals(widget.controller.rules, widget.rules)) {
      widget.controller.rules = widget.rules;
    }
  }
}

class _HighlightRange {
  const _HighlightRange(this.start, this.end, this.style);

  final int start;
  final int end;
  final TextStyle style;
}
