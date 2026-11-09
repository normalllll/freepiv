import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/logic/optimistic_mutation.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_follow_logic.g.dart';

class UserFollowArgs {
  const UserFollowArgs({required this.userId, required this.isFollowed, this.accountId});

  final int userId;
  final bool isFollowed;
  final String? accountId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is UserFollowArgs && other.userId == userId && other.accountId == accountId;
  }

  @override
  int get hashCode => Object.hash(accountId, userId);
}

class UserFollowEntry {
  const UserFollowEntry({required this.isFollowed, this.updating = false});

  final bool isFollowed;
  final bool updating;

  UserFollowEntry copyWith({bool? isFollowed, bool? updating}) {
    return UserFollowEntry(isFollowed: isFollowed ?? this.isFollowed, updating: updating ?? this.updating);
  }
}

@riverpod
class UserFollow extends _$UserFollow {
  @override
  UserFollowEntry build(UserFollowArgs args) {
    return UserFollowEntry(isFollowed: args.isFollowed);
  }

  Future<void> toggle({Restrict restrict = Restrict.public}) async {
    if (state.updating) {
      return;
    }
    if (args.accountId == null || pixivAccountNotifier.value?.user.id != args.accountId) return;

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
      canCommit: () => ref.mounted && pixivAccountNotifier.value?.user.id == args.accountId,
    );
  }

  /// Follows the user as [restrict], or moves an existing follow to it.
  Future<void> setRestrict(Restrict restrict) async {
    if (state.updating) return;
    if (args.accountId == null || pixivAccountNotifier.value?.user.id != args.accountId) return;

    final previous = state;
    await runOptimisticMutation(
      previous: previous,
      optimistic: previous.copyWith(isFollowed: true, updating: true),
      read: () => state,
      write: (next) => state = next,
      mutate: () => pixivApi.postFollowAdd(userId: args.userId, restrict: restrict),
      settle: (current) => current.copyWith(updating: false),
      rollback: (previous) => previous.copyWith(updating: false),
      canCommit: () => ref.mounted && pixivAccountNotifier.value?.user.id == args.accountId,
    );
    if (ref.mounted) ref.invalidate(userFollowRestrictProvider(args));
  }
}

/// How the account follows the user: public or private. Null until followed.
@riverpod
Future<Restrict?> userFollowRestrict(Ref ref, UserFollowArgs args) async => (await pixivApi.getUserFollowDetail(userId: args.userId)).followDetail.restrict;
