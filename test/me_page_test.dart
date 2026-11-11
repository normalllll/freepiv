import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_accounts.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/me/presentation/me_page.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/account_fakes.dart';
import 'support/pilot_harness.dart';

class _Details extends UserDetail {
  _Details(this.answer);
  final Future<UserDetailResult> Function() answer;
  @override
  FutureOr<UserDetailResult> build(UserDetailArgs args) => answer();
}

Future<void> _mount(
  WidgetTester tester, {
  Future<UserDetailResult> Function()? details,
  Size size = desktopSize,
  double textScale = 1,
  bool signedIn = true,
  Map<String, dynamic>? settings,
}) => mountPilotPage(
  tester,
  const MePage(),
  size: size,
  textScale: textScale,
  signedIn: signedIn,
  settings: settings,
  overrides: {if (details != null) userDetailProvider: userDetailProvider.overrideWith2((_) => _Details(details))},
);

/// Tall enough for every row of the grouped list.
const _tallDesktop = Size(1147, 900);

List<String> _rows(WidgetTester tester) => tester.widgetList<FrostListRow>(find.byType(FrostListRow)).map((row) => row.title).toList();

void main() {
  testWidgets('the account card heads the page with its e-mail, counts and own page; no works are shown', (tester) async {
    await _mount(tester);
    final account = sampleAccount.user;
    expect(find.text(account.name), findsOneWidget);
    expect(find.text('@${account.account}'), findsOneWidget);
    expect(find.text(account.mailAddress), findsOneWidget);
    expect(tester.widgetList<FrostStat>(find.byType(FrostStat)).map((stat) => stat.value), contains(formatCount(sampleUserDetail.profile.totalIllusts)));
    expect(find.byType(FrostStat), findsNWidgets(4));
    expect(find.byType(FrostMediaCard), findsNothing);
    final pictures = find.byType(FrostMediaFrame).evaluate().where((frame) => frame.findAncestorWidgetOfExactType<FrostAvatar>() == null);
    expect(pictures, isEmpty, reason: 'no artwork pictures on Me, only the avatar');
    final card = tester.getRect(find.byType(FrostSurface).first);
    expect(tester.getRect(find.byType(FrostListRow).first).top, greaterThan(card.bottom), reason: 'the rows follow the card');

    await tester.tap(find.text(t.me.profile));
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.user(account.id));
  });

  testWidgets('every entry is a row with a chevron, one under another, and opens its page; downloads count what needs attention', (tester) async {
    await _mount(tester, size: _tallDesktop);
    final labels = [
      t.me.following,
      t.me.followers,
      t.me.mypixiv,
      t.me.watchlist,
      t.me.history,
      t.me.editProfile,
      t.me.workspace,
      t.fanbox.title,
      t.navigation.downloads,
      t.me.about,
      t.me.settings,
    ];
    expect(_rows(tester), labels);
    final rows = tester.widgetList<FrostListRow>(find.byType(FrostListRow)).toList();
    final tops = [for (final label in labels) tester.getTopLeft(find.widgetWithText(FrostListRow, label)).dy];
    expect(tops, orderedEquals([...tops]..sort()), reason: 'a vertical list');
    expect(tops.toSet(), hasLength(labels.length));
    final badge = tester.widget<FrostCountBadge>(
      find.descendant(of: find.widgetWithText(FrostListRow, t.navigation.downloads), matching: find.byType(FrostCountBadge)),
    );
    expect((badge.count, badge.tone), (1, FrostCountBadgeTone.negative), reason: 'the sample downloads have one failure');
    expect(rows, hasLength(labels.length));
    final expected = [
      AppRoute.meFollowing.path,
      AppRoute.meFollowers.path,
      AppRoute.meMypixiv.path,
      AppRoute.meWatchlist.path,
      AppRoute.meHistory.path,
      AppRoute.meProfileEdit.path,
      AppRoute.meWorkspaceEdit.path,
      AppRoute.fanbox.path,
      AppRoute.downloads.path,
      AppRoute.about.path,
      AppRoute.settings.path,
    ];
    for (final (index, location) in expected.indexed) {
      await _mount(tester, size: _tallDesktop);
      await tester.tap(find.text(labels[index]));
      await settlePilot(tester);
      expect(openedLocations.last, location);
    }
  });

  testWidgets('counts wait in placeholders; failed counts leave the rest of the page', (tester) async {
    final never = Completer<UserDetailResult>();
    await _mount(tester, details: () => never.future);
    // FrostStat.skeleton builds a private placeholder type.
    expect(find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_SkeletonStat'), findsNWidgets(4), reason: 'placeholders');

    await _mount(tester, details: () async => throw StateError('offline'));
    expect(find.byType(FrostStat), findsNothing);
    expect(find.text(sampleAccount.user.name), findsOneWidget);
    expect(_rows(tester), hasLength(11));
  });

  testWidgets('signed out: the way to sign in, and the entries that need no account', (tester) async {
    pixivAccountNotifier.value = null;
    await _mount(tester, signedIn: false);
    expect(find.text(t.login.signInToPixiv), findsOneWidget);
    expect(_rows(tester), [t.fanbox.title, t.navigation.downloads, t.me.about, t.me.settings]);
  });

  testWidgets('a phone at double text size fits the card and the rows in a width-limited column', (tester) async {
    await _mount(tester, size: phoneSize, textScale: 2);
    expectNoLayoutErrors(tester);
    await _mount(tester);
    expect(tester.getSize(find.byType(FrostListRow).first).width, lessThanOrEqualTo(FrostMetrics.readingMaxWidth));
  });

  group('switching accounts from the card', () {
    Finder switchButton() => find.bySemanticsLabel(t.accounts.switchAccount);

    Future<void> open(WidgetTester tester, {Map<String, dynamic>? settings, Size size = desktopSize, double textScale = 1}) async {
      await _mount(tester, settings: settings ?? accountSettings(), size: size, textScale: textScale);
      await tester.tap(switchButton().first);
      await settlePilot(tester, frames: 8);
    }

    testWidgets('the card has a Switch account icon button beside My profile, which opens the accounts, adding and managing', (tester) async {
      await _mount(tester, settings: accountSettings());
      expect(find.text(t.accounts.switchAccount), findsNothing, reason: 'an icon, its label kept for tooltips and accessibility');
      expect(switchButton(), findsWidgets);
      final profile = tester.getRect(find.text(t.me.profile));
      final switcher = tester.getRect(switchButton().first);
      expect(switcher.left, greaterThan(profile.right), reason: 'beside My profile, at the end');

      await tester.tap(switchButton().first);
      await settlePilot(tester, frames: 8);

      expect(find.text(t.accounts.switchAccount), findsOneWidget, reason: 'the popover is titled');
      expect(find.text('@${sampleAccount.user.account}'), findsWidgets);
      expect(find.text(sampleSecondAccount.user.name), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == t.accounts.current),
        findsOneWidget,
        reason: 'the current account is checked',
      );
      expect(find.byTooltip(t.accounts.switchTo(name: sampleSecondAccount.user.name)), findsOneWidget);
      expect(find.text(t.accounts.add), findsOneWidget);
      expect(find.text(t.accounts.manage), findsOneWidget);
      expect(find.text(t.accounts.signOutOne), findsNothing, reason: 'signing out stays in the settings');
    });

    testWidgets('the account rows have the avatar size of the other user rows, and no more menu', (tester) async {
      await open(tester);

      final row = find.widgetWithText(FrostListRow, sampleSecondAccount.user.name);
      final avatar = tester.widget<FrostAvatar>(find.descendant(of: row, matching: find.byType(FrostAvatar)));
      expect(avatar.size, FrostAvatarSize.regular);
      expect(find.descendant(of: row, matching: find.bySemanticsLabel(FrostScope.labelsOf(tester.element(row)).more)), findsNothing);
    });

    testWidgets('Add account and Manage accounts close the popover and open their pages', (tester) async {
      await open(tester);
      await tester.tap(find.text(t.accounts.add));
      await settlePilot(tester);
      expect(openedLocations.last, AppRoute.accountsAdd.path);
      expect(find.text(t.accounts.manage), findsNothing, reason: 'the popover closed');

      await open(tester);
      await tester.tap(find.text(t.accounts.manage));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.settings(account: true));
    });

    testWidgets('an account that needs signing in says so and opens the add page', (tester) async {
      await open(tester, settings: accountSettings(secondState: PixivAccountState.needsSignIn));
      final entry = find.text('@${sampleSecondAccount.user.account} · ${t.accounts.needsSignIn}');
      expect(entry, findsOneWidget);

      await tester.tap(entry);
      await settlePilot(tester);

      expect(openedLocations.last, AppRoute.accountsAdd.path);
    });

    testWidgets('tapping another account closes the popover and switches to it', (tester) async {
      final apis = FakeAccountApis();
      addTearDown(apis.restore);
      await open(tester);
      pixivApi = apis.createFor(sampleAccount);

      await tester.tap(find.text(sampleSecondAccount.user.name));
      await settlePilot(tester);

      expect(AppSettings.accounts.activeId, '1001');
      expect(find.text(t.accounts.manage), findsNothing, reason: 'the popover closed');
    });

    testWidgets('a phone opens a sheet, at double text size too', (tester) async {
      await open(tester, size: phoneSize);
      expect(find.text(t.accounts.manage), findsOneWidget);
      expectNoLayoutErrors(tester);

      await open(tester, size: phoneSize, textScale: 2);
      expect(find.text(t.accounts.manage), findsOneWidget);
      expectNoLayoutErrors(tester);
    });
  });

  test('the Me strings exist in all four languages', () => expectLocalesComplete(['me']));
}
