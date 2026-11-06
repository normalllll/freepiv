import 'package:freepiv/features/novel/presentation/novel_download_source.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:freepiv/core/platform/reader_volume_keys.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_scroll_clock.dart';
import 'dart:math' as math;
import 'package:skeletonizer/skeletonizer.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:freepiv/features/novel/domain/novel_text_parser.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_not_found_page.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_reader_slivers.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reading_session.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

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
      skipLoadingOnRefresh: false,
      data: (detail) => DownloadSourceScope(
        source: novelDownloadSource(detail.novel),
        child: NovelReaderContent(key: ValueKey<String>('novel-reader-content-${detail.novel.id}'), detail: detail),
      ),
      loading: () => const _ReaderLoadingPage(),
      error: (error, stackTrace) {
        if (_isNotFoundError(error)) {
          return const NovelNotFoundPage();
        }

        return PivErrorPage.fromError(error: error, onRetry: () => ref.read(provider.notifier).reload());
      },
    );
  }
}

class NovelReaderContent extends StatefulWidget {
  const NovelReaderContent({required this.detail, this.volumeKeys, super.key});

  final NovelDetailData detail;
  final ReaderVolumeKeys? volumeKeys;

  @override
  State<NovelReaderContent> createState() => _NovelReaderContentState();
}

