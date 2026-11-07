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

  testWidgets('loading: an author known only by id shows the header and feed at their size', (tester) async {
    final never = Completer<UserDetailResult>();
    await _mount(tester, id: 2000, load: () => never.future);
    expect(find.byType(AppIdentityHeader), findsOneWidget);
    expect(find.byType(AppArtworkWaterfallSkeleton), findsOneWidget);
    expect(find.byType(FrostTabBar), findsNothing);
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
    expect(find.byType(AppUserRow), findsWidgets);
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
  }, skip: true); // FrostTabBar ensureVisible scrolls the outer view: freepiv-20261107-tab-bar-ensure-visible

  test('the author page strings exist in all four languages', () => expectLocalesComplete(['user', 'userPage']));
}
