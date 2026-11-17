import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_web_actions.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_ui/frost_ui.dart';

/// The one primary action of the page: Start or Continue reading, with a thin
/// bar under it showing how far the account has read. Off while the text is
/// not there to read.
class NovelReadButton extends StatelessWidget {
  const NovelReadButton({required this.progress, required this.onPressed, super.key});

  final ReadingProgress? progress;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final progress = this.progress;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.inline,
      children: [
        FrostButton.prominent(
          label: progress == null ? t.novel.detail.startReading : t.novel.detail.continueReading(percent: progress.percent),
          icon: PivIcons.newspaper,
          onPressed: onPressed,
        ),
        if (progress != null) FrostProgressBar(value: progress.fraction, semanticLabel: t.novel.reader.readingProgress),
      ],
    );
  }
}

/// Bookmark, with the bookmark options on its context menu, and More.
class NovelSecondaryActions extends StatelessWidget {
  const NovelSecondaryActions({required this.novel, this.fill = true, super.key});

  final Novel novel;

  /// Whether the bookmark button takes the row's width; otherwise the row is
  /// as wide as its buttons, to sit beside the read button.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final bookmark = AppBookmarkBuilder(
      workId: novel.id,
      initiallyBookmarked: novel.isBookmarked,
      novel: true,
      builder: (context, bookmarked, toggle) => FrostContextMenuRegion(
        entries: novelBookmarkMenu(context, novel),
        child: AppDetailBookmarkButton(bookmarked: bookmarked, label: bookmarked ? t.novelDetail.bookmarked : t.novelDetail.bookmark, onPressed: toggle),
      ),
    );
    return Row(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      spacing: FrostGap.related,
      children: [
        if (fill) Expanded(child: bookmark) else bookmark,
        NovelMoreButton(novel: novel),
      ],
    );
  }
}

class NovelMoreButton extends StatelessWidget {
  const NovelMoreButton({required this.novel, super.key});

  final Novel novel;

  @override
  Widget build(BuildContext context) => FrostMenuAnchor(
    entries: [...novelBookmarkMenu(context, novel), ...novelMoreMenu(context, novel)],
    builder: (context, focusNode, toggle) => FrostButton.icon(icon: PivIcons.more, label: FrostScope.labelsOf(context).more, onPressed: toggle),
  );
}

/// The phone's action bar, pinned above the safe area: the read button with
/// bookmark and More beside it.
class NovelBottomActionBar extends StatelessWidget {
  const NovelBottomActionBar({required this.novel, required this.progress, required this.onRead, super.key});

  final Novel novel;
  final ReadingProgress? progress;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return FrostSurface(
      role: FrostSurfaceRole.chrome,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FrostGap.group, vertical: FrostGap.related),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FrostGap.related,
            children: [
              Expanded(
                child: NovelReadButton(progress: progress, onPressed: onRead),
              ),
              AppBookmarkBuilder(
                workId: novel.id,
                initiallyBookmarked: novel.isBookmarked,
                novel: true,
                builder: (context, bookmarked, toggle) => FrostContextMenuRegion(
                  entries: novelBookmarkMenu(context, novel),
                  child: FrostButton.icon(
                    icon: bookmarked ? PivIcons.heartFilled : PivIcons.heart,
                    label: bookmarked ? t.novelDetail.bookmarked : t.novelDetail.bookmark,
                    selected: bookmarked,
                    onPressed: toggle,
                  ),
                ),
              ),
              NovelMoreButton(novel: novel),
            ],
          ),
        ),
      ),
    );
  }
}
