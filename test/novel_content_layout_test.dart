import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:flutter/gestures.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/core/platform/reader_volume_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_header.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reader_page.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/shared/widgets/novel_previewer.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

const _novel = Novel(
  id: 7,
  title: 'A longer novel title that wraps on a narrow screen',
  caption: '<p>A real introduction<br>with another line.</p>',
  restrict: 0,
  xRestrict: 0,
  isOriginal: false,
  imageUrls: ImageUrls(squareMedium: '', medium: '', large: ''),
  createDate: '',
  tags: [
    Tag(name: 'fantasy', translatedName: 'fantasy'),
    Tag(name: 'story', translatedName: 'Story'),
    Tag(name: 'extra'),
  ],
  pageCount: 2,
  textLength: 1200,
  user: User(
    id: 2,
    name: 'Author name',
    account: 'author',
    profileImageUrls: ProfileImageUrls(medium: ''),
  ),
  series: Series(),
  totalBookmarks: 12,
  isBookmarked: false,
  totalView: 30,
  visible: true,
  totalComments: 0,
  isMuted: false,
  isMypixivOnly: false,
  isXRestricted: false,
  novelAiType: 0,
);

const _webviewNovel = WebviewNovel(
  id: '7',
  title: 'A longer novel title that wraps on a narrow screen',
  userId: '2',
  coverUrl: '',
  tags: [],
  caption: '',
  cdate: '',
  rating: NovelRating(like: 0, bookmark: 12, view: 30),
  text: 'Paragraph to read.',
  illusts: [],
  images: [],
  glossaryItems: [],
  replaceableItemIds: [],
  aiType: 0,
  isOriginal: false,
);

Widget _host(Widget child, {double textScale = 1}) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en', 'US')),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ),
);

