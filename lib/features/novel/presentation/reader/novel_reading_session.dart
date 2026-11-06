import 'package:flutter/widgets.dart';
import 'package:freepiv/core/services/pixiv_service.dart';

/// Session-only reading position; no reading history is written to disk. It
/// is anchored in the text, so it survives a change of text size or spacing.
final novelReadingSessions = PageStorageBucket();

class NovelReadingPosition {
  const NovelReadingPosition({
    required this.segmentIndex,
    required this.textOffset,
    required this.segmentFraction,
    this.blockIndex = 0,
    this.blockFraction = 0,
  });

  final int segmentIndex;
  final int textOffset;
  final double segmentFraction;
  final int blockIndex;
  final double blockFraction;
}

NovelReadingPosition? novelReadingPosition(BuildContext context, int novelId) {
  final saved = novelReadingSessions.readState(context, identifier: novelReadingSessionKey(novelId, accountId: pixivAccountNotifier.value?.user.id));
  return saved is NovelReadingPosition ? saved : null;
}

Object novelReadingSessionKey(int novelId, {required String? accountId}) => (accountId: accountId, novelId: novelId);
