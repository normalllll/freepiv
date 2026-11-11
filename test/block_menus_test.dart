import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/block/block_list.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/block/block_actions.dart' show blockTag;
import 'package:freepiv/features/home/logic/home_logic.dart';
import 'package:freepiv/features/home/presentation/home_page.dart';
import 'package:freepiv/features/illust/presentation/illust_detail_page.dart';
import 'package:freepiv/features/novel/presentation/detail/novel_detail_page.dart';
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/features/user_detail/presentation/user_identity_header.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';
import 'support/work_fakes.dart';

const _second = 'Second sample artist';

Future<void> _rightClick(WidgetTester tester, Finder target) async {
  await tester.tap(target, buttons: kSecondaryButton);
  await settlePilot(tester, frames: 6);
}

Future<void> _tapText(WidgetTester tester, String text, {bool last = false}) async {
  await tester.tap(last ? find.text(text).last : find.text(text));
  await settlePilot(tester, frames: 6);
}

Iterable<int> _shownAuthors(WidgetTester tester) => tester.widgetList<AppArtworkCard>(find.byType(AppArtworkCard)).map((card) => card.illust.user.id);

void main() {
  testWidgets('a work card blocks its author after a confirmation that names them, and the toast undoes it', (tester) async {
    await mountPilotPage(tester, const HomePage());
    final container = ProviderScope.containerOf(tester.element(find.byType(HomePage)));
    final source = container.read(homeIllustSourceProvider);
    final revision = source.refreshRevision;
    final total = source.items.length;
    expect(_shownAuthors(tester), contains(2001));
    final card = find.byWidgetPredicate((widget) => widget is AppArtworkCard && widget.illust.user.name == _second).first;

    await _rightClick(tester, card);
    expect(find.text(t.block.blockUser), findsOneWidget);
    await _tapText(tester, t.block.blockUser);
    expect(find.text(t.block.confirmTitle(name: _second)), findsOneWidget, reason: 'the confirmation names the author');
    await _tapText(tester, t.common.cancel);
    expect(AppSettings.blockList.isEmpty, isTrue);
    expect(source.items.length, total);

    await _rightClick(tester, card);
    await _tapText(tester, t.block.blockUser);
    await _tapText(tester, t.block.confirm);

    expect(AppSettings.blockList.users, const [BlockedUser(id: 2001, name: _second)]);
    expect(_shownAuthors(tester), isNot(contains(2001)), reason: 'their cards are gone');
    expect(_shownAuthors(tester), contains(2000), reason: 'the others stay');
    expect(source.items.length, lessThan(total));
    expect(source.items.every((illust) => illust.user.id != 2001), isTrue);
    expect(source.refreshRevision, revision, reason: 'in place, not reloaded');
    expect(find.text(t.block.blocked(name: _second)), findsOneWidget);

    await _tapText(tester, t.block.undo);
    expect(AppSettings.blockList.isEmpty, isTrue);
    expect(_shownAuthors(tester), isNot(contains(2001)), reason: 'unblocking does not bring loaded cards back');
    expectNoLayoutErrors(tester);
  });

  testWidgets('blocking the author of a work takes the ranking shelf entries of theirs away as well', (tester) async {
    await mountPilotPage(tester, const HomePage());
    final container = ProviderScope.containerOf(tester.element(find.byType(HomePage)));
    final source = container.read(homeIllustSourceProvider);
    expect(source.rankingIllusts.any((illust) => illust.user.id == 2001), isTrue);

    AppSettings.blockList = AppSettings.blockList.withUser(const BlockedUser(id: 2001, name: _second));
    await settlePilot(tester, frames: 4);

    expect(source.rankingIllusts.any((illust) => illust.user.id == 2001), isFalse);
    expect(source.rankingIllusts, isNotEmpty);
    expectNoLayoutErrors(tester);
  });

  testWidgets('a novel row and a novel card offer to block the author', (tester) async {
    final novel = fakeNovel(5, by: 9);
    for (final widget in <Widget>[AppNovelRow(novel: novel), AppNovelCard(novel: novel)]) {
      await mountPilotPage(tester, SizedBox(width: 600, child: widget));
      await _rightClick(tester, find.text(novel.title));
      expect(find.text(t.block.blockUser), findsOneWidget, reason: '${widget.runtimeType}');
      await _tapText(tester, t.block.blockUser);
      expect(find.text(t.block.confirmTitle(name: novel.user.name)), findsOneWidget);
      await _tapText(tester, t.block.confirm);
      expect(AppSettings.blockList.users, [BlockedUser(id: 9, name: novel.user.name)]);
    }
  });

  testWidgets('a tag of an illustration offers copy and block; blocking says so and Undo takes it back', (tester) async {
    await mountPilotPage(tester, IllustDetailPage(illust: sampleIllusts(count: 1).single));

    await _rightClick(tester, find.text('#landscape'));
    expect(find.text(t.illustDetail.copyTag), findsOneWidget);
    await _tapText(tester, t.block.blockTag);

    expect(AppSettings.blockList.tags, ['landscape']);
    expect(find.text(t.block.blocked(name: '#landscape')), findsOneWidget);
    await _tapText(tester, t.block.undo);
    expect(AppSettings.blockList.tags, isEmpty);
  });

  testWidgets('a tag of a novel has the same menu', (tester) async {
    await mountPilotPage(tester, NovelDetailPage(novel: fakeNovel(7, tags: ['landscape'])));

    await _rightClick(tester, find.text('#landscape'));
    expect(find.text(t.illustDetail.copyTag), findsOneWidget);
    await _tapText(tester, t.block.blockTag);

    expect(AppSettings.blockList.tags, ['landscape']);
  });

  group('the author page', () {
    UserDetailResult detailOf(int id) => UserDetailResult(
      user: UserInfo(
        id: id,
        name: 'Author $id',
        account: 'author_$id',
        profileImageUrls: sampleUserDetail.user.profileImageUrls,
        comment: '',
        isFollowed: false,
      ),
      profile: sampleUserDetail.profile,
      profilePublicity: sampleUserDetail.profilePublicity,
      workspace: sampleUserDetail.workspace,
    );

    Future<void> openMore(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.descendant(of: find.byType(UserIdentityHeader), matching: find.byType(FrostMenuAnchor)),
          matching: find.byType(FrostButton),
        ),
      );
      await settlePilot(tester, frames: 6);
    }

    testWidgets('blocks the author after a confirmation, then offers to unblock them', (tester) async {
      await mountPilotPage(tester, UserDetailPage(userId: 2000, userDetail: detailOf(2000)));

      await openMore(tester);
      expect(find.text(t.block.unblockUser), findsNothing);
      await _tapText(tester, t.block.blockUser);
      expect(find.text(t.block.confirmTitle(name: 'Author 2000')), findsOneWidget);
      await _tapText(tester, t.block.confirm);
      expect(AppSettings.blockList.users, const [BlockedUser(id: 2000, name: 'Author 2000')]);

      FrostToast.dismissAll();
      await settlePilot(tester, frames: 6);
      await openMore(tester);
      expect(find.text(t.block.blockUser), findsNothing);
      await _tapText(tester, t.block.unblockUser);
      expect(AppSettings.blockList.isEmpty, isTrue);
      expect(find.text(t.block.unblocked(name: 'Author 2000')), findsOneWidget);
    });

    testWidgets('your own page has neither', (tester) async {
      final own = int.parse(sampleAccount.user.id);
      await mountPilotPage(tester, UserDetailPage(userId: own, userDetail: detailOf(own)));

      await openMore(tester);

      expect(find.text(t.userPage.copyLink), findsOneWidget, reason: 'the menu is open');
      expect(find.text(t.block.blockUser), findsNothing);
      expect(find.text(t.block.unblockUser), findsNothing);
    });
  });

  testWidgets('blocking a tag that is blocked already changes nothing and the notice has no undo', (tester) async {
    await mountPilotPage(tester, NovelDetailPage(novel: fakeNovel(7, tags: ['landscape'])));
    AppSettings.blockList = const BlockList().withTag('landscape');

    await _rightClick(tester, find.text('#landscape'));
    await _tapText(tester, t.block.blockTag);

    expect(find.text(t.block.blocked(name: '#landscape')), findsOneWidget);
    expect(find.text(t.block.undo), findsNothing);
    expect(AppSettings.blockList.tags, ['landscape']);
  });

  testWidgets('blocking a user that is blocked already changes nothing, not even the name, and the notice has no undo', (tester) async {
    final novel = fakeNovel(5, by: 9);
    await mountPilotPage(tester, SizedBox(width: 600, child: AppNovelRow(novel: novel)));
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 9, name: 'Listed as'));

    await _rightClick(tester, find.text(novel.title));
    await _tapText(tester, t.block.blockUser);
    await _tapText(tester, t.block.confirm);

    expect(find.text(t.block.blocked(name: novel.user.name)), findsOneWidget);
    expect(find.text(t.block.undo), findsNothing);
    expect(AppSettings.blockList.users, const [BlockedUser(id: 9, name: 'Listed as')]);
  });

  testWidgets('undo takes out only what the action added, and adds nothing back after a change in Settings', (tester) async {
    final novel = fakeNovel(5, by: 9, tags: ['landscape']);
    await mountPilotPage(tester, SizedBox(width: 600, child: AppNovelRow(novel: novel)));
    AppSettings.blockList = const BlockList().withUser(const BlockedUser(id: 3, name: 'Three')).withTag('first');

    await _rightClick(tester, find.text(novel.title));
    await _tapText(tester, t.block.blockUser);
    await _tapText(tester, t.block.confirm);
    expect(AppSettings.blockList.users.map((user) => user.id), [3, 9]);

    // The user takes the entry away in Settings and adds another.
    AppSettings.blockList = AppSettings.blockList.withoutUser(9).withUser(const BlockedUser(id: 4, name: 'Four'));
    await _tapText(tester, t.block.undo);
    expect(AppSettings.blockList.users.map((user) => user.id), [3, 4], reason: 'the others stay in their order and 9 is not put back');
    expect(AppSettings.blockList.tags, ['first']);

    FrostToast.dismissAll();
    await settlePilot(tester, frames: 6);
    blockTag('landscape');
    await settlePilot(tester, frames: 6);
    expect(AppSettings.blockList.tags, ['first', 'landscape']);
    AppSettings.blockList = const BlockList().withTag('later');
    await _tapText(tester, t.block.undo);
    expect(AppSettings.blockList.tags, ['later'], reason: 'the tag is not put back, and nothing else is removed');
  });

  final own = int.parse(sampleAccount.user.id);
  final cases = <(String, Widget Function(int author))>[
    ('a work card', (author) => AppArtworkCard(illust: fakeIllust(1, by: author))),
    ('a novel row', (author) => AppNovelRow(novel: fakeNovel(5, by: author))),
    ('a novel card', (author) => AppNovelCard(novel: fakeNovel(5, by: author))),
  ];
  for (final (label, build) in cases) {
    for (final (author, expected) in [(own, false), (own + 1, true)]) {
      testWidgets('$label of ${expected ? 'another author has' : 'your own work has no'} block entry in its menu', (tester) async {
        await mountPilotPage(
          tester,
          SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 480, child: build(author)),
            ),
          ),
        );
        await _rightClick(tester, find.byType(build(author).runtimeType));
        expect(
          find.text(t.bookmarkOptions.title).evaluate().isNotEmpty || find.text(t.artworkCard.openAuthor).evaluate().isNotEmpty,
          isTrue,
          reason: 'the menu opened',
        );
        expect(find.text(t.block.blockUser), expected ? findsOneWidget : findsNothing);
      });
    }
  }
}
