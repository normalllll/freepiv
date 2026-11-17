// app-owned: novel reader sidebar
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// A ring in the accent colour, at the thumbnails' radius, around the picture
/// thumbnail nearest the reading position.
class ReaderThumbnailOutline extends StatelessWidget {
  const ReaderThumbnailOutline({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(FrostRadius.md),
      border: Border.all(color: FrostThemeTokens.of(context).accent, width: 2),
    ),
  );
}
