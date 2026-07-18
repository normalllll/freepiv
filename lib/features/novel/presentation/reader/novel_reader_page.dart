import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/novel/domain/novel_text_parser.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_not_found_page.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_reader_slivers.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

class NovelReaderPage extends ConsumerWidget {
  const NovelReaderPage({this.novelId, this.novel, super.key}) : assert(novelId != null || novel != null);

  final int? novelId;
  final Novel? novel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = NovelDetailArgs(novelId: novelId, novel: novel);
    final provider = novelDetailProvider(args);
    final detailValue = ref.watch(provider);

    return detailValue.when(
      data: (detail) => NovelReaderContent(key: ValueKey<String>('novel-reader-content-${detail.novel.id}'), detail: detail),
      loading: () => const _ReaderLoadingPage(),
      error: (error, stackTrace) {
        if (_isNotFoundError(error)) {
          return const NovelNotFoundPage();
        }

        return ErrorPage.fromError(error: error, onRetry: () => ref.read(provider.notifier).reload());
      },
    );
  }
}

class NovelReaderContent extends StatefulWidget {
  const NovelReaderContent({required this.detail, super.key});

  final NovelDetailData detail;

  @override
  State<NovelReaderContent> createState() => _NovelReaderContentState();
}

class _NovelReaderContentState extends State<NovelReaderContent> {
  final PageController _pageController = PageController();
  final FocusNode _shortcutFocusNode = FocusNode(debugLabel: 'novel-reader-shortcuts');
  final Map<int, ScrollController> _segmentScrollControllers = {};

  late List<NovelTextSegment> _segments;
  late int _totalTextCharacters;

  int _pageIndex = 0;
  double _fontSize = 18;
  double _lineHeight = 1.78;
  bool _chromeVisible = false;

  Novel get _novel => widget.detail.novel;

  WebviewNovel get _webviewNovel => widget.detail.webviewNovel;

  int get _currentPageIndex => _clampPageIndex(_pageIndex);

