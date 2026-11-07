import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
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

Illust _work({String title = 'Sample work', String author = 'Sample artist', List<Tag> tags = const [Tag(name: 'landscape')], int pages = 1}) {
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
    isBookmarked: false,
    visible: true,
    isMuted: false,
    totalComments: 6,
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

  testWidgets('loading: a work known only by its id shows the stage and info at their size', (tester) async {
    final never = Completer<Illust>();
    await _mount(tester, id: 1, load: () => never.future);
    expect(find.byType(IllustInfoHeading), findsNothing);
    expect(find.byType(FrostMediaFrame), findsWidgets);
  });

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

  test('the detail strings exist in all four languages', () {
    expectLocalesComplete(['illustDetail', 'illust', 'artworkCard', 'follow']);
  });
}
