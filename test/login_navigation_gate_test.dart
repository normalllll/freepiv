import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/features/me/presentation/me_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:go_router/go_router.dart';
import 'support/frost_test_app.dart';

void main() {
  testWidgets('signed-out application routes return to login while proxy setup remains available', variant: TargetPlatformVariant.only(TargetPlatform.android), (tester) async {
    pixivAccountNotifier.value = null;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: frostTestRouterApp(AppRouter.router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final path in ['/', '/settings', '/downloads', '/about', '/fanbox', '/pixivision', '/novel/7']) {
      AppRouter.router.go(path);
      await tester.pumpAndSettle();
      expect(AppRouter.router.routeInformationProvider.value.uri.path, '/login', reason: path);
      expect(find.text(t.loginPage.signIn), findsOneWidget);
      expect(find.text(t.fanbox.title), findsNothing);
    }

    await tester.tap(find.text(t.settings.proxy.open));
    await tester.pumpAndSettle();
    expect(find.text(t.settings.proxy.save), findsOneWidget, reason: 'the proxy form is open');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Me reaches FANBOX, downloads, settings and about after sign-in', (tester) async {
    pixivAccountNotifier.value = const UserAccountResult(
      accessToken: '',
      expiresIn: 0,
      tokenType: '',
      scope: '',
      refreshToken: '',
      user: LocalUser(
        profileImageUrls: LocalUserProfileImageUrls(px16X16: '', px50X50: '', px170X170: ''),
        id: '42',
        name: 'Reader',
        account: 'reader',
        mailAddress: '',
        isPremium: false,
        xRestrict: 0,
        isMailAuthorized: false,
        requirePolicyAgreement: false,
      ),
    );
    addTearDown(() => pixivAccountNotifier.value = null);
    final router = GoRouter(
      initialLocation: AppRoute.me.path,
      routes: [
        GoRoute(path: AppRoute.me.path, name: AppRoute.me.name, builder: (_, _) => const MePage()),
        GoRoute(path: AppRoute.fanbox.path, name: AppRoute.fanbox.name, builder: (_, _) => const Text('FANBOX destination')),
        GoRoute(
          path: AppRoute.downloads.path,
          name: AppRoute.downloads.name,
          builder: (_, _) => const Text('Downloads destination'),
        ),
        GoRoute(
          path: AppRoute.settings.path,
          name: AppRoute.settings.name,
          builder: (_, _) => const Text('Settings destination'),
        ),
        GoRoute(
          path: AppRoute.about.path,
          name: AppRoute.about.name,
          builder: (_, _) => const Text('About destination'),
        ),
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

    for (final (label, destination) in [
      (t.fanbox.title, 'FANBOX destination'),
      (t.navigation.downloads, 'Downloads destination'),
      (t.me.settings, 'Settings destination'),
      (t.me.about, 'About destination'),
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(destination), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
