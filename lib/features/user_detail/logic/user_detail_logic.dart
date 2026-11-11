import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, FutureProvider;
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/logic/bookmark_tags.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart' show BookmarkPageOptions;
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frost_data/frost_data.dart';

part 'user_detail_logic.g.dart';

class UserDetailArgs {
  const UserDetailArgs({this.userId, this.userDetail}) : assert(userId != null || userDetail != null);

  final int? userId;
  final UserDetailResult? userDetail;

  int get resolvedUserId {
    final userDetail = this.userDetail;
    if (userDetail != null) {
      return userDetail.user.id;
    }

    final userId = this.userId;
    if (userId == null) {
      throw ArgumentError('Either userId or userDetail must be provided.');
    }

    return userId;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is UserDetailArgs && other.resolvedUserId == resolvedUserId;
  }

  @override
  int get hashCode => resolvedUserId.hashCode;
}

enum UserContentTabKind { illust, manga, novel, bookmarks, following, profile }

enum UserBookmarkKind { illustManga, novel }

@riverpod
class UserDetail extends _$UserDetail {
  @override
  FutureOr<UserDetailResult> build(UserDetailArgs args) {
    final userDetail = args.userDetail;
    if (userDetail != null) {
      return userDetail;
    }

    return pixivApi.getUserDetail(userId: args.resolvedUserId);
  }

  Future<void> reload() async {
    state = const AsyncLoading<UserDetailResult>();
    state = await AsyncValue.guard(() => pixivApi.getUserDetail(userId: args.resolvedUserId));
  }
}

@riverpod
class UserIllusts extends _$UserIllusts {
  @override
  UserIllustListSource build({required int userId, required IllustType illustType}) {
    final source = UserIllustListSource(userId: userId, illustType: illustType);
    ref.onDispose(source.dispose);
    return source;
  }
}

@riverpod
class UserNovels extends _$UserNovels {
  @override
  UserNovelListSource build({required int userId}) {
    final source = UserNovelListSource(userId: userId);
    ref.onDispose(source.dispose);
    return source;
  }
}

@riverpod
class UserIllustBookmarks extends _$UserIllustBookmarks {
  @override
  UserIllustBookmarkListSource build({required int userId, Restrict restrict = Restrict.public, BookmarkTagFilter tag = const BookmarkTagFilter.all()}) {
    final source = UserIllustBookmarkListSource(userId: userId, restrict: restrict, tag: tag);
    ref.onDispose(source.dispose);
    return source;
  }
}

@riverpod
class UserNovelBookmarks extends _$UserNovelBookmarks {
  @override
  UserNovelBookmarkListSource build({required int userId, Restrict restrict = Restrict.public, BookmarkTagFilter tag = const BookmarkTagFilter.all()}) {
    final source = UserNovelBookmarkListSource(userId: userId, restrict: restrict, tag: tag);
    ref.onDispose(source.dispose);
    return source;
  }
}

@riverpod
class UserFollowingUsers extends _$UserFollowingUsers {
  @override
  UserFollowingListSource build({required int userId, Restrict restrict = Restrict.public}) {
    final source = UserFollowingListSource(userId: userId, restrict: restrict);
    ref.onDispose(source.dispose);
    return source;
  }
}

class UserIllustListSource extends FrostCursorListSource<Illust, IllustPageResult> {
  UserIllustListSource({required this.userId, required this.illustType});

  final int userId;
  final IllustType illustType;

  @override
  Future<IllustPageResult> loadFirstPage() {
    return pixivApi.getUserIllustPage(userId: userId, illustType: illustType);
  }

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextIllustPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(IllustPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Illust> itemsFromPage(IllustPageResult page) {
    return page.illusts;
  }
}

class UserNovelListSource extends FrostCursorListSource<Novel, NovelPageResult> {
  UserNovelListSource({required this.userId});

  final int userId;

  @override
  Future<NovelPageResult> loadFirstPage() {
    return pixivApi.getUserNovelPage(userId: userId);
  }

  @override
  Future<NovelPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextNovelPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(NovelPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Novel> itemsFromPage(NovelPageResult page) {
    return page.novels;
  }
}

class UserIllustBookmarkListSource extends FrostCursorListSource<Illust, IllustPageResult> {
  UserIllustBookmarkListSource({required this.userId, this.restrict = Restrict.public, this.tag = const BookmarkTagFilter.all()});

  final int userId;

  /// Private lists answer only the account that owns them.
  final Restrict restrict;

  /// The tag the bookmarks carry; all of them for [BookmarkTagFilter.all].
  final BookmarkTagFilter tag;

