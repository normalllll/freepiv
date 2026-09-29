import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/shared/logic/illust_bookmark_logic.dart';
import 'package:freepiv/shared/logic/user_follow_logic.dart';

void main() {
  test('Pixiv bookmark state is shared by account, work type and ID only', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const illustration = IllustBookmarkArgs(accountId: 'account-a', illustId: 17, isBookmarked: true, isNovel: false);
    const sameIllustration = IllustBookmarkArgs(accountId: 'account-a', illustId: 17, isBookmarked: false, isNovel: false);
    const anotherAccount = IllustBookmarkArgs(accountId: 'account-b', illustId: 17, isBookmarked: false, isNovel: false);
    const novel = IllustBookmarkArgs(accountId: 'account-a', illustId: 17, isBookmarked: false, isNovel: true);

    expect(container.read(illustBookmarkProvider(illustration)).isBookmarked, isTrue);
    expect(container.read(illustBookmarkProvider(sameIllustration)).isBookmarked, isTrue);
    expect(container.read(illustBookmarkProvider(anotherAccount)).isBookmarked, isFalse);
    expect(container.read(illustBookmarkProvider(novel)).isBookmarked, isFalse);
  });

  test('Pixiv follow state stays within its account and user', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const followed = UserFollowArgs(accountId: 'account-a', userId: 23, isFollowed: true);
    const sameUser = UserFollowArgs(accountId: 'account-a', userId: 23, isFollowed: false);
    const anotherAccount = UserFollowArgs(accountId: 'account-b', userId: 23, isFollowed: false);
    const anotherUser = UserFollowArgs(accountId: 'account-a', userId: 24, isFollowed: false);

    expect(container.read(userFollowProvider(followed)).isFollowed, isTrue);
    expect(container.read(userFollowProvider(sameUser)).isFollowed, isTrue);
    expect(container.read(userFollowProvider(anotherAccount)).isFollowed, isFalse);
    expect(container.read(userFollowProvider(anotherUser)).isFollowed, isFalse);
  });
}
