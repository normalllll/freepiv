import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/features/me/presentation/me_page.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('signed-out application routes return to login while proxy setup remains available', (tester) async {
    pixivAccountNotifier.value = null;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en', 'US')),
            routerConfig: AppRouter.router,
            builder: (context, child) => AppLayoutScope(child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final path in ['/', '/settings', '/downloads', '/about', '/fanbox', '/pixivision', '/novel/7']) {
      AppRouter.router.go(path);
      await tester.pumpAndSettle();
      expect(AppRouter.router.routeInformationProvider.value.uri.path, '/login', reason: path);
      expect(find.text(t.login.signInToPixiv), findsOneWidget);
      expect(find.text(t.fanbox.title), findsNothing);
    }

    await tester.tap(find.text(t.settings.proxy.open));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Me reaches downloads settings and about after sign-in', (tester) async {
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
        GoRoute(
          path: AppRoute.downloads.path,
          name: AppRoute.downloads.name,
          builder: (_, _) => const Scaffold(body: Text('Downloads destination')),
        ),
        GoRoute(
          path: AppRoute.settings.path,
          name: AppRoute.settings.name,
          builder: (_, _) => const Scaffold(body: Text('Settings destination')),
        ),
        GoRoute(
          path: AppRoute.about.path,
          name: AppRoute.about.name,
          builder: (_, _) => const Scaffold(body: Text('About destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en', 'US')),
            routerConfig: router,
            builder: (context, child) => AppLayoutScope(child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.fanbox.title), findsNothing);

    for (final (label, destination) in [
      (t.settings.downloads.tasksTitle, 'Downloads destination'),
      (t.me.settings, 'Settings destination'),
      (t.me.about, 'About destination'),
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(destination), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
