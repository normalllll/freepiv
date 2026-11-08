import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/illust_detail_page.dart';
import 'package:freepiv/features/illust/presentation/illust_info.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

class _Detail extends IllustDetail {
  _Detail(this.load);

  final Future<Illust> Function() load;

  @override
  FutureOr<Illust> build(IllustDetailArgs args) => load();
}

class _FailingComments extends IllustComments {
  @override
  Future<CommentPageResult> build(int illustId) async => throw StateError('offline');
}

class _NoComments extends IllustComments {
  @override
  Future<CommentPageResult> build(int illustId) async => const CommentPageResult(comments: []);
}

Illust _work({
  String title = 'Sample work',
  String author = 'Sample artist',
  List<Tag> tags = const [Tag(name: 'landscape')],
  int pages = 1,
  int comments = 6,
  bool bookmarked = false,
}) {
  final base = sampleIllusts(count: 1).single;
  return Illust(
    id: base.id,
    title: title,
    kind: base.kind,
    imageUrls: base.imageUrls,
    caption: 'A caption with a <a href="https://example.com">link</a>.',
    restrict: 0,
    user: User(
      id: 2000,
      name: author,
      account: author,
      profileImageUrls: const ProfileImageUrls(medium: ''),
    ),
    tags: tags,
    tools: const [],
    createDate: base.createDate,
    pageCount: pages,
    width: 1000,
    height: 1400,
    sanityLevel: 2,
    xRestrict: 1,
    metaSinglePage: const MetaSinglePage(),
    metaPages: const [],
    totalView: 1000,
    totalBookmarks: 20,
    isBookmarked: bookmarked,
    visible: true,
    isMuted: false,
    totalComments: comments,
    illustAiType: 2,
  );
}

Future<void> _mount(
  WidgetTester tester, {
  Illust? illust,
  int? id,
  Future<Illust> Function()? load,
  Size size = desktopSize,
  double textScale = 1,
  Map<Object, Override> overrides = const {},
}) => mountPilotPage(
  tester,
  IllustDetailPage(illustId: id, illust: illust),
  size: size,
  textScale: textScale,
  overrides: {if (load != null) illustDetailProvider: illustDetailProvider.overrideWith2((_) => _Detail(load)), ...overrides},
);

Finder _scroller(String key) => find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(Scrollable)).first;

