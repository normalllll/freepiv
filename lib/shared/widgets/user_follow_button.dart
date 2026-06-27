import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/logic/user_follow_logic.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UserFollowButton extends ConsumerWidget {
  const UserFollowButton({required this.userId, this.initialIsFollowed, this.restrict = Restrict.public, this.iconSize = 18, super.key});

  final int userId;
  final bool? initialIsFollowed;
  final Restrict restrict;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = userFollowProvider(UserFollowArgs(userId: userId, isFollowed: initialIsFollowed ?? false));
    final follow = ref.watch(provider);
    final isFollowed = follow.isFollowed;
    final translations = t;

    Future<void> toggle() async {
      try {
        await ref.read(provider.notifier).toggle(restrict: restrict);
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        AppToast.errorWithCause(translations.toast.followFailed, error);
      }
    }

    return Tooltip(
      message: isFollowed ? translations.follow.tooltipUnfollow : translations.follow.tooltipFollow,
      child: _UserFollowButtonSurface(isFollowed: isFollowed, updating: follow.updating, iconSize: iconSize, onPressed: follow.updating ? null : toggle),
    );
  }
}

class UserFollowButtonPlaceholder extends StatelessWidget {
  const UserFollowButtonPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(child: Bone(width: 82, height: 34, borderRadius: BorderRadius.circular(8)));
  }
}

class _UserFollowButtonSurface extends StatelessWidget {
  const _UserFollowButtonSurface({required this.isFollowed, required this.updating, required this.iconSize, required this.onPressed});

  final bool isFollowed;
  final bool updating;
  final double iconSize;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = FreepivThemeTokens.of(context);
    final translations = t;
    final foreground = isFollowed ? colorScheme.onSurfaceVariant : colorScheme.onPrimary;
    final background = isFollowed ? Color.alphaBlend(tokens.brand.withValues(alpha: 0.055), tokens.surfaceRaised) : tokens.brand;

    return SizedBox(
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(color: updating ? background.withValues(alpha: 0.68) : background, borderRadius: BorderRadius.circular(8)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: updating ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: iconSize,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      child: updating
                          ? SizedBox.square(
                              key: const ValueKey('updating'),
                              dimension: iconSize,
                              child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                            )
                          : Icon(
                              isFollowed ? Icons.person_outlined : Icons.person_add_alt_1_outlined,
                              key: ValueKey(isFollowed),
                              size: iconSize,
                              color: foreground,
                            ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isFollowed ? translations.follow.followed : translations.follow.notFollowed,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground.withValues(alpha: updating ? 0.68 : 1),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
