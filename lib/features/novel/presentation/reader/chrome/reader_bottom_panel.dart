import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_selector.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_status_line.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_controller.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/custom/reader/reader_progress_track.dart';
import 'package:frost_ui/frost_ui.dart';

/// The panel over the bottom of the text: the previous and next chapter with
/// the current one between them, the progress track, and the entries for the
/// contents, the illustrations, the appearance and auto scroll.
class ReaderBottomPanel extends StatelessWidget {
  const ReaderBottomPanel({
    required this.controller,
    required this.enabled,
    required this.onGoToChapter,
    required this.onJumpToFraction,
    required this.appearance,
    this.onContents,
    this.onIllustrations,
    this.autoScrolling,
    this.onToggleAutoScroll,
    super.key,
  });

  final ReaderController controller;

  /// False when the viewer's account changed under the reader.
  final bool enabled;
  final ValueChanged<int> onGoToChapter;
  final ValueChanged<double> onJumpToFraction;

  /// The button that opens the appearance panel, drawn for the layout's size.
  final Widget Function(BuildContext context, bool compact) appearance;
  final VoidCallback? onContents;
  final VoidCallback? onIllustrations;

  /// Whether auto scroll runs; null when the mode has none (paged).
  final bool? autoScrolling;
  final VoidCallback? onToggleAutoScroll;

  @override
  Widget build(BuildContext context) {
    final t = context.t.novel.reader;
    final model = controller.model;
    final chapters = model.chapters;
    final compact = FrostSizeClass.of(context) == FrostSizeClass.compact;
    final total = model.totalLength;
    final ready = enabled && total > 0;
    final images = model.imageBlocks.length;
    final running = autoScrolling;
    return FrostSurface(
      role: FrostSurfaceRole.chrome,
      child: SafeArea(
        top: false,
        child: FrostContentColumn(
          maxWidth: FrostMetrics.readingMaxWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A single chapter has nothing to go to.
                if (chapters.length > 1)
                  ReaderSelector<int>(
                    listenable: controller,
                    select: () => controller.chapter.index,
                    builder: (context, index) {
                      final previous = ready && index > 0 ? () => onGoToChapter(index - 1) : null;
                      final next = ready && index < chapters.length - 1 ? () => onGoToChapter(index + 1) : null;
                      return Row(
                        spacing: FrostGap.inline,
                        children: [
                          if (compact)
                            FrostButton.icon(icon: PivIcons.chevronLeft, label: t.previousChapter, onPressed: previous)
                          else
                            FrostButton.plain(label: t.previousChapter, icon: PivIcons.chevronLeft, onPressed: previous),
                          Expanded(
                            child: FrostText(
                              readerChapterLabel(context.t, chapters[index]),
                              key: const ValueKey('reader-chapter-title'),
                              content: true,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (compact)
                            FrostButton.icon(icon: PivIcons.chevronRight, label: t.nextChapter, onPressed: next)
                          else
                            FrostButton.plain(label: t.nextChapter, icon: PivIcons.chevronRight, onPressed: next),
                        ],
                      );
                    },
                  ),
                ReaderProgressTrack(
                  key: const ValueKey('reader-progress'),
                  repaint: controller,
                  progress: () => controller.progress,
                  chapterMarks: [for (final chapter in chapters) total == 0 ? 0 : chapter.startOffset / total],
                  imageMarks: [for (final block in model.imageBlocks) total == 0 ? 0 : model.offsetOf(block) / total],
                  semanticLabel: t.readingProgress,
                  valueLabel: (value) => t.progressValue(percent: (value * 100).round()),
                  bubbleLabel: (value) =>
                      t.progressBubble(chapter: readerChapterLabel(context.t, model.chapterAt((value * total).round())), percent: (value * 100).round()),
                  onChanged: ready ? onJumpToFraction : null,
                ),
                // Wraps where the labels do not fit the width.
                Wrap(
                  spacing: FrostGap.inline,
                  alignment: WrapAlignment.spaceEvenly,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (onContents != null)
                      ReaderPanelEntry(
                        key: const ValueKey('reader-contents'),
                        icon: PivIcons.newspaper,
                        label: t.contents,
                        compact: compact,
                        onPressed: onContents,
                      ),
                    if (onIllustrations != null && images > 0)
                      ReaderPanelEntry(
                        key: const ValueKey('reader-illustrations'),
                        icon: PivIcons.images,
                        label: t.illustrationsCount(count: images),
                        compact: compact,
                        onPressed: onIllustrations,
                      ),
                    appearance(context, compact),
                    if (running != null)
                      ReaderPanelEntry(
                        key: const ValueKey('reader-auto-scroll'),
                        icon: running ? PivIcons.pause : PivIcons.play,
                        label: running ? t.pauseAutoScroll : t.startAutoScroll,
                        compact: compact,
                        selected: running,
                        onPressed: ready ? onToggleAutoScroll : null,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An entry of the bottom row: icon and label, the label only where there is
/// room.
class ReaderPanelEntry extends StatelessWidget {
  const ReaderPanelEntry({
    required this.icon,
    required this.label,
    required this.compact,
    required this.onPressed,
    this.selected = false,
    this.focusNode,
    super.key,
  });

  final FrostIconData icon;
  final String label;
  final bool compact;
  final bool selected;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => compact
      ? Focus(
          focusNode: focusNode,
          child: FrostButton.icon(icon: icon, label: label, selected: selected, onPressed: onPressed),
        )
      : Focus(
          focusNode: focusNode,
          child: FrostButton.plain(label: label, icon: icon, onPressed: onPressed),
        );
}
