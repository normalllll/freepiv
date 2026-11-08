import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show GestureBinding, kTouchSlop;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/route_activity.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/core/platform/reader_volume_keys.dart';
import 'package:freepiv/features/downloads/presentation/content_image_entries.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/domain/novel_text_parser.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_not_found_page.dart';
import 'package:freepiv/features/novel/presentation/novel_download_source.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reading_session.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_model.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_scroll_clock.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/custom/reader/reader_text.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The novel reader: the whole text read top to bottom,
/// chapter titles dividing it, on the reading surface. A tap on the text
/// shows or hides the bars over it, and scrolling hides them: the top one
/// with Back, the title, the chapter menu and the settings, the bottom one
/// with the previous and next chapter, the progress and auto scroll.
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
    if (loaded == null || webview == null || detail.isLoading || text.isLoading) return const _ReaderSkeleton();
    return DownloadSourceScope(
      source: novelDownloadSource(loaded),
      child: NovelReaderContent(
        key: ValueKey('novel-reader-content-${loaded.id}'),
        detail: NovelDetailData(novel: loaded, webviewNovel: webview),
      ),
    );
  }
}

/// Keys of the reader's keyboard.
final _previousChapterKeys = {LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA};
final _nextChapterKeys = {LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD};
final _scrollUpKeys = {LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW};
final _scrollDownKeys = {LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS};

/// How far a key scrolls.
const _keyboardScrollExtent = 320.0;

/// What a volume key leaves of the screen it turns, for context.
const _turnOverlap = 120.0;

/// Ranges of the reader settings.
const readerFontSizes = (min: 15.0, max: 26.0);
const readerLineHeights = (min: 1.45, max: 2.2);
const readerScrollSpeeds = (min: 12.0, max: 96.0);

class NovelReaderContent extends ConsumerStatefulWidget {
  const NovelReaderContent({required this.detail, this.volumeKeys, super.key});

  final NovelDetailData detail;
  final ReaderVolumeKeys? volumeKeys;

  @override
  ConsumerState<NovelReaderContent> createState() => NovelReaderContentState();
}

