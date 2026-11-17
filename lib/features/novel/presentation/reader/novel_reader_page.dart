import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/gestures.dart' show GestureBinding, kTouchSlop;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/immersive_pages.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/route_activity.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/core/platform/reader_volume_keys.dart';
import 'package:freepiv/features/downloads/presentation/content_image_entries.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/logic/novel_marker_logic.dart';
import 'package:freepiv/features/novel/logic/reading_progress.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_not_found_page.dart';
import 'package:freepiv/features/novel/presentation/novel_download_source.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/embedded_work_card.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_appearance_panel.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_bottom_panel.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_chrome.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_end_card.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_sidebar.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_status_line.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_top_bar.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_controller.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_input.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_scroll_clock.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_paged_view.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_scroll_view.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';
import 'package:freepiv/ui/custom/reader/reader_paginator.dart';
import 'package:freepiv/ui/custom/reader/reader_text.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// The novel reader: the whole text, chapter titles dividing it, on the
/// reading surface, scrolled top to bottom or turned page by page. The bars
/// lie over the text: the top one with Back, the title, the chapter menu and
/// the settings, the bottom one with the previous and next chapter, the
/// progress and auto scroll. A tap in the middle shows or hides them; taps
/// at the sides turn.
class NovelReaderPage extends ConsumerWidget {
  const NovelReaderPage({this.novelId, this.novel, super.key}) : assert(novelId != null || novel != null);

  final int? novelId;
  final Novel? novel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = NovelDetailArgs(novelId: novelId, novel: novel);
    final provider = novelDetailProvider(args);
    final textProvider = novelTextProvider(args.resolvedNovelId);
    final detail = ref.watch(provider);
    final text = ref.watch(textProvider);
    // Reading needs both the details and the text.
    final error = detail.error ?? text.error;
    if (error != null && !detail.isLoading && !text.isLoading) {
      if (error is PixivError && error.status == 404) return const NovelNotFoundPage();
      return AppPageError.fromError(
        error: error,
        onRetry: () {
          if (detail.hasError) ref.read(provider.notifier).reload();
          if (text.hasError) ref.read(textProvider.notifier).reload();
        },
      );
    }
    final (loaded, webview) = (detail.value, text.value);
    if (loaded == null || webview == null || detail.isLoading || text.isLoading) {
      // The loading page already has the whole window, so the page does not
      // jump when the text arrives.
      if (!FrostAutoScaffold.usesHorizontalLayoutOf(context)) return const _ReaderSkeleton();
      return FrostShellWholeWindow(
        titleRow: FrostButton.icon(
          icon: PivIcons.arrowLeft,
          label: FrostScope.labelsOf(context).back,
          onPressed: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              router.go(AppLocations.novel(args.resolvedNovelId));
            }
          },
        ),
        child: const _ReaderSkeleton(),
      );
    }
    return DownloadSourceScope(
      source: novelDownloadSource(loaded),
      child: NovelReaderContent(
        key: ValueKey('novel-reader-content-${loaded.id}'),
        detail: NovelDetailData(novel: loaded, webviewNovel: webview),
      ),
    );
  }
}

class NovelReaderContent extends ConsumerStatefulWidget {
  const NovelReaderContent({required this.detail, this.volumeKeys, super.key});

  final NovelDetailData detail;
  final ReaderVolumeKeys? volumeKeys;

  @override
  ConsumerState<NovelReaderContent> createState() => NovelReaderContentState();
}

/// The layout of the text for one size of the text area and one typesetting,
/// with its pages in paged mode.
class _Laid {
  _Laid(this.key, this.layout, {this.paginator, this.geometry});

  final Object key;
  final ReaderLayout layout;
  final ReaderPaginator? paginator;
  final ReaderPageGeometry? geometry;
}

