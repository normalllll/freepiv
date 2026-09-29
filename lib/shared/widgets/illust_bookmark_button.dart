import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/logic/illust_bookmark_logic.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/ui/fp_icon.dart';

class IllustBookmarkButton extends ConsumerStatefulWidget {
  const IllustBookmarkButton({required this.illustId, this.initialIsBookmarked, this.isNovel = false, this.iconSize = 22, this.floating = false, super.key});

  final int illustId;
  final bool? initialIsBookmarked;
  final bool isNovel;
  final double iconSize;
  final bool floating;

  @override
  ConsumerState<IllustBookmarkButton> createState() => _IllustBookmarkButtonState();
}

class _IllustBookmarkButtonState extends ConsumerState<IllustBookmarkButton> with SingleTickerProviderStateMixin {
  /// Extra scale of the heart above 1. Bookmarking kicks it with a velocity;
  /// the critically damped spring rises once and settles, never wobbling.
  late final AnimationController _heartAnimation = AnimationController.unbounded(vsync: this);

  /// Initial speed of the kick; with [AppMotion.snappy] the heart peaks at
  /// about 1.14 roughly 40 ms in and is back at rest within a quarter second.
  static const _heartKick = 9.6;

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
    _heartAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountId = pixivAccountNotifier.value?.user.id;
    final provider = illustBookmarkProvider(
      IllustBookmarkArgs(accountId: accountId, illustId: widget.illustId, isBookmarked: widget.initialIsBookmarked ?? false, isNovel: widget.isNovel),
    );
    final bookmark = ref.watch(provider);
    ref.listen(provider, (previous, next) {
      if (previous != null && !previous.isBookmarked && next.isBookmarked && !MediaQuery.disableAnimationsOf(context)) {
        _heartAnimation.animateWith(SpringSimulation(AppMotion.snappy, _heartAnimation.value, 0, _heartAnimation.velocity + _heartKick));
      } else if (previous?.isBookmarked == true && !next.isBookmarked) {
        _heartAnimation.value = 0;
      }
    });

    final tokens = FreepivThemeTokens.of(context);
    final selectedColor = widget.floating ? tokens.textPrimary : tokens.keyGraphicOn(tokens.surface);
    final translations = t;
    final glyph = AnimatedBuilder(
      animation: _heartAnimation,
      builder: (context, child) => Transform.scale(scale: 1 + _heartAnimation.value, child: child),
      child: FpIcon(
        FpIconName.heart,
        size: widget.iconSize,
        color: bookmark.isBookmarked ? selectedColor : tokens.textSecondary,
        filled: bookmark.isBookmarked,
      ),
    );

    Future<void> toggle() async {
      try {
        await ref.read(provider.notifier).toggle();
      } catch (error) {
        if (!mounted || pixivAccountNotifier.value?.user.id != accountId) {
          return;
        }
        AppToast.errorWithCause(translations.toast.bookmarkFailed, error);
      }
    }

    if (widget.floating) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceRaised.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          border: Border.all(color: tokens.line.withValues(alpha: .65)),
        ),
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            tooltip: bookmark.isBookmarked ? translations.illust.tooltip.removeBookmark : translations.illust.tooltip.addBookmark,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: AppMetrics.controlHeight, height: AppMetrics.controlHeight),
            onPressed: bookmark.updating || accountId == null ? null : toggle,
            icon: glyph,
          ),
        ),
      );
    }

    return IconButton(
      tooltip: bookmark.isBookmarked ? translations.illust.tooltip.removeBookmark : translations.illust.tooltip.addBookmark,
      visualDensity: VisualDensity.standard,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: AppMetrics.controlHeight, height: AppMetrics.controlHeight),
      onPressed: bookmark.updating || accountId == null ? null : toggle,
      icon: glyph,
    );
  }
}
