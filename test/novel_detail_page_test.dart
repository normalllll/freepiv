import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/dev/sample_data.dart' show sampleComments, sampleNovels;
import 'package:freepiv/dev/sample_images.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/features/novel/domain/reading_time.dart';
import 'package:freepiv/features/series/logic.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_about.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_author_novels.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_series_block.dart';
import 'package:freepiv/features/novel/logic/novel_series_progress.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_actions.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_head.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_illustrations.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
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

Future<void> _mount(
  WidgetTester tester, {
  Novel? novel,
  int? id,
  Map<Object, Override> overrides = const {},
  Size size = desktopSize,
  double textScale = 1,
  Future<void> Function(HistoryRepository history)? seedHistory,
}) => mountPilotPage(
  tester,
  NovelDetailPage(novel: novel, novelId: id),
  overrides: overrides,
  size: size,
  textScale: textScale,
  seedHistory: seedHistory,
);

FrostButton _read(WidgetTester tester) =>
    tester.widgetList<FrostButton>(find.byType(FrostButton)).firstWhere((button) => button.label == t.novel.detail.startReading);

Novel _make({
  int id = 7,
  String title = 'A novel',
  String authorName = 'Author name',
  int xRestrict = 0,
  int aiType = 0,
  bool isOriginal = false,
  int textLength = 1200,
  int pageCount = 2,
  String createDate = '',
  Series series = const Series(),
  ImageUrls? imageUrls,
}) => Novel(
  id: id,
  title: title,
  caption: 'From the details',
  restrict: 0,
  xRestrict: xRestrict,
  isOriginal: isOriginal,
  imageUrls: imageUrls ?? _novel.imageUrls,
  createDate: createDate,
  tags: const [],
  pageCount: pageCount,
  textLength: textLength,
  user: User(
    id: 2,
    name: authorName,
    account: 'author',
    profileImageUrls: const ProfileImageUrls(medium: ''),
  ),
  series: series,
  totalBookmarks: 12345,
  isBookmarked: false,
  totalView: 30,
  visible: true,
  totalComments: 0,
  isMuted: false,
  isMypixivOnly: false,
  isXRestricted: false,
  novelAiType: aiType,
);

/// The text with chapters, two uploaded pictures of known proportions and one
/// embedded work, in that order.
WebviewNovel _illustrated({String? language, String cover = ''}) => WebviewNovel(
  id: '7',
  title: 'A novel',
  userId: '2',
  coverUrl: cover,
  tags: const [],
  caption: '',
  cdate: '',
  rating: const NovelRating(like: 0, bookmark: 12, view: 30),
  text: 'Opening\n[chapter:One]\n[uploadedimage:1]\nBody\n[pixivimage:9001]\n[chapter:Two]\n[uploadedimage:2]\nMore',
  illusts: [
    WebviewNovelEmbeddedWork(
      key: '9001',
      illustId: 9001,
      page: 1,
      visible: true,
      title: 'Lanterns',
      xRestrict: 0,
      userId: '2',
      userName: 'Author name',
      imageMedium: sampleImageUrl(3, width: 300, height: 400),
      imageOriginal: sampleImageUrl(3, width: 900, height: 1200),
    ),
  ],
  images: [
    for (final (index, (width, height)) in [(240, 135), (240, 480)].indexed)
      WebviewNovelImage(
        novelImageId: '${index + 1}',
        urls: WebviewNovelImageUrls(
          size240Mw: sampleImageUrl(10 + index, width: width, height: height),
          size480Mw: sampleImageUrl(10 + index, width: 480, height: height * 2),
          original: sampleImageUrl(10 + index, width: 1200, height: height * 5),
        ),
      ),
  ],
  glossaryItems: const [],
  replaceableItemIds: const [],
  aiType: 0,
  isOriginal: false,
  language: language,
);

class _PendingText extends NovelText {
  @override
  Future<WebviewNovel> build(int novelId) => Completer<WebviewNovel>().future;
}

class _SeriesSource extends NovelSeriesSource {
  _SeriesSource({required super.seriesId, required this.pages});

  /// What each load returns, in turn; an [Exception] fails it.
  final List<Object> pages;
  int loads = 0;

  @override
  Future<NovelSeriesPageResult> fetchFirstPage() async {
    final page = pages[(loads++).clamp(0, pages.length - 1)];
    if (page is Exception) throw page;
    return page as NovelSeriesPageResult;
  }
}

class _Series extends NovelSeriesWorks {
  _Series(this.pages);

  final List<Object> pages;
  late final _SeriesSource source = _SeriesSource(seriesId: 500, pages: pages);

  @override
  NovelSeriesSource build(int seriesId) => source;
}