  @override
  void initState() {
    super.initState();
    _rebuildReaderModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _shortcutFocusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant NovelReaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.novel.id != widget.detail.novel.id || oldWidget.detail.webviewNovel.text != widget.detail.webviewNovel.text) {
      _pageIndex = 0;
      _disposeSegmentScrollControllers();
      _rebuildReaderModel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpControllerToPage(0));
    }
  }

  @override
  void dispose() {
    _disposeSegmentScrollControllers();
    _shortcutFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ReaderPalette.resolve(context);

    return AutoScaffold(
      builder: (context, layout, orientation, shouldUseDesktopShell) {
        final pageIndex = _currentPageIndex;
        final useDesktopLayout = shouldUseDesktopShell;
        final shortcutsEnabled = useDesktopLayout && isDesktopPlatform;

        if (useDesktopLayout) {
          final reader = _DesktopNovelReaderLayout(
            novel: _novel,
            segments: _segments,
            totalTextCharacters: _totalTextCharacters,
            pageController: _pageController,
            pageIndex: pageIndex,
            fontSize: _fontSize,
            lineHeight: _lineHeight,
            palette: palette,
            scrollControllerForSegment: _scrollControllerForSegment,
            shortcutsEnabled: shortcutsEnabled,
            chromeVisible: _chromeVisible,
            onBack: _closeReader,
            onToggleChrome: _toggleChrome,
            onPageChanged: _handlePageChanged,
            onPageRequested: _goToPage,
            onProgressChanged: _jumpToProgress,
            onShowSettings: _showSettingsSheet,
          );

          if (!shortcutsEnabled) {
            return reader;
          }

          return Focus(focusNode: _shortcutFocusNode, autofocus: true, onKeyEvent: _handleShortcutKeyEvent, child: reader);
        }

        return _MobileNovelReaderLayout(
          novel: _novel,
          segments: _segments,
          totalTextCharacters: _totalTextCharacters,
          pageController: _pageController,
          pageIndex: pageIndex,
          fontSize: _fontSize,
          lineHeight: _lineHeight,
          palette: palette,
          scrollControllerForSegment: _scrollControllerForSegment,
          shortcutsEnabled: false,
          chromeVisible: _chromeVisible,
          onBack: _closeReader,
          onToggleChrome: _toggleChrome,
          onPageChanged: _handlePageChanged,
          onPageRequested: _goToPage,
          onProgressChanged: _jumpToProgress,
          onShowSettings: _showSettingsSheet,
        );
      },
    );
  }

  void _rebuildReaderModel() {
    final blocks = parseNovelText(_webviewNovel.text);
    _segments = segmentNovelTextBlocks(blocks);
    _totalTextCharacters = _segments.isEmpty ? 0 : _segments.last.endOffset;
    _pageIndex = _clampPageIndex(_pageIndex);
  }

  int _clampPageIndex(int value) {
    if (_segments.isEmpty) {
      return 0;
    }

    return value.clamp(0, _segments.length - 1);
  }

  void _handlePageChanged(int pageIndex) {
    if (_pageIndex == pageIndex) {
      return;
    }

    setState(() {
      _pageIndex = pageIndex;
    });
  }

  void _goToPage(int pageIndex) {
    final nextPage = _clampPageIndex(pageIndex);
    setState(() {
      _pageIndex = nextPage;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpControllerToPage(nextPage));
    }
  }

  void _jumpToProgress(double value) {
    final nextPage = _clampPageIndex(value.round());
    setState(() {
      _pageIndex = nextPage;
    });
    _jumpControllerToPage(nextPage);
  }

  void _jumpControllerToPage(int pageIndex) {
    if (!_pageController.hasClients || _segments.isEmpty) {
      return;
    }

    _pageController.jumpToPage(_clampPageIndex(pageIndex));
  }

  void _setFontSize(double value) {
    setState(() {
      _fontSize = value.clamp(15, 26).toDouble();
    });
  }

  void _setLineHeight(double value) {
    setState(() {
      _lineHeight = value.clamp(1.45, 2.2).toDouble();
    });
  }

  void _toggleChrome() {
    setState(() {
      _chromeVisible = !_chromeVisible;
    });
  }

  void _closeReader() {
    Navigator.of(context).maybePop();
  }

  KeyEventResult _handleShortcutKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (_previousPageKeys.contains(key)) {
      _goToPage(_currentPageIndex - 1);
      return KeyEventResult.handled;
    } else if (_nextPageKeys.contains(key)) {
      _goToPage(_currentPageIndex + 1);
      return KeyEventResult.handled;
    } else if (_scrollUpKeys.contains(key)) {
      _scrollCurrentPage(-_keyboardScrollExtent);
      return KeyEventResult.handled;
    } else if (_scrollDownKeys.contains(key)) {
      _scrollCurrentPage(_keyboardScrollExtent);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  ScrollController _scrollControllerForSegment(int index) {
    return _segmentScrollControllers.putIfAbsent(index, ScrollController.new);
  }

  void _scrollCurrentPage(double delta) {
    final controller = _segmentScrollControllers[_currentPageIndex];
    if (controller == null || !controller.hasClients) {
      return;
    }

    final position = controller.position;
    final target = (position.pixels + delta).clamp(position.minScrollExtent, position.maxScrollExtent).toDouble();
    controller.animateTo(target, duration: const Duration(milliseconds: 160), curve: Curves.easeOutCubic);
  }

  void _disposeSegmentScrollControllers() {
    for (final controller in _segmentScrollControllers.values) {
      controller.dispose();
    }
    _segmentScrollControllers.clear();
  }

  void _showSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: _ReaderPalette.resolve(context).surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final palette = _ReaderPalette.resolve(context);

            void updateSheet(VoidCallback action) {
              action();
              modalSetState(() {});
            }

            return _ReaderSheetSurface(
              palette: palette,
              title: t.novel.reader.settings,
              child: _ReaderSettingsPanel(
                fontSize: _fontSize,
                lineHeight: _lineHeight,
                palette: palette,
                onFontSizeChanged: (value) => updateSheet(() => _setFontSize(value)),
                onLineHeightChanged: (value) => updateSheet(() => _setLineHeight(value)),
              ),
            );
          },
        );
      },
    );
  }
}

class _DesktopNovelReaderLayout extends StatelessWidget {
  const _DesktopNovelReaderLayout({
    required this.novel,
    required this.segments,
    required this.totalTextCharacters,
    required this.pageController,
    required this.pageIndex,
    required this.fontSize,
    required this.lineHeight,
    required this.palette,
    required this.scrollControllerForSegment,
    required this.shortcutsEnabled,
    required this.chromeVisible,
    required this.onBack,
    required this.onToggleChrome,
    required this.onPageChanged,
    required this.onPageRequested,
    required this.onProgressChanged,
    required this.onShowSettings,
  });

