import 'package:flutter/widgets.dart';
import 'package:freepiv/app/account_scope.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_accounts.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/account/account_actions.dart';
import 'package:freepiv/features/settings/presentation/pixiv_sign_out.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

import 'support/account_fakes.dart';

/// A page with a deeper page pushed on it and two buttons that use the
/// account actions, in the app's Frost config.
Future<GoRouter> _mount(WidgetTester tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FrostButton(label: 'Deeper', onPressed: () => GoRouter.of(context).push('/deep')),
              Builder(
                builder: (context) => FrostButton(label: 'Leave', onPressed: () => confirmPixivSignOut(context)),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/deep',
        builder: (context, _) => Center(
          child: Builder(
            builder: (context) => FrostButton(label: 'Switch', onPressed: () => switchToAccount(context, '1001')),
          ),
        ),
      ),
      GoRoute(path: AppRoute.login.path, builder: (_, _) => const Text('login page')),
      GoRoute(path: AppRoute.accountsAdd.path, builder: (_, _) => const Text('add page')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    AccountScope(
      builder: (context, accountId) => TranslationProvider(
        child: FrostApp.router(config: freepivFrostConfig, routerConfig: router, title: 'freepiv'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<FakeAccountApis> _start(Map<String, dynamic> settings, {Map<String, Object> failures = const {}}) async {
  final apis = FakeAccountApis(failures);
  addTearDown(apis.restore);
  await AppSettings.initialize(store: SampleSettingsStore(settings));
  pixivApi = apis.createFor(AppSettings.accounts.active?.session);
  pixivAccountNotifier.value = pixivApi.account();
  addTearDown(() => pixivAccountNotifier.value = null);
  return apis;
}

void main() {
  testWidgets('a switch starts the account scope with a router of its own and says who is now signed in', (tester) async {
    await _start(accountSettings());
    final appRouter = AppRouter.router;
    await _mount(tester);
    await tester.tap(find.text('Deeper'));
    await tester.pumpAndSettle();
    expect(find.text('Switch'), findsOneWidget);

    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();

    expect(AppRouter.router, isNot(same(appRouter)), reason: 'the new scope has its own router');
    expect(AppSettings.accounts.activeId, '1001');
    expect(find.text(t.accounts.switched(name: sampleSecondAccount.user.name)), findsOneWidget);
  });

  testWidgets('a refused account stays where it was, says why and is marked', (tester) async {
    await _start(accountSettings(), failures: {'1001': oauthRefused});
    final router = await _mount(tester);
    await tester.tap(find.text('Deeper'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/deep');
    expect(AppSettings.accounts.activeId, '1000');
    expect(AppSettings.accounts.entry('1001')!.state, PixivAccountState.needsSignIn);
    expect(find.textContaining(t.accounts.switchFailed), findsOneWidget);
  });

  testWidgets('a network failure only says so', (tester) async {
    await _start(accountSettings(), failures: {'1001': offline});
    final router = await _mount(tester);
    await tester.tap(find.text('Deeper'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/deep');
    expect(AppSettings.accounts.entry('1001')!.state, PixivAccountState.usable);
    expect(find.textContaining(t.accounts.switchFailed), findsOneWidget);
  });

  testWidgets('an account that needs signing in opens the add page instead of switching', (tester) async {
    await _start(accountSettings(secondState: PixivAccountState.needsSignIn));
    final router = await _mount(tester);
    await tester.tap(find.text('Deeper'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();

    expect(find.text('add page'), findsOneWidget);
    expect(router.state.uri.path, AppRoute.accountsAdd.path);
    expect(AppSettings.accounts.activeId, '1000');
  });

  testWidgets('signing out of the current account switches to the other one and says so', (tester) async {
    await _start(accountSettings());
    await _mount(tester);

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text(t.signOut.title), findsOneWidget);
    await tester.tap(find.text(t.signOut.confirm).last);
    await tester.pumpAndSettle();

    expect(AppSettings.accounts.entries.map((entry) => entry.id), ['1001']);
    expect(AppSettings.accounts.activeId, '1001');
    expect(find.text(t.accounts.switched(name: sampleSecondAccount.user.name)), findsOneWidget);
  });

  testWidgets('signing out of the last account signs out and starts the scope over', (tester) async {
    await _start({
      AppSettings.accountsKey: PixivAccountBook(
        entries: [PixivAccountEntry(session: sampleAccount, lastUsed: DateTime.utc(2026))],
        activeId: '1000',
      ).toJson(),
    });
    await _mount(tester);

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.signOut.confirm).last);
    await tester.pumpAndSettle();

    expect(pixivAccountNotifier.value, isNull);
    expect(AppSettings.accounts.isEmpty, isTrue);
  });
}
