import 'package:flutter/foundation.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

/// Which of an account's bookmarks a list shows: all of them, those without a
/// tag, or those carrying one tag.
@immutable
class BookmarkTagFilter {
  /// Every bookmark.
  const BookmarkTagFilter.all() : _kind = _Kind.all, name = null;

  /// The bookmarks that carry no tag.
  const BookmarkTagFilter.uncategorized() : _kind = _Kind.uncategorized, name = null;

  /// The bookmarks that carry the tag [name].
  const BookmarkTagFilter.named(String this.name) : _kind = _Kind.named;

  final _Kind _kind;

  /// The tag of a named filter; null for the others.
  final String? name;

  bool get isAll => _kind == _Kind.all;
  bool get isUncategorized => _kind == _Kind.uncategorized;
  bool get isNamed => _kind == _Kind.named;

  /// What Pixiv's `tag` parameter takes for this filter; null for all.
  ///
  /// Pixiv spells the bookmarks without a tag as a tag of its own.
  String? get apiTag => switch (_kind) {
    _Kind.all => null,
    _Kind.uncategorized => uncategorizedApiTag,
    _Kind.named => name,
  };

  /// The tag Pixiv answers to for bookmarks without a tag.
  static const uncategorizedApiTag = '未分類';

  /// The filter a tag of Pixiv's own list stands for: the uncategorized one
  /// when Pixiv lists the bookmarks without a tag among the tags.
  factory BookmarkTagFilter.ofTag(String tag) => tag == uncategorizedApiTag ? const BookmarkTagFilter.uncategorized() : BookmarkTagFilter.named(tag);

  @override
  bool operator ==(Object other) => other is BookmarkTagFilter && other._kind == _kind && other.name == name;

  @override
  int get hashCode => Object.hash(_kind, name);

  @override
  String toString() => 'BookmarkTagFilter(${_kind.name}${name == null ? '' : ': $name'})';
}

enum _Kind { all, uncategorized, named }

/// Every bookmark tag of [userId]'s [restrict] bookmarks of illustrations and
/// manga, or of novels when [novel] is set, read page by page to the last.
Future<List<BookmarkTag>> readBookmarkTags({required int userId, required Restrict restrict, required bool novel}) async {
  var page = await pixivApi.getBookmarkTagPage(
    userId: userId,
    options: BookmarkTagOptions(restrict: restrict, isNovel: novel),
  );
  final tags = [...page.bookmarkTags];
  final read = <String>{};
  for (var next = page.nextUrl; next != null && next.isNotEmpty && read.add(next); next = page.nextUrl) {
    page = await pixivApi.getNextBookmarkTagPage(url: next);
    tags.addAll(page.bookmarkTags);
  }
  return tags;
}