/// A series of [titles] (works 1000, 1001, …) as its first page, of [total]
/// works in all.
NovelSeriesPageResult _seriesPage(List<String> titles, {required int total, bool concluded = false}) {
  final works = [
    for (final (index, title) in titles.indexed)
      _make(
        id: 1000 + index,
        title: title,
        series: const Series(id: 500, title: 'The series'),
      ),
  ];
  return NovelSeriesPageResult(
    novelSeriesDetail: NovelSeriesDetail(
      id: 500,
      title: 'The series',
      caption: '',
      isOriginal: true,
      isConcluded: concluded,
      contentCount: total,
      totalCharacterCount: 0,
      displayText: '',
      novelAiType: 0,
      watchlistAdded: false,
      user: works.first.user,
    ),
    novels: works,
  );
}

Map<Object, Override> _seriesOverride(List<Object> pages) => {novelSeriesWorksProvider: novelSeriesWorksProvider.overrideWith2((_) => _Series(pages))};

/// A novel of the series 500 with a title made from its id.
Novel _inSeries(int id) => _make(
  id: id,
  title: 'Work $id',
  series: const Series(id: 500, title: 'The series'),
);

List<FrostKeyValue> _facts(WidgetTester tester) => tester.widget<FrostKeyValueList>(find.byType(FrostKeyValueList)).entries;

String? _fact(WidgetTester tester, String label) => _facts(tester).where((entry) => entry.label == label).map((entry) => entry.value).firstOrNull;

Finder _titleText(String title) => find.descendant(of: find.byType(NovelTitleBlock), matching: find.text(title));

/// Sections that load on their own, each held until its completer completes.
class _GatedText extends NovelText {
  _GatedText(this.result);

  final Future<WebviewNovel> result;

  @override
  Future<WebviewNovel> build(int novelId) => result;
}

class _GatedSeriesSource extends NovelSeriesSource {
  _GatedSeriesSource(this.page) : super(seriesId: 500);

  final Future<NovelSeriesPageResult> page;

  @override
  Future<NovelSeriesPageResult> fetchFirstPage() => page;
}

class _GatedSeries extends NovelSeriesWorks {
  _GatedSeries(this.page);

  final Future<NovelSeriesPageResult> page;

  @override
  NovelSeriesSource build(int seriesId) => _GatedSeriesSource(page);
}

class _GatedComments extends NovelComments {
  _GatedComments(this.page);

  final Future<CommentPageResult> page;

  @override
  Future<CommentPageResult> build(int novelId) => page;
}

class _GatedUserWorks extends NovelUserWorks {
  _GatedUserWorks(this.page);

  final Future<NovelPageResult> page;

  @override
  Future<NovelPageResult> build(int userId) => page;
}

class _GatedRelatedSource extends NovelRelatedListSource {
  _GatedRelatedSource(this.page, {required super.novelId});

  final Future<NovelPageResult> page;

  @override
  Future<NovelPageResult> loadFirstPage() => page;

  @override
  Future<NovelPageResult> loadNextPage(String nextUrl) async => const NovelPageResult(novels: [], rankingNovels: []);
}

class _GatedRelated extends NovelRelatedWorks {
  _GatedRelated(this.page);

  final Future<NovelPageResult> page;

  @override
  NovelRelatedListSource build(int novelId) {
    final source = _GatedRelatedSource(page, novelId: novelId);
    ref.onDispose(source.dispose);
    return source;
  }
}

/// What each section loads, with the one named [gated] held until [release].
class _Sections {
  _Sections({this.gated, this.cover = ''}) {
    if (gated != null) _gate = Completer<void>();
  }

  final String? gated;

  /// The cover address the text brings, when it differs from the novel's own.
  final String cover;
  Completer<void>? _gate;

  Future<T> _load<T>(String name, T value) => gated == name ? _gate!.future.then((_) => value) : Future.value(value);

  void release() => _gate?.complete();

  Map<Object, Override> overrides() {
    final works = [for (var i = 0; i < 9; i++) 'Work ${1000 + i}'];
    final seriesPage = _seriesPage(works, total: 9);
    final comments = CommentPageResult(comments: sampleComments(count: 4));
    final userWorks = NovelPageResult(novels: sampleNovels(count: 5), rankingNovels: const []);
    final related = NovelPageResult(novels: sampleNovels(count: 6), rankingNovels: const []);
    return {
      novelTextProvider: novelTextProvider.overrideWith2((_) => _GatedText(_load('text', _illustrated(cover: cover)))),
      novelSeriesWorksProvider: novelSeriesWorksProvider.overrideWith2((_) => _GatedSeries(_load('series', seriesPage))),
      novelCommentsProvider: novelCommentsProvider.overrideWith2((_) => _GatedComments(_load('comments', comments))),
      novelUserWorksProvider: novelUserWorksProvider.overrideWith2((_) => _GatedUserWorks(_load('author', userWorks))),
      novelRelatedWorksProvider: novelRelatedWorksProvider.overrideWith2((_) => _GatedRelated(_load('related', related))),
      novelBatchReadingProgressProvider: novelBatchReadingProgressProvider.overrideWith(
        (ref, batch) => _load<Map<int, ReadingProgress>>('progress', {
          for (final id in batch.ids.take(3)) id: ReadingProgress(offset: 400, totalLength: 1000, updatedAt: DateTime.utc(2026, 11, 1)),
        }),
      ),
    };
  }
}