  @override
  Future<IllustPageResult> loadFirstPage() {
    if (tag.apiTag case final tag?) {
      return pixivApi.getUserIllustBookmarkPageWithOptions(
        userId: userId,
        options: BookmarkPageOptions(restrict: restrict, tag: tag),
      );
    }
    return pixivApi.getUserIllustBookmarkPage(userId: userId, restrict: restrict);
  }

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextIllustPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(IllustPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Illust> itemsFromPage(IllustPageResult page) {
    return page.illusts;
  }
}

class UserNovelBookmarkListSource extends FrostCursorListSource<Novel, NovelPageResult> {
  UserNovelBookmarkListSource({required this.userId, this.restrict = Restrict.public, this.tag = const BookmarkTagFilter.all()});

  final int userId;

  /// Private lists answer only the account that owns them.
  final Restrict restrict;

  /// The tag the bookmarks carry; all of them for [BookmarkTagFilter.all].
  final BookmarkTagFilter tag;

  @override
  Future<NovelPageResult> loadFirstPage() {
    if (tag.apiTag case final tag?) {
      return pixivApi.getUserNovelBookmarkPageWithOptions(
        userId: userId,
        options: BookmarkPageOptions(restrict: restrict, tag: tag),
      );
    }
    return pixivApi.getUserNovelBookmarkPage(userId: userId, restrict: restrict);
  }

  @override
  Future<NovelPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextNovelPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(NovelPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Novel> itemsFromPage(NovelPageResult page) {
    return page.novels;
  }
}

class UserFollowingListSource extends FrostCursorListSource<UserPreview, UserPageResult> {
  UserFollowingListSource({required this.userId, this.restrict = Restrict.public});

  final int userId;

  /// Private lists answer only the account that owns them.
  final Restrict restrict;

  @override
  Future<UserPageResult> loadFirstPage() {
    return pixivApi.getFollowingUserPage(userId: userId, restrict: restrict);
  }

  @override
  Future<UserPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextUserPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(UserPageResult page) {
    return page.nextUrl;
  }

  @override
  List<UserPreview> itemsFromPage(UserPageResult page) {
    return page.userPreviews;
  }
}

/// The authors Pixiv relates to [userId], a page at a time.
///
/// A page that names a next URL is followed by it; one that does not is
/// followed by the offset of what has been read so far. Pixiv relates a fixed
/// set of authors and answers a later page with the same ones again, so a
/// page that brings no author not yet listed ends the list.
class UserRelatedListSource extends FrostListSource<UserPreview> {
  UserRelatedListSource({required this.userId});

  final int userId;
  String? _nextUrl;
  var _read = 0;

  /// The authors listed so far, by ID.
  final _listed = <int>{};

  @override
  Future<List<UserPreview>> initList() async {
    _nextUrl = null;
    _read = 0;
    _listed.clear();
    return _apply(await loadFirstPage());
  }

  @override
  Future<List<UserPreview>> nextList() async {
    final nextUrl = _nextUrl;
    return _apply(nextUrl == null || nextUrl.isEmpty ? await loadOffsetPage(_read) : await loadNextPage(nextUrl));
  }

  Future<UserPageResult> loadFirstPage() => loadOffsetPage(0);

  Future<UserPageResult> loadOffsetPage(int offset) => pixivApi.getUserRelatedPage(offset: offset, seedUserId: userId);

  Future<UserPageResult> loadNextPage(String nextUrl) => pixivApi.getNextUserPage(url: nextUrl);

  @override
  void clearData() {
    _nextUrl = null;
    _read = 0;
    _listed.clear();
    super.clearData();
  }

  List<UserPreview> _apply(UserPageResult page) {
    _nextUrl = page.nextUrl;
    _read += page.userPreviews.length;
    final fresh = [
      for (final preview in page.userPreviews)
        if (_listed.add(preview.user.id)) preview,
    ];
    return fresh;
  }
}

/// The related authors of [userId], shared by the author page's section and
/// its full list; loaded on first watch.
final userRelatedSourceProvider = Provider.autoDispose.family<UserRelatedListSource, int>((ref, userId) {
  final source = UserRelatedListSource(userId: userId);
  ref.onDispose(source.dispose);
  return source;
});

/// What the tag list of one kind of bookmark of an account is read from.
typedef BookmarkTagsKey = ({int userId, Restrict restrict, bool novel});

/// The account's bookmark tags of one kind and privacy, every page of them.
final bookmarkTagsProvider = FutureProvider.autoDispose.family<List<BookmarkTag>, BookmarkTagsKey>(
  (ref, key) => readBookmarkTags(userId: key.userId, restrict: key.restrict, novel: key.novel),
);
