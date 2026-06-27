import 'dart:async';

import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  UserIllustBookmarkListSource build({required int userId}) {
    final source = UserIllustBookmarkListSource(userId: userId);
    ref.onDispose(source.dispose);
    return source;
  }
}

@riverpod
class UserNovelBookmarks extends _$UserNovelBookmarks {
  @override
  UserNovelBookmarkListSource build({required int userId}) {
    final source = UserNovelBookmarkListSource(userId: userId);
    ref.onDispose(source.dispose);
    return source;
  }
}

@riverpod
class UserFollowingUsers extends _$UserFollowingUsers {
  @override
  UserFollowingListSource build({required int userId}) {
    final source = UserFollowingListSource(userId: userId);
    ref.onDispose(source.dispose);
    return source;
  }
}

class UserIllustListSource extends NextUrlListSource<Illust, IllustPageResult> {
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

class UserNovelListSource extends NextUrlListSource<Novel, NovelPageResult> {
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

class UserIllustBookmarkListSource extends NextUrlListSource<Illust, IllustPageResult> {
  UserIllustBookmarkListSource({required this.userId});

  final int userId;

  @override
  Future<IllustPageResult> loadFirstPage() {
    return pixivApi.getUserIllustBookmarkPage(userId: userId, restrict: Restrict.public);
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

class UserNovelBookmarkListSource extends NextUrlListSource<Novel, NovelPageResult> {
  UserNovelBookmarkListSource({required this.userId});

  final int userId;

  @override
  Future<NovelPageResult> loadFirstPage() {
    return pixivApi.getUserNovelBookmarkPage(userId: userId, restrict: Restrict.public);
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

class UserFollowingListSource extends NextUrlListSource<UserPreview, UserPageResult> {
  UserFollowingListSource({required this.userId});

  final int userId;

  @override
  Future<UserPageResult> loadFirstPage() {
    return pixivApi.getFollowingUserPage(userId: userId, restrict: Restrict.public);
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
