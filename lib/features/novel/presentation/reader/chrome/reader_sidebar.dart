import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart' show ReaderChapter;
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_selector.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_status_line.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_controller.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_paged_view.dart' show ReaderPageGeometry;
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/custom/reader/reader_thumbnail_outline.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';
import 'package:frost_ui/frost_ui.dart';

/// The two lists of the sidebar.
enum ReaderSidebarTab { contents, illustrations }

/// An illustration of the text for the sidebar: where it is, its thumbnail
/// and the shape that thumbnail is drawn in.
class ReaderIllustration {
  const ReaderIllustration({required this.block, required this.offset, required this.url, required this.aspectRatio, required this.isWork});

  /// The block holding it, and the characters before it.
  final int block;
  final int offset;

  /// The thumbnail's address; null when the work cannot be seen.
  final String? url;

  /// Width over height.
  final double aspectRatio;

  /// An embedded work of Pixiv, not an image uploaded with the novel.
  final bool isWork;
}

/// Width of the sidebar, docked or over the text.
const readerSidebarWidth = 320.0;

/// Space kept on each side of the text column beside a docked sidebar.
const readerSidebarMargin = 24.0;

/// Whether the sidebar sits beside the text in a window of [size]: only when
/// the text column keeps the width it has without the sidebar, with the
/// margins on both sides of it. Otherwise it lies over the text.
bool readerSidebarDocks({required Size size, required ReaderTypesetting typesetting, required bool paged}) {
  final rest = size.width - readerSidebarWidth;
  if (rest <= 0) return false;
  if (!paged) {
    final column = typesetting.columnWidth(size.width);
    return typesetting.columnWidth(rest) == column && rest >= column + 2 * readerSidebarMargin;
  }
  final whole = ReaderPageGeometry.of(size, typesetting);
  final narrowed = ReaderPageGeometry.of(Size(rest, size.height), typesetting);
  final column = typesetting.columnWidth(whole.pageWidth);
  final spreadWidth = whole.spread ? 2 * column + whole.gutter : column;
  return whole.spread == narrowed.spread && typesetting.columnWidth(narrowed.pageWidth) == column && rest >= spreadWidth + 2 * readerSidebarMargin;
}

/// The contents and the illustrations of the text, one list at a time.
class ReaderSidebar extends StatefulWidget {
  const ReaderSidebar({
    required this.controller,
    required this.tab,
    required this.onTabChanged,
    required this.onClose,
    required this.onGoToChapter,
    required this.illustrations,
    required this.onGoToIllustration,
    required this.onOpenIllustration,
    this.markerPage,
    super.key,
  });

  final ReaderController controller;
  final ReaderSidebarTab tab;
  final ValueChanged<ReaderSidebarTab> onTabChanged;
  final VoidCallback onClose;
  final ValueChanged<int> onGoToChapter;
  final List<ReaderIllustration> illustrations;

  /// Moves the text to the illustration.
  final ValueChanged<ReaderIllustration> onGoToIllustration;

  /// Opens the illustration's own picture: the viewer, or the work.
  final ValueChanged<ReaderIllustration> onOpenIllustration;

  /// The 1-based section of the Pixiv reading bookmark, when there is one.
  final int? markerPage;

  @override
  State<ReaderSidebar> createState() => _ReaderSidebarState();
}

class _ReaderSidebarState extends State<ReaderSidebar> with SingleTickerProviderStateMixin {
  late final FrostTabController _tabs = FrostTabController(length: 2, initialIndex: widget.tab.index, vsync: this);

