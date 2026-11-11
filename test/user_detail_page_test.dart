import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/features/user_detail/presentation/user_identity_header.dart';
import 'package:freepiv/features/user_detail/presentation/user_related_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:freepiv/ui/compositions/user_card.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
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
  _relatedTests();
  testWidgets('the identity header sits over the six tabs and the author\'s works', (tester) async {
    await _mount(tester, detail: sampleUserDetail);
    expect(find.byType(UserIdentityHeader), findsOneWidget);
    expect(find.text('@sample_artist'), findsOneWidget);
    for (final label in [t.user.tabs.illustrations, t.user.tabs.manga, t.user.tabs.novels, t.user.tabs.bookmarks, t.user.tabs.following, t.user.tabs.profile]) {
      expect(_tab(label), findsOneWidget);
    }
    expect(find.byType(AppArtworkCard), findsWidgets);
    expectNoLayoutErrors(tester);
  });

  testWidgets('the identity avatar is 72 across, loaded and loading', (tester) async {
    await _mount(tester, detail: sampleUserDetail);
    final header = find.byType(UserIdentityHeader);
    expect(tester.getSize(find.descendant(of: header, matching: find.byType(FrostAvatar)).first), const Size(72, 72));
    final never = Completer<UserDetailResult>();
    await _mount(tester, id: 2000, load: () => never.future);
    expect(tester.getSize(find.descendant(of: find.byType(UserIdentityHeader), matching: find.byType(FrostAvatar)).first), const Size(72, 72));
  });

  testWidgets('loading: an author known only by id shows the header and feed at their size', (tester) async {
    final never = Completer<UserDetailResult>();
    await _mount(tester, id: 2000, load: () => never.future);
    expect(find.byType(UserIdentityHeader), findsOneWidget);
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
      final identity = tester.getSize(find.byType(UserIdentityHeader)).height;
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
        // At the normal text size the stuck tabs tuck slightly under the header.
        expect(pinned.top, closeTo(textScale > 1.3 ? header : header - 12, 2), reason: 'the tabs sit right under the page header (drag ${step + 1})');
        final cards = find.byType(AppArtworkCard).hitTestable();
        expect(cards, findsWidgets);
        expect(tester.getRect(cards.first).bottom, greaterThan(pinned.bottom), reason: 'works scroll under the tabs, not over them');
      }
      expectNoLayoutErrors(tester);
    });
  }

  test('the author page strings exist in all four languages', () => expectLocalesComplete(['user', 'userPage']));
}

class _Related extends UserRelatedListSource {
  _Related(this.pages, {required super.userId, this.repeats = false});

  /// The pages in order, each with the next URL it names (or none).
  final List<({int count, String? next})> pages;

  /// Every page lists the same authors from the first on, as Pixiv answers;
  /// otherwise each page lists authors not served before.
  final bool repeats;

  /// What was asked for, in order: `offset N` or `url U`.
  final asked = <String>[];
  var _served = 0;
  var _authors = 0;

  UserPageResult _page() {
    final index = _served++;
    final page = index < pages.length ? pages[index] : (count: 0, next: null);
    final first = repeats ? 0 : _authors;
    _authors += page.count;
    return UserPageResult(
      userPreviews: sampleUserPreviews(count: first + page.count).sublist(first),
      nextUrl: page.next,
    );
  }

  @override
  Future<UserPageResult> loadOffsetPage(int offset) async {
    asked.add('offset $offset');
    return _page();
  }

  @override
  Future<UserPageResult> loadNextPage(String nextUrl) async {
    asked.add('url $nextUrl');
    return _page();
  }
}

class _FirstRelated extends UserRelatedListSource {
  _FirstRelated(this.first, {required super.userId});

  final Future<UserPageResult> Function() first;

  @override
  Future<UserPageResult> loadFirstPage() => first();
}

Map<Object, Override> _relatedOverride(Future<UserPageResult> Function() first) => {
  userRelatedSourceProvider: userRelatedSourceProvider.overrideWith((ref, userId) {
    final source = _FirstRelated(first, userId: userId);
    ref.onDispose(source.dispose);
    return source;
  }),
};

Future<void> _mountRelated(WidgetTester tester, Future<UserPageResult> Function() first, {UserDetailResult? detail}) =>
    mountPilotPage(tester, UserDetailPage(userDetail: detail ?? sampleUserDetail), overrides: _relatedOverride(first));

UserDetailResult _detailWith({required int id, UserProfile? profile}) => UserDetailResult(
  user: UserInfo(id: id, name: 'Author $id', account: 'author_$id', profileImageUrls: sampleUserDetail.user.profileImageUrls, comment: '', isFollowed: false),
  profile: profile ?? sampleUserDetail.profile,
  profilePublicity: sampleUserDetail.profilePublicity,
  workspace: sampleUserDetail.workspace,
);