  final Novel novel;
  final List<NovelTextSegment> segments;
  final int totalTextCharacters;
  final PageController pageController;
  final int pageIndex;
  final double fontSize;
  final double lineHeight;
  final _ReaderPalette palette;
  final ScrollController Function(int index) scrollControllerForSegment;
  final bool shortcutsEnabled;
  final bool chromeVisible;
  final VoidCallback onBack;
  final VoidCallback onToggleChrome;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageRequested;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onShowSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _ReaderStage(
                segments: segments,
                pageController: pageController,
                pageIndex: pageIndex,
                pageCount: segments.length,
                fontSize: fontSize,
                lineHeight: lineHeight,
                palette: palette,
                scrollControllerForSegment: scrollControllerForSegment,
                desktop: true,
                onTap: onToggleChrome,
                onPageChanged: onPageChanged,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: _ReaderChromeVisibility(
                visible: chromeVisible,
                slideOffset: const Offset(0, -0.08),
                child: _ReaderTopChrome(novel: novel, palette: palette, compact: false, onBack: onBack, onShowSettings: onShowSettings),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _ReaderChromeVisibility(
                visible: chromeVisible,
                slideOffset: const Offset(0, 0.08),
                child: _ReaderBottomChrome(
                  segments: segments,
                  totalTextCharacters: totalTextCharacters,
                  pageIndex: pageIndex,
                  palette: palette,
                  compact: false,
                  shortcutsEnabled: shortcutsEnabled,
                  onPageRequested: onPageRequested,
                  onProgressChanged: onProgressChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNovelReaderLayout extends StatelessWidget {
  const _MobileNovelReaderLayout({
    required this.novel,
    required this.segments,
    required this.totalTextCharacters,
    required this.pageController,
    required this.pageIndex,
    required this.fontSize,
    required this.lineHeight,
    required this.palette,
    required this.scrollControllerForSegment,
    required this.shortcutsEnabled,
    required this.chromeVisible,
    required this.onBack,
    required this.onToggleChrome,
    required this.onPageChanged,
    required this.onPageRequested,
    required this.onProgressChanged,
    required this.onShowSettings,
  });

  final Novel novel;
  final List<NovelTextSegment> segments;
  final int totalTextCharacters;
  final PageController pageController;
  final int pageIndex;
  final double fontSize;
  final double lineHeight;
  final _ReaderPalette palette;
  final ScrollController Function(int index) scrollControllerForSegment;
  final bool shortcutsEnabled;
  final bool chromeVisible;
  final VoidCallback onBack;
  final VoidCallback onToggleChrome;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageRequested;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onShowSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _ReaderStage(
                segments: segments,
                pageController: pageController,
                pageIndex: pageIndex,
                pageCount: segments.length,
                fontSize: fontSize,
                lineHeight: lineHeight,
                palette: palette,
                scrollControllerForSegment: scrollControllerForSegment,
                desktop: false,
                onTap: onToggleChrome,
                onPageChanged: onPageChanged,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: _ReaderChromeVisibility(
                visible: chromeVisible,
                slideOffset: const Offset(0, -0.08),
                child: _ReaderTopChrome(novel: novel, palette: palette, compact: true, onBack: onBack, onShowSettings: onShowSettings),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _ReaderChromeVisibility(
                visible: chromeVisible,
                slideOffset: const Offset(0, 0.08),
                child: _ReaderBottomChrome(
                  segments: segments,
                  totalTextCharacters: totalTextCharacters,
                  pageIndex: pageIndex,
                  palette: palette,
                  compact: true,
                  shortcutsEnabled: shortcutsEnabled,
                  onPageRequested: onPageRequested,
                  onProgressChanged: onProgressChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderStage extends StatelessWidget {
  const _ReaderStage({
    required this.segments,
    required this.pageController,
    required this.pageIndex,
    required this.pageCount,
    required this.fontSize,
    required this.lineHeight,
    required this.palette,
    required this.scrollControllerForSegment,
    required this.desktop,
    required this.onTap,
    required this.onPageChanged,
  });

  final List<NovelTextSegment> segments;
  final PageController pageController;
  final int pageIndex;
  final int pageCount;
  final double fontSize;
  final double lineHeight;
  final _ReaderPalette palette;
  final ScrollController Function(int index) scrollControllerForSegment;
  final bool desktop;
  final VoidCallback? onTap;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return _ReaderTapListener(
        onTap: onTap,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CompactMessage(icon: Icons.menu_book_outlined, message: t.novel.reader.emptyBody),
            ),
          ),
        ),
      );
    }

    return _ReaderTapListener(
      onTap: onTap,
      child: PageView.builder(
        controller: pageController,
        itemCount: segments.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          return _ReaderSegmentView(
            segment: segments[index],
            pageCount: pageCount,
            fontSize: fontSize,
            lineHeight: lineHeight,
            palette: palette,
            scrollController: scrollControllerForSegment(index),
            desktop: desktop,
          );
        },
      ),
    );
  }
}

class _ReaderTapListener extends StatefulWidget {
  const _ReaderTapListener({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_ReaderTapListener> createState() => _ReaderTapListenerState();
}

class _ReaderTapListenerState extends State<_ReaderTapListener> {
  int? _pointer;
  Offset? _downPosition;
  Duration? _downTime;
  bool _moved = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerCancel: _resetPointer,
      onPointerUp: _handlePointerUp,
      child: widget.child,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointer != null) {
      return;
    }

    _pointer = event.pointer;
    _downPosition = event.position;
    _downTime = event.timeStamp;
    _moved = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) {
      return;
    }

    final downPosition = _downPosition;
    if (downPosition == null) {
      return;
    }

    if ((event.position - downPosition).distance > _readerTapSlop) {
      _moved = true;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) {
      return;
    }

    final downPosition = _downPosition;
    final downTime = _downTime;
    final distance = downPosition == null ? double.infinity : (event.position - downPosition).distance;
    final elapsed = downTime == null ? Duration.zero : event.timeStamp - downTime;
    final isTap = !_moved && distance <= _readerTapSlop && elapsed <= _readerTapMaxDuration;

    _resetPointer(event);

    if (isTap) {
      widget.onTap?.call();
    }
  }

  void _resetPointer(PointerEvent event) {
    if (event.pointer != _pointer) {
      return;
    }

    _pointer = null;
    _downPosition = null;
    _downTime = null;
    _moved = false;
  }
}

class _ReaderSegmentView extends StatelessWidget {
  const _ReaderSegmentView({
    required this.segment,
    required this.pageCount,
    required this.fontSize,
    required this.lineHeight,
    required this.palette,
    required this.scrollController,
    required this.desktop,
  });

  final NovelTextSegment segment;
  final int pageCount;
  final double fontSize;
  final double lineHeight;
  final _ReaderPalette palette;
  final ScrollController scrollController;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final paragraphStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: palette.onBackground, fontSize: fontSize, height: lineHeight, letterSpacing: 0);
    final chapterStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(color: palette.onBackground, fontSize: fontSize + 4, fontWeight: FontWeight.w800, height: 1.35, letterSpacing: 0);

    return ColoredBox(
      color: palette.background,
      child: Scrollbar(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(desktop ? 36 : 22, desktop ? 56 : 30, desktop ? 36 : 22, desktop ? 88 : 68),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: desktop ? 680 : 620),
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final block in segment.blocks)
                      NovelReaderBlockView(block: block, paragraphStyle: paragraphStyle, chapterStyle: chapterStyle, dividerColor: palette.line),
                    const SizedBox(height: 18),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        t.novel.reader.pagePosition(current: segment.index + 1, total: pageCount),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: palette.muted, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderTopChrome extends StatelessWidget {
  const _ReaderTopChrome({required this.novel, required this.palette, required this.compact, required this.onBack, required this.onShowSettings});

  final Novel novel;
  final _ReaderPalette palette;
  final bool compact;
  final VoidCallback onBack;
  final VoidCallback onShowSettings;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.94),
        borderRadius: compact ? BorderRadius.zero : BorderRadius.circular(8),
        border: Border.all(color: palette.line.withValues(alpha: compact ? 1 : 0.72)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 8 : 10, compact ? 6 : 8, compact ? 8 : 10, compact ? 6 : 8),
        child: Row(
          children: [
            _ReaderQuietIconButton(icon: Icons.arrow_back, tooltip: t.common.back, enabled: true, palette: palette, onPressed: onBack),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: compact ? TextAlign.center : TextAlign.start,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w700),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      novel.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: palette.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ReaderQuietIconButton(icon: Icons.tune, tooltip: t.novel.reader.settings, enabled: true, palette: palette, onPressed: onShowSettings),
          ],
        ),
      ),
    );

    if (compact) {
      return SizedBox(width: double.infinity, child: content);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: content),
    );
  }
}

