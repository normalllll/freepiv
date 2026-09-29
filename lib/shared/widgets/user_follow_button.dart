import 'package:freepiv/core/core.dart';
import 'package:freepiv/app/theme/app_feedback.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/logic/user_follow_logic.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/shared/ui/spring_builder.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UserFollowButton extends ConsumerStatefulWidget {
  const UserFollowButton({
    required this.userId,
    this.initialIsFollowed,
    this.restrict = Restrict.public,
    this.iconSize = 18,
    this.dense = false,
    this.height,
    super.key,
  });

  final int userId;
  final bool? initialIsFollowed;
  final Restrict restrict;
  final double iconSize;

  /// The smaller button for headers, where it sits on the cover beside the
  /// name instead of on a row of its own.
  final bool dense;

  /// Overrides the [dense] height, for the collapsed header bar where even the
  /// cover button is too heavy.
  final double? height;

  @override
  ConsumerState<UserFollowButton> createState() => _UserFollowButtonState();
}

class _UserFollowButtonState extends ConsumerState<UserFollowButton> {
  @override
  void initState() {
    super.initState();
    pixivAccountNotifier.addListener(_accountChanged);
  }

  void _accountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    pixivAccountNotifier.removeListener(_accountChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountId = pixivAccountNotifier.value?.user.id;
    final provider = userFollowProvider(UserFollowArgs(userId: widget.userId, isFollowed: widget.initialIsFollowed ?? false, accountId: accountId));
    final follow = ref.watch(provider);
    final isFollowed = follow.isFollowed;
    final translations = t;

    Future<void> toggle() async {
      try {
        await ref.read(provider.notifier).toggle(restrict: widget.restrict);
      } catch (error) {
        if (!context.mounted || pixivAccountNotifier.value?.user.id != accountId) {
          return;
        }
        AppToast.errorWithCause(translations.toast.followFailed, error);
      }
    }

    if (int.tryParse(accountId ?? '') == widget.userId) return const SizedBox.shrink();
    return Tooltip(
      message: isFollowed ? translations.follow.tooltipUnfollow : translations.follow.tooltipFollow,
      child: FollowToggleButton(
        isFollowed: isFollowed,
        updating: follow.updating,
        iconSize: widget.iconSize,
        dense: widget.dense,
        height: widget.height,
        onPressed: follow.updating || accountId == null ? null : toggle,
      ),
    );
  }
}

class UserFollowButtonPlaceholder extends StatelessWidget {
  const UserFollowButtonPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      child: Bone(width: 82, height: AppMetrics.controlHeight, borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
    );
  }
}

/// The follow / following toggle's look, shared by Pixiv users and FANBOX
/// creators so both read as the same action.
class FollowToggleButton extends StatelessWidget {
  const FollowToggleButton({
    required this.isFollowed,
    required this.onPressed,
    this.updating = false,
    this.iconSize = 18,
    this.dense = false,
    this.height,
    super.key,
  });

  /// Height of the [dense] button.
  static const denseHeight = 34.0;

  final bool isFollowed;
  final bool updating;
  final double iconSize;
  final bool dense;
  final double? height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final translations = t;
    // Follow is the solid accent action; Following is a persistent selection,
    // so it takes the accent wash and ink used for selection elsewhere. A
    // neutral fill all but vanished on light cards.
    final foreground = isFollowed ? tokens.selectionInk : tokens.onAction;
    final background = isFollowed ? tokens.selectionSurface : tokens.actionFill;
    final graphicColor = isFollowed ? tokens.selectionInk : tokens.onAction;
    // The glyph follows the label's text scale so the two stay in proportion,
    // capped so the button does not grow taller than its label needs.
    final baseIcon = dense ? iconSize - 2 : iconSize;
    final glyphSize = MediaQuery.textScalerOf(context).scale(baseIcon).clamp(baseIcon, baseIcon * 1.75).toDouble();
    return Semantics(
      selected: isFollowed,
      child: TextButton(
        onPressed: updating ? null : onPressed,
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, dense ? (height ?? denseHeight) : AppMetrics.controlHeight)),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 4 : 8)),
          tapTargetSize: dense ? MaterialTapTargetSize.shrinkWrap : null,
          backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) && !updating ? tokens.surfaceInset : background),
          // A translucent state layer, so hovering keeps the accent wash
          // instead of replacing it with an opaque neutral.
          backgroundBuilder: isFollowed ? appButtonFeedbackBackground : appPrimaryButtonFeedbackBackground,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          mouseCursor: appClickCursor,
          foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) && !updating ? tokens.disabledText : foreground),
          side: WidgetStateProperty.resolveWith((states) => appFeedbackBorder(tokens, states)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The glyph swaps by shrinking out and growing in (+ → ✓), so the
            // change reads as one button changing state (docs/MOTION_SPEC.md 7).
            SizedBox.square(
              dimension: glyphSize,
              child: AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.expand),
                switchInCurve: SpringCurve(AppMotion.snappy, AppMotion.expand),
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation.drive(Tween(begin: .5, end: 1.0)), child: child),
                ),
                child: switch ((updating, isFollowed)) {
                  (true, _) => CircularProgressIndicator(key: const ValueKey('updating'), strokeWidth: 2, color: graphicColor),
                  (false, final followed) => Icon(
                    followed ? Icons.check_rounded : Icons.add_rounded,
                    key: ValueKey(followed),
                    size: glyphSize,
                    color: onPressed == null ? tokens.disabledText : graphicColor,
                  ),
                },
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              // Under a width cap (large text in a header) the label shrinks
              // instead of wrapping or overflowing.
              child: _fitLabel(
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Both localized labels reserve width, so the button never
                    // changes size on a toggle; the labels cross-fade in place.
                    for (final followed in [false, true])
                      ExcludeSemantics(
                        excluding: followed != isFollowed,
                        child: AnimatedOpacity(
                          opacity: followed == isFollowed ? 1 : 0,
                          duration: AppMotion.duration(context, AppMotion.hover),
                          curve: Curves.easeOut,
                          child: Text(followed ? translations.follow.followed : translations.follow.follow, textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fitLabel(Widget label) => dense ? FittedBox(fit: BoxFit.scaleDown, child: label) : label;
}
