// app-owned: novel reader status lines
import 'package:flutter/widgets.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';
import 'package:frost_ui/frost_ui.dart';

/// One line of status above or below the text, in the reading theme's
/// secondary colour: the reading surface may be a fixed palette that Frost's
/// text colours do not know.
class ReaderStatusText extends StatelessWidget {
  const ReaderStatusText(this.text, {required this.palette, super.key});

  final String text;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    final style = FrostTypography.of(context).style(FrostTextRole.footnote).copyWith(color: palette.secondary);
    return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