class _ReaderChromeVisibility extends StatelessWidget {
  const _ReaderChromeVisibility({required this.visible, required this.slideOffset, required this.child});

  final bool visible;
  final Offset slideOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : slideOffset,
        child: AnimatedOpacity(duration: const Duration(milliseconds: 160), curve: Curves.easeOutCubic, opacity: visible ? 1 : 0, child: child),
      ),
    );
  }
}

class _ReaderBottomChrome extends StatelessWidget {
  const _ReaderBottomChrome({
    required this.segments,
    required this.totalTextCharacters,
    required this.pageIndex,
    required this.palette,
    required this.compact,
    required this.shortcutsEnabled,
    required this.onPageRequested,
    required this.onProgressChanged,
  });

  final List<NovelTextSegment> segments;
  final int totalTextCharacters;
  final int pageIndex;
  final _ReaderPalette palette;
  final bool compact;
  final bool shortcutsEnabled;
  final ValueChanged<int> onPageRequested;
  final ValueChanged<double> onProgressChanged;

  @override
  Widget build(BuildContext context) {
    final pageCount = segments.length;
    final percent = _readPercent(segments: segments, totalTextCharacters: totalTextCharacters, pageIndex: pageIndex);
    final currentPageLabel = pageCount == 0 ? '0' : '${pageIndex + 1}';
    final progressLabel = '$currentPageLabel / ${math.max(pageCount, 1)} · $percent%';

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.94),
        borderRadius: compact ? BorderRadius.zero : BorderRadius.circular(8),
        border: Border.all(color: palette.line.withValues(alpha: compact ? 1 : 0.72)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, -8))],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 14 : 16, compact ? 8 : 12, compact ? 14 : 16, compact ? 10 : 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _ReaderQuietIconButton(
                  icon: Icons.chevron_left,
                  tooltip: t.novel.reader.previousPage,
                  enabled: pageIndex > 0,
                  palette: palette,
                  onPressed: () => onPageRequested(pageIndex - 1),
                ),
                Expanded(
                  child: Text(
                    progressLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w700),
                  ),
                ),
                _ReaderQuietIconButton(
                  icon: Icons.chevron_right,
                  tooltip: t.novel.reader.nextPage,
                  enabled: pageIndex < pageCount - 1,
                  palette: palette,
                  onPressed: () => onPageRequested(pageIndex + 1),
                ),
              ],
            ),
            _ReaderProgressSlider(pageIndex: pageIndex, pageCount: pageCount, palette: palette, onProgressChanged: onProgressChanged),
            if (!compact && shortcutsEnabled) ...[
              const SizedBox(height: 2),
              Text(
                t.novel.reader.shortcutsHelp,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.muted, height: 1.3),
              ),
            ],
          ],
        ),
      ),
    );

    if (compact) {
      return SizedBox(width: double.infinity, child: content);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: content),
    );
  }
}