  @override
  void didUpdateWidget(ReaderSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.index != _tabs.index) _tabs.index = widget.tab.index;
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.novel.reader;
    final hasIllustrations = widget.illustrations.isNotEmpty;
    final tab = hasIllustrations ? widget.tab : ReaderSidebarTab.contents;
    return FrostSurface(
      role: FrostSurfaceRole.chrome,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FrostGap.related, vertical: FrostGap.related),
              child: Row(
                spacing: FrostGap.inline,
                children: [
                  Expanded(
                    child: hasIllustrations
                        ? FrostTabBar(
                            controller: _tabs,
                            tabs: [
                              FrostTab(label: t.contents),
                              FrostTab(label: t.illustrations),
                            ],
                            onTap: (index) => widget.onTabChanged(ReaderSidebarTab.values[index]),
                          )
                        : FrostText(t.contents, role: FrostTextRole.headline),
                  ),
                  FrostButton.icon(key: const ValueKey('reader-sidebar-close'), icon: PivIcons.close, label: t.closeSidebar, onPressed: widget.onClose),
                ],
              ),
            ),
            Expanded(
              child: switch (tab) {
                ReaderSidebarTab.contents => _Contents(controller: widget.controller, markerPage: widget.markerPage, onGoToChapter: widget.onGoToChapter),
                ReaderSidebarTab.illustrations => _Illustrations(
                  controller: widget.controller,
                  illustrations: widget.illustrations,
                  onGo: widget.onGoToIllustration,
                  onOpen: widget.onOpenIllustration,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Contents extends StatefulWidget {
  const _Contents({required this.controller, required this.markerPage, required this.onGoToChapter});

  final ReaderController controller;
  final int? markerPage;
  final ValueChanged<int> onGoToChapter;

  @override
  State<_Contents> createState() => _ContentsState();
}

class _ContentsState extends State<_Contents> {
  final _scroll = ScrollController();

  /// Every row has this height, so the current one can be brought into view
  /// without building the others.
  double _extent = 56;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _reveal(int index) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final top = index * _extent;
    if (top >= position.pixels && top + _extent <= position.pixels + position.viewportDimension) return;
    position.jumpTo((top - (position.viewportDimension - _extent) / 2).clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal(widget.controller.chapter.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final model = controller.model;
    final chapters = model.chapters;
    final t = context.t.novel.reader;
    _extent = MediaQuery.textScalerOf(context).scale(56).clamp(56, 120);
    final markerChapter = widget.markerPage == null ? null : model.chapterAt(model.offsetOfPage(widget.markerPage!)).index;
    return ReaderSelector<int>(
      listenable: controller,
      select: () => controller.chapter.index,
      builder: (context, current) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _reveal(current);
        });
        return ListView.builder(
          key: const ValueKey('reader-contents-list'),
          controller: _scroll,
          // Rows inset themselves only inside a page with a gutter.
          padding: const EdgeInsets.symmetric(horizontal: FrostGap.group),
          itemExtent: _extent,
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            return FrostListRow(
              key: ValueKey('reader-chapter-$index'),
              title: readerChapterLabel(context.t, chapter),
              contentTitle: chapter.title != null,
              selected: index == current,
              onPressed: () => widget.onGoToChapter(index),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: FrostGap.inline,
                children: [
                  if (index == markerChapter) FrostIcon(PivIcons.bookOpen, size: 16, semanticLabel: t.markerMenu),
                  SizedBox(
                    width: 56,
                    child: index == current
                        ? ReaderSelector<double>(
                            listenable: controller,
                            select: () => _chapterShare(controller, chapter),
                            builder: (context, share) => FrostProgressBar(value: share, semanticLabel: t.readingProgress),
                          )
                        : FrostProgressBar(value: index < current ? 1 : 0, semanticLabel: t.readingProgress),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// How much of [chapter] lies before the reading position, to a percent.
  static double _chapterShare(ReaderController controller, ReaderChapter chapter) {
    final length = chapter.endOffset - chapter.startOffset;
    if (length <= 0) return 0;
    final share = ((controller.offset - chapter.startOffset) / length).clamp(0.0, 1.0).toDouble();
    return (share * 100).round() / 100;
  }
}

class _Illustrations extends StatelessWidget {
  const _Illustrations({required this.controller, required this.illustrations, required this.onGo, required this.onOpen});

  final ReaderController controller;
  final List<ReaderIllustration> illustrations;
  final ValueChanged<ReaderIllustration> onGo;
  final ValueChanged<ReaderIllustration> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.t.novel.reader;
    return ReaderSelector<int>(
      // The thumbnail nearest the reading position is marked.
      listenable: controller,
      select: () {
        var nearest = -1;
        for (var i = 0; i < illustrations.length; i++) {
          if (illustrations[i].offset <= controller.offset) nearest = i;
        }
        return nearest;
      },
      builder: (context, nearest) => FrostWaterfallGrid<ReaderIllustration>(
        key: const ValueKey('reader-illustrations-grid'),
        items: illustrations,
        minTileWidth: 120,
        maxColumns: 2,
        padding: const EdgeInsets.all(FrostGap.related),
        crossAxisSpacing: FrostGap.related,
        mainAxisSpacing: FrostGap.related,
        itemBuilder: (context, item, index) => AspectRatio(
          aspectRatio: item.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FrostClickSurface(
                key: ValueKey('reader-illustration-${item.block}'),
                shape: FrostClickShape.rounded(BorderRadius.circular(FrostRadius.md)),
                onTap: () => onGo(item),
                // A double tap opens the picture; the tap above waits for it.
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () => onOpen(item),
                  child: Semantics(
                    label: t.illustrationAt(number: index + 1),
                    image: true,
                    child: AppPixivImage(url: item.url ?? '', radius: FrostRadius.md, fit: BoxFit.cover),
                  ),
                ),
              ),
              if (index == nearest) const Positioned.fill(child: IgnorePointer(child: ReaderThumbnailOutline())),
              PositionedDirectional(
                top: 4,
                end: 4,
                child: FrostButton.iconOnMedia(
                  key: ValueKey('reader-illustration-open-${item.block}'),
                  icon: PivIcons.externalLink,
                  label: t.openIllustration,
                  size: FrostControlSize.compact,
                  onPressed: () => onOpen(item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