/// Public for tests: the reading place and what pauses auto scroll.
class NovelReaderContentState extends ConsumerState<NovelReaderContent> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _keyboard = FocusNode(debugLabel: 'novel-reader-shortcuts');
  final _region = GlobalKey<FrostSelectionAreaState>();
  final _topBar = GlobalKey();
  final _blockKeys = <int, GlobalKey>{};
  late ReaderModel _model;

  late double _fontSize;
  late double _lineHeight;
  late double _speed;
  late bool _volumeEnabled;
  late final ReaderVolumeKeyLease _volumeLease;
  late final Ticker _ticker;
  final _clock = ReaderScrollClock();
  late final String? _sessionAccount;

  bool _chromeVisible = true;
  bool _autoScrolling = false;
  bool _settingsOpen = false;
  bool _selectionActive = false;
  bool _accountChanged = false;
  bool _windowFocused = true;
  bool _foreground = true;
  int _block = 0;

  /// Where to put the text once it is laid out: on opening, and after a
  /// change of size, spacing or window.
  NovelReadingPosition? _pending;

  Novel get _novel => widget.detail.novel;

  /// The block at the top of the screen.
  int get currentBlock => _block;

  /// The chapter being read.
  ReaderChapter get currentChapter => _model.chapterOf(_block);

  bool get autoScrolling => _autoScrolling;

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
    _fontSize = saved.textSize;
    _lineHeight = saved.lineHeight;
    _speed = saved.autoScrollSpeed;
    _volumeEnabled = saved.volumeKeys;
    _sessionAccount = pixivAccountNotifier.value?.user.id;
    _foreground = WidgetsBinding.instance.lifecycleState == null || WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _ticker = createTicker(_tick);
    _volumeLease = (widget.volumeKeys ?? ReaderVolumeKeys.instance).claim(
      onTurn: _turn,
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
    _scroll.addListener(_scrolled);
    _model = _buildModel();
    _pending = novelReadingPosition(context, _novel.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _keyboard.requestFocus();
      _restore();
    });
  }

  ReaderModel _buildModel() {
    final webview = widget.detail.webviewNovel;
    return ReaderModel(parseNovelText(webview.text, imageUrls: novelEmbeddedImageUrls(webview)));
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
    _save();
    _ticker.dispose();
    _volumeLease.release();
    pixivAccountNotifier.removeListener(_accountChangedListener);
    appRootRouteActivity.removeListener(_activityChanged);
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    _keyboard.dispose();
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
    _activityChanged();
  }

  @override
  void didChangeMetrics() {
    if (_model.isEmpty) return;
    _pause();
    _pending ??= _position();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restore();
    });
  }

  // ---- The reading place.

  /// The top of the text, under the top bar.
  double get _textTop => (_topBar.currentContext?.size?.height ?? 0) + FrostGap.group;

  RenderBox? _box(int block) {
    final object = _blockKeys[block]?.currentContext?.findRenderObject();
    return object is RenderBox && object.attached && object.hasSize ? object : null;
  }

  double? _offsetOf(RenderBox box) => RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;

  void _scrolled() {
    if (!_scroll.hasClients) return;
    final top = _scroll.offset + _textTop;
    var block = _block;
    var best = double.negativeInfinity;
    for (final index in _blockKeys.keys) {
      final box = _box(index);
      if (box == null) continue;
      final offset = _offsetOf(box)!;
      if (offset <= top + 1 && offset > best) {
        best = offset;
        block = index;
      }
    }
    final measured = _measureProgress();
    if (block != _block || (measured - _progress).abs() > .001) {
      setState(() {
        _block = block;
        _progress = measured;
      });
    }
    if (_pending == null) _save();
  }

  NovelReadingPosition _position() {
    final box = _box(_block);
    final offset = box == null ? null : _offsetOf(box);
    final fraction = box == null || offset == null || box.size.height <= 0 ? 0.0 : ((_scroll.offset + _textTop - offset) / box.size.height).clamp(0.0, 1.0);
    final characters = novelTextBlockCharacterCount(_model.blocks.isEmpty ? const NovelTextPageBreak() : _model.blocks[_block]);
    return NovelReadingPosition(
      segmentIndex: currentChapter.index,
      textOffset: _model.offsetOf(_block) + (characters * fraction).round(),
      segmentFraction: progress,
      blockIndex: _block,
      blockFraction: fraction,
    );
  }

  /// How far through the text the reader is, 0 to 1, by the characters
  /// before the top of the screen; the end of the text is 1.
  double get progress => _progress;
  double _progress = 0;

  double _measureProgress() {
    if (_model.totalCharacters == 0) return 0;
    if (_scroll.hasClients && _scroll.position.hasContentDimensions && _scroll.offset >= _scroll.position.maxScrollExtent - .5) return 1;
    final box = _box(_block);
    final offset = box == null ? null : _offsetOf(box);
    final fraction = box == null || offset == null || box.size.height <= 0 || !_scroll.hasClients
        ? 0.0
        : ((_scroll.offset + _textTop - offset) / box.size.height).clamp(0.0, 1.0);
    final characters = novelTextBlockCharacterCount(_model.blocks[_block]);
    return ((_model.offsetOf(_block) + characters * fraction) / _model.totalCharacters).clamp(0.0, 1.0);
  }

  void _save() {
    if (_model.isEmpty) return;
    final position = _pending ?? _position();
    novelReadingSessions.writeState(context, position, identifier: novelReadingSessionKey(_novel.id, accountId: _sessionAccount));
  }

  void _restore() {
    final saved = _pending;
    if (saved == null) return;
    final block = saved.blockIndex >= 0 && saved.blockIndex < _model.blocks.length ? saved.blockIndex : _model.blockAtOffset(saved.textOffset);
    _jumpToBlock(block, fraction: saved.blockFraction, then: () => _pending = null);
  }

  /// Puts [block] (and [fraction] of it) at the top of the text. A block not
  /// built yet is first reached by its share of the text, then exactly.
  void _jumpToBlock(int block, {double fraction = 0, VoidCallback? then, int attempts = 4}) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final box = _box(block);
    if (box != null) {
      final target = _offsetOf(box)! + box.size.height * fraction - _textTop;
      _scroll.jumpTo(target.clamp(position.minScrollExtent, position.maxScrollExtent));
      setState(() => _block = block);
      then?.call();
      _save();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrolled();
      });
      return;
    }
    if (attempts == 0) {
      then?.call();
      return;
    }
    final share = _model.totalCharacters == 0 ? block / math.max(1, _model.blocks.length) : _model.offsetOf(block) / _model.totalCharacters;
    _scroll.jumpTo((position.maxScrollExtent * share).clamp(position.minScrollExtent, position.maxScrollExtent));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _jumpToBlock(block, fraction: fraction, then: then, attempts: attempts - 1);
    });
  }

  void goToChapter(int index) {
    if (_model.chapters.isEmpty) return;
    _pause();
    final chapter = _model.chapters[index.clamp(0, _model.chapters.length - 1)];
    _jumpToBlock(chapter.firstBlock);
  }

  /// Moves to the place [value] of the way through the text.
  void _jumpToProgress(double value) {
    _pause();
    final target = value * _model.totalCharacters;
    final block = _model.blockAtOffset(target.floor());
    final characters = novelTextBlockCharacterCount(_model.blocks[block]);
    final fraction = characters == 0 ? 0.0 : ((target - _model.offsetOf(block)) / characters).clamp(0.0, 1.0);
    _jumpToBlock(block, fraction: fraction);
  }

  /// Whether the bars are shown.
  bool get chromeVisible => _chromeVisible;

  void _scrollBy(double delta) {
    _userScrolled();
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final target = (position.pixels + delta).clamp(position.minScrollExtent, position.maxScrollExtent);
    final duration = FrostMotion.duration(context, FrostMotion.reveal);
    if (duration == Duration.zero) {
      _scroll.jumpTo(target);
    } else {
      unawaited(_scroll.animateTo(target, duration: duration, curve: Curves.easeOutCubic));
    }
  }

  /// A volume key: a screen on or back, keeping a little of the last one.
  void _turn(int direction) {
    if (!_volumeEnabled || !_controlsEligible || !_scroll.hasClients) return;
    _pause();
    _scrollBy(direction * math.max(1, _scroll.position.viewportDimension - _turnOverlap));
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
    } else if (_controlsEligible && !_model.isEmpty) {
      _clock.reset();
      setState(() => _autoScrolling = true);
      _ticker.start();
    }
  }

  /// Auto scroll runs on through the chapters and stops at the end.
  void _tick(Duration elapsed) {
    if (!_controlsEligible || !_scroll.hasClients || !_scroll.position.hasContentDimensions) {
      _pause();
      return;
    }
    if (_pending != null) {
      _clock.reset();
      return;
    }
    final position = _scroll.position;
    final distance = _clock.advance(elapsed, _speed);
    if (position.pixels >= position.maxScrollExtent - .5) {
      _pause();
      return;
    }
    _scroll.jumpTo(math.min(position.maxScrollExtent, position.pixels + distance));
  }

  void _userScrolled() {
    _pause();
    if (_chromeVisible) setState(() => _chromeVisible = false);
  }

  // ---- Settings.

  /// A new size or spacing keeps the reader's place.
  void _applySettings(ReaderSettings next) {
    final reflow = next.textSize != _fontSize || next.lineHeight != _lineHeight;
    if (reflow) {
      _pause();
      _pending ??= _position();
    }
    setState(() {
      _fontSize = next.textSize.clamp(readerFontSizes.min, readerFontSizes.max);
      _lineHeight = next.lineHeight.clamp(readerLineHeights.min, readerLineHeights.max);
      _speed = next.autoScrollSpeed;
      _volumeEnabled = next.volumeKeys;
    });
    _activityChanged();
    if (reflow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _restore();
      });
    }
  }

  void _settingsShown(bool open) {
    _settingsOpen = open;
    if (open) _pause();
    _activityChanged();
    if (!open && mounted) _keyboard.requestFocus();
  }

  // ---- Leaving and the keyboard.

  void _close() {
    _pause();
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppLocations.novel(_novel.id));
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (ModalRoute.of(context)?.isCurrent != true || appRootRouteActivity.popupOnTop || _settingsOpen) return KeyEventResult.ignored;
      if (_selectionActive) {
        _region.currentState?.clearSelection();
        _selectionActive = false;
        _activityChanged();
        return KeyEventResult.handled;
      }
      _close();
      return KeyEventResult.handled;
    }
    if (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (_previousChapterKeys.contains(key) || _nextChapterKeys.contains(key)) {
      // An empty text has no chapters to move between.
      if (_model.chapters.isEmpty) return KeyEventResult.ignored;
      goToChapter(currentChapter.index + (_previousChapterKeys.contains(key) ? -1 : 1));
    } else if (_scrollUpKeys.contains(key)) {
      _scrollBy(-_keyboardScrollExtent);
    } else if (_scrollDownKeys.contains(key)) {
      _scrollBy(_keyboardScrollExtent);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _selectionChanged(SelectedContent? content) {
    _selectionActive = content != null && content.plainText.isNotEmpty;
    if (_selectionActive) _pause();
    _activityChanged();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    ref.listen(readerSettingsProvider, (_, next) => _applySettings(next));
    // Follow the route being covered by another page.
    ModalRoute.isCurrentOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _activityChanged());
    final typesetting = ReaderTypesetting.of(context, size: _fontSize, spacing: _lineHeight);
    final padding = MediaQuery.paddingOf(context);
    final enabled = !_accountChanged;
    final chapters = _model.chapters;
    final chapter = chapters.isEmpty ? null : currentChapter;
    final body = _model.isEmpty
        ? Center(
            child: FrostEmptyState(icon: PivIcons.bookOpen, title: t.novel.reader.emptyBody),
          )
        : NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction != ScrollDirection.idle) _userScrolled();
              return false;
            },
            child: ReaderSelectableText(
              areaKey: _region,
              onSelectionChanged: _selectionChanged,
              child: _TapToToggle(
                onTap: () {
                  if (_selectionActive) return;
                  _keyboard.requestFocus();
                  setState(() => _chromeVisible = !_chromeVisible);
                },
                child: CustomScrollView(
                  controller: _scroll,
                  slivers: [
                    SliverPadding(padding: EdgeInsets.only(top: padding.top + _barExtent + FrostGap.group)),
                    FrostSliverContentColumn(
                      maxWidth: FrostMetrics.readingMaxWidth,
                      sliver: SliverList.builder(
                        itemCount: _model.blocks.length,
                        itemBuilder: (context, index) => KeyedSubtree(
                          key: _blockKeys.putIfAbsent(index, GlobalKey.new),
                          child: _ReaderBlock(block: _model.blocks[index], typesetting: typesetting, first: index == 0, novel: _novel),
                        ),
                      ),
                    ),
                    SliverPadding(padding: EdgeInsets.only(bottom: padding.bottom + _barExtent + FrostGap.section)),
                  ],
                ),
              ),
            ),
          );
    return Focus(
      focusNode: _keyboard,
      autofocus: true,
      onKeyEvent: _key,
      child: FrostSurface(
        role: FrostSurfaceRole.reading,
        child: Stack(
          children: [
            Positioned.fill(child: body),
            _Bar(
              key: _topBar,
              top: true,
              visible: _chromeVisible,
              child: Row(
                spacing: FrostGap.inline,
                children: [
                  FrostButton.icon(icon: PivIcons.arrowLeft, label: FrostScope.labelsOf(context).back, onPressed: _close),
                  Expanded(
                    child: FrostText(_novel.title, content: true, role: FrostTextRole.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (chapter != null && chapters.length > 1)
                    Flexible(
                      child: FrostTitleMenu(
                        key: const ValueKey('reader-chapters'),
                        title: t.novel.reader.chapterPosition(current: chapter.index + 1, total: chapters.length),
                        entries: [
                          for (final item in chapters)
                            FrostMenuAction(
                              item.title ?? t.novel.reader.chapterNumber(number: item.index + 1),
                              checked: item.index == chapter.index,
                              onSelected: enabled ? () => goToChapter(item.index) : null,
                            ),
                        ],
                      ),
                    ),
                  FrostPopover(
                    title: t.novel.reader.settings,
                    builder: (context, focusNode, toggle) => Focus(
                      focusNode: focusNode,
                      child: FrostButton.icon(
                        key: const ValueKey('reader-settings'),
                        icon: PivIcons.settings,
                        label: t.novel.reader.settings,
                        onPressed: enabled ? toggle : null,
                      ),
                    ),
                    contentBuilder: (context, close) =>
                        _ReaderSettingsPanel(volumeSupported: (widget.volumeKeys ?? ReaderVolumeKeys.instance).supported, onShown: _settingsShown),
                  ),
                ],
              ),
            ),
            _Bar(
              top: false,
              visible: _chromeVisible,
              child: Row(
                spacing: FrostGap.inline,
                children: [
                  FrostButton.icon(
                    icon: PivIcons.chevronLeft,
                    label: t.novel.reader.previousChapter,
                    onPressed: enabled && chapter != null && chapter.index > 0 ? () => goToChapter(chapter.index - 1) : null,
                  ),
                  Expanded(
                    child: FrostSlider(
                      key: const ValueKey('reader-progress'),
                      value: _progress,
                      onChanged: enabled ? _jumpToProgress : null,
                      semanticLabel: t.novel.reader.readingProgress,
                      valueLabel: (value) => t.novel.reader.progressValue(percent: (value * 100).round()),
                    ),
                  ),
                  FrostButton.icon(
                    icon: PivIcons.chevronRight,
                    label: t.novel.reader.nextChapter,
                    onPressed: enabled && chapter != null && chapter.index < chapters.length - 1 ? () => goToChapter(chapter.index + 1) : null,
                  ),
                  FrostButton.icon(
                    key: const ValueKey('reader-auto-scroll'),
                    icon: _autoScrolling ? PivIcons.pause : PivIcons.play,
                    label: _autoScrolling ? t.novel.reader.pauseAutoScroll : t.novel.reader.startAutoScroll,
                    selected: _autoScrolling,
                    onPressed: enabled && !_model.isEmpty ? _toggleAutoScroll : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The height of a bar's controls.
  double get _barExtent => FrostControlSize.regular.height(context) + FrostGap.related * 2;
}

/// A tap on the text, not a drag or a selection, shows or hides the bars.
class _TapToToggle extends StatefulWidget {
  const _TapToToggle({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_TapToToggle> createState() => _TapToToggleState();
}

class _TapToToggleState extends State<_TapToToggle> {
  /// Whether the tap landed on a block that keeps the bars ([_KeepsBars]).
  static bool _onKeepsBars(PointerEvent event) {
    final hit = HitTestResult();
    GestureBinding.instance.hitTestInView(hit, event.position, event.viewId);
    return hit.path.map((entry) => entry.target).whereType<RenderMetaData>().any((target) => identical(target.metaData, _KeepsBars.tag));
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
      if (_onKeepsBars(event)) return;
      widget.onTap();
    },
    onPointerCancel: (_) => _down = null,
    child: widget.child,
  );
}

/// A block whose taps act on itself (an illustration, an embedded work) and
/// leave the bars as they are.
class _KeepsBars extends StatelessWidget {
  const _KeepsBars({required this.child});

  static const tag = Object();

  final Widget child;

  @override
  Widget build(BuildContext context) => MetaData(metaData: tag, child: child);
}

/// A bar over the text, at the top or the bottom, sliding away when hidden.
class _Bar extends StatelessWidget {
  const _Bar({required this.top, required this.visible, required this.child, super.key});

  final bool top;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = FrostMotion.duration(context, FrostMotion.reveal);
    final bar = FrostSurface(
      role: FrostSurfaceRole.chrome,
      child: SafeArea(
        top: top,
        bottom: !top,
        child: FrostContentColumn(
          maxWidth: FrostMetrics.readingMaxWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
            child: child,
          ),
        ),
      ),
    );
    return Positioned(
      left: 0,
      right: 0,
      top: top ? 0 : null,
      bottom: top ? null : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: ExcludeFocus(
          excluding: !visible,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : Offset(0, top ? -1 : 1),
            duration: duration,
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(opacity: visible ? 1 : 0, duration: duration, child: bar),
          ),
        ),
      ),
    );
  }
}

/// One block of the text: a paragraph, a chapter title, a page break or an
/// illustration (or the way to the work it shows).
class _ReaderBlock extends ConsumerWidget {
  const _ReaderBlock({required this.block, required this.typesetting, required this.first, required this.novel});

  final NovelTextBlock block;
  final ReaderTypesetting typesetting;
  final bool first;
  final Novel novel;

  /// Illustrations keep this shape until theirs is known.
  static const _imageRatio = 4 / 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return switch (block) {
      NovelTextParagraph(:final text) => ReaderParagraph(text: text, typesetting: typesetting),
      NovelTextChapter(:final title) => ReaderChapterTitle(title: title, typesetting: typesetting, first: first),
      // The paragraph above already ends with the gap.
      NovelTextPageBreak() => Padding(
        padding: EdgeInsets.only(bottom: typesetting.paragraphGap),
        child: const FrostDivider(),
      ),
      // Taps on an illustration or its button act on it, not on the bars.
      NovelTextImage(:final id, :final isPixivWork, :final url) => _KeepsBars(
        child: Padding(
          padding: EdgeInsets.only(bottom: typesetting.paragraphGap),
          child: switch ((url, isPixivWork ? int.tryParse(id.split('-').first) : null)) {
            (final url?, _) => FrostContextMenuRegion(
              entries: contentImageMenu(context, ref.read(rustMediaTransportProvider), url: url, title: novel.title),
              child: Semantics(
                button: true,
                image: true,
                label: t.novel.detail.images,
                child: FrostClickSurface(
                  shape: FrostClickShape.rounded(BorderRadius.circular(FrostRadius.lg)),
                  onTap: () => unawaited(
                    GoRouter.of(context).push(
                      AppRoute.originalImageViewer.path,
                      extra: OriginalImageViewerArgs(
                        title: novel.title,
                        source: DownloadSourceScope.of(context),
                        pages: [OriginalImagePage(url: url, previewUrl: url, downloadOrigin: DownloadOrigin.ofImageUrl(Uri.parse(url)))],
                      ),
                    ),
                  ),
                  child: AppPixivImage(url: url, aspectRatio: _imageRatio, fit: BoxFit.contain),
                ),
              ),
            ),
            (null, final work?) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: FrostButton.outlined(
                label: t.novel.reader.openEmbeddedWork,
                icon: PivIcons.externalLink,
                onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.illust(work))),
              ),
            ),
            _ => FrostText(t.novel.reader.embeddedImageUnavailable, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
          },
        ),
      ),
    };
  }
}

/// Size, spacing, scroll speed and the volume keys, kept as they change,
/// and the keyboard's keys. Opening it pauses auto scroll.
class _ReaderSettingsPanel extends ConsumerStatefulWidget {
  const _ReaderSettingsPanel({required this.volumeSupported, required this.onShown});

  final bool volumeSupported;
  final ValueChanged<bool> onShown;

  @override
  ConsumerState<_ReaderSettingsPanel> createState() => _ReaderSettingsPanelState();
}

class _ReaderSettingsPanelState extends ConsumerState<_ReaderSettingsPanel> {
  late final ValueChanged<bool> _shown = widget.onShown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _shown(true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _shown(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.novel.reader;
    final settings = ref.watch(readerSettingsProvider);
    final notifier = ref.read(readerSettingsProvider.notifier);
    Widget slider({
      required Key key,
      required String label,
      required double value,
      required ({double min, double max}) range,
      required int divisions,
      required String Function(double) text,
      required ValueChanged<double> onChanged,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.inline,
      children: [
        FrostText(label),
        FrostSlider(
          key: key,
          value: value.clamp(range.min, range.max),
          min: range.min,
          max: range.max,
          divisions: divisions,
          semanticLabel: label,
          valueLabel: text,
          onChanged: onChanged,
        ),
      ],
    );
    return FrostFormSection(
      children: [
        slider(
          key: const ValueKey('reader-font-size'),
          label: t.fontSize,
          value: settings.textSize,
          range: readerFontSizes,
          divisions: (readerFontSizes.max - readerFontSizes.min).round(),
          text: (value) => '${value.round()}',
          onChanged: notifier.setTextSize,
        ),
        slider(
          key: const ValueKey('reader-line-height'),
          label: t.lineHeight,
          value: settings.lineHeight,
          range: readerLineHeights,
          divisions: ((readerLineHeights.max - readerLineHeights.min) / .05).round(),
          text: (value) => value.toStringAsFixed(2),
          onChanged: notifier.setLineHeight,
        ),
        slider(
          key: const ValueKey('reader-scroll-speed'),
          label: t.autoScrollSpeed,
          value: settings.autoScrollSpeed,
          range: readerScrollSpeeds,
          divisions: ((readerScrollSpeeds.max - readerScrollSpeeds.min) / 6).round(),
          text: (value) => t.scrollSpeedValue(speed: value.round()),
          onChanged: notifier.setAutoScrollSpeed,
        ),
        if (widget.volumeSupported)
          FrostListRow.toggle(title: t.volumeKeys, subtitle: FrostRowSubtitle(t.volumeKeysHelp), value: settings.volumeKeys, onChanged: notifier.setVolumeKeys),
        FrostText(t.shortcutsHelp, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
      ],
    );
  }
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
