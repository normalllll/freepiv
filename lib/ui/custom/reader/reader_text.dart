// app-owned: 小说阅读器正文
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// The reader's own typesetting: the body in the reading
/// font at the size and line height the reader chose, chapter titles a step
/// above it, and the space between paragraphs following the line height.
/// Fonts come from FrostTypography, colours from the theme tokens.
@immutable
class ReaderTypesetting {
  const ReaderTypesetting({required this.body, required this.chapter, required this.paragraphGap});

  /// The body text at [size] and line height [spacing] (a multiple of the size).
  factory ReaderTypesetting.of(BuildContext context, {required double size, required double spacing}) {
    final type = FrostTypography.of(context);
    final tokens = FrostThemeTokens.of(context);
    final base = type.style(FrostTextRole.body);
    final title = type.style(FrostTextRole.title2);
    final body = base.copyWith(fontSize: size, height: spacing, color: tokens.textPrimary);
    return ReaderTypesetting(
      body: body,
      chapter: title.copyWith(fontSize: size * chapterScale, height: chapterLineHeight, color: tokens.textPrimary),
      paragraphGap: size * (spacing - 1) + size * paragraphGapScale,
    );
  }

  /// Chapter titles stand this much above the body size.
  static const chapterScale = 1.3;
  static const chapterLineHeight = 1.4;

  /// The space between paragraphs beyond their leading, as a share of the size.
  static const paragraphGapScale = .4;

  final TextStyle body;
  final TextStyle chapter;
  final double paragraphGap;
}

/// One paragraph of the body.
class ReaderParagraph extends StatelessWidget {
  const ReaderParagraph({required this.text, required this.typesetting, super.key});

  final String text;
  final ReaderTypesetting typesetting;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: typesetting.paragraphGap),
    child: Text(text, style: typesetting.body, softWrap: true),
  );
}

/// A chapter's title, which divides it from the one before.
class ReaderChapterTitle extends StatelessWidget {
  const ReaderChapterTitle({required this.title, required this.typesetting, required this.first, super.key});

  final String title;
  final ReaderTypesetting typesetting;

  /// The text's first block: no space above it.
  final bool first;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: first ? 0 : typesetting.paragraphGap * 2, bottom: typesetting.paragraphGap),
    child: Text(title, style: typesetting.chapter, softWrap: true),
  );
}

/// The body's text can be selected across paragraphs; Ctrl+C copies it.
/// Frost's selection handles and menu are not open to App text yet
/// (freepiv-20261107-selection-area-for-app-text), so there are none.
class ReaderSelectableText extends StatelessWidget {
  const ReaderSelectableText({required this.child, required this.focusNode, this.onSelectionChanged, this.regionKey, super.key});

  final Widget child;
  final FocusNode focusNode;
  final ValueChanged<SelectedContent?>? onSelectionChanged;

  /// Reaches the region to clear its selection.
  final GlobalKey<SelectableRegionState>? regionKey;

  @override
  Widget build(BuildContext context) => SelectableRegion(
    key: regionKey,
    focusNode: focusNode,
    selectionControls: emptyTextSelectionControls,
    onSelectionChanged: onSelectionChanged,
    child: child,
  );
}
