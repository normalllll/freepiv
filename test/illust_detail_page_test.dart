import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/dev/sample_images.dart';
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

class _GatedComments extends IllustComments {
  _GatedComments(this.gate);

  final Completer<CommentPageResult> gate;

  @override
  Future<CommentPageResult> build(int illustId) => gate.future;
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
  int? comments = 6,
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

Future<void> _openComments(WidgetTester tester, {int count = 6}) async {
  final row = find.text(t.illust.section.commentsWithCount(count: count));
  await tester.scrollUntilVisible(row, 200, scrollable: _infoScroller());
  await Scrollable.ensureVisible(tester.element(row), alignment: .5);
  await settlePilot(tester);
  await tester.tap(row);
  await settlePilot(tester);
}

Finder _infoScroller() => _scroller(find.byKey(const ValueKey('illust-narrow')).evaluate().isNotEmpty ? 'illust-narrow' : 'illust-info');

Finder _scroller(String key) => find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(Scrollable)).first;

void main() {
  testWidgets('a work handed over by a list shows at once: stage, Bookmark, comments, the author\'s works and related works', (tester) async {
    await _mount(tester, illust: _work());
    expect(find.byType(IllustInfoHeading), findsOneWidget);
    expect(find.widgetWithText(FrostButton, 'Bookmark 20'), findsOneWidget);
    expect(find.byType(IllustCommentsPanel), findsOneWidget);
    expect(find.text('Sample creator 1'), findsNothing, reason: 'closed until asked for');
    await _openComments(tester);
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
          for (final key in [IllustInfoBlocks.heading, IllustInfoBlocks.about, IllustInfoBlocks.comments, IllustInfoBlocks.works, IllustInfoBlocks.related])
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
    expect(find.byType(IllustInfoHeading), findsOneWidget);
    await _openComments(tester);
    expect(find.text(t.illust.comments.failed), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(IllustRelatedPreview), 300, scrollable: _scroller('illust-info'));
  });

  testWidgets('with comments counted but none loaded, and with failed comments, the entry to all of them stays', (tester) async {
    for (final comments in [() => _NoComments(), () => _FailingComments()]) {
      await _mount(tester, illust: _work(), overrides: {illustCommentsProvider: illustCommentsProvider.overrideWith2((_) => comments())});
      await _openComments(tester);
      final open = find.text(t.illustDetail.allComments(count: 6));
      await tester.ensureVisible(open);
      await tester.tap(open);
      await settlePilot(tester);
      expect(openedLocations, contains(AppLocations.illustComments(_work().id)));
    }
  });

  testWidgets('a work whose list left the count out shows it when it arrives, and the row keeps its height', (tester) async {
    final gate = Completer<int?>();
    await _mount(
      tester,
      illust: _work(comments: null),
      overrides: {illustCommentTotalProvider: illustCommentTotalProvider.overrideWith((ref, illustId) => gate.future)},
    );
    final plain = find.text(t.illust.section.comments);
    await tester.scrollUntilVisible(plain, 200, scrollable: _infoScroller());
    final height = tester.getSize(find.byType(IllustCommentsPanel)).height;
    gate.complete(38);
    await settlePilot(tester);
    expect(plain, findsNothing);
    expect(tester.getSize(find.byType(IllustCommentsPanel)).height, height);
    await _openComments(tester, count: 38);
    final all = find.text(t.illustDetail.allComments(count: 38));
    await tester.ensureVisible(all);
    expect(all, findsOneWidget);
  });

  testWidgets('a work that came with its count does not ask for it, and one that cannot get it stays plain', (tester) async {
    var asked = 0;
    await _mount(
      tester,
      illust: _work(),
      overrides: {
        illustCommentTotalProvider: illustCommentTotalProvider.overrideWith((ref, illustId) async {
          asked++;
          return 1;
        }),
      },
    );
    expect(asked, 0);
    await _mount(
      tester,
      illust: _work(comments: null),
      overrides: {illustCommentTotalProvider: illustCommentTotalProvider.overrideWith((ref, illustId) async => throw StateError('offline'))},
    );
    await tester.scrollUntilVisible(find.text(t.illust.section.comments), 200, scrollable: _infoScroller());
    expect(tester.takeException(), isNull);
  });

  testWidgets('with no comments: the empty line, then Write a comment at its edge, opening the comments page', (tester) async {
    await _mount(tester, illust: _work(comments: 0), overrides: {illustCommentsProvider: illustCommentsProvider.overrideWith2((_) => _NoComments())});
    await _openComments(tester, count: 0);
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
    await _openComments(tester, count: 0);
    final open = find.text(t.illust.comments.open);
    await tester.ensureVisible(open);
    expect(open, findsOneWidget);
    expect(find.text(t.illust.comments.write), findsNothing);
  });

  testWidgets('Bookmark is neutral with an outline heart, and accent solid with a filled heart once bookmarked', (tester) async {
    Color? labelColor(String label) =>
        tester.widget<RichText>(find.descendant(of: find.widgetWithText(FrostButton, label), matching: find.byType(RichText)).last).text.style?.color;

    await mountPilotPage(
      tester,
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FrostButton.prominent(label: 'solid', onPressed: () {}),
            FrostButton(label: 'neutral', onPressed: () {}),
          ],
        ),
      ),
    );
    final solid = labelColor('solid'), neutral = labelColor('neutral');
    expect(solid, isNot(neutral));

    await _mount(tester, illust: _work());
    expect(tester.widget<FrostButton>(find.widgetWithText(FrostButton, 'Bookmark 20')).icon, PivIcons.heart);
    expect(labelColor('Bookmark 20'), neutral);

    await _mount(tester, illust: _work(bookmarked: true));
    expect(tester.widget<FrostButton>(find.widgetWithText(FrostButton, 'Bookmark 20')).icon, PivIcons.heartFilled);
    expect(labelColor('Bookmark 20'), solid);
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

  testWidgets('the narrow layout has no tabs: About, the comments row, the works', (tester) async {
    await _mount(tester, illust: _work(), size: phoneSize);
    expect(find.byType(FrostTabBar), findsNothing);
    expect(find.byType(FrostMediaSystemChrome), findsNothing, reason: 'the picture starts under the header: the status bar is over the glass');
    await tester.scrollUntilVisible(find.byType(IllustCommentsPanel), 200, scrollable: _infoScroller());
    await settlePilot(tester);
  });

  testWidgets('opened, the comments end with the way to all of them, opening their page', (tester) async {
    await _mount(tester, illust: _work(), size: phoneSize);
    await _openComments(tester);
    final all = find.text(t.illustDetail.allComments(count: 6));
    await tester.scrollUntilVisible(all, 200, scrollable: _infoScroller());
    await Scrollable.ensureVisible(tester.element(all), alignment: .5);
    await settlePilot(tester);
    await tester.tap(all);
    await settlePilot(tester);
    expect(openedLocations, contains(AppLocations.illustComments(_work().id)));
  });

  for (final size in [desktopSize, phoneSize]) {
    testWidgets('comments loading behind their row move nothing on the page (${size.width.toInt()} wide)', (tester) async {
      final gate = Completer<CommentPageResult>();
      await _mount(tester, illust: _work(), size: size, overrides: {illustCommentsProvider: illustCommentsProvider.overrideWith2((_) => _GatedComments(gate))});
      final works = find.byKey(IllustInfoBlocks.works);
      await tester.scrollUntilVisible(works, 200, scrollable: _infoScroller());
      await settlePilot(tester, frames: 3);
      final before = tester.getTopLeft(works).dy;
      gate.complete(CommentPageResult(comments: sampleComments()));
      await settlePilot(tester);
      expect(tester.getTopLeft(works).dy, before);
    });
  }

  testWidgets('once the picture has scrolled away, the way back does not fly from it', (tester) async {
    final tag = FrostMediaHeroTag(image: const SampleImage(seed: 1, width: 10, height: 14), aspectRatio: 10 / 14);
    await mountPilotPage(
      tester,
      IllustDetailPage(illust: _work(), heroTag: tag),
      size: phoneSize,
    );
    bool flies() => tester
        .widgetList<HeroMode>(find.ancestor(of: find.byType(FrostMediaHero, skipOffstage: false), matching: find.byType(HeroMode, skipOffstage: false)))
        .every((mode) => mode.enabled);
    expect(flies(), isTrue);
    await tester.drag(_scroller('illust-narrow'), Offset(0, -phoneSize.height * 2));
    await settlePilot(tester);
    expect(flies(), isFalse);
    await tester.drag(_scroller('illust-narrow'), Offset(0, phoneSize.height * 2));
    await settlePilot(tester);
    expect(flies(), isTrue);
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
      final preview = find.byType(IllustRelatedPreview);
      final heightLoading = tester.getSize(preview).height;

      gate.complete(IllustPageResult(illusts: sampleIllusts(count: 8), rankingIllusts: const []));
      await settlePilot(tester);
      final loaded = columns();
      expect(loaded.length, 2, reason: 'the loaded grid has two columns');
      expect(loading, loaded, reason: 'the skeleton has the same columns at the same edges');
      expect(tester.getSize(preview).height, moreOrLessEquals(heightLoading, epsilon: .5), reason: 'equal squares and a title row of one height');
      final cards = find.descendant(of: preview, matching: find.byType(FrostMediaCard));
      expect(cards, findsWidgets);
      for (final card in tester.elementList(cards)) {
        final box = card.renderObject! as RenderBox;
        expect(box.size.width, moreOrLessEquals(box.size.height, epsilon: .5), reason: 'a square tile');
      }
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
