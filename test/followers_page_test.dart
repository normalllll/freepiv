import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/me/logic/me_logic.dart';
import 'package:freepiv/features/me/presentation/following_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

/// The account whose followers were asked for.
final _askedFor = <int>[];

class _Followers extends FollowerListSource {
  _Followers(this.first, {required super.userId});

  final Future<UserPageResult> Function() first;

  @override
  Future<UserPageResult> loadFirstPage() {
    _askedFor.add(userId);
    return first();
  }
}

Future<void> _mount(WidgetTester tester, Future<UserPageResult> Function() first, {Size size = desktopSize, double textScale = 1, bool signedIn = true}) {
  _askedFor.clear();
  return mountPilotPage(
    tester,
    const FollowersPage(),
    size: size,
    textScale: textScale,
    signedIn: signedIn,
    overrides: {followersSourceProvider: followersSourceProvider.overrideWith((ref, userId) => _Followers(first, userId: userId))},
  );
}

UserPreview _long(UserPreview preview) => UserPreview(
  user: User(id: preview.user.id, name: longText, account: longText, profileImageUrls: preview.user.profileImageUrls, isFollowed: false),
  illusts: preview.illusts,
  isMuted: preview.isMuted,
);

void main() {
  testWidgets('the signed-in account\'s followers fill the reading column as user rows', (tester) async {
    await _mount(tester, () async => UserPageResult(userPreviews: sampleUserPreviews(count: 3)));
    expect(find.text(t.me.followers), findsOneWidget);
    expect(_askedFor, [int.parse(sampleAccount.user.id)]);
    expect(find.byType(AppUserRow), findsNWidgets(3));
    final row = tester.getRect(find.byType(AppUserRow).first);
    expect(row.width, lessThanOrEqualTo(FrostMetrics.readingMaxWidth));
    expect(row.center.dx, moreOrLessEquals(desktopSize.width / 2, epsilon: 1));
  });

  testWidgets('empty, loading, failed and signed-out lists each say so', (tester) async {
    await _mount(tester, () async => const UserPageResult(userPreviews: []));
    expect(find.text(t.me.emptyFollowers), findsOneWidget);

    final never = Completer<UserPageResult>();
    await _mount(tester, () => never.future);
    expect(find.byType(AppRowsSkeleton), findsOneWidget);

    var attempts = 0;
    await _mount(tester, () async {
      if (attempts++ == 0) throw StateError('offline');
      return UserPageResult(userPreviews: sampleUserPreviews(count: 2));
    });
    await tester.tap(find.text(t.common.retry));
    await settlePilot(tester);
    expect(find.byType(AppUserRow), findsNWidgets(2));

    pixivAccountNotifier.value = null;
    await _mount(tester, () async => const UserPageResult(userPreviews: []), signedIn: false);
    expect(find.text(t.settings.account.notSignedIn), findsOneWidget);
    expect(_askedFor, isEmpty);
  });

  testWidgets('long names fit a phone at double text size', (tester) async {
    await _mount(tester, () async => UserPageResult(userPreviews: [for (final preview in sampleUserPreviews(count: 3)) _long(preview)]), size: phoneSize, textScale: 2);
    expect(find.byType(AppUserRow), findsWidgets);
    expectNoLayoutErrors(tester);
  });
}
