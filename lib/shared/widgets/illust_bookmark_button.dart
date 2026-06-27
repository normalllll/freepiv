import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/logic/illust_bookmark_logic.dart';

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

class _IllustBookmarkButtonState extends ConsumerState<IllustBookmarkButton> {
  @override
  Widget build(BuildContext context) {
    final provider = illustBookmarkProvider(
      IllustBookmarkArgs(
        runtimeTag: 'illust-id:${widget.illustId}',
        illustId: widget.illustId,
        isBookmarked: widget.initialIsBookmarked ?? false,
        isNovel: widget.isNovel,
      ),
    );
    final bookmark = ref.watch(provider);

    final colorScheme = Theme.of(context).colorScheme;
    final tokens = FreepivThemeTokens.of(context);
    final translations = t;

    Future<void> toggle() async {
      try {
        await ref.read(provider.notifier).toggle();
      } catch (error) {
        if (!mounted) {
          return;
        }
        AppToast.errorWithCause(translations.toast.bookmarkFailed, error);
      }
    }

    if (widget.floating) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceRaised.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: tokens.shadow, blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            tooltip: bookmark.isBookmarked ? translations.illust.tooltip.removeBookmark : translations.illust.tooltip.addBookmark,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 56, height: 56),
            onPressed: bookmark.updating ? null : toggle,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              child: Icon(
                bookmark.isBookmarked ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(bookmark.isBookmarked),
                size: widget.iconSize < 28 ? 30 : widget.iconSize,
                color: bookmark.isBookmarked ? tokens.brand : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return IconButton(
      tooltip: bookmark.isBookmarked ? translations.illust.tooltip.removeBookmark : translations.illust.tooltip.addBookmark,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      onPressed: bookmark.updating ? null : toggle,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 140),
        child: Icon(
          bookmark.isBookmarked ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(bookmark.isBookmarked),
          size: widget.iconSize,
          color: bookmark.isBookmarked ? tokens.brand : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
