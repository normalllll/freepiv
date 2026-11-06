import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_reader_slivers.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reader_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_ui/frost_ui.dart';

const _novel = Novel(
  id: 7,
  title: 'A novel',
  caption: 'From the details',
  restrict: 0,
  xRestrict: 0,
  isOriginal: false,
  imageUrls: ImageUrls(squareMedium: '', medium: '', large: ''),
  createDate: '',
  tags: [],
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

const _text = WebviewNovel(
  id: '7',
  title: 'A novel',
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

Widget _reader() => ProviderScope(
  child: TranslationProvider(
    child: FrostScope(
      config: freepivFrostConfig,
      child: MaterialApp(
        theme: AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en', 'US')),
        home: const NovelReaderContent(
          detail: NovelDetailData(novel: _novel, webviewNovel: _text),
        ),
      ),
    ),
  ),
);

Iterable<TextStyle?> _paragraphStyles(WidgetTester tester) =>
    tester.widgetList<NovelReaderBlockView>(find.byType(NovelReaderBlockView)).map((view) => view.paragraphStyle);

void main() {
  testWidgets('reopening a novel keeps the persisted text size and spacing, not those it was last read with', (tester) async {
    await AppSettings.initialize(store: SampleSettingsStore({'readerFontSize': 18.0, 'readerLineHeight': 1.6}));
    await tester.pumpWidget(_reader());
    await tester.pumpAndSettle();
    expect(_paragraphStyles(tester), isNotEmpty);
    expect(_paragraphStyles(tester).map((style) => (style?.fontSize, style?.height)), everyElement((18.0, 1.6)));
    await tester.pumpWidget(const SizedBox());

    // Changed elsewhere (another novel, the settings page) in the meantime.
    await AppSettings.initialize(store: SampleSettingsStore({'readerFontSize': 24.0, 'readerLineHeight': 2.0}));
    await tester.pumpWidget(_reader());
    await tester.pumpAndSettle();
    expect(_paragraphStyles(tester).map((style) => (style?.fontSize, style?.height)), everyElement((24.0, 2.0)));
  });
}
