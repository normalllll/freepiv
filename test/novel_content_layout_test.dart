import 'package:freepiv/app/frost_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/shared/widgets/novel_previewer.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

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


}
