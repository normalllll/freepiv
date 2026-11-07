import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/comments/presentation/comment_thread_item.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/detail/novel_detail_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

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

class _Detail extends NovelDetail {
  _Detail(this.load);

  final Future<Novel> Function() load;

  @override
  FutureOr<Novel> build(NovelDetailArgs args) => load();
}

class _FailingComments extends NovelComments {
  @override
  Future<CommentPageResult> build(int novelId) async => throw StateError('offline');
}

Novel _named(String text) => Novel(
  id: 7,
  title: text,
  caption: text,
  restrict: 0,
  xRestrict: 0,
  isOriginal: false,
  imageUrls: _novel.imageUrls,
  createDate: '',
  tags: [Tag(name: text, translatedName: text)],
  pageCount: 2,
  textLength: 1200,
  user: User(
    id: 2,
    name: text,
    account: text,
    profileImageUrls: const ProfileImageUrls(medium: ''),
  ),
  series: Series(id: 1, title: text),
  totalBookmarks: 12,
  isBookmarked: false,
  totalView: 30,
  visible: true,
  totalComments: 4,
  isMuted: false,
  isMypixivOnly: false,
  isXRestricted: false,
  novelAiType: 0,
);

Future<void> _mount(WidgetTester tester, {Novel? novel, int? id, Map<Object, Override> overrides = const {}, Size size = desktopSize, double textScale = 1}) =>
    mountPilotPage(
      tester,
      NovelDetailPage(novel: novel, novelId: id),
      overrides: overrides,
      size: size,
      textScale: textScale,
    );

FrostButton _read(WidgetTester tester) =>
    tester.widgetList<FrostButton>(find.byType(FrostButton)).firstWhere((button) => button.label == t.novel.detail.startReading);

void main() {
  testWidgets('a failed text leaves the details on the page, with reading off and a retry', (tester) async {
    final text = _Text([Exception('text unavailable'), _text]);
    await _mount(tester, novel: _novel, overrides: {novelTextProvider: novelTextProvider.overrideWith2((_) => text)});
    expect(find.text('A novel'), findsWidgets, reason: 'the details show without the text');
    expect(find.text(t.novelText.loadFailed), findsOneWidget);
    expect(_read(tester).onPressed, isNull);

    await tester.tap(find.text(t.common.retry).first);
    await settlePilot(tester);
    expect(text.loads, 2);
    expect(find.text(t.novelText.loadFailed), findsNothing);
    expect(_read(tester).onPressed, isNotNull);
  });

  testWidgets('loading: a novel known only by its id shows the head at its size', (tester) async {
    final never = Completer<Novel>();
    await _mount(tester, id: 7, overrides: {novelDetailProvider: novelDetailProvider.overrideWith2((_) => _Detail(() => never.future))});
    expect(find.byType(FrostMediaFrame), findsWidgets);
    expect(find.text(t.novel.detail.startReading), findsNothing);
  });

  testWidgets('error: a failed load offers a retry; a missing novel says so', (tester) async {
    await _mount(tester, id: 7, overrides: {novelDetailProvider: novelDetailProvider.overrideWith2((_) => _Detail(() async => throw StateError('offline')))});
    expect(find.byType(FrostErrorContent), findsOneWidget);
    await _mount(
      tester,
      id: 8,
      overrides: {
        novelDetailProvider: novelDetailProvider.overrideWith2(
          (_) => _Detail(() async => throw const PixivError(kind: PixivErrorKind.httpStatus, status: 404, message: 'gone')),
        ),
      },
    );
    expect(find.byType(AppPageError), findsOneWidget);
    expect(find.text(t.novelDetail.missing), findsOneWidget);
  });

  testWidgets('partial failure: comments that fail retry in place while the rest shows', (tester) async {
    await _mount(tester, novel: _novel, overrides: {novelCommentsProvider: novelCommentsProvider.overrideWith2((_) => _FailingComments())});
    await tester.scrollUntilVisible(find.byType(AppCommentsPreview), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text(t.illust.comments.failed), findsOneWidget);
    expect(_read(tester).onPressed, isNotNull);
  });

  testWidgets('a long title does not push the reading button away, at double text size on a phone', (tester) async {
    await _mount(tester, novel: _named(longText), size: phoneSize, textScale: 2);
    await tester.scrollUntilVisible(find.text(t.novel.detail.startReading), 200, scrollable: find.byType(Scrollable).first);
    expectNoLayoutErrors(tester);
  });

  test('the novel strings exist in all four languages', () => expectLocalesComplete(['novelDetail', 'novel', 'novelText']));
}
