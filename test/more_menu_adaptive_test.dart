import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/core/downloads/download_manager.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/ui/fp_icon.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<GoRouter> mountShell(WidgetTester tester, Size size, {double textScale = 1, AppLocale locale = AppLocale.enUs}) async {
    LocaleSettings.setLocale(locale);
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    final cacheDirectory = Directory('build/more-menu-test/cache').absolute;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, (call) async {
      if (call.method == 'getTemporaryDirectory' || call.method == 'getApplicationSupportDirectory' || call.method == 'getApplicationDocumentsDirectory') {
        return cacheDirectory.path;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, null));
    await tester.runAsync(initializeDownloadManager);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final canPop = ValueNotifier<bool>(false);
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => RouterShell(canPopListenable: canPop, onBack: () {}, onResetRightNavigator: () {}, child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Center(child: Text('Home destination')),
            ),
            GoRoute(
              path: '/downloads',
              builder: (context, state) => const Center(child: Text('Download destination')),
            ),
            GoRoute(
              path: '/search',
              builder: (context, state) => const Center(child: Text('Discover destination')),
            ),
            GoRoute(
              path: '/newest',
              builder: (context, state) => const Center(child: Text('Activity destination')),
            ),
            GoRoute(
              path: '/me',
              builder: (context, state) => const Center(child: Text('Me destination')),
            ),
            GoRoute(
              path: '/about',
              builder: (context, state) => const Center(child: Text('About destination')),
            ),
          ],
        ),
      ],
    );
    addTearDown(() {
      router.dispose();
      canPop.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(
            locale: locale.flutterLocale,
            theme: AppTheme.light(platform: TargetPlatform.windows, locale: locale.flutterLocale),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
              child: AppLayoutScope(child: child!),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('desktop more menu stays visible in a short window and Escape dismisses it', (tester) async {
    await mountShell(tester, const Size(800, 340));
    final more = find.byWidgetPredicate((widget) => widget is DesktopNavItem && widget.label == t.navigation.more);
    await tester.scrollUntilVisible(
      more,
      80,
      scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();

    final menuSurface = find.byWidgetPredicate((widget) => widget is FpSurface && widget.role == FpSurfaceRole.overlay);
    final menuItems = find.descendant(of: menuSurface, matching: find.byType(TextButton));
    expect(menuSurface, findsOneWidget);
    expect(find.descendant(of: menuSurface, matching: find.byType(BackdropFilter)), findsOneWidget);
    expect(menuItems, findsNWidgets(5));
    final menu = tester.getRect(menuItems.first);
    expect(menu.left, greaterThan(tester.getRect(more).right));
    expect(menu.top, greaterThanOrEqualTo(0));
    expect(tester.getRect(menuItems.last).bottom, lessThanOrEqualTo(340));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(menuSurface, findsNothing);
    expect(find.text('Home destination'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(menuItems, findsNWidgets(5));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }, skip: Platform.isAndroid);

  testWidgets('mobile navigation has four direct destinations and no more sheet', (tester) async {
    await mountShell(tester, const Size(560, 240));
    expect(_destination(t.navigation.more), findsNothing);
    expect(_destination(t.navigation.home), findsOneWidget);
    expect(_destination(t.common.discover), findsOneWidget);
    expect(_destination(t.navigation.activity), findsOneWidget);
    expect(_destination(t.navigation.me), findsOneWidget);

    await tester.tap(_destination(t.common.discover));
    await tester.pumpAndSettle();
    expect(find.text('Discover destination'), findsOneWidget);
    await tester.tap(_destination(t.navigation.activity));
    await tester.pumpAndSettle();
    expect(find.text('Activity destination'), findsOneWidget);
    await tester.tap(_destination(t.navigation.me));
    await tester.pumpAndSettle();
    expect(find.text('Me destination'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('four mobile labels stay complete across widths languages and text scales', (tester) async {
    addTearDown(() => LocaleSettings.setLocale(AppLocale.enUs));
    for (final locale in AppLocale.values) {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          await mountShell(tester, Size(width, 844), textScale: scale, locale: locale);
          final labels = [t.navigation.home, t.common.discover, t.navigation.activity, t.navigation.me];
          expect(_destination(t.navigation.more), findsNothing);
          final iconCenters = <double>[];
          final labelTops = <double>[];
          for (final label in labels) {
            final destination = _destination(label);
            expect(destination, findsOneWidget);
            final text = find.descendant(of: destination, matching: find.text(label));
            expect(text, findsOneWidget);
            expect((tester.widget<Text>(text)).maxLines, isNull);
            iconCenters.add(tester.getCenter(find.descendant(of: destination, matching: find.byType(FpIcon))).dy);
            labelTops.add(tester.getTopLeft(text).dy);
          }
          for (final center in iconCenters.skip(1)) {
            expect(center, closeTo(iconCenters.first, 0.1));
          }
          for (final top in labelTops.skip(1)) {
            expect(top, closeTo(labelTops.first, 0.1));
          }
          expect(tester.takeException(), isNull, reason: '$locale $width $scale');
        }
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('desktop menu can reach its last item when shorter than the menu', (tester) async {
    await mountShell(tester, const Size(800, 200));
    final more = find.byWidgetPredicate((widget) => widget is DesktopNavItem && widget.label == t.navigation.more);
    await tester.scrollUntilVisible(
      more,
      80,
      scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();
    // The collapsed sidebar keeps its hidden secondary column mounted, so
    // look for the item inside the menu surface only.
    final menuSurface = find.byWidgetPredicate((widget) => widget is FpSurface && widget.role == FpSurfaceRole.overlay);
    final last = find.descendant(of: menuSurface, matching: find.text(t.navigation.about));
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(find.text('About destination'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }, skip: Platform.isAndroid);
}

/// Navigation items expose their visible label as their semantics label
/// (no duplicate tooltip).
Finder _destination(String label) =>
    find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == label && widget.properties.button == true);
