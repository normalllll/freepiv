import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/account/account_actions.dart';
import 'package:freepiv/features/settings/presentation/pixiv_sign_out.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/account_fakes.dart';

Future<void> _pump(WidgetTester tester, [int frames = 12]) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late FakeAccountApis apis;
  late FrostWindowController window;

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1147, 717);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    apis = FakeAccountApis();
    addTearDown(apis.restore);
    await AppSettings.initialize(store: SampleSettingsStore(sampleSettings));
    pixivApi = apis.createFor(AppSettings.accounts.active?.session);
    pixivAccountNotifier.value = pixivApi.account();
    addTearDown(() => pixivAccountNotifier.value = null);
    window = FrostWindowController(minimumSize: const Size(320, 480));
    AppRouter.router.go(AppRoute.home.path);
    await tester.pumpWidget(FreepivApp(windowController: window, overrides: sampleOverrides));
    await _pump(tester);
  }

  testWidgets('switching accounts gives the app a new router at the home page and a working title-bar search', (tester) async {
    await mount(tester);
    final before = AppRouter.router;
    final rootKey = AppRouter.rootNavigatorKey;
    unawaited(AppRouter.router.push(AppRoute.settings.path));
    await _pump(tester);
    expect(AppRouter.currentUri.path, AppRoute.settings.path);

    await switchToAccount(AppRouter.rootNavigatorKey.currentContext!, '1001');
    await _pump(tester);

    expect(AppSettings.accounts.activeId, '1001');
    expect(AppRouter.router, isNot(same(before)));
    expect(AppRouter.rootNavigatorKey, isNot(same(rootKey)));
    expect(AppRouter.currentUri.path, AppRoute.home.path, reason: 'the pages pushed for the old account are gone');
    expect(tester.takeException(), isNull, reason: 'nothing of the old scope is used after it was disposed');

    final session = ProviderScope.containerOf(tester.element(find.byType(FrostShell))).read(appSearchSessionProvider);
    session.controller.value = const TextEditingValue(text: 'miku', selection: TextSelection.collapsed(offset: 4));
    session.focusNode.requestFocus();
    await _pump(tester, 3);
    expect(tester.takeException(), isNull);
    expect(find.byType(AppTitleBarSearch, skipOffstage: false), findsOneWidget);
    final field = tester.widget<FrostCaptionSearch>(find.byType(FrostCaptionSearch, skipOffstage: false));
    expect(field.controller, same(session.controller), reason: 'the title bar shows the session of the new scope');
    expect(field.controller.text, 'miku');
    expect(find.text(t.accounts.switched(name: sampleSecondAccount.user.name)), findsOneWidget);
  });

  /// Signs out through the confirmation, as the settings do, and waits for the
  /// new scope.
  Future<void> signOut(WidgetTester tester, {String? accountId}) async {
    final signedOut = confirmPixivSignOut(AppRouter.rootNavigatorKey.currentContext!, accountId: accountId);
    await _pump(tester, 6);
    await tester.tap(find.text(t.signOut.confirm).last);
    await _pump(tester);
    expect(await signedOut, isTrue);
  }

  testWidgets('signing out of the current account opens the home page of the other one, in a new router', (tester) async {
    await mount(tester);
    final before = AppRouter.router;
    unawaited(AppRouter.router.push(AppRoute.settings.path));
    await _pump(tester);

    await signOut(tester);

    expect(AppSettings.accounts.activeId, '1001');
    expect(AppRouter.router, isNot(same(before)));
    expect(AppRouter.currentUri.path, AppRoute.home.path);
    expect(find.text(t.accounts.switched(name: sampleSecondAccount.user.name)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signing out of the last account opens the login page', (tester) async {
    await mount(tester);
    await removePixivAccount('1001');
    final before = AppRouter.router;

    await signOut(tester);

    expect(AppSettings.accounts.isEmpty, isTrue);
    expect(AppRouter.router, isNot(same(before)));
    expect(AppRouter.currentUri.path, AppRoute.login.path);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the window controller outlives the switch', (tester) async {
    await mount(tester);

    await switchPixivAccount('1001');
    await _pump(tester);

    expect(tester.widgetList<FrostWindowHost>(find.byType(FrostWindowHost)).single.controller, same(window));
  });
}
