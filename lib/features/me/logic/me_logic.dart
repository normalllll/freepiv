import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_data/frost_data.dart';

/// The users following [userId], a page at a time.
class FollowerListSource extends FrostCursorListSource<UserPreview, UserPageResult> {
  FollowerListSource({required this.userId});

  final int userId;

  @override
  Future<UserPageResult> loadFirstPage() => pixivApi.getFollowerPage(userId: userId);

  @override
  Future<UserPageResult> loadNextPage(String nextUrl) => pixivApi.getNextUserPage(url: nextUrl);

  @override
  String? nextUrlFromPage(UserPageResult page) => page.nextUrl;

  @override
  List<UserPreview> itemsFromPage(UserPageResult page) => page.userPreviews;
}

/// The signed-in account's followers, by its user ID; loaded on first watch.
final followersSourceProvider = Provider.autoDispose.family<FollowerListSource, int>((ref, userId) {
  final source = FollowerListSource(userId: userId);
  ref.onDispose(source.dispose);
  return source;
});