void main() {
  testWidgets('novel tile keeps real summary, separate rank and original tag', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const NovelPreviewer(novel: _novel, rank: 3), textScale: 2));
    await tester.pump();

    expect(find.textContaining('A real introduction with another line.'), findsOneWidget);
    expect(find.text('#3'), findsOneWidget);
    expect(find.textContaining('#fantasy · fantasy'), findsNothing);
    expect(find.textContaining('#fantasy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('coverless narrow detail keeps reading action before supporting content', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const NovelHeader(novel: _novel, webviewNovel: _webviewNovel, onStartReading: _noop)));
    await tester.pump();

    expect(find.byType(LargeNovelCoverImage), findsNothing);
    expect(find.byType(NovelCaptionBox), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Escape closes settings before returning to the same novel detail', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en', 'US')),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NovelReaderContent(
                      detail: NovelDetailData(novel: _novel, webviewNovel: _webviewNovel),
                    ),
                  ),
                ),
                child: const Text('Open reader from novel 7'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open reader from novel 7'));
    await tester.pumpAndSettle();
    expect(find.byType(NovelReaderContent), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(NovelReaderContent), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(NovelReaderContent), findsNothing);
    expect(find.text('Open reader from novel 7'), findsOneWidget);
  });

  testWidgets('font reflow keeps the current paragraph near its reading position', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final paragraphs = List.generate(8, (index) => 'Paragraph $index ${'reading words ' * 14}').join('\n\n');
    final detail = NovelDetailData(novel: _novel, webviewNovel: _webviewWithText(paragraphs));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en', 'US')),
          home: NovelReaderContent(detail: detail),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paragraph = find.textContaining('Paragraph 4');
    final scroll = Scrollable.ensureVisible(tester.element(paragraph), alignment: 0.15, duration: const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    await scroll;
    final before = tester.getTopLeft(paragraph).dy;

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect((tester.getTopLeft(paragraph).dy - before).abs(), lessThan(80));
    expect(tester.takeException(), isNull);
  });

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('single $kind tap on body text toggles chrome without selecting or moving content', (tester) async {
      const text = 'Click this readable paragraph to show or hide the reading controls.';
      await tester.pumpWidget(_readerHost(text));
      await tester.pumpAndSettle();
      final point = tester.getTopLeft(find.text(text)) + const Offset(20, 12);
      final before = tester.getTopLeft(find.text(text));
      await tester.tapAt(point, kind: kind);
      await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Reading settings').hitTestable(), findsNothing);
      expect(tester.getTopLeft(find.text(text)), before);
      final selection = tester.state<SelectionAreaState>(find.byType(SelectionArea)).selectableRegion;
      expect(selection.contextMenuButtonItems.any((item) => item.type == ContextMenuButtonType.copy), false);
      await tester.tapAt(point, kind: kind);
      await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Reading settings').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('double click, long press and mouse drag select body text without hiding chrome', (tester) async {
    const text = 'Select this paragraph using the normal text selection gestures.';
    await tester.pumpWidget(_readerHost(text));
    await tester.pumpAndSettle();
    final point = tester.getTopLeft(find.text(text)) + const Offset(20, 12);
    final selection = tester.state<SelectionAreaState>(find.byType(SelectionArea)).selectableRegion;
    await tester.tapAt(point, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(point, kind: PointerDeviceKind.mouse);
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(selection.contextMenuButtonItems.any((item) => item.type == ContextMenuButtonType.copy), true);
    expect(find.byTooltip('Reading settings').hitTestable(), findsOneWidget);
    selection.hideToolbar();
    selection.clearSelection();
    await tester.pumpAndSettle();
    await tester.longPressAt(point);
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(selection.contextMenuButtonItems.any((item) => item.type == ContextMenuButtonType.copy), true);
    expect(find.byTooltip('Reading settings').hitTestable(), findsOneWidget);
    selection.hideToolbar();
    selection.clearSelection();
    await tester.pumpAndSettle();
    final drag = await tester.startGesture(point, kind: PointerDeviceKind.mouse);
    await drag.moveBy(const Offset(120, 0));
    await tester.pump();
    await drag.up();
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(selection.contextMenuButtonItems.any((item) => item.type == ContextMenuButtonType.copy), true);
    expect(find.byTooltip('Reading settings').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reader back control uses shell ownership and mobile back action', (tester) async {
    final reselection = ValueNotifier<({int index, int sequence})>((index: 0, sequence: 0));
    addTearDown(reselection.dispose);
    var returned = 0;
    Widget shellHost(bool desktop) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en', 'US')),
        home: FrostShellNavigationScope(
          ownsBackControl: desktop,
          canGoBack: true,
          goBack: () => returned++,
          primaryReselection: reselection,
          child: NovelReaderContent(
            detail: NovelDetailData(novel: _novel, webviewNovel: _webviewNovel),
          ),
        ),
      ),
    );
    await tester.pumpWidget(shellHost(true));
    await tester.pumpAndSettle();
    expect(find.byType(FrostCompactBackButton), findsNothing);
    await tester.pumpWidget(shellHost(false));
    await tester.pumpAndSettle();
    expect(find.byType(FrostCompactBackButton), findsOneWidget);
    await tester.tap(find.byType(FrostCompactBackButton));
    expect(returned, 1);
  });

  testWidgets('visible auto scroll switch continues as soon as a scrollable segment reaches its bottom', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_readerHost('Long reading ${'words ' * 180}[newpage]Final section.'));
    await tester.pumpAndSettle();
    expect(find.text('Auto scroll'), findsOneWidget);
    final toggle = find.byType(FrostSwitch);
    expect(tester.widget<FrostSwitch>(toggle).value, false);
    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first).controller!;
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<FrostSwitch>(toggle).value, true);
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('2 / 2 pages'), findsOneWidget);
    await tester.pump();
    expect(tester.widget<FrostSwitch>(toggle).value, false);
    expect(find.text('Final section.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auto scroll label and switch remain reachable in every language with enlarged text', (tester) async {
    for (final (family, asset) in [('Noto Sans SC', 'assets/fonts/NotoSansSC-Subset.ttf'), ('Noto Sans JP', 'assets/fonts/NotoSansJP-Subset.ttf')]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.enUs));
    for (final locale in AppLocale.values) {
      await tester.runAsync(() => LocaleSettings.setLocale(locale));
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light(platform: TargetPlatform.android, locale: locale.flutterLocale),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const NovelReaderContent(
                detail: NovelDetailData(novel: _novel, webviewNovel: _webviewNovel),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.novel.reader.autoScroll).hitTestable(), findsOneWidget, reason: '$locale scale $scale');
        expect(find.byType(FrostSwitch).hitTestable(), findsOneWidget, reason: '$locale scale $scale');
        expect(tester.takeException(), isNull, reason: '$locale scale $scale');
      }
    }
  });

  testWidgets('automatic scroll starts explicitly and pauses on settings and background', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_readerHost('Automatic reading ${'words ' * 500}'));
    await tester.pumpAndSettle();
    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first).controller!;
    final initial = scroll.offset;
    await tester.pump(const Duration(seconds: 1));
    expect(scroll.offset, initial);
    await tester.tap(find.byTooltip('Start auto scroll'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(scroll.offset, greaterThan(initial));
    await tester.tap(find.byTooltip('Reading settings'));
    await tester.pumpAndSettle();
    final paused = scroll.offset;
    await tester.pump(const Duration(seconds: 1));
    expect(scroll.offset, paused);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Start auto scroll'), findsOneWidget);
    await tester.tap(find.byTooltip('Start auto scroll'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final background = scroll.offset;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(scroll.offset, background);
    expect(find.byTooltip('Start auto scroll'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('automatic scroll keeps short segments for a screen of reading time then stops at final end', (tester) async {
    await tester.pumpWidget(_readerHost('First.[newpage]Second.[newpage]Last.'));
    await tester.pumpAndSettle();
    final screenHeight = tester.getSize(find.byType(SingleChildScrollView).first).height;
    final screenReadingTime = Duration(microseconds: (screenHeight / 36 * Duration.microsecondsPerSecond).ceil());
    await tester.tap(find.byTooltip('Start auto scroll'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1 / 3 pages'), findsOneWidget);
    await tester.pump(screenReadingTime - const Duration(seconds: 1) - const Duration(milliseconds: 1));
    expect(find.text('1 / 3 pages'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2));
    expect(find.text('2 / 3 pages'), findsOneWidget);
    await tester.pump();
    await tester.pump(screenReadingTime - const Duration(milliseconds: 1));
    expect(find.text('2 / 3 pages'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2));
    expect(find.text('3 / 3 pages'), findsOneWidget);
    await tester.pump();
    expect(find.byTooltip('Start auto scroll'), findsOneWidget);
    expect(find.text('3 / 3 pages'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}

WebviewNovel _webviewWithText(String text) => WebviewNovel(
  id: '7',
  title: _novel.title,
  userId: '2',
  coverUrl: '',
  tags: const [],
  caption: '',
  cdate: '',
  rating: const NovelRating(like: 0, bookmark: 12, view: 30),
  text: text,
  illusts: const [],
  images: const [],
  glossaryItems: const [],
  replaceableItemIds: const [],
  aiType: 0,
  isOriginal: false,
);

Widget _readerHost(String text, {ReaderVolumeKeys? volumeKeys, bool reducedMotion = false}) => ProviderScope(
  child: FrostScope(
    config: freepivFrostConfig,
    child: MaterialApp(
      theme: AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en', 'US')),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: NovelReaderContent(
        detail: NovelDetailData(novel: _novel, webviewNovel: _webviewWithText(text)),
        volumeKeys: volumeKeys,
      ),
    ),
  ),
);
