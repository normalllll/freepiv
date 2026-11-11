import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/settings/presentation/pixiv_sign_out.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<(GoRouter, List<String>)> mount(WidgetTester tester) async {
    final signedOut = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Center(
            child: Builder(
              builder: (context) => FrostButton(
                label: 'Sign out',
                onPressed: () => confirmPixivSignOut(context, signOut: () => signedOut.add('out')),
              ),
            ),
          ),
        ),
        GoRoute(path: AppRoute.login.path, builder: (_, _) => const Text('login page')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: FrostApp.router(config: freepivFrostConfig, routerConfig: router, title: 'freepiv'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out of Pixiv?'), findsOneWidget);
    return (router, signedOut);
  }

  testWidgets('cancelling keeps the account', (tester) async {
    final (router, signedOut) = await mount(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(signedOut, isEmpty);
    expect(router.state.uri.path, '/');
  });

  testWidgets('confirming signs out and opens the login page', (tester) async {
    final (router, signedOut) = await mount(tester);
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();
    expect(signedOut, ['out']);
    expect(find.text('login page'), findsOneWidget);
  });
}