class _ReaderQuietIconButton extends StatelessWidget {
  const _ReaderQuietIconButton({required this.icon, required this.tooltip, required this.enabled, required this.palette, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final _ReaderPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? palette.onBackground : palette.muted.withValues(alpha: 0.38);

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 21),
        color: color,
        disabledColor: color,
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          fixedSize: const Size(38, 38),
          minimumSize: const Size(38, 38),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _ReaderProgressSlider extends StatelessWidget {
  const _ReaderProgressSlider({required this.pageIndex, required this.pageCount, required this.palette, required this.onProgressChanged});

  final int pageIndex;
  final int pageCount;
  final _ReaderPalette palette;
  final ValueChanged<double> onProgressChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = pageCount > 1;
    final max = math.max(1, pageCount - 1).toDouble();
    final value = enabled ? pageIndex.clamp(0, pageCount - 1).toDouble() : 0.0;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: palette.accent,
        inactiveTrackColor: palette.line,
        thumbColor: palette.accent,
        overlayColor: palette.accent.withValues(alpha: 0.16),
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 1.2),
        activeTickMarkColor: palette.surface,
        inactiveTickMarkColor: palette.muted.withValues(alpha: 0.42),
      ),
      child: Slider(
        min: 0,
        max: max,
        divisions: enabled ? pageCount - 1 : null,
        value: value,
        label: t.novel.reader.currentPage(page: pageIndex + 1),
        onChanged: enabled ? onProgressChanged : null,
      ),
    );
  }
}

