import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_header.dart';
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

class _Text extends NovelText {
  _Text(this.results);

  /// What each load returns, in turn; an [Exception] fails it.
  final List<Object> results;
  int loads = 0;

  @override
  Future<WebviewNovel> build(int novelId) async => _next();

  Future<WebviewNovel> _next() async {
    final result = results[(loads++).clamp(0, results.length - 1)];
    if (result is Exception) throw result;
    return result as WebviewNovel;
  }

  @override
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_next);
  }
}

Widget _host(_Text text) => ProviderScope(
  retry: (_, _) => null,
  overrides: [novelTextProvider.overrideWith2((_) => text)],
  child: TranslationProvider(
    child: FrostScope(
      config: freepivFrostConfig,
      child: MaterialApp(
        theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en', 'US')),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Consumer(
              builder: (context, ref, _) => NovelHeader(novel: _novel, webviewNovel: ref.watch(novelTextProvider(7)).value, onStartReading: () {}),
            ),
          ),
        ),
      ),
    ),
  ),
);

FilledButton _readButton(WidgetTester tester) => tester.widget<FilledButton>(find.byWidgetPredicate((widget) => widget is FilledButton));

void main() {
  testWidgets('a failed text leaves the details on the page, with reading off and a retry', (tester) async {
    final text = _Text([Exception('text unavailable'), _text]);
    await tester.pumpWidget(_host(text));
    await tester.pumpAndSettle();
    expect(find.text('A novel'), findsWidgets, reason: 'the details show without the text');
    expect(find.text('The text couldn\'t load'), findsOneWidget);
    expect(_readButton(tester).onPressed, isNull);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(text.loads, 2);
    expect(find.text('The text couldn\'t load'), findsNothing);
    expect(_readButton(tester).onPressed, isNotNull);
  });

  testWidgets('reading is off until the text arrives', (tester) async {
    await tester.pumpWidget(_host(_Text([_text])));
    expect(_readButton(tester).onPressed, isNull);
    await tester.pumpAndSettle();
    expect(_readButton(tester).onPressed, isNotNull);
  });
}