void main() {
  testWidgets('a work handed over by a list shows at once: stage, the one solid Bookmark, comments, the author\'s works and related works', (tester) async {
    await _mount(tester, illust: _work());
    expect(find.byType(IllustInfoHeading), findsOneWidget);
    expect(find.widgetWithText(FrostButton, 'Bookmark 20'), findsOneWidget);
    expect(find.byType(IllustCommentsPreview), findsOneWidget);
    expect(find.text('Sample creator 1'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(IllustRelatedPreview), 300, scrollable: _scroller('illust-info'));
    expect(find.byType(IllustRelatedPreview), findsOneWidget);
    expectNoLayoutErrors(tester);
  });

  testWidgets('the header More menu shows only its icon', (tester) async {
    await _mount(tester, illust: _work());
    expectIconOnlyMore(tester);
  });

  for (final (size, textScale) in [(desktopSize, 1.0), (desktopSize, 2.0), (phoneSize, 1.0), (phoneSize, 2.0)]) {
    testWidgets('loading: the skeleton has the loaded info column\'s blocks in order, where they will be (${size.width.toInt()} wide, text ×$textScale)', (
      tester,
    ) async {
      // An ordinary work: a one-line title, two short tags, no caption, three
      // one-line comments, the shape the skeleton stands for.
      final work = _ordinary();
      final overrides = {illustCommentsProvider: illustCommentsProvider.overrideWith2((_) => _ShortComments())};
      // Measured from the heading: on a phone the picture above it takes its
      // height from the work, which a skeleton cannot know.
      Future<Map<Key, double>> blocks() async {
        await Scrollable.ensureVisible(tester.element(find.byKey(IllustInfoBlocks.heading)));
        await settlePilot(tester, frames: 3);
        final origin = tester.getTopLeft(find.byKey(IllustInfoBlocks.heading)).dy;
        return {
          for (final key in [
            IllustInfoBlocks.heading,
            IllustInfoBlocks.tabs,
            IllustInfoBlocks.about,
            IllustInfoBlocks.comments,
            IllustInfoBlocks.works,
            IllustInfoBlocks.related,
          ])
            if (find.byKey(key).evaluate().isNotEmpty) key: tester.getTopLeft(find.byKey(key)).dy - origin,
        };
      }

      final never = Completer<Illust>();
      await _mount(tester, id: work.id, load: () => never.future, size: size, textScale: textScale, overrides: overrides);
      expectNoLayoutErrors(tester, where: 'the skeleton');
      expect(find.byType(IllustInfoHeadingSkeleton), findsOneWidget);
      final skeleton = await blocks();

      await _mount(tester, illust: work, size: size, textScale: textScale, overrides: overrides);
      final loaded = await blocks();
      // Blocks below the screen may not be built yet on one side.
      final shown = skeleton.keys.where(loaded.containsKey).toList();
      expect(shown, loaded.keys.where(skeleton.containsKey).toList(), reason: 'the same blocks in the same order');
      expect(shown.length, greaterThanOrEqualTo(3));
      final order = skeleton.values.toList();
      expect(order, orderedEquals([...order]..sort()));
      for (final key in shown) {
        expect(skeleton[key], closeTo(loaded[key]!, 4), reason: '$key');
      }
    });
  }

  testWidgets('error: a failed load offers a retry over the page; a missing work says so without one', (tester) async {
    var attempts = 0;
    await _mount(
      tester,
      id: 1,
      load: () async {
        attempts++;
        throw StateError('offline');
      },
    );
    expect(find.byType(AppPageError), findsOneWidget);
    expect(find.byType(FrostErrorContent), findsOneWidget);

    await _mount(
      tester,
      id: 2,
      load: () async => throw const PixivError(kind: PixivErrorKind.httpStatus, status: 404, message: 'not found'),
    );
    expect(find.text(t.illustDetail.missing), findsOneWidget);
    expect(find.byType(FrostErrorContent), findsNothing);
    expect(attempts, greaterThan(0));
  });

  testWidgets('partial failure: comments that fail retry in their own section while the rest shows', (tester) async {
    await _mount(tester, illust: _work(), overrides: {illustCommentsProvider: illustCommentsProvider.overrideWith2((_) => _FailingComments())});
    expect(find.text(t.illust.comments.failed), findsOneWidget);
    expect(find.byType(IllustInfoHeading), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(IllustRelatedPreview), 300, scrollable: _scroller('illust-info'));
  });

  testWidgets('with comments counted but none loaded, and with failed comments, the entry to all of them stays', (tester) async {
    for (final comments in [() => _NoComments(), () => _FailingComments()]) {
      await _mount(tester, illust: _work(), overrides: {illustCommentsProvider: illustCommentsProvider.overrideWith2((_) => comments())});
      final open = find.text(t.illustDetail.allComments(count: 6));
      await tester.ensureVisible(open);
      await tester.tap(open);
      await settlePilot(tester);
      expect(openedLocations, contains(AppLocations.illustComments(_work().id)));
    }
  });

  testWidgets('with no comments: the empty line, then Write a comment at its edge, opening the comments page', (tester) async {
    await _mount(tester, illust: _work(comments: 0), overrides: {illustCommentsProvider: illustCommentsProvider.overrideWith2((_) => _NoComments())});
    expect(find.text(t.illust.comments.open), findsNothing);
    final empty = find.text(t.illust.comments.empty);
    final write = find.text(t.illust.comments.write);
    expect(empty, findsOneWidget);
    expect(write, findsOneWidget);
    await tester.ensureVisible(write);
    await tester.pump();
    expect(tester.getTopLeft(write).dy, greaterThan(tester.getBottomLeft(empty).dy - 1), reason: 'below the empty line');
    expect(tester.getTopLeft(write).dx, moreOrLessEquals(tester.getTopLeft(empty).dx, epsilon: 0.5), reason: 'the words share the text edge');
    await tester.tap(write);
    await settlePilot(tester);
    expect(openedLocations, contains(AppLocations.illustComments(_work().id)));
  });

  testWidgets('with no comments but a failed preview the plain entry stays', (tester) async {
    await _mount(tester, illust: _work(comments: 0), overrides: {illustCommentsProvider: illustCommentsProvider.overrideWith2((_) => _FailingComments())});
    final open = find.text(t.illust.comments.open);
    await tester.ensureVisible(open);
    expect(open, findsOneWidget);
    expect(find.text(t.illust.comments.write), findsNothing);
  });

  testWidgets('a long title, author name and tags fit at double text size, wide and narrow', (tester) async {
    final work = _work(
      title: longText,
      author: longText,
      tags: const [
        Tag(name: longText, translatedName: longText),
        Tag(name: longText),
      ],
      pages: 3,
    );
    for (final size in [desktopSize, phoneSize]) {
      await _mount(tester, illust: work, size: size, textScale: 2);
      expectNoLayoutErrors(tester);
    }
  });

  testWidgets('the narrow layout has About and Comments tabs', (tester) async {
    await _mount(tester, illust: _work(), size: phoneSize);
    expect(find.text(t.illustDetail.tabs.about), findsWidgets);
    await tester.drag(_scroller('illust-narrow'), const Offset(0, -500));
    await settlePilot(tester);
    await tester.tap(find.text(t.illustDetail.tabs.comments).first);
    await settlePilot(tester);
    await tester.scrollUntilVisible(find.text('Sample creator 1'), 300, scrollable: _scroller('illust-narrow'));
    expect(find.byType(IllustRelatedPreview), findsNothing);
  });

  for (final size in [desktopSize, phoneSize]) {
    testWidgets('loading related works shows as many columns as the loaded grid, at its edges (${size.width.toInt()} wide)', (tester) async {
      final gate = Completer<IllustPageResult>();
      await _mount(
        tester,
        illust: _work(),
        size: size,
        overrides: {illustRelatedWorksProvider: illustRelatedWorksProvider.overrideWith2((_) => _GatedRelated(gate))},
      );
      final scroller = _scroller(size == desktopSize ? 'illust-info' : 'illust-narrow');
      await tester.scrollUntilVisible(find.byType(IllustRelatedPreview), 300, scrollable: scroller);
      await settlePilot(tester, frames: 3);
      Set<double> columns() => {
        for (final card in find.descendant(of: find.byType(IllustRelatedPreview), matching: find.byType(FrostMediaCard)).evaluate())
          tester.getTopLeft(find.byElementPredicate((element) => element == card)).dx,
      };
      final loading = columns();
      expect(loading, isNotEmpty, reason: 'the skeleton shows');

      gate.complete(IllustPageResult(illusts: sampleIllusts(count: 8), rankingIllusts: const []));
      await settlePilot(tester);
      final loaded = columns();
      expect(loaded.length, 2, reason: 'the loaded grid has two columns');
      expect(loading, loaded, reason: 'the skeleton has the same columns at the same edges');
    });
  }

  test('the detail strings exist in all four languages', () {
    expectLocalesComplete(['illustDetail', 'illust', 'artworkCard', 'follow']);
  });
}

/// Three one-line comments, as the skeleton's rows stand for.
class _ShortComments extends IllustComments {
  @override
  Future<CommentPageResult> build(int illustId) async => CommentPageResult(
    comments: [
      for (final comment in sampleComments(count: 4).where((comment) => comment.stamp == null).take(3))
        Comment(id: comment.id, comment: 'A comment of usual length', date: comment.date, user: comment.user, hasReplies: false),
    ],
  );
}

/// A sample work with a one-line title and two short tags.
Illust _ordinary() {
  final base = sampleIllusts(count: 3)[2];
  return Illust(
    id: base.id,
    title: base.title,
    kind: base.kind,
    imageUrls: base.imageUrls,
    caption: '',
    restrict: 0,
    user: base.user,
    tags: const [
      Tag(name: 'sky'),
      Tag(name: 'landscape'),
    ],
    tools: const [],
    createDate: base.createDate,
    pageCount: 1,
    width: base.width,
    height: base.height,
    sanityLevel: 2,
    xRestrict: 0,
    metaSinglePage: const MetaSinglePage(),
    metaPages: const [],
    totalView: base.totalView,
    totalBookmarks: base.totalBookmarks,
    isBookmarked: false,
    visible: true,
    isMuted: false,
    totalComments: 3,
    illustAiType: 1,
  );
}

/// Related works that load when [gate] completes.
class _GatedRelated extends IllustRelatedWorks {
  _GatedRelated(this.gate);

  final Completer<IllustPageResult> gate;

  @override
  IllustRelatedListSource build(int illustId) {
    final source = _GatedRelatedSource(illustId: illustId, gate: gate);
    ref.onDispose(source.dispose);
    return source;
  }
}

class _GatedRelatedSource extends IllustRelatedListSource {
  _GatedRelatedSource({required super.illustId, required this.gate});

  final Completer<IllustPageResult> gate;

  @override
  Future<IllustPageResult> loadFirstPage() => gate.future;
}