class _ReaderSettingsPanel extends StatelessWidget {
  const _ReaderSettingsPanel({
    required this.fontSize,
    required this.lineHeight,
    required this.palette,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
  });

  final double fontSize;
  final double lineHeight;
  final _ReaderPalette palette;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.novel.reader.display,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _ReaderStepper(
          icon: Icons.text_fields,
          label: t.novel.reader.fontSize,
          value: fontSize.round().toString(),
          palette: palette,
          onDecrease: () => onFontSizeChanged(fontSize - 1),
          onIncrease: () => onFontSizeChanged(fontSize + 1),
        ),
        const SizedBox(height: 8),
        _ReaderStepper(
          icon: Icons.format_line_spacing,
          label: t.novel.reader.lineHeight,
          value: lineHeight.toStringAsFixed(2),
          palette: palette,
          onDecrease: () => onLineHeightChanged(lineHeight - 0.08),
          onIncrease: () => onLineHeightChanged(lineHeight + 0.08),
        ),
      ],
    );
  }
}

class _ReaderStepper extends StatelessWidget {
  const _ReaderStepper({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
    required this.onDecrease,
    required this.onIncrease,
  });

  final IconData icon;
  final String label;
  final String value;
  final _ReaderPalette palette;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: palette.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.onBackground)),
            ),
            IconButton(icon: const Icon(Icons.remove), tooltip: t.novel.reader.decrease, color: palette.onBackground, onPressed: onDecrease),
            SizedBox(
              width: 44,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(icon: const Icon(Icons.add), tooltip: t.novel.reader.increase, color: palette.onBackground, onPressed: onIncrease),
          ],
        ),
      ),
    );
  }
}

class _ReaderSheetSurface extends StatelessWidget {
  const _ReaderSheetSurface({required this.palette, required this.title, required this.child});

  final _ReaderPalette palette;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: math.min(MediaQuery.sizeOf(context).height * 0.78, 560),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: t.novel.reader.close,
                  color: palette.onBackground,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _ReaderLoadingPage extends StatelessWidget {
  const _ReaderLoadingPage();

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (context, layout, orientation, shouldUseDesktopShell) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class _ReaderPalette {
  const _ReaderPalette({
    required this.background,
    required this.surface,
    required this.onBackground,
    required this.muted,
    required this.line,
    required this.accent,
  });

  final Color background;
  final Color surface;
  final Color onBackground;
  final Color muted;
  final Color line;
  final Color accent;

  static _ReaderPalette resolve(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return _ReaderPalette(
      background: tokens.surface,
      surface: tokens.surfaceRaised,
      onBackground: colorScheme.onSurface,
      muted: colorScheme.onSurfaceVariant,
      line: tokens.line,
      accent: tokens.brand,
    );
  }
}

int _readPercent({required List<NovelTextSegment> segments, required int totalTextCharacters, required int pageIndex}) {
  if (segments.isEmpty || totalTextCharacters <= 0) {
    return 0;
  }

  final clampedIndex = pageIndex.clamp(0, segments.length - 1);
  final endOffset = segments[clampedIndex].endOffset;
  return ((endOffset / totalTextCharacters) * 100).clamp(0, 100).round();
}

final _previousPageKeys = {LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA};

final _nextPageKeys = {LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD};

final _scrollUpKeys = {LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW};

final _scrollDownKeys = {LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS};

const _keyboardScrollExtent = 320.0;

const _readerTapSlop = 12.0;

const _readerTapMaxDuration = Duration(milliseconds: 700);

bool _isNotFoundError(Object error) {
  return error is PixivError && error.status == 404;
}