void _relatedTests() {
  group('related users', () {
    Future<void> openDetails(WidgetTester tester) async {
      await tester.tap(_tab(t.user.tabs.profile));
      await settlePilot(tester);
    }

    testWidgets('the end of Details lists six authors with follow buttons, and View all opens the full list', (tester) async {
      await _mountRelated(tester, () async => UserPageResult(userPreviews: sampleUserPreviews(count: 8)));
      await openDetails(tester);
      expect(find.text(t.user.related.title), findsOneWidget);
      expect(find.widgetWithText(FrostListRow, 'Sample creator 1'), findsOneWidget);
      expect(find.widgetWithText(FrostListRow, 'サンプルの作者 6'), findsOneWidget);
      expect(find.widgetWithText(FrostListRow, 'Sample creator 7'), findsNothing, reason: 'only six rows');
      expect(find.descendant(of: find.byType(FrostListRow), matching: find.byType(AppFollowButton)), findsNWidgets(6));
      await tester.tap(find.text(t.user.related.viewAll));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.userRelated(sampleUserDetail.user.id));
    });

    testWidgets('a row opens its author', (tester) async {
      await _mountRelated(tester, () async => UserPageResult(userPreviews: sampleUserPreviews(count: 2)));
      await openDetails(tester);
      await tester.tap(find.text('Sample creator 1'));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.user(3000));
    });

    testWidgets('the section is hidden when there are none, when the request fails and on one\'s own page', (tester) async {
      await _mountRelated(tester, () async => const UserPageResult(userPreviews: []));
      await openDetails(tester);
      expect(find.text(t.user.related.title), findsNothing);

      await _mountRelated(tester, () async => throw StateError('offline'));
      await openDetails(tester);
      expect(find.text(t.user.related.title), findsNothing);

      await _mountRelated(
        tester,
        () async => UserPageResult(userPreviews: sampleUserPreviews(count: 3)),
        detail: _detailWith(id: int.parse(sampleAccount.user.id)),
      );
      await openDetails(tester);
      expect(find.text(t.user.related.title), findsNothing);
    });

    testWidgets('the section shows when the profile has no details to list', (tester) async {
      const bare = UserProfile(
        gender: '',
        birth: '',
        birthDay: '',
        birthYear: 0,
        region: '',
        addressId: 0,
        countryCode: '',
        job: '',
        jobId: 0,
        totalFollowUsers: 0,
        totalMypixivUsers: 0,
        totalIllusts: 0,
        totalManga: 0,
        totalNovels: 0,
        totalIllustBookmarksPublic: 0,
        totalIllustSeries: 0,
        totalNovelSeries: 0,
        isPremium: false,
        isUsingCustomProfileImage: false,
      );
      await _mountRelated(
        tester,
        () async => UserPageResult(userPreviews: sampleUserPreviews(count: 2)),
        detail: _detailWith(id: 2000, profile: bare),
      );
      await openDetails(tester);
      expect(find.text(t.user.empty.profile), findsOneWidget);
      expect(find.text(t.user.related.title), findsOneWidget);
    });

    test('the list pages by next URL, by offset without one, and stops on an empty page', () async {
      final byUrl = _Related([(count: 3, next: 'https://next/1'), (count: 2, next: null)], userId: 1);
      await byUrl.refresh(true);
      expect(byUrl.items, hasLength(3));
      await byUrl.loadMore();
      expect(byUrl.items, hasLength(5));
      expect(byUrl.asked, ['offset 0', 'url https://next/1']);

      final byOffset = _Related([(count: 3, next: null), (count: 2, next: null), (count: 0, next: null)], userId: 1);
      await byOffset.refresh(true);
      await byOffset.loadMore();
      expect(byOffset.items, hasLength(5));
      expect(byOffset.hasMore, isTrue);
      await byOffset.loadMore();
      expect(byOffset.asked, ['offset 0', 'offset 3', 'offset 5'], reason: 'the offset follows what has been read');
      expect(byOffset.hasMore, isFalse, reason: 'an empty page ends the list');
    });

    test('a page of authors already listed ends the list without repeating them', () async {
      final related = _Related([(count: 3, next: null), (count: 3, next: null), (count: 3, next: null)], userId: 1, repeats: true);
      await related.refresh(true);
      await related.loadMore();
      expect(related.items.map((preview) => preview.user.id), [3000, 3001, 3002], reason: 'Pixiv answers the second page with the first again');
      expect(related.hasMore, isFalse);
      await related.loadMore();
      expect(related.asked, ['offset 0', 'offset 3'], reason: 'nothing more is asked for');
    });

    testWidgets('the full page lists user cards, and none says so', (tester) async {
      await mountPilotPage(
        tester,
        const UserRelatedPage(userId: 2000),
        overrides: _relatedOverride(() async => UserPageResult(userPreviews: sampleUserPreviews(count: 3))),
      );
      expect(find.text(t.user.related.title), findsOneWidget);
      expect(find.byType(AppUserCard), findsNWidgets(3));
      await mountPilotPage(tester, const UserRelatedPage(userId: 2000), overrides: _relatedOverride(() async => const UserPageResult(userPreviews: [])));
      expect(find.text(t.user.related.empty), findsOneWidget);
    });
  });
}
