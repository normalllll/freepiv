import 'package:flutter/widgets.dart';

/// Session-only reading position; no reading history is written to disk.
final novelReadingSessions = PageStorageBucket();

class NovelReadingPosition {
  const NovelReadingPosition({
    required this.segmentIndex,
    required this.textOffset,
    required this.segmentFraction,
    required this.fontSize,
    required this.lineHeight,
    this.blockIndex = 0,
    this.blockFraction = 0,
  });

  final int segmentIndex;
  final int textOffset;
  final double segmentFraction;
  final double fontSize;
  final double lineHeight;
  final int blockIndex;
  final double blockFraction;
}

NovelReadingPosition? novelReadingPosition(BuildContext context, int novelId) {
  final saved = novelReadingSessions.readState(context, identifier: novelId);
  return saved is NovelReadingPosition ? saved : null;
}
