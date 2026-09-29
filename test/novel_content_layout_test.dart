import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme.dart';
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