class _NovelReaderContentState extends State<NovelReaderContent> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final PageController _pageController;
  final FocusNode _shortcutFocusNode = FocusNode(debugLabel: 'novel-reader-shortcuts');
  final Map<int, ScrollController> _segmentScrollControllers = {};
  final Map<int, List<GlobalKey>> _blockKeys = {};

  late List<NovelTextSegment> _segments;
  late int _totalTextCharacters;

  int _pageIndex = 0;
  late double _fontSize;
  late double _lineHeight;
  bool _chromeVisible = true;
  NovelReadingPosition? _pendingRestore;
  late final ReaderVolumeKeyLease _volumeLease;
  late final ReaderSettingsNotifier _readerSettings;
  late final Ticker _autoTicker;
  final _scrollClock = ReaderScrollClock();
  late bool _volumeEnabled;
  bool _windowFocused = true;
  bool _foreground = true;
  bool _settingsOpen = false;
  bool _selectionActive = false;
  bool _accountChanged = false;
  late final String? _sessionAccountId;
  bool _autoScrolling = false;
  bool _advancingSegment = false;
  late double _scrollSpeed;
  double _endTravel = 0;

  bool get _controlsEligible =>
      mounted && _foreground && _windowFocused && !_accountChanged && !_settingsOpen && !_selectionActive && ModalRoute.of(context)?.isCurrent == true;

  Novel get _novel => widget.detail.novel;

  WebviewNovel get _webviewNovel => widget.detail.webviewNovel;

  int get _currentPageIndex => _clampPageIndex(_pageIndex);

  @override
  void initState() {
    super.initState();
    _readerSettings = ProviderScope.containerOf(context, listen: false).read(readerSettingsProvider.notifier);
    final saved = ProviderScope.containerOf(context, listen: false).read(readerSettingsProvider);
    _fontSize = saved.fontSize;
    _lineHeight = saved.lineHeight;
    _scrollSpeed = saved.autoScrollSpeed;
    _volumeEnabled = saved.volumeKeys;
    WidgetsBinding.instance.addObserver(this);
    _sessionAccountId = pixivAccountNotifier.value?.user.id;
    _foreground = WidgetsBinding.instance.lifecycleState == null || WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _autoTicker = createTicker(_tickAutoScroll);
    _volumeLease = (widget.volumeKeys ?? ReaderVolumeKeys.instance).claim(
      onTurn: _turnReadingScreen,
      onError: () {
        if (mounted) setState(() => _volumeEnabled = false);
      },
      onFocusChanged: (focused) {
        _windowFocused = focused;
        _handleRouteActivity();
      },
    );
    pixivAccountNotifier.addListener(_handleAccountChange);
    _rebuildReaderModel();
    _restoreSession();
    _pageController = PageController(initialPage: _pageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _shortcutFocusNode.requestFocus();
        _restoreScrollPosition();
      }
    });
  }

  @override
  void didUpdateWidget(covariant NovelReaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.novel.id != widget.detail.novel.id || oldWidget.detail.webviewNovel.text != widget.detail.webviewNovel.text) {
      _pauseAutomaticScroll();
      _saveSession(novelId: oldWidget.detail.novel.id);
      _disposeSegmentScrollControllers();
      _blockKeys.clear();
      _rebuildReaderModel();
      _restoreSession();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jumpControllerToPage(_pageIndex);
        _restoreScrollPosition();
      });
    }
  }

  @override
  void dispose() {
    _saveSession();
    _autoTicker.dispose();
    _volumeLease.release();
    pixivAccountNotifier.removeListener(_handleAccountChange);
    WidgetsBinding.instance.removeObserver(this);
    _disposeSegmentScrollControllers();
    _shortcutFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ReaderPalette.resolve(context);

    // Subscribe to the local route's current state, including a covering page.
    ModalRoute.isCurrentOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleRouteActivity();
    });
    return FrostAutoScaffold(
      builder: (context, layout, orientation, useHorizontalLayout) => Focus(
        focusNode: _shortcutFocusNode,
        autofocus: true,
        onKeyEvent: _handleShortcutKeyEvent,
        child: _NovelReaderLayout(
          novel: _novel,
          segments: _segments,
          totalTextCharacters: _totalTextCharacters,
          pageController: _pageController,
          pageIndex: _currentPageIndex,
          fontSize: _fontSize,
          lineHeight: _lineHeight,
          palette: palette,
          scrollControllerForSegment: _scrollControllerForSegment,
          blockKeysForSegment: _blockKeysForSegment,
          desktop: useHorizontalLayout,
          chromeVisible: _chromeVisible,
          autoScrolling: _autoScrolling,
          onAutomaticScroll: _toggleAutomaticScroll,
          onBack: _closeReader,
          onToggleChrome: _toggleChrome,
          canToggleChrome: () => _controlsEligible,
          onUserInteraction: _pauseAutomaticScroll,
          onUserScroll: _handleUserScroll,
          onSelectionChanged: _handleSelectionChanged,
          onPageChanged: _handlePageChanged,
          onPageRequested: _goToPage,
          onProgressChanged: _jumpToProgress,
          onShowSettings: _showSettingsSheet,
        ),
      ),
    );
  }

  void _handleAccountChange() {
    _accountChanged = true;
    _handleRouteActivity();
  }

  void _handleRouteActivity() {
    if (!mounted) return;
    _volumeLease.setEnabled(_volumeEnabled && _controlsEligible);
    if (!_controlsEligible && _autoScrolling) {
      _pauseAutomaticScroll(rebuild: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _handleRouteActivity();
  }

  void _handleSelectionChanged(SelectedContent? content) {
    _selectionActive = content != null && content.plainText.isNotEmpty;
    if (_selectionActive) _pauseAutomaticScroll();
    _handleRouteActivity();
  }

  void _handleUserScroll() {
    _pauseAutomaticScroll();
    if (_chromeVisible) setState(() => _chromeVisible = false);
  }

  void _pauseAutomaticScroll({bool rebuild = true}) {
    _autoTicker.stop();
    _scrollClock.reset();
    _endTravel = 0;
    if (!_autoScrolling) return;
    _autoScrolling = false;
    if (rebuild && mounted) setState(() {});
  }

  void _toggleAutomaticScroll() {
    if (_autoScrolling) {
      _pauseAutomaticScroll();
    } else if (_controlsEligible && _segments.isNotEmpty) {
      _scrollClock.reset();
      _endTravel = 0;
      setState(() => _autoScrolling = true);
      _autoTicker.start();
    }
  }

  void _tickAutoScroll(Duration elapsed) {
    if (!_controlsEligible || _segments.isEmpty) {
      _pauseAutomaticScroll();
      return;
    }
    if (_advancingSegment || _pendingRestore != null) {
      _scrollClock.reset();
      return;
    }
    final controller = _segmentScrollControllers[_currentPageIndex];
    if (controller == null || !controller.hasClients || !controller.position.hasContentDimensions) {
      _scrollClock.reset();
      return;
    }
    final position = controller.position;
    final distance = _scrollClock.advance(elapsed, _scrollSpeed);
    if (position.pixels < position.maxScrollExtent - 0.5) {
      _endTravel = 0;
      controller.jumpTo(math.min(position.maxScrollExtent, position.pixels + distance));
      return;
    }
    if (_currentPageIndex == _segments.length - 1) {
      _pauseAutomaticScroll();
      return;
    }
    // A short, already fully visible section needs reading time. Scrollable
    // sections continue immediately when their bottom is reached.
    if (position.maxScrollExtent <= position.minScrollExtent) {
      _endTravel += distance;
      if (_endTravel < position.viewportDimension) return;
    }
    _endTravel = 0;
    _advancingSegment = true;
    _scrollClock.reset();
    final next = _currentPageIndex + 1;
    _saveSession();
    setState(() => _pageIndex = next);
    _jumpControllerToPage(next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nextController = _segmentScrollControllers[next];
      if (nextController != null && nextController.hasClients) nextController.jumpTo(nextController.position.minScrollExtent);
      _advancingSegment = false;
    });
  }

  void _turnReadingScreen(int direction) {
    if (!_volumeEnabled || !_controlsEligible) return;
    _pauseAutomaticScroll();
    final controller = _segmentScrollControllers[_currentPageIndex];
    if (controller == null || !controller.hasClients) return;
    final position = controller.position;
    final canScroll = direction > 0 ? position.pixels < position.maxScrollExtent - 1 : position.pixels > position.minScrollExtent + 1;
    if (canScroll) {
      // Leave context at the screen edge; chrome is an overlay, not a viewport.
      _scrollCurrentPage(direction * math.max(1, position.viewportDimension - 120));
    } else {
      final next = _clampPageIndex(_currentPageIndex + direction);
      if (next == _currentPageIndex) return;
      _goToPage(next);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final nextController = _segmentScrollControllers[next];
        if (nextController != null && nextController.hasClients) {
          nextController.jumpTo(direction > 0 ? nextController.position.minScrollExtent : nextController.position.maxScrollExtent);
        }
      });
    }
  }

  void _rebuildReaderModel() {
    final blocks = parseNovelText(_webviewNovel.text, imageUrls: novelEmbeddedImageUrls(_webviewNovel));
    _segments = segmentNovelTextBlocks(blocks);
    _totalTextCharacters = _segments.isEmpty ? 0 : _segments.last.endOffset;
    _pageIndex = _clampPageIndex(_pageIndex);
  }

  void _restoreSession() {
    _pageIndex = 0;
    _pendingRestore = null;
    final saved = novelReadingPosition(context, _novel.id);
    if (saved == null) return;
    _pendingRestore = saved;
    _fontSize = saved.fontSize.clamp(15, 26).toDouble();
    _lineHeight = saved.lineHeight.clamp(1.45, 2.2).toDouble();
    final matchingIndex = _segments.indexWhere((segment) => segment.endOffset > saved.textOffset);
    final segmentAtSavedIndex = saved.segmentIndex >= 0 && saved.segmentIndex < _segments.length ? _segments[saved.segmentIndex] : null;
    final index = segmentAtSavedIndex != null && segmentAtSavedIndex.startOffset <= saved.textOffset && segmentAtSavedIndex.endOffset >= saved.textOffset
        ? saved.segmentIndex
        : matchingIndex;
    _pageIndex = _clampPageIndex(index < 0 ? _segments.length - 1 : index);
  }

  double _currentScrollFraction() {
    final controller = _segmentScrollControllers[_currentPageIndex];
    if (controller == null || !controller.hasClients || controller.position.maxScrollExtent <= 0) return 0;
    return (controller.offset / controller.position.maxScrollExtent).clamp(0, 1).toDouble();
  }

  void _saveSession({int? novelId}) {
    if (_segments.isEmpty) return;
    final segment = _segments[_currentPageIndex];
    final anchor = _pendingRestore ?? _currentReadingPosition();
    novelReadingSessions.writeState(
      context,
      NovelReadingPosition(
        segmentIndex: _currentPageIndex,
        textOffset: anchor.textOffset.clamp(segment.startOffset, segment.endOffset),
        segmentFraction: anchor.segmentFraction,
        blockIndex: anchor.blockIndex,
        blockFraction: anchor.blockFraction,
        fontSize: _fontSize,
        lineHeight: _lineHeight,
      ),
      identifier: novelReadingSessionKey(novelId ?? _novel.id, accountId: _sessionAccountId),
    );
  }

  void _restoreScrollPosition() {
    final saved = _pendingRestore;
    if (saved == null) return;
    final controller = _segmentScrollControllers[_currentPageIndex];
    if (controller == null || !controller.hasClients) return;
    final segment = _segments[_currentPageIndex];
    final blockIndex = saved.segmentIndex == _currentPageIndex
        ? saved.blockIndex.clamp(0, segment.blocks.length - 1)
        : _blockIndexAtTextOffset(segment, saved.textOffset);
    final blockOffset = _blockScrollOffset(_currentPageIndex, blockIndex);
    final blockExtent = _blockExtent(_currentPageIndex, blockIndex);
    final target = blockOffset == null || blockExtent == null
        ? controller.position.maxScrollExtent * saved.segmentFraction.clamp(0, 1)
        : blockOffset + blockExtent * saved.blockFraction.clamp(0, 1);
    controller.jumpTo(target.clamp(controller.position.minScrollExtent, controller.position.maxScrollExtent));
    _pendingRestore = null;
  }

  void _rememberCurrentPosition() {
    if (_pendingRestore != null || _segments.isEmpty) return;
    _pendingRestore = _currentReadingPosition();
  }

  NovelReadingPosition _currentReadingPosition() {
    final segment = _segments[_currentPageIndex];
    final controller = _segmentScrollControllers[_currentPageIndex];
    final scrollOffset = controller != null && controller.hasClients ? controller.offset : 0.0;
    var blockIndex = 0;
    var blockOffset = 0.0;
    for (var index = 0; index < segment.blocks.length; index++) {
      final offset = _blockScrollOffset(_currentPageIndex, index);
      if (offset == null || offset > scrollOffset + 1) break;
      blockIndex = index;
      blockOffset = offset;
    }
    final blockExtent = _blockExtent(_currentPageIndex, blockIndex);
    final blockFraction = blockExtent == null || blockExtent <= 0 ? 0.0 : ((scrollOffset - blockOffset) / blockExtent).clamp(0, 1).toDouble();
    var textOffset = segment.startOffset;
    for (var index = 0; index < blockIndex; index++) {
      textOffset += novelTextBlockCharacterCount(segment.blocks[index]);
    }
    textOffset += (novelTextBlockCharacterCount(segment.blocks[blockIndex]) * blockFraction).round();
    return NovelReadingPosition(
      segmentIndex: _currentPageIndex,
      textOffset: textOffset,
      segmentFraction: _currentScrollFraction(),
      blockIndex: blockIndex,
      blockFraction: blockFraction,
      fontSize: _fontSize,
      lineHeight: _lineHeight,
    );
  }

  int _blockIndexAtTextOffset(NovelTextSegment segment, int textOffset) {
    var cursor = segment.startOffset;
    for (var index = 0; index < segment.blocks.length; index++) {
      cursor += novelTextBlockCharacterCount(segment.blocks[index]);
      if (cursor > textOffset) return index;
    }
    return segment.blocks.length - 1;
  }

  List<GlobalKey> _blockKeysForSegment(int index) =>
      _blockKeys.putIfAbsent(index, () => List<GlobalKey>.generate(_segments[index].blocks.length, (_) => GlobalKey()));

  double? _blockScrollOffset(int segmentIndex, int blockIndex) {
    final keys = _blockKeys[segmentIndex];
    if (keys == null || blockIndex < 0 || blockIndex >= keys.length) return null;
    final renderObject = keys[blockIndex].currentContext?.findRenderObject();
    if (renderObject == null || !renderObject.attached) return null;
    return RenderAbstractViewport.of(renderObject).getOffsetToReveal(renderObject, 0).offset;
  }

  double? _blockExtent(int segmentIndex, int blockIndex) {
    final keys = _blockKeys[segmentIndex];
    if (keys == null || blockIndex < 0 || blockIndex >= keys.length) return null;
    final renderObject = keys[blockIndex].currentContext?.findRenderObject();
    return renderObject is RenderBox && renderObject.hasSize ? renderObject.size.height : null;
  }

  @override
  void didChangeMetrics() {
    if (!mounted || _segments.isEmpty) return;
    _pauseAutomaticScroll();
    _rememberCurrentPosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreScrollPosition();
    });
  }

  void _reflowAtCurrentPosition(VoidCallback change) {
    _pauseAutomaticScroll();
    _rememberCurrentPosition();
    setState(change);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreScrollPosition();
    });
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
    _saveSession();
  }

  void _goToPage(int pageIndex) {
    _pauseAutomaticScroll();
    final nextPage = _clampPageIndex(pageIndex);
    _saveSession();
    setState(() {
      _pageIndex = nextPage;
    });
    _saveSession();

    if (_pageController.hasClients) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _pageController.jumpToPage(nextPage);
      } else {
        _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpControllerToPage(nextPage));
    }
  }

  void _jumpToProgress(double value) {
    _pauseAutomaticScroll();
    final nextPage = _clampPageIndex(value.round());
    setState(() {
      _pageIndex = nextPage;
    });
    _saveSession();
    _jumpControllerToPage(nextPage);
  }

  void _jumpControllerToPage(int pageIndex) {
    if (!_pageController.hasClients || _segments.isEmpty) {
      return;
    }

    _pageController.jumpToPage(_clampPageIndex(pageIndex));
  }

  void _setFontSize(double value) {
    _reflowAtCurrentPosition(() {
      _fontSize = value.clamp(15, 26).toDouble();
    });
    _readerSettings.setFontSize(_fontSize);
  }

  void _setLineHeight(double value) {
    _reflowAtCurrentPosition(() {
      _lineHeight = value.clamp(1.45, 2.2).toDouble();
    });
    _readerSettings.setLineHeight(_lineHeight);
  }

  void _toggleChrome() {
    if (_selectionActive) return;
    _shortcutFocusNode.requestFocus();
    setState(() {
      _chromeVisible = !_chromeVisible;
    });
  }

  void _closeReader() {
    _pauseAutomaticScroll();
    if (ModalRoute.of(context)?.isCurrent == true && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  KeyEventResult _handleShortcutKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (ModalRoute.of(context)?.isCurrent != true || _settingsOpen) return KeyEventResult.ignored;
      if (_selectionActive) {
        final selection = _blockKeys[_currentPageIndex]?.firstOrNull?.currentContext?.findAncestorStateOfType<SelectionAreaState>()?.selectableRegion;
        selection?.hideToolbar();
        selection?.clearSelection();
        return KeyEventResult.handled;
      }
      _closeReader();
      return KeyEventResult.handled;
    }

    if (FocusManager.instance.primaryFocus != _shortcutFocusNode) return KeyEventResult.ignored;

    if (FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
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
    return _segmentScrollControllers.putIfAbsent(index, () {
      final controller = ScrollController();
      controller.addListener(() {
        if (index == _currentPageIndex && _pendingRestore == null) _saveSession();
      });
      return controller;
    });
  }

  void _scrollCurrentPage(double delta) {
    _handleUserScroll();
    final controller = _segmentScrollControllers[_currentPageIndex];
    if (controller == null || !controller.hasClients) {
      return;
    }

    final position = controller.position;
    final target = (position.pixels + delta).clamp(position.minScrollExtent, position.maxScrollExtent).toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.jumpTo(target);
    } else {
      controller.animateTo(target, duration: const Duration(milliseconds: 160), curve: Curves.easeOutCubic);
    }
  }

  void _disposeSegmentScrollControllers() {
    for (final controller in _segmentScrollControllers.values) {
      controller.dispose();
    }
    _segmentScrollControllers.clear();
  }

  Future<void> _showSettingsSheet() async {
    _pauseAutomaticScroll();
    _settingsOpen = true;
    _handleRouteActivity();
    Widget settings(BuildContext context) {
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
              volumeSupported: (widget.volumeKeys ?? ReaderVolumeKeys.instance).supported,
              volumeEnabled: _volumeEnabled,
              onVolumeChanged: (enabled) => updateSheet(() {
                setState(() => _volumeEnabled = enabled);
                _readerSettings.setVolumeKeys(enabled);
                _handleRouteActivity();
              }),
              scrollSpeed: _scrollSpeed,
              onSpeedChanged: (speed) => updateSheet(() {
                setState(() => _scrollSpeed = speed);
                _readerSettings.setAutoScrollSpeed(speed);
              }),
            ),
          );
        },
      );
    }

    if (FrostAutoScaffold.usesHorizontalLayoutOf(context)) {
      await showFrostDialog<void>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: _ReaderPalette.resolve(context).surface,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: settings(context)),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: _ReaderPalette.resolve(context).surface,
        builder: settings,
      );
    }
    if (!mounted) return;
    _settingsOpen = false;
    _handleRouteActivity();
    _shortcutFocusNode.requestFocus();
  }
}