/// Public for tests: the reading position and what pauses auto scroll.
class NovelReaderContentState extends ConsumerState<NovelReaderContent> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _keyboard = FocusNode(debugLabel: 'novel-reader-shortcuts');
  final _region = GlobalKey<FrostSelectionAreaState>();
  final _scrollView = GlobalKey<ReaderScrollViewState>();
  final _pagedView = GlobalKey<ReaderPagedViewState>();
  late final ReaderModel _model;

  late double _fontSize;
  late ReaderLineSpacing _lineSpacing;

  /// The rest of the reader settings: theme, font, indent, page mode…
  late ReaderSettings _settings;
  late double _speed;
  late bool _volumeEnabled;
  late final ReaderVolumeKeyLease _volumeLease;
  late final Ticker _ticker;
  final _clock = ReaderScrollClock();
  late final String? _sessionAccount;
  late final ProviderContainer _container;

  /// Null until the saved position is read.
  ReaderController? _controller;
  _Laid? _laid;

  final _chrome = ReaderChromeController();

  /// The open list of the sidebar; null when it is closed.
  ReaderSidebarTab? _sidebar;

  /// Whether the text area has room to hold the sidebar beside the text
  /// column, as of the last build; and whether it does so now.
  bool _sidebarFits = false;
  bool _sidebarDocked = false;
  late final List<ReaderIllustration> _illustrations;

  /// Counts the layouts made, for the footer that reads the pages of the current one.
  final _layouts = ValueNotifier<int>(0);
  bool _autoScrolling = false;
  bool _settingsOpen = false;
  bool _selectionActive = false;
  bool _accountChanged = false;
  bool _windowFocused = true;
  bool _foreground = true;

  Novel get _novel => widget.detail.novel;

  /// Where the reader is; null until the saved position is read.
  ReaderController? get controller => _controller;

  /// The text's layout in use, for tests.
  ReaderLayout? get layout => _laid?.layout;

  /// The pages in paged mode, for tests.
  ReaderPaginator? get paginator => _laid?.paginator;

  /// The chapter being read.
  ReaderChapter get currentChapter => _controller?.chapter ?? _model.chapters.first;

  /// How far through the text the reader is, 0 to 1.
  double get progress => _controller?.progress ?? 0;

  bool get autoScrolling => _autoScrolling;

  /// The open list of the sidebar, null when it is closed.
  ReaderSidebarTab? get sidebar => _sidebar;

  /// Whether the sidebar sits beside the text now (it lies over it otherwise).
  bool get sidebarDocked => _sidebarDocked;

  /// Whether the bars are shown.
  bool get chromeVisible => _chrome.shown;

  /// The bars' visibility, for tests.
  ReaderChromeController get chrome => _chrome;

  bool get _paged => _settings.pageMode == ReaderPageMode.paged;

  bool get _controlsEligible =>
      mounted &&
      _foreground &&
      _windowFocused &&
      !_accountChanged &&
      !_settingsOpen &&
      !_selectionActive &&
      ModalRoute.of(context)?.isCurrent == true &&
      // A dialog of the root navigator covers the reader from outside its route.
      !appRootRouteActivity.popupOnTop;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(readerSettingsProvider);
    _settings = saved;
    _fontSize = saved.textSize;
    _lineSpacing = saved.lineSpacing;
    _speed = saved.autoScrollSpeed.pixelsPerSecond;
    _volumeEnabled = saved.volumeKeys;
    _container = ProviderScope.containerOf(context, listen: false);
    _sessionAccount = pixivAccountNotifier.value?.user.id;
    _foreground = WidgetsBinding.instance.lifecycleState == null || WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _ticker = createTicker(_tick);
    _volumeLease = (widget.volumeKeys ?? ReaderVolumeKeys.instance).claim(
      onTurn: _volumeTurn,
      onError: () {
        if (mounted) setState(() => _volumeEnabled = false);
      },
      onFocusChanged: (focused) {
        _windowFocused = focused;
        _activityChanged();
      },
    );
    WidgetsBinding.instance.addObserver(this);
    pixivAccountNotifier.addListener(_accountChangedListener);
    appRootRouteActivity.addListener(_activityChanged);
    _model = ReaderModel(parseWebviewNovel(widget.detail.webviewNovel));
    _illustrations = _illustrationsOf();
    _chrome.addListener(_chromeChanged);
    unawaited(_loadPosition());
    WidgetsBinding.instance.addPostFrameCallback((_) => _hintShortcuts());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboard.requestFocus();
    });
  }

  Future<void> _loadPosition() async {
    final saved = await loadReadingProgress(_novel.id);
    if (!mounted) return;
    final novelId = _novel.id;
    final container = _container;
    setState(() {
      _controller = ReaderController(
        model: _model,
        initialOffset: saved?.offset ?? 0,
        // Read to the end: the text opens with its end card in view.
        initialAtEnd: saved != null && saved.totalLength > 0 && saved.offset >= saved.totalLength,
        mode: _settings.pageMode,
        save: (offset, totalLength) async {
          if (_accountChanged) return;
          await saveReadingProgress(novelId, offset: offset, totalLength: totalLength);
          // The detail page under the reader shows the progress.
          container.invalidate(novelReadingProgressProvider(novelId));
        },
      );
    });
  }

  /// The first time the reader opens on a desktop with a keyboard, a small
  /// hint names the keys that turn pages; it is shown once.
  void _hintShortcuts() {
    if (!mounted || AppSettings.readerShortcutsHintSeen || kIsWeb) return;
    if (!const {TargetPlatform.windows, TargetPlatform.macOS, TargetPlatform.linux}.contains(defaultTargetPlatform)) return;
    AppSettings.readerShortcutsHintSeen = true;
    FrostToast.info(context.t.novel.reader.shortcutsHint);
  }

  /// False while the reader is out of the tree (its route being removed
  /// under another page), when route changes must not reach it.
  bool _active = true;

  @override
  void deactivate() {
    _active = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  @override
  void dispose() {
    _controller?.dispose();
    if (_laid case final laid?) _disposeAfterFrame(laid.layout);
    _ticker.dispose();
    _volumeLease.release();
    pixivAccountNotifier.removeListener(_accountChangedListener);
    appRootRouteActivity.removeListener(_activityChanged);
    WidgetsBinding.instance.removeObserver(this);
    _keyboard.dispose();
    _chrome.removeListener(_chromeChanged);
    _chrome.dispose();
    _layouts.dispose();
    super.dispose();
  }

  void _accountChangedListener() {
    _accountChanged = true;
    _activityChanged();
    if (mounted) setState(() {});
  }

  /// Volume keys and auto scroll belong to the reader only while it is the
  /// page in front with nothing over it.
  void _activityChanged() {
    if (!mounted || !_active) return;
    _volumeLease.setEnabled(_volumeEnabled && _controlsEligible);
    if (!_controlsEligible && _autoScrolling) {
      _pause(rebuild: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) unawaited(_controller?.saveNow());
    _activityChanged();
  }

  // ---- Moving.

  void goToChapter(int index) {
    _pause();
    _controller?.goToChapter(index);
  }

  NovelMarkerProvider get _marker =>
      novelMarkerProvider(NovelMarkerArgs(accountId: _sessionAccount, novelId: _novel.id, page: parseNovelMarker(widget.detail.webviewNovel.marker)));

  void _markerFailed(Object error) {
    if (mounted && !_accountChanged) toastErrorWithCause(context.t.novel.reader.markerFailed, error);
  }

  // ---- The sidebar.

  void _openSidebar(ReaderSidebarTab tab) {
    _pause();
    if (_sidebar == tab) return;
    setState(() => _sidebar = tab);
    // Over the text, the sidebar stands on the shown bars.
    if (!_sidebarFits) _chrome.show();
  }

  void _closeSidebar({bool hideBars = false}) {
    if (_sidebar == null) return;
    setState(() => _sidebar = null);
    if (hideBars) _chrome.hide();
    _keyboard.requestFocus();
  }

  /// The bars going away takes the sidebar that stands on them.
  void _chromeChanged() {
    if (!_chrome.shown && _sidebar != null && !_sidebarDocked && mounted) {
      setState(() => _sidebar = null);
      _keyboard.requestFocus();
    }
  }

  void _sidebarChapter(int index) {
    goToChapter(index);
    if (!_sidebarDocked) _closeSidebar(hideBars: true);
  }

  void _sidebarIllustration(ReaderIllustration item) {
    _pause();
    _controller?.goToOffset(item.offset);
    if (!_sidebarDocked) _closeSidebar(hideBars: true);
  }

  List<ReaderIllustration> _illustrationsOf() {
    final sizes = ref.read(imageSizeStoreProvider);
    return [
      for (final block in _model.imageBlocks)
        switch (_model.blocks[block]) {
          NovelUploadedImage(:final image) => _illustration(block, image == null ? null : novelStripImageUrl(image), sizes, isWork: false),
          NovelEmbeddedWork(:final work) => _illustration(block, work == null ? null : novelEmbeddedWorkImageUrl(work), sizes, isWork: true),
          _ => _illustration(block, null, sizes, isWork: false),
        },
    ];
  }

  ReaderIllustration _illustration(int block, String? url, ImageSizeStore sizes, {required bool isWork}) {
    final size = (url == null ? null : sizes.sizeOf(url)) ?? (isWork ? const Size(3, 4) : novelImageFallbackSize);
    return ReaderIllustration(block: block, offset: _model.offsetOf(block), url: url, aspectRatio: size.width / size.height, isWork: isWork);
  }

  /// The uploaded illustrations' own pictures, in the order of the text.
  List<({int block, OriginalImagePage page})> get _viewerPages => [
    for (final block in _model.imageBlocks)
      if (_model.blocks[block] case NovelUploadedImage(:final image?))
        if (novelTextImageUrl(image) case final url?)
          (
            block: block,
            page: OriginalImagePage(
              url: novelViewerImageUrl(image) ?? url,
              previewUrl: url,
              downloadOrigin: DownloadOrigin.ofImageUrl(Uri.parse(novelViewerImageUrl(image) ?? url)),
            ),
          ),
  ];

  /// An illustration's own picture: all uploaded pictures in the viewer,
  /// starting at it; an embedded work opens its page.
  void _openIllustration(ReaderIllustration item) {
    // The button's tooltip (a hover, or a press held a moment) lives in the
    // root overlay and would stay over the viewer that opens.
    RawTooltip.dismissAllToolTips();
    final router = GoRouter.of(context);
    final block = _model.blocks[item.block];
    if (block is NovelEmbeddedWork) {
      unawaited(router.push(AppLocations.illust(block.illustId)));
      return;
    }
    final pages = _viewerPages;
    final index = pages.indexWhere((page) => page.block == item.block);
    if (index < 0) return;
    unawaited(
      router.push(
        AppRoute.originalImageViewer.path,
        extra: OriginalImageViewerArgs(
          title: _novel.title,
          source: DownloadSourceScope.of(context),
          pages: [for (final page in pages) page.page],
          initialIndex: index,
        ),
      ),
    );
  }

  /// Moves to the start of the 1-based `[newpage]` section [page].
  void _goToSection(int page) {
    _pause();
    _controller?.goToPixivPage(page);
  }

  int get _currentSection => _model.pageOf(_controller?.offset ?? 0);

  /// The saved settings at the size and spacing in use.
  ReaderSettings get _typography => ReaderSettings(
    textSize: _fontSize,
    lineSpacing: _lineSpacing,
    margins: _settings.margins,
    theme: _settings.theme,
    font: _settings.font,
    indent: _settings.indent,
    pageMode: _settings.pageMode,
    pageAnimation: _settings.pageAnimation,
    tapZones: _settings.tapZones,
    autoScrollSpeed: _settings.autoScrollSpeed,
    volumeKeys: _settings.volumeKeys,
  );

  /// Moves to the place [value] of the way through the text.
  void _jumpToProgress(double value) {
    _pause();
    _controller?.goToFraction(value);
  }

  /// A screen or page on (+1) or back (-1).
  void _turnScreen(int direction) {
    _pause();
    _chrome.hide();
    final controller = _controller;
    if (controller == null) return;
    if (direction > 0) {
      controller.nextScreen();
    } else {
      controller.previousScreen();
    }
  }

  /// A volume key.
  void _volumeTurn(int direction) {
    if (!_volumeEnabled || !_controlsEligible) return;
    _turnScreen(direction);
  }

  // ---- Auto scroll.

  void _pause({bool rebuild = true}) {
    _ticker.stop();
    _clock.reset();
    if (!_autoScrolling) return;
    _autoScrolling = false;
    if (rebuild && mounted) setState(() {});
  }

  void _toggleAutoScroll() {
    if (_autoScrolling) {
      _pause();
    } else if (_controlsEligible && !_paged && _model.blocks.isNotEmpty && _scrollView.currentState != null) {
      _clock.reset();
      _chrome.hide();
      setState(() => _autoScrolling = true);
      _ticker.start();
    }
  }

  /// Auto scroll runs on through the chapters and stops at the end.
  void _tick(Duration elapsed) {
    final view = _scrollView.currentState;
    if (!_controlsEligible || view == null) {
      _pause();
      return;
    }
    final distance = _clock.advance(elapsed, _speed);
    if (!view.advance(distance)) _pause();
  }

  void _userScrolled() {
    _pause();
    _chrome.hide();
  }

  // ---- Settings.

  void _applySettings(ReaderSettings next) {
    if (next.pageMode != _settings.pageMode) _pause();
    setState(() {
      _settings = next;
      _fontSize = next.textSize.clamp(AppSettings.readerFontSizeRange.min, AppSettings.readerFontSizeRange.max);
      _lineSpacing = next.lineSpacing;
      _speed = next.autoScrollSpeed.pixelsPerSecond;
      _volumeEnabled = next.volumeKeys;
    });
    _controller?.mode = next.pageMode;
    _activityChanged();
  }

  void _settingsShown(bool open) {
    _settingsOpen = open;
    if (open) _pause();
    _activityChanged();
    if (!open && mounted) _keyboard.requestFocus();
  }

  // ---- Leaving, the keyboard and taps.

  void _close() {
    _pause();
    unawaited(_controller?.saveNow());
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppLocations.novel(_novel.id));
    }
  }

  /// Keys belong to the reader while nothing is over it and no text field
  /// takes them.
  bool get _keysAllowed {
    if (ModalRoute.of(context)?.isCurrent != true || appRootRouteActivity.popupOnTop || _settingsOpen) return false;
    final focused = FocusManager.instance.primaryFocus?.context;
    return focused == null || (focused.widget is! EditableText && focused.findAncestorStateOfType<EditableTextState>() == null);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    final command = readerCommandFor(event, mode: _settings.pageMode);
    if (command == null || !_keysAllowed) return KeyEventResult.ignored;
    final controller = _controller;
    switch (command) {
      case ReaderCommand.escape:
        if (_selectionActive) {
          _region.currentState?.clearSelection();
          _selectionActive = false;
          _activityChanged();
        } else if (_sidebar != null) {
          _closeSidebar();
        } else if (_chrome.anyVisible) {
          _chrome.hide();
        } else {
          _close();
        }
        return KeyEventResult.handled;
      case ReaderCommand.contents:
        if (_sidebar == ReaderSidebarTab.contents) {
          _closeSidebar();
        } else {
          _openSidebar(ReaderSidebarTab.contents);
        }
        return KeyEventResult.handled;
      case _ when controller == null || _model.blocks.isEmpty:
        return KeyEventResult.ignored;
      case ReaderCommand.nextScreen:
        _turnScreen(1);
      case ReaderCommand.previousScreen:
        _turnScreen(-1);
      case ReaderCommand.lineDown || ReaderCommand.lineUp:
        _pause();
        _chrome.hide();
        _scrollView.currentState?.scrollLines(command == ReaderCommand.lineDown ? 1 : -1);
      case ReaderCommand.nextChapter:
        _pause();
        _chrome.hide();
        controller.nextChapter();
      case ReaderCommand.previousChapter:
        _pause();
        _chrome.hide();
        controller.previousChapter();
      case ReaderCommand.start:
        _pause();
        _chrome.hide();
        controller.goToStart();
      case ReaderCommand.end:
        _pause();
        _chrome.hide();
        controller.goToEnd();
    }
    return KeyEventResult.handled;
  }

  void _tapped(Offset position, Size size) {
    if (_selectionActive) return;
    _keyboard.requestFocus();
    switch (readerTapActionFor(position, size, _settings.tapZones)) {
      case ReaderTapAction.back:
        _turnScreen(-1);
      case ReaderTapAction.forward:
        _turnScreen(1);
      case ReaderTapAction.toggleBars:
        _chrome.toggle();
    }
  }

  void _selectionChanged(SelectedContent? content) {
    _selectionActive = content != null && content.plainText.isNotEmpty;
    if (_selectionActive) _pause();
    _activityChanged();
  }

  // ---- The text.

  /// Everything of the typesetting that changes the layout.
  static Object _typesettingKey(ReaderTypesetting typesetting) {
    final palette = typesetting.palette;
    return (
      typesetting.textScaler,
      typesetting.body,
      typesetting.chapterTitle,
      typesetting.rubyScale,
      typesetting.indent,
      typesetting.margins,
      typesetting.locale,
      (palette.background, palette.text, palette.secondary, palette.link, palette.ruby, palette.selection),
    );
  }

  /// The layout for a text area of [size], kept while nothing it depends on
  /// changes.
  _Laid _layFor(Size size, ReaderTypesetting typesetting) {
    final t = context.t.novel.reader;
    // Scrolled text depends on the column, not on the width around it: a
    // sidebar beside the text does not lay it out again.
    final key = (_settings.pageMode, _paged ? size : (typesetting.columnWidth(size.width), size.height), _typesettingKey(typesetting), t.pageJump(page: 1));
    final laid = _laid;
    if (laid != null && laid.key == key) return laid;
    if (laid != null) _disposeAfterFrame(laid.layout);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _layouts.value++;
    });
    final sizes = ref.read(imageSizeStoreProvider);
    String pageJumpLabel(int page) => t.pageJump(page: page);
    if (!_paged) {
      final layout = ReaderLayout(
        model: _model,
        typesetting: typesetting,
        width: size.width,
        flow: ReaderFlow.scroll,
        sizes: sizes,
        viewportHeight: size.height,
        pageJumpLabel: pageJumpLabel,
      );
      return _laid = _Laid(key, layout);
    }
    final geometry = ReaderPageGeometry.of(size, typesetting);
    final layout = ReaderLayout(
      model: _model,
      typesetting: typesetting,
      width: geometry.pageWidth,
      flow: ReaderFlow.paged,
      sizes: sizes,
      viewportHeight: geometry.pageHeight,
      pageJumpLabel: pageJumpLabel,
    );
    return _laid = _Laid(
      key,
      layout,
      paginator: ReaderPaginator(layout, pageHeight: geometry.pageHeight),
      geometry: geometry,
    );
  }

  /// The view lets go of a replaced layout in the frame that replaces it.
  static void _disposeAfterFrame(ReaderLayout layout) => WidgetsBinding.instance.addPostFrameCallback((_) => layout.dispose());

  void _openLink(Uri url) => unawaited(launchUrl(url, mode: LaunchMode.externalApplication));

  /// An uploaded image or embedded work, filling the box the view gives it.
  /// Taps on it act on it, not on the bars or the page.
  Widget _blockContent(BuildContext context, int index, ValueChanged<Size>? onImageSize) {
    final t = context.t;
    final block = _model.blocks[index];
    if (block is NovelEmbeddedWork) {
      return _KeepsBars(
        child: EmbeddedWorkCard(
          block: block,
          height: _laid?.layout.typesetting.embeddedWorkExtent ?? 112,
          onOpen: (id) => unawaited(GoRouter.of(context).push(AppLocations.illust(id))),
        ),
      );
    }
    final image = block is NovelUploadedImage ? block.image : null;
    final url = image == null ? null : novelTextImageUrl(image);
    final viewerUrl = image == null ? null : novelViewerImageUrl(image) ?? url;
    final child = url == null
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: FrostText(t.novel.reader.embeddedImageUnavailable, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
          )
        : FrostContextMenuRegion(
            entries: contentImageMenu(context, ref.read(rustMediaTransportProvider), url: viewerUrl ?? url, title: _novel.title),
            child: Semantics(
              button: true,
              image: true,
              label: t.novel.detail.images,
              child: FrostClickSurface(
                shape: FrostClickShape.rounded(BorderRadius.circular(FrostRadius.lg)),
                onTap: () {
                  final shown = viewerUrl ?? url;
                  unawaited(
                    GoRouter.of(context).push(
                      AppRoute.originalImageViewer.path,
                      extra: OriginalImageViewerArgs(
                        title: _novel.title,
                        source: DownloadSourceScope.of(context),
                        pages: [OriginalImagePage(url: shown, previewUrl: url, downloadOrigin: DownloadOrigin.ofImageUrl(Uri.parse(shown)))],
                      ),
                    ),
                  );
                },
                child: AppPixivImage(url: url, fit: BoxFit.contain, onImageSize: onImageSize),
              ),
            ),
          );
    return _KeepsBars(child: child);
  }

  /// "The end", the bookmark and comments, and the series the novel is in.
  Widget _endCard(BuildContext context) {
    final webview = widget.detail.webviewNovel;
    final navigation = webview.seriesNavigation;
    final router = GoRouter.of(context);
    return ReaderEndCard(
      novelId: _novel.id,
      bookmarked: _novel.isBookmarked,
      onComments: () => unawaited(router.push(AppLocations.novelComments(_novel.id))),
      onOpenNovel: (id) => unawaited(router.pushReplacement(AppLocations.novelReader(id))),
      seriesId: int.tryParse(webview.seriesId ?? ''),
      seriesTitle: webview.seriesTitle,
      seriesWatched: webview.seriesIsWatched ?? false,
      next: navigation?.nextNovel,
      previous: navigation?.prevNovel,
    );
  }

  Widget _view(ReaderController controller, ReaderTypesetting typesetting) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final laid = _layFor(constraints.biggest, typesetting);
        if (laid.paginator case final paginator?) {
          return ReaderPagedView(
            key: _pagedView,
            controller: controller,
            paginator: paginator,
            geometry: laid.geometry!,
            animation: _settings.pageAnimation,
            blockBuilder: _blockContent,
            endBuilder: _endCard,
            onLink: _openLink,
            onPageJump: _goToSection,
          );
        }
        return ReaderScrollView(
          key: _scrollView,
          controller: controller,
          layout: laid.layout,
          blockBuilder: _blockContent,
          endBuilder: _endCard,
          onLink: _openLink,
          onPageJump: _goToSection,
        );
      },
    );
  }

  /// One line of status above or below the text.
  double _statusExtent(BuildContext context) {
    final style = FrostTypography.of(context).style(FrostTextRole.footnote);
    return MediaQuery.textScalerOf(context).scale(style.fontSize ?? 12) * (style.height ?? 1.4) + FrostGap.related;
  }

  /// The page and the pages of its chapter in paged mode.
  ({int page, int pages})? _pageStatus() {
    final paginator = _laid?.paginator;
    final controller = _controller;
    if (!_paged || paginator == null || controller == null) return null;
    final page = paginator.pageAt(controller.offset);
    return (page: page.index + 1, pages: paginator.pagesOfChapter(page.chapter).length);
  }

  /// "Series · author", or the author alone.
  String? get _subtitle {
    final parts = [_novel.series.title, _novel.user.name].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static Uri _novelWebUrl(int id) => Uri.parse('https://www.pixiv.net/novel/show.php?id=$id');

  Future<void> _copyLink() async {
    final t = context.t;
    try {
      await copyTextToClipboard(_novelWebUrl(_novel.id).toString());
      FrostToast.copied(t.illust.toast.linkCopied);
    } catch (error) {
      toastErrorWithCause(t.illust.toast.linkCopyFailed, error);
    }
  }

  List<FrostMenuEntry> _menuEntries(BuildContext context) {
    final t = context.t.novel.reader;
    final router = GoRouter.of(context);
    return [
      FrostMenuAction(t.openDetail, onSelected: () => unawaited(router.push(AppLocations.novel(_novel.id), extra: _novel))),
      FrostMenuAction(t.comments, onSelected: () => unawaited(router.push(AppLocations.novelComments(_novel.id)))),
      FrostMenuAction(t.copyLink, onSelected: () => unawaited(_copyLink())),
      FrostMenuAction(t.shortcuts, onSelected: () => unawaited(showReaderShortcuts(context))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    ref.listen(readerSettingsProvider, (_, next) => _applySettings(next));
    // Follow the route being covered by another page.
    ModalRoute.isCurrentOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _activityChanged());
    final typesetting = ReaderTypesetting.of(context, _typography, language: widget.detail.webviewNovel.language);
    final status = _statusExtent(context);
    final controller = _controller;
    final enabled = !_accountChanged;

    final Widget text;
    if (_model.blocks.isEmpty) {
      text = Center(
        child: FrostEmptyState(icon: PivIcons.bookOpen, title: t.novel.reader.emptyBody),
      );
    } else if (controller == null) {
      text = const SizedBox.expand();
    } else {
      text = NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction != ScrollDirection.idle) _userScrolled();
          return false;
        },
        child: ReaderSelectableText(
          areaKey: _region,
          onSelectionChanged: _selectionChanged,
          child: _TapZones(onTap: _tapped, child: _view(controller, typesetting)),
        ),
      );
    }
    final palette = typesetting.palette;
    final marker = _sessionAccount == null ? null : ref.watch(_marker).page;
    // Beside a sidebar the page has the whole window and its top bar lives in the
    // title row; elsewhere that row is empty, the bar lies over the text, and the
    // page hides the shell's floating entries.
    final titleRow = controller == null
        ? null
        : FrostSolidMaterial(
            child: ReaderTitleRow(
              chrome: _chrome,
              title: _novel.title,
              subtitle: _subtitle,
              onBack: _close,
              menuEntries: _menuEntries(context),
              marker: _markerButton(enabled),
            ),
          );
    final sidebarLayout = FrostAutoScaffold.usesHorizontalLayoutOf(context);
    Widget page(Widget child) {
      final window = ReaderPageScope(
        child: FrostShellWholeWindow(titleRow: titleRow, child: child),
      );
      return sidebarLayout ? window : ImmersivePage(child: window);
    }

    return PopScope<Object?>(
      // Any way out (Back, a system back gesture) keeps the place at once.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(_controller?.saveNow());
      },
      child: Focus(
        focusNode: _keyboard,
        autofocus: true,
        onKeyEvent: _key,
        child: FrostSolidMaterial(
          child: page(
            FrostSurface(
              role: FrostSurfaceRole.reading,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final controller = _controller;
                  final open = _sidebar != null && controller != null;
                  _sidebarFits = readerSidebarDocks(size: constraints.biggest, typesetting: typesetting, paged: _paged);
                  final docked = open && _sidebarFits;
                  _sidebarDocked = docked;
                  Widget sidebar() => ReaderSidebar(
                    controller: controller!,
                    tab: _sidebar!,
                    onTabChanged: (tab) => setState(() => _sidebar = tab),
                    onClose: _closeSidebar,
                    onGoToChapter: _sidebarChapter,
                    illustrations: _illustrations,
                    onGoToIllustration: _sidebarIllustration,
                    onOpenIllustration: _openIllustration,
                    markerPage: marker,
                  );
                  final main = Builder(
                    builder: (context) =>
                        _readerArea(context, controller: controller, typesetting: typesetting, palette: palette, status: status, text: text, enabled: enabled),
                  );
                  if (docked) {
                    return Row(
                      children: [
                        SizedBox(width: readerSidebarWidth, child: sidebar()),
                        Expanded(
                          child: MediaQuery.removePadding(context: context, removeLeft: true, child: main),
                        ),
                      ],
                    );
                  }
                  return Stack(
                    children: [
                      Positioned.fill(child: main),
                      if (open)
                        PositionedDirectional(
                          top: 0,
                          bottom: 0,
                          start: 0,
                          width: constraints.maxWidth < readerSidebarWidth + 48 ? constraints.maxWidth - 48 : readerSidebarWidth,
                          child: sidebar(),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _markerButton(bool enabled) => _sessionAccount != null && _model.pageCount > 1
      ? ReaderMarkerButton(provider: _marker, enabled: enabled, currentSection: () => _currentSection, onGoToSection: _goToSection, onFailed: _markerFailed)
      : null;

  /// The text with its status lines and the bars over it.
  Widget _readerArea(
    BuildContext context, {
    required ReaderController? controller,
    required ReaderTypesetting typesetting,
    required ReaderPalette palette,
    required double status,
    required Widget text,
    required bool enabled,
  }) {
    final padding = MediaQuery.paddingOf(context);
    final reading = Stack(
      children: [
        Positioned(left: padding.left, right: padding.right, top: padding.top + status, bottom: padding.bottom + status, child: text),
        if (controller != null) ...[
          Positioned(
            left: padding.left,
            right: padding.right,
            top: padding.top,
            child: ReaderHeaderLine(controller: controller, palette: palette, extent: status),
          ),
          Positioned(
            left: padding.left,
            right: padding.right,
            bottom: padding.bottom,
            child: ReaderFooterLine(
              controller: controller,
              layouts: _layouts,
              palette: palette,
              extent: status,
              pageStatus: _pageStatus,
              language: widget.detail.webviewNovel.language,
            ),
          ),
        ],
      ],
    );
    // The app theme reads on the reading surface itself.
    final surface = _settings.theme == ReaderTheme.app ? reading : ColoredBox(color: palette.background, child: reading);
    if (controller == null) return surface;
    return ReaderChrome(
      controller: _chrome,
      topBar: ReaderTopBar(title: _novel.title, subtitle: _subtitle, onBack: _close, menuEntries: _menuEntries(context), marker: _markerButton(enabled)),
      bottomPanel: ReaderBottomPanel(
        controller: controller,
        enabled: enabled && _model.blocks.isNotEmpty,
        onGoToChapter: goToChapter,
        onJumpToFraction: _jumpToProgress,
        onContents: () => _openSidebar(ReaderSidebarTab.contents),
        onIllustrations: () => _openSidebar(ReaderSidebarTab.illustrations),
        appearance: _appearanceButton,
        autoScrolling: _paged ? null : _autoScrolling,
        onToggleAutoScroll: _toggleAutoScroll,
      ),
      child: surface,
    );
  }

  Widget _appearanceButton(BuildContext context, bool compact) {
    final t = context.t.novel.reader;
    return FrostPopover(
      title: t.appearance,
      builder: (context, focusNode, toggle) => ReaderPanelEntry(
        key: const ValueKey('reader-settings'),
        focusNode: focusNode,
        icon: PivIcons.settings,
        label: t.appearance,
        compact: compact,
        onPressed: _accountChanged ? null : toggle,
      ),
      contentBuilder: (context, close) => ReaderAppearancePanel(
        volumeSupported: (widget.volumeKeys ?? ReaderVolumeKeys.instance).supported,
        onShown: _settingsShown,
        onShortcuts: () => unawaited(showReaderShortcuts(this.context)),
      ),
    );
  }
}

/// A tap on the text, not a drag or a selection, reports where it landed in
/// the area. Taps on a link, an image or an embedded work act on those alone.
class _TapZones extends StatefulWidget {
  const _TapZones({required this.onTap, required this.child});

  final void Function(Offset position, Size size) onTap;
  final Widget child;

  @override
  State<_TapZones> createState() => _TapZonesState();
}

class _TapZonesState extends State<_TapZones> {
  /// Whether the tap landed on a block that keeps the bars ([_KeepsBars]) or
  /// on a link.
  static bool _onOwnTarget(PointerEvent event) {
    final hit = HitTestResult();
    GestureBinding.instance.hitTestInView(hit, event.position, event.viewId);
    return hit.path
        .map((entry) => entry.target)
        .any((target) => (target is RenderMetaData && identical(target.metaData, _KeepsBars.tag)) || (target is TextSpan && target.recognizer != null));
  }

  Offset? _down;
  Duration? _downAt;

  /// Longer presses select text.
  static const _tapDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) {
      _down = event.position;
      _downAt = event.timeStamp;
    },
    onPointerUp: (event) {
      final down = _down, downAt = _downAt;
      _down = null;
      if (down == null || downAt == null) return;
      if ((event.position - down).distance > kTouchSlop || event.timeStamp - downAt > _tapDuration) return;
      if (_onOwnTarget(event)) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      widget.onTap(event.localPosition, box.size);
    },
    onPointerCancel: (_) => _down = null,
    child: widget.child,
  );
}

/// A block whose taps act on itself (an illustration, an embedded work) and
/// leave the bars and the page as they are.
class _KeepsBars extends StatelessWidget {
  const _KeepsBars({required this.child});

  static const tag = Object();

  final Widget child;

  @override
  Widget build(BuildContext context) => MetaData(metaData: tag, child: child);
}

/// The reader while the text loads: its surface and lines where the text
/// will be.
class _ReaderSkeleton extends StatelessWidget {
  const _ReaderSkeleton();

  @override
  Widget build(BuildContext context) => FrostSurface(
    role: FrostSurfaceRole.reading,
    child: SafeArea(
      child: FrostContentColumn(
        maxWidth: FrostMetrics.readingMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FrostGap.group,
          children: [
            for (var paragraph = 0; paragraph < 6; paragraph++)
              const FrostText('A paragraph of the novel that runs over a few lines of the reading column before the next one starts.', maxLines: 4),
          ],
        ).frostSkeleton(true),
      ),
    ),
  );
}
