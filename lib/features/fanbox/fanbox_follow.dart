import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

import 'fanbox_actions.dart';
import 'logic.dart';

/// Follow for a FANBOX creator, the one solid button of the line it is on
/// until followed; it waits while the request runs and says why one failed.
class FanboxFollowButton extends ConsumerWidget {
  const FanboxFollowButton({required this.creatorId, this.prominent = true, super.key});

  final String creatorId;
  final bool prominent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final creator = ref.watch(fanboxCreatorProvider(creatorId)).value;
    final scope = 'creator:$creatorId';
    final operation = ref.watch(fanboxOperationProvider(scope));
    final followed = creator?.isFollowed ?? false;
    Future<void> toggle() async {
      final user = creator!.user.id;
      final success = await ref.read(fanboxOperationProvider(scope).notifier).run(() async {
        final api = await ref.read(fanboxApiProvider.future);
        await (followed ? api.unfollowCreator(userId: user) : api.followCreator(userId: user));
      });
      if (success) {
        ref.invalidate(fanboxCreatorProvider(creatorId));
        ref.invalidate(fanboxBrowseProvider);
      } else if (context.mounted) {
        FrostToast.error(fanboxError(context, ref.read(fanboxOperationProvider(scope)).error ?? StateError('')));
      }
    }

    final onPressed = creator == null || operation.isLoading ? null : () => unawaited(toggle());
    final state = operation.isLoading ? const FrostActionState.running() : FrostActionState.idle;
    final label = followed ? t.follow.followed : t.fanbox.follow;
    if (followed) return FrostButton.tinted(key: const ValueKey('fanbox-follow'), label: label, tooltip: t.fanbox.unfollow, state: state, onPressed: onPressed);
    return prominent
        ? FrostButton.prominent(key: const ValueKey('fanbox-follow'), label: label, state: state, onPressed: onPressed)
        : FrostButton.outlined(key: const ValueKey('fanbox-follow'), label: label, state: state, onPressed: onPressed);
  }
}
