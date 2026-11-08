import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/me/presentation/following_page.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

class _Following extends UserFollowingListSource {
  _Following(this.first) : super(userId: 1000);

  final Future<UserPageResult> Function() first;

  @override
  Future<UserPageResult> loadFirstPage() => first();
}

class _Notifier extends UserFollowingUsers {
  _Notifier(this.first);

  final Future<UserPageResult> Function() first;

  @override
  UserFollowingListSource build({required int userId}) {
    final source = _Following(first);
    ref.onDispose(source.dispose);
    return source;
  }
}

Future<void> _mount(WidgetTester tester, Future<UserPageResult> Function() first, {Size size = desktopSize, double textScale = 1, bool signedIn = true}) =>
    mountPilotPage(
      tester,
      const FollowingPage(),
      size: size,
      textScale: textScale,
      signedIn: signedIn,
      overrides: {userFollowingUsersProvider: userFollowingUsersProvider.overrideWith2((_) => _Notifier(first))},
    );

void main() {
  testWidgets('a work in a row flies into the work it opens', (tester) async {
    final previews = sampleUserPreviews(count: 2);
    await _mount(tester, () async => UserPageResult(userPreviews: previews));
    final thumbnail = find.byType(AppArtworkThumbnail).first;
    expect(
      find.descendant(of: thumbnail, matching: find.byType(FrostMediaHero)),
      findsOneWidget,
      reason: 'the hero the detail stage receives',
    );
    expect(tester.widget<AppArtworkThumbnail>(thumbnail).illust.id, previews.first.illusts.first.id);
    await tester.tap(thumbnail);
    await settlePilot(tester);
    expect(openedLocations.single, AppLocations.illust(previews.first.illusts.first.id));
  });

  testWidgets('followed users are rows; Follow does not open the row', (tester) async {
    await _mount(tester, () async => UserPageResult(userPreviews: sampleUserPreviews(count: 4)));
    expect(find.byType(AppUserRow), findsNWidgets(4));
    await tester.tap(find.byType(AppFollowButton).first);
    await settlePilot(tester);
    expect(openedLocations, isEmpty);
    await tester.tap(find.text('Sample creator 1'));
    await settlePilot(tester);
    expect(openedLocations.single, '/user/3000');
  });

  testWidgets('empty', (tester) async {
    await _mount(tester, () async => const UserPageResult(userPreviews: []));
    expect(find.text(t.me.emptyFollowing), findsOneWidget);
  });

  testWidgets('loading', (tester) async {
    final never = Completer<UserPageResult>();
    await _mount(tester, () => never.future);
    expect(find.byType(AppUserRowsSkeleton), findsOneWidget);
  });

  testWidgets('error', (tester) async {
    await _mount(tester, () async => throw StateError('offline'));
    expect(find.byType(FrostErrorContent), findsOneWidget);
  });

  testWidgets('long names truncate on a phone at double text size', (tester) async {
    await _mount(
      tester,
      () async => const UserPageResult(
        userPreviews: [
          UserPreview(
            user: User(
              id: 1,
              name: longText,
              account: longText,
              profileImageUrls: ProfileImageUrls(medium: ''),
            ),
            illusts: [],
            isMuted: false,
          ),
        ],
      ),
      size: phoneSize,
      textScale: 2,
    );
    expectNoLayoutErrors(tester);
  });

  testWidgets('signed out it offers to sign in', (tester) async {
    await _mount(tester, () async => const UserPageResult(userPreviews: []), signedIn: false);
    expect(find.text(t.login.signInToPixiv), findsOneWidget);
  });
}
