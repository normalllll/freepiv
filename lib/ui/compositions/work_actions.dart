import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/logic/illust_bookmark_logic.dart';
import 'package:freepiv/shared/logic/user_follow_logic.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart' show Restrict;
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:frost_ui/frost_ui.dart';

/// A work's bookmark state and its toggle (public, optimistic, rolled back
/// on failure with a toast), for the control [builder] draws.
class AppBookmarkBuilder extends ConsumerWidget {
  const AppBookmarkBuilder({required this.workId, required this.initiallyBookmarked, required this.builder, this.novel = false, super.key});

  final int workId;
  final bool initiallyBookmarked;
  final bool novel;

  /// [toggle] is null while a change is on its way or nobody is signed in.
  final Widget Function(BuildContext context, bool bookmarked, VoidCallback? toggle) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder(
      valueListenable: pixivAccountNotifier,
      builder: (context, account, _) {
        final accountId = account?.user.id;
        final provider = illustBookmarkProvider(IllustBookmarkArgs(accountId: accountId, illustId: workId, isBookmarked: initiallyBookmarked, isNovel: novel));
        final bookmark = ref.watch(provider);
        Future<void> toggle() async {
          try {
            await ref.read(provider.notifier).toggle();
          } catch (error) {
            if (pixivAccountNotifier.value?.user.id == accountId) toastErrorWithCause(t.toast.bookmarkFailed, error);
          }
        }

        return builder(context, bookmark.isBookmarked, bookmark.updating || accountId == null ? null : toggle);
      },
    );
  }
}

/// The bookmark button at the end of a work card's text, filled once
/// bookmarked.
class AppCardBookmarkButton extends StatelessWidget {
  const AppCardBookmarkButton({required this.workId, required this.initiallyBookmarked, this.novel = false, super.key});

  final int workId;
  final bool initiallyBookmarked;
  final bool novel;

  @override
  Widget build(BuildContext context) => AppBookmarkBuilder(
    workId: workId,
    initiallyBookmarked: initiallyBookmarked,
    novel: novel,
    builder: (context, bookmarked, toggle) => FrostButton.icon(
      icon: bookmarked ? PivIcons.heartFilled : PivIcons.heart,
      label: bookmarked ? context.t.illust.tooltip.removeBookmark : context.t.illust.tooltip.addBookmark,
      size: FrostControlSize.compact,
      selected: bookmarked,
      onPressed: toggle,
    ),
  );
}

/// The bookmark button of a list row: an icon, filled once bookmarked.
class AppRowBookmarkButton extends StatelessWidget {
  const AppRowBookmarkButton({required this.workId, required this.initiallyBookmarked, this.novel = false, super.key});

  final int workId;
  final bool initiallyBookmarked;
  final bool novel;

  @override
  Widget build(BuildContext context) => AppBookmarkBuilder(
    workId: workId,
    initiallyBookmarked: initiallyBookmarked,
    novel: novel,
    builder: (context, bookmarked, toggle) => FrostButton.icon(
      icon: bookmarked ? PivIcons.heartFilled : PivIcons.heart,
      label: bookmarked ? context.t.illust.tooltip.removeBookmark : context.t.illust.tooltip.addBookmark,
      selected: bookmarked,
      onPressed: toggle,
    ),
  );
}

/// A user's follow state and its toggle (public; optimistic, rolled back on
/// failure with a toast). Draws nothing for the signed-in user.
class AppFollowBuilder extends ConsumerWidget {
  const AppFollowBuilder({required this.userId, required this.initiallyFollowed, required this.builder, super.key});

  final int userId;
  final bool initiallyFollowed;
  final Widget Function(BuildContext context, bool followed, VoidCallback? toggle) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder(
      valueListenable: pixivAccountNotifier,
      builder: (context, account, _) {
        final accountId = account?.user.id;
        if (int.tryParse(accountId ?? '') == userId) return const SizedBox.shrink();
        final provider = userFollowProvider(UserFollowArgs(userId: userId, isFollowed: initiallyFollowed, accountId: accountId));
        final follow = ref.watch(provider);
        Future<void> toggle() async {
          try {
            await ref.read(provider.notifier).toggle(restrict: Restrict.public);
          } catch (error) {
            if (pixivAccountNotifier.value?.user.id == accountId) toastErrorWithCause(t.toast.followFailed, error);
          }
        }

        return builder(context, follow.isFollowed, follow.updating || accountId == null ? null : toggle);
      },
    );
  }
}

/// Follow as the one primary action of an identity header or an author
/// line; "Following" once followed.
class AppFollowButton extends StatelessWidget {
  const AppFollowButton({required this.user, this.prominent = true, super.key});

  final User user;

  /// The solid button; a row's quieter button otherwise.
  final bool prominent;

  @override
  Widget build(BuildContext context) => AppFollowBuilder(
    userId: user.id,
    initiallyFollowed: user.isFollowed ?? false,
    builder: (context, followed, toggle) {
      final label = followed ? context.t.follow.followed : context.t.follow.follow;
      final tooltip = followed ? context.t.follow.tooltipUnfollow : context.t.follow.tooltipFollow;
      final button = followed
          ? FrostButton.tinted(label: label, tooltip: tooltip, onPressed: toggle)
          : prominent
          ? FrostButton.prominent(label: label, tooltip: tooltip, onPressed: toggle)
          : FrostButton.outlined(label: label, tooltip: tooltip, onPressed: toggle);
      if (prominent) return button;
      // In a row the button keeps the width of both labels, so what stands
      // before it does not move when it changes.
      return Stack(
        alignment: AlignmentDirectional.centerEnd,
        children: [
          for (final other in [context.t.follow.followed, context.t.follow.follow])
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: ExcludeSemantics(child: FrostButton.outlined(label: other, onPressed: null)),
            ),
          button,
        ],
      );
    },
  );
}