class _NovelReaderLayout extends StatelessWidget {
  const _NovelReaderLayout({
    required this.novel,
    required this.segments,
    required this.totalTextCharacters,
    required this.pageController,
    required this.pageIndex,
    required this.fontSize,
    required this.lineHeight,
    required this.palette,
    required this.scrollControllerForSegment,
    required this.blockKeysForSegment,
    required this.desktop,
    required this.autoScrolling,
    required this.onAutomaticScroll,
    required this.onUserInteraction,
    required this.onUserScroll,
    required this.onSelectionChanged,
    required this.chromeVisible,
    required this.onBack,
    required this.onToggleChrome,
    required this.canToggleChrome,
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
  final List<GlobalKey> Function(int index) blockKeysForSegment;
  final bool desktop;
  final bool autoScrolling;
  final VoidCallback onAutomaticScroll;
  final VoidCallback onUserInteraction;
  final VoidCallback onUserScroll;
  final ValueChanged<SelectedContent?> onSelectionChanged;
  final bool chromeVisible;
  final VoidCallback onBack;
  final VoidCallback onToggleChrome;
  final bool Function() canToggleChrome;
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
          fit: StackFit.expand,
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
                blockKeysForSegment: blockKeysForSegment,
                desktop: desktop,
                onUserInteraction: onUserInteraction,
                onUserScroll: onUserScroll,
                onSelectionChanged: onSelectionChanged,
                onTap: onToggleChrome,
                canToggleChrome: canToggleChrome,
                onPageChanged: onPageChanged,
              ),
            ),

