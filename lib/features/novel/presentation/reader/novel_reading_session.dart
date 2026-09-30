import 'package:flutter/widgets.dart';
import 'package:freepiv/core/services/pixiv_service.dart';

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
  final saved = novelReadingSessions.readState(context, identifier: novelReadingSessionKey(novelId, accountId: pixivAccountNotifier.value?.user.id));
  return saved is NovelReadingPosition ? saved : null;
}

Object novelReadingSessionKey(int novelId, {required String? accountId}) => (accountId: accountId, novelId: novelId);
