// app-owned: 小说阅读器正文
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/widgets.dart';
import 'package:freepiv/ui/custom/reader/reader_clean_copy.dart';
import 'package:freepiv/ui/custom/reader/reader_line_text.dart';
import 'package:freepiv/ui/custom/reader/reader_paragraph.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';
import 'package:frost_ui/frost_ui.dart';

export 'package:freepiv/ui/custom/reader/reader_paragraph.dart' show ReaderParagraph;

/// A chapter's title, which divides it from the one before.
class ReaderChapterTitle extends StatelessWidget {
  const ReaderChapterTitle({required this.title, required this.typesetting, required this.first, super.key});

  final String title;
  final ReaderTypesetting typesetting;

  /// The text's first block: no space above it.
  final bool first;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: first ? 0 : typesetting.chapterTopGap, bottom: typesetting.chapterBottomGap),
    child: ReaderParagraph(text: ReaderLineText.title(title, typesetting), typesetting: typesetting),
  );
}

/// The body's text can be selected across paragraphs with Frost's handles,
/// highlight and copy menu; Ctrl+C copies, Escape clears. Copied text has no
/// word joiners.
class ReaderSelectableText extends StatelessWidget {
  const ReaderSelectableText({required this.child, this.onSelectionChanged, this.areaKey, super.key});

  final Widget child;
  final ValueChanged<SelectedContent?>? onSelectionChanged;

  /// Reaches the area to clear its selection.
  final GlobalKey<FrostSelectionAreaState>? areaKey;

  @override
  Widget build(BuildContext context) => FrostSelectionArea(
    key: areaKey,
    onSelectionChanged: onSelectionChanged,
    child: ReaderCleanCopy(child: child),
  );
}
