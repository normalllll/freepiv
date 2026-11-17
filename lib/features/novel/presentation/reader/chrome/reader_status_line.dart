import 'package:flutter/widgets.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/features/novel/domain/reading_time.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_selector.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_controller.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/custom/reader/reader_status_text.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';
import 'package:frost_ui/frost_ui.dart';

/// The title of [chapter]: its own, or its number.
String readerChapterLabel(Translations t, ReaderChapter chapter) => chapter.title ?? t.novel.reader.chapterNumber(number: chapter.index + 1);

/// Where the footer's page numbers come from in paged mode: the 1-based page
/// of the reading position and the pages of its chapter; null in scroll mode.
typedef ReaderPageStatus = ({int page, int pages})? Function();

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: extent,
    child: Center(
      child: FrostContentColumn(maxWidth: FrostMetrics.readingMaxWidth, child: child),
    ),
  );
}

/// The line above the text: the chapter being read. Empty when the text is a
/// single untitled chapter.
class ReaderHeaderLine extends StatelessWidget {
  const ReaderHeaderLine({required this.controller, required this.palette, required this.extent, super.key});

  final ReaderController controller;
  final ReaderPalette palette;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final chapters = controller.model.chapters;
    if (chapters.length < 2 && chapters.first.title == null) return SizedBox(height: extent);
    return _StatusLine(
      extent: extent,
      child: ReaderSelector<int>(
        listenable: controller,
        select: () => controller.chapter.index,
        builder: (context, index) => ReaderStatusText(readerChapterLabel(context.t, chapters[index]), palette: palette),
      ),
    );
  }
}

/// The line below the text: the share read and the minutes left in the
/// chapter (scroll), or the page and the share read (paged).
class ReaderFooterLine extends StatelessWidget {
  const ReaderFooterLine({
    required this.controller,
    required this.layouts,
    required this.palette,
    required this.extent,
    required this.pageStatus,
    this.language,
    super.key,
  });

  final ReaderController controller;

  /// Notifies when the pages [pageStatus] reads from are laid again.
  final Listenable layouts;
  final ReaderPalette palette;
  final double extent;
  final ReaderPageStatus pageStatus;
  final String? language;

  @override
  Widget build(BuildContext context) {
    return _StatusLine(
      extent: extent,
      child: ReaderSelector<({int percent, int minutes, int page, int pages})>(
        listenable: Listenable.merge([controller, layouts]),
        select: () {
          final percent = (controller.progress * 100).round();
          final paged = pageStatus();
          if (paged != null) return (percent: percent, minutes: 0, page: paged.page, pages: paged.pages);
          final left = controller.atEnd ? 0 : controller.chapter.endOffset - controller.offset;
          return (percent: percent, minutes: readingMinutes(left, language: language), page: 0, pages: 0);
        },
        builder: (context, status) {
          final t = context.t.novel.reader;
          final text = status.page > 0
              ? t.pageStatus(page: status.page, pages: status.pages, percent: status.percent)
              : status.minutes > 0
              ? t.progressStatus(percent: status.percent, minutes: status.minutes)
              : t.progressValue(percent: status.percent);
          return ReaderStatusText(text, palette: palette);
        },
      ),
    );
  }
}
