import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/identity_header.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:freepiv/ui/compositions/user_card.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

class _Detail extends UserDetail {
  _Detail(this.load);

  final Future<UserDetailResult> Function() load;

  @override
  FutureOr<UserDetailResult> build(UserDetailArgs args) => load();
}

class _Works extends UserIllustListSource {
  _Works(this.first) : super(userId: 2000, illustType: IllustType.illust);

  final Future<IllustPageResult> Function() first;

  @override
  Future<IllustPageResult> loadFirstPage() => first();
}

class _WorksNotifier extends UserIllusts {
  _WorksNotifier(this.first);

  final Future<IllustPageResult> Function() first;

  @override
  UserIllustListSource build({required int userId, required IllustType illustType}) {
    final source = illustType == IllustType.illust
        ? _Works(first)
        : _Works(() async => IllustPageResult(illusts: sampleIllusts(count: 3), rankingIllusts: const []));
    ref.onDispose(source.dispose);
    return source;
  }
}

UserDetailResult _withName(String name) => UserDetailResult(
  user: UserInfo(id: 2000, name: name, account: name, profileImageUrls: sampleUserDetail.user.profileImageUrls, comment: name, isFollowed: false),
  profile: sampleUserDetail.profile,
  profilePublicity: sampleUserDetail.profilePublicity,
  workspace: sampleUserDetail.workspace,
);

Future<void> _mount(
  WidgetTester tester, {
  UserDetailResult? detail,
  int? id,
  Future<UserDetailResult> Function()? load,
  Future<IllustPageResult> Function()? works,
  Size size = desktopSize,
  double textScale = 1,
}) => mountPilotPage(
  tester,
  UserDetailPage(userId: id, userDetail: detail),
  size: size,
  textScale: textScale,
  overrides: <Object, Override>{
    if (load != null) userDetailProvider: userDetailProvider.overrideWith2((_) => _Detail(load)),
    if (works != null) userIllustsProvider: userIllustsProvider.overrideWith2((_) => _WorksNotifier(works)),
  },
);

Finder _tab(String label) => find.descendant(of: find.byType(FrostTabBar), matching: find.text(label));

