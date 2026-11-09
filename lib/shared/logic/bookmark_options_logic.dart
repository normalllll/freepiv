import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bookmark_options_logic.g.dart';

typedef WorkBookmarkKey = ({String? accountId, int workId, bool novel});

/// How a work is bookmarked now and the tags offered for it.
class WorkBookmarkOptions {
  const WorkBookmarkOptions({required this.restrict, required this.tags, required this.chosen});

  final Restrict restrict;

  /// The bookmark's own tags first, then the work's, then the account's.
  final List<String> tags;

  /// The tags the bookmark carries.
  final Set<String> chosen;
}

/// Read each time the options open, so they show what Pixiv holds.
@riverpod
Future<WorkBookmarkOptions> workBookmarkOptions(Ref ref, WorkBookmarkKey key) async {
  final detail =
      (key.novel ? await pixivApi.getNovelBookmarkDetail(novelId: key.workId) : await pixivApi.getIllustBookmarkDetail(illustId: key.workId)).bookmarkDetail;
  final userId = int.tryParse(key.accountId ?? '');

  // The account's tags only add choices; the bookmark can be saved without.
  Future<List<String>> own(Restrict restrict) async {
    if (userId == null) return const [];
    try {
      final page = await pixivApi.getBookmarkTagPage(
        userId: userId,
        options: BookmarkTagOptions(restrict: restrict, isNovel: key.novel),
      );
      return [for (final tag in page.bookmarkTags) tag.name];
    } catch (_) {
      return const [];
    }
  }

  final accountTags = await Future.wait([own(Restrict.public), own(Restrict.private)]);
  final chosen = {
    for (final tag in detail.tags)
      if (tag.isRegistered) tag.name,
  };
  return WorkBookmarkOptions(
    restrict: detail.restrict,
    chosen: chosen,
    tags: {...chosen, for (final tag in detail.tags) tag.name, ...accountTags.expand((tags) => tags)}.toList(),
  );
}