/// Where each section of the page is, by name, top to bottom.
Map<String, Rect> _sections(WidgetTester tester) {
  Rect? rect(Finder finder) => finder.evaluate().isEmpty ? null : tester.getRect(finder.first);
  Rect? union(List<Finder> finders) {
    final rects = [for (final f in finders) ?rect(f)];
    return rects.isEmpty ? null : rects.reduce((a, b) => a.expandToInclude(b));
  }

  final all = <String, Rect?>{
    'head': union([find.byType(NovelCover), find.byType(NovelTitleBlock)]),
    'controls': union([find.byType(NovelReadButton), find.byType(NovelSecondaryActions)]),
    'about': rect(find.byType(NovelAbout)),
    'facts': rect(find.byType(FrostKeyValueList)),
    'series': rect(find.byType(NovelSeriesBlock)),
    'illustrations': rect(find.byType(NovelIllustrations)),
    'comments': rect(find.byType(AppCommentsPreview)),
    'author': rect(find.byType(NovelAuthorNovels)),
    'relatedHeader': rect(find.widgetWithText(FrostSectionHeader, t.novelDetail.related)),
  };
  final present = all.entries.where((entry) => entry.value != null).toList()..sort((a, b) => a.value!.top.compareTo(b.value!.top));
  return {for (final entry in present) entry.key: entry.value!};
}

