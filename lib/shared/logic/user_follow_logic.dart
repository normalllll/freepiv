import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/logic/optimistic_mutation.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_follow_logic.g.dart';

class UserFollowArgs {
  const UserFollowArgs({required this.userId, required this.isFollowed});

  final int userId;
  final bool isFollowed;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is UserFollowArgs && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

class UserFollowEntry {
  const UserFollowEntry({required this.isFollowed, this.updating = false});

  final bool isFollowed;
  final bool updating;

  UserFollowEntry copyWith({bool? isFollowed, bool? updating}) {
    return UserFollowEntry(isFollowed: isFollowed ?? this.isFollowed, updating: updating ?? this.updating);
  }
}

@Riverpod(keepAlive: true)
class UserFollow extends _$UserFollow {
  @override
  UserFollowEntry build(UserFollowArgs args) {
    return UserFollowEntry(isFollowed: args.isFollowed);
  }

  Future<void> toggle({Restrict restrict = Restrict.public}) async {
    if (state.updating) {
      return;
    }

    final previous = state;
    final nextIsFollowed = !previous.isFollowed;

    await runOptimisticMutation(
      previous: previous,
      optimistic: previous.copyWith(isFollowed: nextIsFollowed, updating: true),
      read: () => state,
      write: (next) => state = next,
      mutate: () {
        if (nextIsFollowed) {
          return pixivApi.postFollowAdd(userId: args.userId, restrict: restrict);
        }

        return pixivApi.postFollowDelete(userId: args.userId);
      },
      settle: (current) => current.copyWith(updating: false),
      rollback: (previous) => previous.copyWith(updating: false),
    );
  }
}