void main() {
  testWidgets('the identity header sits over the six tabs and the author\'s works', (tester) async {
    await _mount(tester, detail: sampleUserDetail);
    expect(find.byType(AppIdentityHeader), findsOneWidget);
    expect(find.text('@sample_artist'), findsOneWidget);
    for (final label in [t.user.tabs.illustrations, t.user.tabs.manga, t.user.tabs.novels, t.user.tabs.bookmarks, t.user.tabs.following, t.user.tabs.profile]) {
      expect(_tab(label), findsOneWidget);
    }
    expect(find.byType(AppArtworkCard), findsWidgets);
    expectNoLayoutErrors(tester);
  });

  testWidgets('the identity avatar is 72 across, loaded and loading', (tester) async {
    await _mount(tester, detail: sampleUserDetail);
    final header = find.byType(AppIdentityHeader);
    expect(tester.getSize(find.descendant(of: header, matching: find.byType(FrostAvatar)).first), const Size(72, 72));
    final never = Completer<UserDetailResult>();
    await _mount(tester, id: 2000, load: () => never.future);
    expect(tester.getSize(find.descendant(of: find.byType(AppIdentityHeader), matching: find.byType(FrostAvatar)).first), const Size(72, 72));
  });

  testWidgets('loading: an author known only by id shows the header and feed at their size', (tester) async {
    final never = Completer<UserDetailResult>();
    await _mount(tester, id: 2000, load: () => never.future);
    expect(find.byType(AppIdentityHeader), findsOneWidget);
    expect(find.byType(AppArtworkWaterfallSkeleton), findsOneWidget);
    expect(find.byType(FrostTabBar), findsOneWidget);
  });

  testWidgets('error: a failed load offers a retry over the page', (tester) async {
    await _mount(tester, id: 2000, load: () async => throw StateError('offline'));
    expect(find.byType(AppPageError), findsOneWidget);
    expect(find.byType(FrostErrorContent), findsOneWidget);
  });

  testWidgets('empty: a tab without works says so', (tester) async {
    await _mount(
      tester,
      detail: sampleUserDetail,
      works: () async => const IllustPageResult(illusts: [], rankingIllusts: []),
    );
    expect(find.text(t.user.empty.illustrations), findsOneWidget);
  });

  testWidgets('partial failure: a tab that fails retries on its own while the others load', (tester) async {
    await _mount(tester, detail: sampleUserDetail, works: () async => throw StateError('offline'));
    expect(find.byType(FrostErrorContent), findsOneWidget);
    await tester.tap(_tab(t.user.tabs.manga));
    await settlePilot(tester);
    expect(find.byType(AppArtworkCard), findsWidgets);
  });

  testWidgets('a long name, account and bio fit at double text size, and every tab stays reachable on a phone', (tester) async {
    await _mount(tester, detail: _withName(longText), size: phoneSize, textScale: 2);
    expectNoLayoutErrors(tester);
    for (final label in [t.user.tabs.following, t.user.tabs.profile]) {
      await tester.ensureVisible(_tab(label));
      await settlePilot(tester);
      await tester.tap(_tab(label));
      await settlePilot(tester);
      expectNoLayoutErrors(tester);
    }
    expect(find.byType(UserProfileDetails), findsOneWidget);
    expect(find.text('Kanagawa'), findsOneWidget);
  });

  testWidgets('Following lists users with their follow buttons', (tester) async {
    await _mount(tester, detail: sampleUserDetail);
    await tester.tap(_tab(t.user.tabs.following));
    await settlePilot(tester);
    expect(find.byType(AppUserCard), findsWidgets);
  });

  group('every tab starts at the tab bar\'s left edge', () {
    const wide = Size(1700, 900);
    double edge(WidgetTester tester) => tester.getTopLeft(_tab(t.user.tabs.illustrations)).dx;

    Future<void> show(WidgetTester tester, String label) async {
      await tester.tap(_tab(label));
      await settlePilot(tester);
    }

    testWidgets('works, Bookmarks picker, Novels, Following and Details', (tester) async {
      await _mount(tester, detail: sampleUserDetail, size: wide);
      final left = edge(tester);
      expect(tester.getTopLeft(find.byType(AppArtworkCard).first).dx, left, reason: 'the waterfall');
      await show(tester, t.user.tabs.bookmarks);
      expect(tester.getTopLeft(find.byType(FrostPicker<UserBookmarkKind>)).dx, left, reason: 'the picker');
      await show(tester, t.user.tabs.novels);
      expect(tester.getTopLeft(find.byType(AppNovelRow).first).dx, left, reason: 'the novels');
      await show(tester, t.user.tabs.following);
      expect(tester.getTopLeft(find.byType(AppUserCard).first).dx, left, reason: 'the following list');
      await show(tester, t.user.tabs.profile);
      expect(tester.getTopLeft(find.byType(UserProfileDetails)).dx, left, reason: 'the details');
      expectNoLayoutErrors(tester);
    });
  });

  testWidgets('switching tabs keeps a scrolled-away identity header away', (tester) async {
    await _mount(tester, detail: sampleUserDetail);
    final outer = tester.state<NestedScrollViewState>(find.byType(NestedScrollView)).outerController;
    outer.jumpTo(outer.position.maxScrollExtent);
    await settlePilot(tester);
    final collapsed = outer.offset;
    await tester.tap(_tab(t.user.tabs.profile));
    await settlePilot(tester);
    expect(outer.offset, collapsed);
  });

  testWidgets('each tab keeps its own place: scrolling one leaves the others where they were', (tester) async {
    await _mount(
      tester,
      detail: sampleUserDetail,
      works: () async => IllustPageResult(illusts: sampleIllusts(count: 60), rankingIllusts: const []),
    );
    final nested = tester.state<NestedScrollViewState>(find.byType(NestedScrollView));
    final outer = nested.outerController;
    while (outer.offset < outer.position.maxScrollExtent) {
      await tester.dragFrom(const Offset(500, 650), const Offset(0, -300));
      await settlePilot(tester);
    }
    await tester.dragFrom(const Offset(500, 650), const Offset(0, -500));
    await settlePilot(tester);
    final place = nested.innerController.offset;
    expect(place, greaterThan(0));

    await tester.tap(_tab(t.user.tabs.manga));
    await settlePilot(tester);
    expect(nested.innerController.offset, 0, reason: 'the manga tab was not scrolled along');

    await tester.tap(_tab(t.user.tabs.illustrations));
    await settlePilot(tester);
    expect(nested.innerController.offset, closeTo(place, 1), reason: 'back where it was');
    expect(outer.offset, outer.position.maxScrollExtent, reason: 'the identity stays away');
    expectNoLayoutErrors(tester);
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets('the tabs stay pinned under the page header while the works scroll, and the works stay below them (text ×$textScale)', (tester) async {
      await _mount(tester, detail: sampleUserDetail, textScale: textScale);
      final bar = find.byType(FrostTabBar);
      final header = tester.getRect(find.byType(FrostPageHeader)).bottom;
      final outer = tester.state<NestedScrollViewState>(find.byType(NestedScrollView)).outerController;
      final identity = tester.getSize(find.byType(AppIdentityHeader)).height;
      expect(tester.getTopLeft(bar).dy, greaterThan(header + identity - 1), reason: 'below the identity at first');
      expect(outer.position.maxScrollExtent, lessThan(tester.getBottomLeft(bar).dy), reason: 'the outer view scrolls the identity away, not the tabs');
      // Past the identity, however tall the text makes it.
      while (outer.offset < outer.position.maxScrollExtent) {
        await tester.dragFrom(const Offset(500, 650), const Offset(0, -300));
        await settlePilot(tester);
      }
      for (var step = 0; step < 4; step++) {
        await tester.dragFrom(const Offset(500, 650), const Offset(0, -300));
        await settlePilot(tester);
        expect(outer.offset, outer.position.maxScrollExtent, reason: 'the works scroll, the identity stays away');
        final pinned = tester.getRect(bar);
        expect(pinned.top, closeTo(header, 2), reason: 'the tabs sit right under the page header (drag ${step + 1})');
        final cards = find.byType(AppArtworkCard).hitTestable();
        expect(cards, findsWidgets);
        expect(tester.getRect(cards.first).bottom, greaterThan(pinned.bottom), reason: 'works scroll under the tabs, not over them');
      }
      expectNoLayoutErrors(tester);
    });
  }

  test('the author page strings exist in all four languages', () => expectLocalesComplete(['user', 'userPage']));
}