            Align(
              alignment: Alignment.topCenter,
              child: _ReaderChromeVisibility(
                visible: chromeVisible,
                slideOffset: const Offset(0, -0.08),
                child: _ReaderTopChrome(novel: novel, palette: palette, compact: !desktop, onBack: onBack, onShowSettings: onShowSettings),
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
                  compact: !desktop,
                  autoScrolling: autoScrolling,
                  onAutomaticScroll: onAutomaticScroll,
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
    required this.blockKeysForSegment,
    required this.desktop,
    required this.onTap,
    required this.canToggleChrome,
    required this.onPageChanged,
    required this.onUserInteraction,
    required this.onUserScroll,
    required this.onSelectionChanged,
  });

  final List<NovelTextSegment> segments;
  final PageController pageController;
  final int pageIndex;
  final int pageCount;
  final double fontSize;
  final double lineHeight;
  final _ReaderPalette palette;
  final ScrollController Function(int index) scrollControllerForSegment;
  final List<GlobalKey> Function(int index) blockKeysForSegment;
  final bool desktop;
  final VoidCallback? onTap;
  final bool Function() canToggleChrome;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onUserInteraction;
  final VoidCallback onUserScroll;
  final ValueChanged<SelectedContent?> onSelectionChanged;

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
              child: FrostCompactMessage(icon: FrostIconData.glyph(Icons.menu_book_outlined), message: t.novel.reader.emptyBody),
            ),
          ),
        ),
      );
    }

    return Listener(
      onPointerDown: (_) => onUserInteraction(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification && notification.dragDetails != null ||
              notification is UserScrollNotification && notification.direction != ScrollDirection.idle) {
            onUserScroll();
          }
          return false;
        },
        child: _ReaderTapListener(
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
                blockKeys: blockKeysForSegment(index),
                desktop: desktop,
                onSelectionChanged: onSelectionChanged,
                onTap: onTap,
                canToggleChrome: canToggleChrome,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReaderTapListener extends StatelessWidget {
  const _ReaderTapListener({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child);
  }
}

/// Text selection owns its gesture arena. Observe only a completed plain tap
/// and defer until the double-tap window closes, so selecting a word, dragging,
/// long pressing or clearing an existing selection never toggles reader chrome.
class _ReaderTextTapRegion extends StatefulWidget {
  const _ReaderTextTapRegion({required this.onTap, required this.canToggle, required this.child});
  final VoidCallback? onTap;
  final bool Function() canToggle;
  final Widget child;
  @override
  State<_ReaderTextTapRegion> createState() => _ReaderTextTapRegionState();
}

class _ReaderTextTapRegionState extends State<_ReaderTextTapRegion> {
  Timer? _tapTimer;
  PointerDownEvent? _down;

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  void _pointerDown(PointerDownEvent event) {
    _tapTimer?.cancel();
    _down = _down == null && event.buttons == kPrimaryButton && widget.canToggle() ? event : null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _pointerDown,
      onPointerMove: (event) {
        if (_down != null && (event.position - _down!.position).distance > kTouchSlop) _down = null;
      },
      onPointerCancel: (_) => _down = null,
      onPointerUp: (event) {
        final down = _down;
        _down = null;
        if (down == null || down.pointer != event.pointer || event.timeStamp - down.timeStamp >= kLongPressTimeout) return;
        _tapTimer = Timer(kDoubleTapTimeout, () {
          if (mounted && widget.canToggle()) widget.onTap?.call();
        });
      },
      child: widget.child,
    );
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
    required this.blockKeys,
    required this.desktop,
    required this.onSelectionChanged,
    required this.onTap,
    required this.canToggleChrome,
  });

  final NovelTextSegment segment;
  final int pageCount;
  final double fontSize;
  final double lineHeight;
  final _ReaderPalette palette;
  final ScrollController scrollController;
  final List<GlobalKey> blockKeys;
  final bool desktop;
  final ValueChanged<SelectedContent?> onSelectionChanged;
  final VoidCallback? onTap;
  final bool Function() canToggleChrome;

  @override
  Widget build(BuildContext context) {
    // One script decision per segment from its opening paragraphs, so the
    // whole page uses one regional glyph set without scanning every block.
    final sample = segment.blocks.whereType<NovelTextParagraph>().take(12).map((block) => block.text).join();
    final paragraphStyle = frostContentTextStyle(
      context,
      sample,
      Theme.of(context).textTheme.bodyLarge?.copyWith(color: palette.onBackground, fontSize: fontSize, height: lineHeight, letterSpacing: 0),
    );
    final chapterStyle = frostContentTextStyle(
      context,
      sample,
      Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: palette.onBackground, fontSize: fontSize + 4, fontWeight: FontWeight.w700, height: 1.35, letterSpacing: 0),
    );

    return ColoredBox(
      color: palette.background,
      child: Scrollbar(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(0, 80 * MediaQuery.textScalerOf(context).scale(14) / 14, 0, 100 * MediaQuery.textScalerOf(context).scale(14) / 14),
          child: FrostContentColumn(
            maxWidth: FrostMetrics.readingMaxWidth,
            child: SelectionArea(
              onSelectionChanged: onSelectionChanged,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < segment.blocks.length; index++)
                    KeyedSubtree(
                      key: blockKeys[index],
                      child: _ReaderTextTapRegion(
                        onTap: segment.blocks[index] is NovelTextParagraph || segment.blocks[index] is NovelTextChapter ? onTap : null,
                        canToggle: canToggleChrome,
                        child: NovelReaderBlockView(
                          block: segment.blocks[index],
                          paragraphStyle: paragraphStyle,
                          chapterStyle: chapterStyle,
                          dividerColor: palette.line,
                        ),
                      ),
                    ),
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
    final leading = FrostPageHeader.leadingFor(context, onBack: onBack);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: compact ? BorderRadius.zero : BorderRadius.circular(8),
        border: Border.all(color: palette.line.withValues(alpha: compact ? 1 : 0.72)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 8 : 10, compact ? 6 : 8, compact ? 8 : 10, compact ? 6 : 8),
        child: Row(
          children: [
            if (leading != null) ...[leading, SizedBox(width: 8.0)],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: compact ? TextAlign.center : TextAlign.start,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w700),
                  ),
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
      child: FrostContentColumn(maxWidth: FrostMetrics.readingMaxWidth, child: content),
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
      child: ExcludeFocus(
        excluding: !visible,
        child: ExcludeSemantics(
          excluding: !visible,
          child: AnimatedOpacity(duration: FrostMotion.duration(context, FrostMotion.expand), opacity: visible ? 1 : 0, child: child),
        ),
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
    required this.autoScrolling,
    required this.onAutomaticScroll,
    required this.onPageRequested,
    required this.onProgressChanged,
  });

  final List<NovelTextSegment> segments;
  final int totalTextCharacters;
  final int pageIndex;
  final _ReaderPalette palette;
  final bool compact;
  final bool autoScrolling;
  final VoidCallback onAutomaticScroll;
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
        color: palette.surface,
        borderRadius: compact ? BorderRadius.zero : BorderRadius.circular(8),
        border: Border.all(color: palette.line.withValues(alpha: compact ? 1 : 0.72)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, -8))],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 14 : 16, 4, compact ? 14 : 16, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final progressStyle = Theme.of(context).textTheme.labelLarge?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w700);
                final autoScroll = _ReaderAutoScrollSwitch(
                  running: autoScrolling,
                  enabled: segments.isNotEmpty,
                  palette: palette,
                  onChanged: onAutomaticScroll,
                );
                final progress = Expanded(
                  child: Text(progressLabel, textAlign: TextAlign.center, style: progressStyle),
                );
                final previous = _ReaderQuietIconButton(
                  icon: Icons.chevron_left,
                  tooltip: t.novel.reader.previousPage,
                  enabled: pageIndex > 0,
                  palette: palette,
                  onPressed: () => onPageRequested(pageIndex - 1),
                );
                final next = _ReaderQuietIconButton(
                  icon: Icons.chevron_right,
                  tooltip: t.novel.reader.nextPage,
                  enabled: pageIndex < pageCount - 1,
                  palette: palette,
                  onPressed: () => onPageRequested(pageIndex + 1),
                );
                double textWidth(String value) {
                  final painter = TextPainter(
                    text: TextSpan(text: value, style: progressStyle),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout();
                  final width = painter.width;
                  painter.dispose();
                  return width;
                }

                final neededWidth = FrostDensity.of(context).controlHeight * 2 + 68 + textWidth(t.novel.reader.autoScroll) + textWidth(progressLabel) + 16;
                if (neededWidth > constraints.maxWidth) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [previous, progress, next]),
                      autoScroll,
                    ],
                  );
                }
                return Row(children: [previous, progress, autoScroll, next]);
              },
            ),
            _ReaderProgressSlider(pageIndex: pageIndex, pageCount: pageCount, palette: palette, onProgressChanged: onProgressChanged),
          ],
        ),
      ),
    );

    if (compact) {
      return SizedBox(width: double.infinity, child: content);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FrostContentColumn(maxWidth: FrostMetrics.readingMaxWidth, child: content),
    );
  }
}