void main() {
  testWidgets('the reading button offers the start of the text, or continuing from where the account stopped', (tester) async {
    await _mount(tester, novel: _novel);
    expect(_read(tester).label, t.novel.detail.startReading);
    expect(find.text(t.novel.detail.continueReading(percent: 38)), findsNothing);

    await _mount(
      tester,
      novel: _novel,
      seedHistory: (history) =>
          history.saveReadingProgress('1000', _novel.id, ReadingProgress(offset: 3800, totalLength: 10000, updatedAt: DateTime.utc(2026, 11, 1))),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settlePilot(tester);
    final labels = tester.widgetList<FrostButton>(find.byType(FrostButton)).map((button) => button.label);
    expect(labels, contains(t.novel.detail.continueReading(percent: 38)));
    expect(labels, isNot(contains(t.novel.detail.startReading)));
  });

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
    expect(find.byType(FrostMediaCard), findsOneWidget);
    expect(find.text('A novel'), findsNothing);
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
    expect(find.text(t.novel.detail.startReading), findsOneWidget, reason: 'the bar keeps the button in view');
    expectNoLayoutErrors(tester);
  });

  testWidgets('the read button waits for the text, and shows a progress bar only once the account has read', (tester) async {
    await _mount(tester, novel: _novel, overrides: {novelTextProvider: novelTextProvider.overrideWith2((_) => _PendingText())});
    expect(_read(tester).onPressed, isNull, reason: 'off while the text loads');
    expect(find.byType(FrostProgressBar), findsNothing);

    await _mount(
      tester,
      novel: _novel,
      seedHistory: (history) =>
          history.saveReadingProgress('1000', _novel.id, ReadingProgress(offset: 3800, totalLength: 10000, updatedAt: DateTime.utc(2026, 11, 1))),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settlePilot(tester);
    final bar = tester.widget<FrostProgressBar>(find.byType(FrostProgressBar));
    expect(bar.value, closeTo(0.38, 0.001));
  });

  testWidgets('wide: the cover, read button and facts form a column beside the title, caption and illustrations', (tester) async {
    await _mount(
      tester,
      novel: _novel,
      size: const Size(1400, 900),
      overrides: {
        novelTextProvider: novelTextProvider.overrideWith2((_) => _Text([_illustrated()])),
      },
    );
    final cover = tester.getTopLeft(find.byType(NovelCover));
    final title = tester.getTopLeft(_titleText('A novel'));
    expect(tester.getSize(find.byType(NovelCover)).width, 300);
    expect(title.dx, greaterThan(cover.dx + 300), reason: 'the title is in the right column');
    expect(tester.getTopLeft(find.byType(NovelReadButton)).dx, cover.dx);
    expect(tester.getTopLeft(find.byType(NovelSecondaryActions)).dx, cover.dx);
    expect(tester.getTopLeft(find.byType(FrostKeyValueList)).dx, cover.dx);
    expect(tester.getTopLeft(find.byType(FrostKeyValueList)).dy, greaterThan(tester.getBottomLeft(find.byType(NovelReadButton)).dy));
    expect(tester.getTopLeft(find.byType(NovelIllustrations)).dx, title.dx, reason: 'the strip is in the right column');
    expect(find.byType(NovelBottomActionBar), findsNothing);
    expectNoLayoutErrors(tester);
  });

  testWidgets('narrow: one column, the facts after the caption', (tester) async {
    await _mount(
      tester,
      novel: _novel,
      size: const Size(900, 800),
      overrides: {
        novelTextProvider: novelTextProvider.overrideWith2((_) => _Text([_illustrated()])),
      },
    );
    final cover = tester.getTopLeft(find.byType(NovelCover));
    expect(tester.getSize(find.byType(NovelCover)).width, 160);
    expect(_titleText('A novel'), findsOneWidget);
    expect(tester.getTopLeft(_titleText('A novel')).dx, greaterThan(cover.dx + 160), reason: 'cover and title side by side from 600');
    for (final finder in [find.byType(NovelAbout), find.byType(FrostKeyValueList), find.byType(NovelIllustrations)]) {
      expect(tester.getTopLeft(finder).dx, cover.dx, reason: 'one column');
    }
    expect(
      tester.getTopLeft(find.byType(NovelReadButton)).dx,
      tester.getTopLeft(_titleText('A novel')).dx,
      reason: 'the controls are under the title, beside the cover',
    );
    expect(tester.getBottomLeft(find.byType(NovelReadButton)).dy, lessThanOrEqualTo(tester.getBottomLeft(find.byType(NovelCover)).dy + 0.01));
    expect(tester.getTopLeft(find.byType(FrostKeyValueList)).dy, greaterThan(tester.getTopLeft(find.byType(NovelAbout)).dy));
    expect(tester.getTopLeft(find.byType(NovelIllustrations)).dy, greaterThan(tester.getTopLeft(find.byType(FrostKeyValueList)).dy));
    expectNoLayoutErrors(tester);
  });

  testWidgets('narrow: the read button and the bookmark row share one row; wide stacks them', (tester) async {
    await _mount(tester, novel: _novel, size: const Size(900, 800));
    final read = find.byType(NovelReadButton), more = find.byType(NovelSecondaryActions);
    expect(tester.getCenter(read).dy, closeTo(tester.getCenter(more).dy, 24), reason: 'one row');
    expect(tester.getTopLeft(more).dx, greaterThan(tester.getTopRight(read).dx - 1));
    expectNoLayoutErrors(tester);

    await _mount(tester, novel: _novel, size: const Size(1400, 900));
    expect(
      tester.getTopLeft(find.byType(NovelSecondaryActions)).dy,
      greaterThan(tester.getBottomLeft(find.byType(NovelReadButton)).dy - 1),
      reason: 'stacked in the left column',
    );
  });

  testWidgets('phone: the read button is in a bar at the bottom and the in-page buttons are gone', (tester) async {
    await _mount(tester, novel: _novel, size: phoneSize);
    final bar = find.byType(NovelBottomActionBar);
    expect(bar, findsOneWidget);
    expect(tester.getBottomLeft(bar).dy, phoneSize.height);
    expect(find.descendant(of: bar, matching: find.byType(NovelReadButton)), findsOneWidget);
    expect(find.byType(NovelReadButton), findsOneWidget, reason: 'the page keeps none of its own');
    expect(find.byType(NovelSecondaryActions), findsNothing);
    expect(find.text(t.novel.detail.startReading), findsOneWidget);
    expect(tester.getTopLeft(_titleText('A novel')).dy, greaterThan(tester.getBottomLeft(find.byType(NovelCover)).dy), reason: 'stacked');
    expectNoLayoutErrors(tester);
  });

  testWidgets('badges mark R-18, R-18G, AI and original works, and a plain one carries none', (tester) async {
    final labels = ['R-18', 'R-18G', t.artworkCard.ai, t.novelDetail.original];
    Future<List<String>> shown(Novel novel) async {
      await _mount(
        tester,
        novel: novel,
        overrides: {
          novelTextProvider: novelTextProvider.overrideWith2((_) => _Text([_text])),
        },
      );
      return [
        for (final label in labels)
          if (find.text(label).evaluate().isNotEmpty) label,
      ];
    }

    expect(await shown(_make()), isEmpty);
    expect(await shown(_make(xRestrict: 1)), ['R-18']);
    expect(await shown(_make(xRestrict: 2)), ['R-18G']);
    expect(await shown(_make(aiType: 2)), [t.artworkCard.ai]);
    expect(await shown(_make(xRestrict: 1, aiType: 2, isOriginal: true)), ['R-18', t.artworkCard.ai, t.novelDetail.original]);
    expect(find.text('A novel'), findsWidgets, reason: 'nothing is hidden behind a mark');
  });

  testWidgets('facts: length with reading time, structure, illustrations, date and reception', (tester) async {
    final novel = _make(textLength: 12000, pageCount: 3, createDate: '2026-11-01T12:00:00+09:00');
    await _mount(
      tester,
      novel: novel,
      overrides: {
        novelTextProvider: novelTextProvider.overrideWith2((_) => _Text([_illustrated(language: 'ja')])),
      },
    );
    final n = t.novelDetail;
    final loaded = ReaderModel(parseWebviewNovel(_illustrated(language: 'ja'))).totalLength;
    expect(loaded, lessThan(12000));
    expect(
      _fact(tester, n.factLength),
      '${t.novel.detail.totalChars(count: '12,000')} · ${n.readingTime(minutes: readingMinutes(loaded, language: 'ja'))}',
      reason: 'the loaded text is counted, at the Japanese 500 a minute',
    );
    expect(_fact(tester, n.factStructure), '${n.chapterCount(count: 2)} · ${n.sectionCount(count: 3)}');
    expect(_facts(tester).map((fact) => fact.label), [
      n.factLength,
      n.factStructure,
      n.factPublished,
      n.factReception,
    ], reason: 'the picture count is the strip header');
    expect(_fact(tester, n.factPublished), '2026-11-01');
    expect(_fact(tester, n.factReception), '${n.bookmarks(count: '12,345')} · ${n.views(count: '30')}');

    await _mount(
      tester,
      novel: _make(textLength: 12000),
      overrides: {
        novelTextProvider: novelTextProvider.overrideWith2((_) => _Text([_text])),
      },
    );
    expect(
      _fact(tester, n.factLength),
      '${t.novel.detail.totalChars(count: '12,000')} · ${n.readingTime(minutes: readingMinutes(ReaderModel(parseWebviewNovel(_text)).totalLength))}',
      reason: 'no language reads as Chinese: 400 a minute',
    );
    expect(_fact(tester, n.factStructure), n.sectionCount(count: 2), reason: 'no chapter markers');
    expect(_fact(tester, n.factPublished), isNull, reason: 'no date');

    await _mount(tester, novel: _make(textLength: 240000), overrides: {novelTextProvider: novelTextProvider.overrideWith2((_) => _PendingText())});
    expect(_fact(tester, n.factLength), contains(n.readingTimeWholeHours(hours: 10)));
    await _mount(tester, novel: _make(textLength: 270000), overrides: {novelTextProvider: novelTextProvider.overrideWith2((_) => _PendingText())});
    expect(_fact(tester, n.factLength), contains(n.readingTimeHours(hours: 11, minutes: 15)));
  });

  group('the series block', () {
    List<String> titles(int count) => [for (var index = 0; index < count; index++) 'Work ${1000 + index}'];

    List<FrostListRow> rows(WidgetTester tester) => tester.widgetList<FrostListRow>(find.byType(FrostListRow)).toList();

    FrostListRow header(WidgetTester tester) => rows(tester).firstWhere((row) => row.title == 'The series');

    List<FrostListRow> works(WidgetTester tester) => rows(tester).where((row) => row.title.startsWith('Work ')).toList();

    testWidgets('centres on the novel, marks it, and says which part of how many it is', (tester) async {
      await _mount(tester, novel: _inSeries(1004), overrides: _seriesOverride([_seriesPage(titles(9), total: 9)]));
      expect([for (final row in works(tester)) row.title], ['Work 1002', 'Work 1003', 'Work 1004', 'Work 1005', 'Work 1006']);
      expect(
        [
          for (final row in works(tester))
            if (row.selected) row.title,
        ],
        ['Work 1004'],
      );
      expect(header(tester).subtitle?.text, '${t.novelDetail.partOf(part: 5, total: 9)} · ${t.series.ongoing}');
      expect(find.text(t.novelDetail.allParts(count: 9)), findsOneWidget);
    });

    testWidgets('keeps five rows at either end of the series, and says it is completed', (tester) async {
      await _mount(tester, novel: _inSeries(1000), overrides: _seriesOverride([_seriesPage(titles(9), total: 9, concluded: true)]));
      expect([for (final row in works(tester)) row.title], titles(5));
      expect(header(tester).subtitle?.text, '${t.novelDetail.partOf(part: 1, total: 9)} · ${t.series.concluded}');
      await _mount(tester, novel: _inSeries(1008), overrides: _seriesOverride([_seriesPage(titles(9), total: 9)]));
      expect([for (final row in works(tester)) row.title], titles(9).sublist(4));
    });

    testWidgets('a novel beyond the first page shows the first five and no part number', (tester) async {
      await _mount(tester, novel: _inSeries(5000), overrides: _seriesOverride([_seriesPage(titles(10), total: 40)]));
      expect([for (final row in works(tester)) row.title], titles(5));
      expect([
        for (final row in works(tester))
          if (row.selected) row.title,
      ], isEmpty);
      expect(header(tester).subtitle?.text, startsWith(t.series.episodes(count: 40)));
      expect(header(tester).subtitle?.text, isNot(contains(t.novelDetail.partOf(part: 1, total: 40))));
      expect(find.text(t.novelDetail.allParts(count: 40)), findsOneWidget);
    });

    testWidgets('rows the account has started carry a progress bar, and a tap opens the novel', (tester) async {
      await _mount(
        tester,
        novel: _inSeries(1004),
        overrides: _seriesOverride([_seriesPage(titles(9), total: 9)]),
        seedHistory: (history) =>
            history.saveReadingProgress('1000', 1003, ReadingProgress(offset: 500, totalLength: 1000, updatedAt: DateTime.utc(2026, 11, 1))),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await settlePilot(tester);
      // Every row has room for its bar; only the started one shows it.
      final shown = find.descendant(of: find.byWidgetPredicate((widget) => widget is Opacity && widget.opacity == 1), matching: find.byType(FrostProgressBar));
      expect(tester.widget<FrostProgressBar>(shown).value, 0.5);
      await tester.tap(find.text('Work 1003'));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.novel(1003));
    });

    testWidgets('a series that fails to load offers a retry in place', (tester) async {
      await _mount(tester, novel: _inSeries(1004), overrides: _seriesOverride([Exception('offline'), _seriesPage(titles(9), total: 9)]));
      expect(find.text(t.novelDetail.seriesFailed), findsOneWidget);
      expect(works(tester), isEmpty);
      expect(find.text(t.novelText.loadFailed), findsNothing, reason: 'the rest of the page is unaffected');
      await tester.tap(find.text(t.common.retry));
      await settlePilot(tester);
      expect(find.text(t.novelDetail.seriesFailed), findsNothing);
      expect(works(tester), hasLength(5));
    });
  });

  group('the illustrations strip', () {
    final text = _illustrated();
    final uploaded = text.images.map((image) => image.urls.size240Mw!).toList();
    final workUrl = text.illusts.single.imageMedium!;

    Future<void> mountStrip(WidgetTester tester, {Size size = desktopSize}) {
      final sizes = MemoryImageSizeStore();
      unawaited(sizes.record(uploaded[0], const Size(240, 135)));
      unawaited(sizes.record(uploaded[1], const Size(240, 480)));
      return _mount(
        tester,
        novel: _novel,
        size: size,
        overrides: {
          novelTextProvider: novelTextProvider.overrideWith2((_) => _Text([text])),
          imageSizeStoreProvider: imageSizeStoreProvider.overrideWithValue(sizes),
        },
      );
    }

    Finder tiles() => find.descendant(of: find.byType(NovelIllustrations), matching: find.byType(FrostMediaCard));

    testWidgets('shows the small pictures, each at its own proportions, with the total', (tester) async {
      await mountStrip(tester);
      expect(find.text(t.novel.reader.illustrationsCount(count: 3)), findsOneWidget);
      final urls = tester
          .widgetList<AppPixivImage>(find.descendant(of: find.byType(NovelIllustrations), matching: find.byType(AppPixivImage)))
          .map((image) => image.url);
      expect(urls, [uploaded[0], workUrl, uploaded[1]], reason: 'the 240-wide pictures and the work\'s medium one, never the originals');
      final sizes = [for (var index = 0; index < 3; index++) tester.getSize(tiles().at(index))];
      expect(sizes.map((size) => size.height), everyElement(120));
      expect(sizes[0].width, closeTo(120 * 240 / 135, 0.5));
      expect(sizes[1].width, closeTo(120 * 3 / 4, 0.5));
      expect(sizes[2].width, closeTo(60, 0.5));
    });

    testWidgets('is smaller on a phone', (tester) async {
      await mountStrip(tester, size: phoneSize);
      expect(tester.getSize(tiles().first).height, 96);
    });

    testWidgets('an uploaded picture opens the viewer on all of them, a work opens its page', (tester) async {
      await mountStrip(tester);
      await tester.tap(tiles().at(2));
      await settlePilot(tester);
      expect(openedLocations.last, AppRoute.originalImageViewer.path);
      final viewer = openedExtras.last as OriginalImageViewerArgs;
      expect(viewer.pages.map((page) => page.url), text.images.map((image) => image.urls.original));
      expect(viewer.initialIndex, 1);

      await mountStrip(tester);
      await tester.tap(tiles().at(1));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.illust(9001));
    });

    testWidgets('a novel without pictures has no strip', (tester) async {
      await _mount(
        tester,
        novel: _novel,
        overrides: {
          novelTextProvider: novelTextProvider.overrideWith2((_) => _Text([_text])),
        },
      );
      expect(find.byType(NovelIllustrations), findsOneWidget);
      expect(tiles(), findsNothing);
      expect(find.textContaining(t.novel.reader.illustrations), findsNothing);
    });
  });

  test('the novel strings exist in all four languages', () => expectLocalesComplete(['novelDetail', 'novel', 'novelText']));
  group('sections loading', () {
    for (final width in [390.0, 750.0]) {
      for (final name in ['text', 'series', 'progress', 'comments', 'author', 'related']) {
        testWidgets('nothing moves when "$name" has loaded, at $width', (tester) async {
          final sections = _Sections(gated: name);
          await _mount(tester, novel: _inSeries(1002), size: Size(width, 7000), overrides: sections.overrides());
          await tester.pump(const Duration(seconds: 1));
          final before = _sections(tester);
          sections.release();
          await tester.pump();
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
          await tester.pump(const Duration(seconds: 1));
          final after = _sections(tester);

          // The section that loaded; the text fills the sections of its own.
          final filled = switch (name) {
            'text' => 'about',
            'series' || 'progress' => 'series',
            'comments' => 'comments',
            'author' => 'author',
            _ => 'relatedHeader',
          };
          final names = before.keys.where((key) => key != 'controls' || width >= 600).toList();
          // The strip of pictures appears below the series block; its presence is not known before the text.
          final textSections = const {'illustrations'};
          for (final key in names) {
            if (!after.containsKey(key)) continue;
            final isAbove = names.indexOf(key) < names.indexOf(filled);
            if (isAbove && !(name == 'text' && textSections.contains(key))) {
              expect(after[key]!.top, closeTo(before[key]!.top, 0.01), reason: '$key lies above "$filled": it does not move');
            }
          }
          if (name == 'text') {
            // The rows the text adds to the facts are there as bones before it: the facts
            // keep their height, and the series block and what lies above it do not move.
            expect(after['facts']!.height, closeTo(before['facts']!.height, 0.01), reason: 'the facts keep their height');
            expect(after['series']!.top, closeTo(before['series']!.top, 0.01), reason: 'the series block does not move');
            return;
          }
          // Below it, nothing moves unless the loaded section ended up smaller.
          final grown = after[filled]!.bottom - before[filled]!.bottom;
          expect(grown, lessThanOrEqualTo(0.01), reason: '"$filled" does not grow when its content arrives');
          for (final key in names.skip(names.indexOf(filled) + 1)) {
            if (!after.containsKey(key)) continue;
            expect(after[key]!.top - before[key]!.top, closeTo(grown, 0.01), reason: '$key lies below "$filled" and moves only by what it shrank');
          }
        });
      }
    }
  });

  group('cover', () {
    for (final width in [390.0, 750.0]) {
      for (final (w, h) in [(180, 500), (400, 400), (707, 500), (800, 450)]) {
        testWidgets('a ${w}x$h picture changes neither the head nor what lies below it, at $width', (tester) async {
          final novel = _make(
            id: 1002,
            title: 'Work 1002',
            series: const Series(id: 500, title: 'The series'),
            imageUrls: ImageUrls(squareMedium: '', medium: '', large: sampleImageUrl(5, width: 300, height: 400)),
          );
          final sections = _Sections(
            gated: 'text',
            cover: sampleImageUrl(6, width: w, height: h),
          );
          await _mount(tester, novel: novel, size: Size(width, 7000), overrides: sections.overrides());
          final frames = <Rect>[tester.getRect(find.byType(NovelCover))];
          final heads = <double>[_sections(tester)['head']!.height];
          await tester.pump(const Duration(seconds: 1));
          final before = _sections(tester);
          heads.add(before['head']!.height);
          sections.release();
          await tester.pump();
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
          await tester.pump(const Duration(seconds: 1));
          final after = _sections(tester);
          heads.add(after['head']!.height);
          frames.add(tester.getRect(find.byType(NovelCover)));

          expect(frames.last.height, closeTo(frames.last.width * 1.414, 0.01), reason: 'the frame has a fixed proportion');
          for (final head in heads) {
            expect(head, closeTo(heads.first, 0.01), reason: 'the head keeps its height');
          }
          expect(after['about']!.top, closeTo(before['about']!.top, 0.01), reason: 'the about text does not move');
        });
      }
    }

    testWidgets('the picture is drawn whole in its frame', (tester) async {
      await _mount(tester, novel: _inSeries(1002), overrides: _Sections().overrides());
      await tester.pump(const Duration(seconds: 1));
      final image = tester.widget<AppPixivImage>(find.descendant(of: find.byType(NovelCover), matching: find.byType(AppPixivImage)));
      expect(image.fit, BoxFit.contain);
    });
  });

  group('facts', () {
    for (final width in [390.0, 750.0]) {
      for (final (name, text) in [('chapters and pictures', _illustrated()), ('neither', _text)]) {
        testWidgets('keep their height when the text loads, a novel with $name, at $width', (tester) async {
          final done = Completer<WebviewNovel>();
          await _mount(
            tester,
            novel: _make(textLength: ReaderModel(parseWebviewNovel(text)).totalLength, pageCount: 3),
            size: Size(width, 3000),
            // The test font is about twice as wide as the app's: this keeps a value that fits on one line in the app on one line here.
            textScale: 0.55,
            overrides: {novelTextProvider: novelTextProvider.overrideWith2((_) => _GatedText(done.future))},
          );
          await tester.pump(const Duration(seconds: 1));
          final loading = tester.getSize(find.byType(FrostKeyValueList)).height;
          final labels = _facts(tester).map((fact) => fact.label).toList();
          done.complete(text);
          await tester.pump();
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
          await tester.pump(const Duration(seconds: 1));
          expect(tester.getSize(find.byType(FrostKeyValueList)).height, closeTo(loading, 0.01), reason: 'the same height before and after');
          expect(_facts(tester).map((fact) => fact.label), labels, reason: 'no row comes or goes');
        });
      }
    }
  });

  group('skeleton', () {
    for (final width in [390.0, 750.0, 1200.0]) {
      testWidgets('has the head where the loaded page has it, at $width', (tester) async {
        final detail = Completer<Novel>();
        final overrides = {..._Sections().overrides(), novelDetailProvider: novelDetailProvider.overrideWith2((_) => _Detail(() => detail.future))};
        await _mount(tester, id: 1002, size: Size(width, 3000), overrides: overrides);
        await tester.pump(const Duration(seconds: 1));

        Finder controls() => find.byType(NovelReadButton).evaluate().isNotEmpty ? find.byType(NovelReadButton) : find.byType(NovelBottomActionBar);
        ({Rect cover, double title, double controls}) head() => (
          cover: tester.getRect(find.byType(NovelCover)),
          title: tester.getTopLeft(find.byType(NovelTitleBlock)).dy,
          controls: tester.getTopLeft(controls().first).dy,
        );

        final skeleton = head();
        detail.complete(_inSeries(1002));
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(seconds: 1));
        final loaded = head();

        expect(skeleton.cover, loaded.cover, reason: 'the cover keeps its place and size');
        expect(skeleton.title, closeTo(loaded.title, 0.01), reason: 'the title block keeps its top');
        expect(skeleton.controls, closeTo(loaded.controls, 0.01), reason: 'the controls keep their top');
      });
    }
  });

  group('head', () {
    Rect rect(WidgetTester tester, Type type) => tester.getRect(find.byType(type).first);

    for (final width in [390.0, 750.0, 1200.0]) {
      testWidgets('leaves no blank below it: the next section follows at the section gap, at $width', (tester) async {
        await _mount(tester, novel: _inSeries(1002), size: Size(width, 3000), overrides: _Sections().overrides());
        await tester.pump(const Duration(seconds: 1));
        final cover = rect(tester, NovelCover), title = rect(tester, NovelTitleBlock), about = rect(tester, NovelAbout);
        // A phone has the controls in its bottom bar.
        final controls = width < 600 ? null : rect(tester, NovelReadButton);
        if (width >= 960) {
          expect(about.top - title.bottom, FrostGap.section, reason: 'two columns: the caption under the title');
        } else {
          final head = [cover, title, ?controls].reduce((a, b) => a.expandToInclude(b));
          expect(about.top - head.bottom, FrostGap.section, reason: 'one column: the caption under the head');
          if (width >= 600) {
            expect(controls!.bottom, closeTo(cover.bottom, 0.01), reason: 'the controls fill the space beside the cover');
          }
        }
      });
    }

    for (final width in [390.0, 750.0, 1200.0]) {
      testWidgets('the header shows the title once the title block has scrolled under it, at $width', (tester) async {
        await _mount(tester, novel: _inSeries(1002), size: Size(width, 700), overrides: _Sections().overrides());
        await tester.pump(const Duration(seconds: 1));
        final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
        final header = MediaQuery.paddingOf(tester.element(find.byType(NovelTitleBlock))).top;
        final bottom = tester.getRect(find.byType(NovelTitleBlock)).bottom + position.pixels;
        Finder inHeader() => find.descendant(of: find.byType(FrostPageHeader), matching: find.text('Work 1002'));

        expect(inHeader(), findsNothing);
        position.jumpTo(bottom - header - 1);
        await tester.pump(const Duration(milliseconds: 400));
        expect(inHeader(), findsNothing, reason: 'one pixel of the title block is still below the header');
        position.jumpTo(bottom - header + 0.01);
        await tester.pump(const Duration(milliseconds: 400));
        expect(inHeader(), findsOneWidget, reason: 'the title block is under the header');
      });
    }
  });

  group('gaps between sections', () {
    for (final width in [390.0, 750.0]) {
      testWidgets('are single, at $width', (tester) async {
        await _mount(tester, novel: _inSeries(1002), size: Size(width, 7000), overrides: _Sections().overrides());
        await tester.pump(const Duration(seconds: 1));
        final sections = _sections(tester);
        final names = sections.keys.toList();
        expect(names, containsAll(['head', 'about', 'facts', 'series', 'illustrations', 'comments', 'author', 'relatedHeader']));
        for (var i = 0; i + 1 < names.length; i++) {
          // On a phone the controls are in the bottom bar, not between sections.
          if (names[i] == 'controls' || names[i + 1] == 'controls') continue;
          final gap = sections[names[i + 1]]!.top - sections[names[i]]!.bottom;
          expect(gap, FrostGap.section, reason: '${names[i]} to ${names[i + 1]}');
        }
      });
    }
  });
}
