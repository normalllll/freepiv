import 'package:flutter/foundation.dart' show immutable;
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

/// What a history entry is a work of.
enum HistoryWorkKind {
  illust,
  manga,
  ugoira,
  novel;

  bool get isNovel => this == novel;

  /// The kind of an illustration-type work, by Pixiv's own name for it.
  static HistoryWorkKind ofIllust(String kind) => switch (kind) {
    'manga' => manga,
    'ugoira' => ugoira,
    _ => illust,
  };
}

/// How many entries each account's history keeps, the oldest going first.
enum HistoryLimit {
  fiveHundred(500),
  oneThousand(1000),
  twoThousand(2000),
  fiveThousand(5000),
  tenThousand(10000);

  const HistoryLimit(this.count);

  final int count;

  static const standard = twoThousand;

  /// The limit stored under [name]; the standard one for anything else.
  static HistoryLimit named(Object? name) => values.where((limit) => limit.name == name).firstOrNull ?? standard;
}

/// A work as it was when it was last viewed: just what a card or a row of the
/// history shows, so nothing is fetched to show it.
@immutable
class HistoryEntry {
  const HistoryEntry({
    required this.kind,
    required this.workId,
    required this.title,
    required this.authorId,
    required this.authorName,
    required this.thumbnailUrl,
    required this.xRestrict,
    required this.aiGenerated,
    required this.viewedAt,
    this.width,
    this.height,
    this.pageCount,
    this.textLength,
  });

  factory HistoryEntry.ofIllust(Illust illust, DateTime viewedAt) => HistoryEntry(
    kind: HistoryWorkKind.ofIllust(illust.kind),
    workId: illust.id,
    title: illust.title,
    authorId: illust.user.id,
    authorName: illust.user.name,
    thumbnailUrl: illust.imageUrls.medium,
    xRestrict: illust.xRestrict,
    aiGenerated: illust.illustAiType == 2,
    viewedAt: viewedAt,
    width: illust.width,
    height: illust.height,
    pageCount: illust.pageCount,
  );

  factory HistoryEntry.ofNovel(Novel novel, DateTime viewedAt) => HistoryEntry(
    kind: HistoryWorkKind.novel,
    workId: novel.id,
    title: novel.title,
    authorId: novel.user.id,
    authorName: novel.user.name,
    thumbnailUrl: novel.imageUrls.medium,
    xRestrict: novel.xRestrict,
    aiGenerated: novel.novelAiType == 2,
    viewedAt: viewedAt,
    textLength: novel.textLength,
  );

  final HistoryWorkKind kind;
  final int workId;
  final String title;
  final int authorId;
  final String authorName;
  final String thumbnailUrl;
  final int xRestrict;
  final bool aiGenerated;
  final DateTime viewedAt;

  /// Of an illustration-type work.
  final int? width;
  final int? height;
  final int? pageCount;

  /// Of a novel.
  final int? textLength;

  /// The width of the work's preview to its height, a square without sizes.
  double get aspectRatio {
    final width = this.width;
    final height = this.height;
    return width != null && height != null && width > 0 && height > 0 ? width / height : 1;
  }

  @override
  int get hashCode =>
      Object.hash(kind, workId, title, authorId, authorName, thumbnailUrl, xRestrict, aiGenerated, viewedAt, width, height, pageCount, textLength);

  @override
  bool operator ==(Object other) =>
      other is HistoryEntry &&
      other.kind == kind &&
      other.workId == workId &&
      other.title == title &&
      other.authorId == authorId &&
      other.authorName == authorName &&
      other.thumbnailUrl == thumbnailUrl &&
      other.xRestrict == xRestrict &&
      other.aiGenerated == aiGenerated &&
      other.viewedAt == viewedAt &&
      other.width == width &&
      other.height == height &&
      other.pageCount == pageCount &&
      other.textLength == textLength;
}