class _ReaderAutoScrollSwitch extends StatelessWidget {
  const _ReaderAutoScrollSwitch({required this.running, required this.enabled, required this.palette, required this.onChanged});
  final bool running;
  final bool enabled;
  final _ReaderPalette palette;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: running ? t.novel.reader.pauseAutoScroll : t.novel.reader.startAutoScroll,
    child: MergeSemantics(
      child: FrostClickSurface(
        feedback: FrostClickFeedback.quiet,
        shape: FrostClickShape.rounded(BorderRadius.circular(8)),
        onTap: enabled ? onChanged : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Text(
                t.novel.reader.autoScroll,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            FrostSwitch(value: running, onChanged: enabled ? (_) => onChanged() : null, semanticLabel: t.novel.reader.autoScroll),
          ],
        ),
      ),
    ),
  );
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
          overlayColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          fixedSize: Size.square(FrostDensity.of(context).controlHeight),
          minimumSize: Size.square(FrostDensity.of(context).controlHeight),
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
        overlayColor: Colors.transparent,
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 1.2),
        activeTickMarkColor: palette.surface,
        inactiveTickMarkColor: palette.muted.withValues(alpha: 0.42),
      ),
      child: SizedBox(
        height: 24,
        child: Slider(
          min: 0,
          max: max,
          divisions: enabled ? pageCount - 1 : null,
          value: value,
          label: t.novel.reader.currentPage(page: pageIndex + 1),
          onChanged: enabled ? onProgressChanged : null,
        ),
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
    required this.volumeSupported,
    required this.volumeEnabled,
    required this.onVolumeChanged,
    required this.scrollSpeed,
    required this.onSpeedChanged,
  });

  final double fontSize;
  final double lineHeight;
  final _ReaderPalette palette;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;
  final bool volumeSupported;
  final bool volumeEnabled;
  final ValueChanged<bool> onVolumeChanged;
  final double scrollSpeed;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.novel.reader.display,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _ReaderStepper(
          icon: Icons.text_fields,
          label: t.novel.reader.fontSize,
          value: fontSize.round().toString(),
          palette: palette,
          canDecrease: fontSize > 15,
          canIncrease: fontSize < 26,
          onDecrease: () => onFontSizeChanged(fontSize - 1),
          onIncrease: () => onFontSizeChanged(fontSize + 1),
        ),
        const SizedBox(height: 8),
        _ReaderStepper(
          icon: Icons.format_line_spacing,
          label: t.novel.reader.lineHeight,
          value: lineHeight.toStringAsFixed(2),
          palette: palette,
          canDecrease: lineHeight > 1.45,
          canIncrease: lineHeight < 2.2,
          onDecrease: () => onLineHeightChanged(lineHeight - 0.08),
          onIncrease: () => onLineHeightChanged(lineHeight + 0.08),
        ),
        const SizedBox(height: 8),
        _ReaderStepper(
          icon: Icons.speed,
          label: t.novel.reader.autoScrollSpeed,
          value: t.novel.reader.scrollSpeedValue(speed: scrollSpeed.round()),
          palette: palette,
          canDecrease: scrollSpeed > 12,
          canIncrease: scrollSpeed < 96,
          onDecrease: () => onSpeedChanged((scrollSpeed - 12).clamp(12, 96)),
          onIncrease: () => onSpeedChanged((scrollSpeed + 12).clamp(12, 96)),
        ),
        if (volumeSupported)
          FrostListRow.toggle(
            title: t.novel.reader.volumeKeys,
            subtitle: FrostRowSubtitle(t.novel.reader.volumeKeysHelp),
            value: volumeEnabled,
            onChanged: onVolumeChanged,
          ),
        const SizedBox(height: 16),
        Text(t.novel.reader.shortcutsHelp, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.muted)),
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
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final IconData icon;
  final String label;
  final String value;
  final _ReaderPalette palette;
  final bool canDecrease;
  final bool canIncrease;
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final caption = Row(
              children: [
                Icon(icon, size: 18, color: palette.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.onBackground)),
                ),
              ],
            );
            final valueStyle = Theme.of(context).textTheme.labelLarge?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w700);
            final valuePainter = TextPainter(
              text: TextSpan(text: value, style: valueStyle),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            final valueWidth = math.max(56.0, valuePainter.width + 8).clamp(56.0, math.max(56.0, constraints.maxWidth - 112));
            final controls = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  tooltip: t.novel.reader.decrease,
                  color: palette.onBackground,
                  onPressed: canDecrease ? onDecrease : null,
                ),
                SizedBox(
                  width: valueWidth.toDouble(),
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: t.novel.reader.increase,
                  color: palette.onBackground,
                  onPressed: canIncrease ? onIncrease : null,
                ),
              ],
            );
            if (constraints.maxWidth < 380 || MediaQuery.textScalerOf(context).scale(14) > 20) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  caption,
                  const SizedBox(height: 4),
                  Align(alignment: AlignmentDirectional.centerEnd, child: controls),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: caption),
                controls,
              ],
            );
          },
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
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.78),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: palette.onBackground, fontWeight: FontWeight.w700),
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
            Flexible(child: SingleChildScrollView(child: child)),
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
    return FrostAutoScaffold(
      builder: (context, layout, orientation, useHorizontalLayout) {
        final desktop = useHorizontalLayout;
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(desktop ? 36 : 22, FrostGap.of(context).page, desktop ? 36 : 22, FrostGap.of(context).page),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: FrostMetrics.readingMaxWidth),
                  child: Skeletonizer.zone(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var paragraph = 0; paragraph < 4; paragraph++) ...[
                          for (var line = 0; line < 4; line++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Bone(height: MediaQuery.textScalerOf(context).scale(18), width: double.infinity),
                            ),
                          const SizedBox(height: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
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
    final tokens = FrostThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return _ReaderPalette(
      background: tokens.surface,
      surface: tokens.surfaceRaised,
      onBackground: colorScheme.onSurface,
      muted: colorScheme.onSurfaceVariant,
      line: tokens.line,
      accent: tokens.keyGraphicOn(tokens.surfaceRaised),
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

bool _isNotFoundError(Object error) {
  return error is PixivError && error.status == 404;
}
