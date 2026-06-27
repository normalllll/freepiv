import 'package:flutter/material.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/features/novel/domain/novel_text_parser.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_detail_constraints.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

class NovelReaderSlivers {
  const NovelReaderSlivers._();

  static List<Widget> buildEntry({required Novel novel, required WebviewNovel webviewNovel, required VoidCallback onStartReading}) {
    final blocks = parseNovelText(webviewNovel.text);
    final paragraphCount = blocks.whereType<NovelTextParagraph>().length;
    final segmentCount = segmentNovelTextBlocks(blocks).length;

    return [
      SliverToBoxAdapter(
        child: NovelReaderWidthLimiter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IllustSectionTitle(title: t.novel.detail.content, icon: Icons.menu_book_outlined),
                const SizedBox(height: 10),
                _NovelReaderEntry(
                  charCount: novel.textLength,
                  paragraphCount: paragraphCount,
                  segmentCount: segmentCount,
                  canRead: blocks.isNotEmpty,
                  onStartReading: onStartReading,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}

class NovelReaderBlockView extends StatelessWidget {
  const NovelReaderBlockView({required this.block, required this.paragraphStyle, required this.chapterStyle, required this.dividerColor, super.key});

  final NovelTextBlock block;
  final TextStyle? paragraphStyle;
  final TextStyle? chapterStyle;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      NovelTextParagraph(:final text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(text, softWrap: true, style: paragraphStyle),
      ),
      NovelTextChapter(:final title) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 14),
        child: Text(title, style: chapterStyle),
      ),
      NovelTextPageBreak() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: dividerColor),
      ),
    };
  }
}

class _NovelReaderEntry extends StatelessWidget {
  const _NovelReaderEntry({
    required this.charCount,
    required this.paragraphCount,
    required this.segmentCount,
    required this.canRead,
    required this.onStartReading,
  });

  final int charCount;
  final int paragraphCount;
  final int segmentCount;
  final bool canRead;
  final VoidCallback onStartReading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final summary = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ReaderEntryChip(
                  icon: Icons.text_fields,
                  label: t.novel.detail.totalChars(count: formatCount(charCount)),
                ),
                _ReaderEntryChip(
                  icon: Icons.notes_outlined,
                  label: t.novel.detail.paragraphCount(count: paragraphCount),
                ),
                _ReaderEntryChip(
                  icon: Icons.view_carousel_outlined,
                  label: t.novel.detail.segmentCount(count: segmentCount),
                ),
              ],
            );
            final button = FilledButton.icon(
              onPressed: canRead ? onStartReading : null,
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(t.novel.detail.startReading),
            );

            if (compact) {
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [summary, const SizedBox(height: 12), button]);
            }

            return Row(
              children: [
                Expanded(child: summary),
                const SizedBox(width: 12),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReaderEntryChip extends StatelessWidget {
  const _ReaderEntryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(7)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
