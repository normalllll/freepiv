import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/home/presentation/home_page.dart';
import 'package:frost_ui/frost_ui.dart';

/// The app itself, with its router, shell wiring and sample data.
Future<void> _mount(WidgetTester tester, {String at = '/'}) async {
  tester.view.physicalSize = const Size(1147, 717);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await AppSettings.initialize(store: SampleSettingsStore(sampleSettings));
  pixivAccountNotifier.value = sampleAccount;
  addTearDown(() => pixivAccountNotifier.value = null);
  AppRouter.router.go(at);
  await tester.pumpWidget(
    FreepivApp(
      windowController: FrostWindowController(minimumSize: const Size(320, 480)),
      overrides: sampleOverrides,
    ),
  );
  await _frames(tester);
}

/// Sample pages keep placeholders ticking, so time is advanced in steps.
Future<void> _frames(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _go(WidgetTester tester, String location) async {
  AppRouter.router.go(location);
  await _frames(tester);
}

Future<void> _push(WidgetTester tester, String location) async {
  AppRouter.router.push(location);
  await _frames(tester);
}

FrostShell _shell(WidgetTester tester) => tester.widget<FrostShell>(find.byType(FrostShell));

Future<void> _selectSecondary(WidgetTester tester, AppRoute route) async {
  _shell(tester).secondary!.onSelected(appSecondaryRoutes.indexOf(route));
  await _frames(tester);
}

Future<void> _escape(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await _frames(tester);
}

void main() {
  testWidgets('three destinations and the downloads, FANBOX and settings group', (tester) async {
    await _mount(tester);
    final shell = _shell(tester);
    expect(shell.destinations.map((destination) => destination.label), ['Home', 'Activity', 'Me']);
    expect(shell.secondary!.destinations.map((destination) => destination.label), ['Downloads', 'FANBOX', 'Settings']);
    expect(appSecondaryRoutes, [AppRoute.downloads, AppRoute.fanbox, AppRoute.settings]);
    expect(shell.atDestinationRoot, isTrue);
    expect(shell.canGoBack, isFalse);
    expect(shell.backToFirst, isNotNull);
    expect(shell.brand, isNotNull);
  });

  testWidgets('a page any destination opens keeps the destination it was opened from highlighted', (tester) async {
    await _mount(tester);
    for (final (destination, index) in [(AppRoute.newest, 1), (AppRoute.me, 2), (AppRoute.home, 0)]) {
      await _go(tester, destination.path);
      expect(_shell(tester).selectedIndex, index, reason: destination.path);
      await _selectSecondary(tester, AppRoute.settings);
      expect(AppRouter.currentUri.path, AppRoute.settings.path);
      expect(_shell(tester).secondary!.selectedIndex, appSecondaryRoutes.indexOf(AppRoute.settings));
      expect(_shell(tester).selectedIndex, isNull, reason: 'settings opened from ${destination.path} highlights settings alone');
      await _push(tester, AppRoute.about.path);
      expect(_shell(tester).selectedIndex, index, reason: 'two pages up from ${destination.path}');
    }
    await _go(tester, AppRoute.meFollowing.path);
    expect(_shell(tester).selectedIndex, 2, reason: 'a page of Me highlights Me');
  });

  testWidgets('a FANBOX page highlights FANBOX alone, and the page it was opened from takes the highlight back', (tester) async {
    await _mount(tester);
    await _push(tester, AppLocations.fanboxPost('1001'));
    expect(_shell(tester).secondary!.selectedIndex, appSecondaryRoutes.indexOf(AppRoute.fanbox));
    expect(_shell(tester).selectedIndex, isNull, reason: 'no primary destination next to FANBOX');
    await _escape(tester);
    expect(AppRouter.currentUri.path, AppRoute.home.path);
    expect(_shell(tester).selectedIndex, 0);
    expect(_shell(tester).secondary!.selectedIndex, isNull);
  });

  testWidgets('choosing the secondary page already on top opens nothing', (tester) async {
    await _mount(tester);
    await _selectSecondary(tester, AppRoute.settings);
    expect(AppRouter.rightNavigatorDepth, 1);
    await _selectSecondary(tester, AppRoute.settings);
    expect(AppRouter.rightNavigatorDepth, 1, reason: 'no second settings page');
    await _push(tester, AppRoute.about.path);
    await _selectSecondary(tester, AppRoute.settings);
    expect(AppRouter.rightNavigatorDepth, 1, reason: 'settings below the top page does not count: it replaces both');
    expect(AppRouter.currentUri.path, AppRoute.settings.path);
  });

  testWidgets('a sidebar choice of a secondary destination is a switch: Back works as after a primary switch and the stack does not grow', (tester) async {
    await _mount(tester);
    // A primary switch: a destination root, nothing to go back to.
    _shell(tester).onDestinationSelected(1);
    await _frames(tester);
    expect(_shell(tester).canGoBack, isFalse);

    await _push(tester, AppRoute.ranking.path);
    for (final route in [...appSecondaryRoutes, ...appSecondaryRoutes]) {
      await _selectSecondary(tester, route);
      expect(AppRouter.currentUri.path, route.path);
      expect(AppRouter.rightNavigatorDepth, 1, reason: '${route.path} replaces the pages above the destination root');
      expect(_shell(tester).atDestinationRoot, isTrue, reason: '${route.path} is a destination root');
      expect(_shell(tester).canGoBack, isFalse, reason: 'no Back to the page it was chosen from');
      await _escape(tester);
      expect(AppRouter.currentUri.path, route.path, reason: 'Escape does nothing at a destination root');
    }

    // Pages opened from a switched destination go back to it, and it stays a root.
    await _push(tester, AppRoute.about.path);
    expect(_shell(tester).canGoBack, isTrue);
    await _escape(tester);
    expect(AppRouter.currentUri.path, AppRoute.settings.path);
    expect(_shell(tester).canGoBack, isFalse);

    // The same page opened from a row of Me is pushed and keeps Back.
    _shell(tester).onDestinationSelected(2);
    await _frames(tester);
    await _push(tester, AppRoute.settings.path);
    expect(_shell(tester).canGoBack, isTrue);
    await _escape(tester);
    expect(AppRouter.currentUri.path, AppRoute.me.path);
  });

  testWidgets('secondary navigation preserves the source page and its state', (tester) async {
    await _mount(tester);
    final home = find.byType(HomePage);
    final homeElement = tester.element(home);
    // The page's own vertical scroll, not a row inside it.
    ScrollableState pageScroll() => tester
        .stateList<ScrollableState>(find.descendant(of: home, matching: find.byType(Scrollable)))
        .where((state) => state.position.axis == Axis.vertical && state.position.maxScrollExtent > 300)
        .first;
    final scroll = pageScroll();
    scroll.position.jumpTo(300);
    await tester.pump();

    await _selectSecondary(tester, AppRoute.settings);
    expect(AppRouter.currentUri.path, AppRoute.settings.path);
    _shell(tester).onDestinationSelected(0);
    await _frames(tester);
    expect(AppRouter.currentUri.path, AppRoute.home.path);
    expect(tester.element(home), same(homeElement), reason: 'the home page was kept, not rebuilt');
    expect(pageScroll(), same(scroll));
    expect(scroll.position.pixels, 300);
  });

  testWidgets('back goes one page at a time, and from a deep link to the page it belongs to', (tester) async {
    await _mount(tester);
    await _push(tester, AppRoute.settings.path);
    await _push(tester, AppRoute.about.path);
    expect(AppRouter.rightNavigatorDepth, 2);
    expect(_shell(tester).routeDepth, 2);

    AppRouter.popRightNavigator();
    await _frames(tester);
    expect(AppRouter.currentUri.path, AppRoute.settings.path);
    expect(_shell(tester).routeDepth, 1);
    AppRouter.popRightNavigator();
    await _frames(tester);
    expect(AppRouter.currentUri.path, AppRoute.home.path);
    expect(_shell(tester).atDestinationRoot, isTrue);
    AppRouter.popRightNavigator();
    await _frames(tester);
    expect(AppRouter.currentUri.path, AppRoute.home.path, reason: 'nothing below a destination root');

    await _go(tester, AppRoute.meFollowing.path);
    expect(AppRouter.rightNavigatorDepth, 0);
    expect(_shell(tester).canGoBack, isTrue);
    AppRouter.popRightNavigator();
    await _frames(tester);
    expect(AppRouter.currentUri.path, AppRoute.me.path);
  });

  testWidgets('Escape goes back one page at a time and does nothing at a destination root', (tester) async {
    await _mount(tester);
    await _push(tester, AppRoute.settings.path);
    await _push(tester, AppRoute.about.path);
    await _escape(tester);
    expect(AppRouter.currentUri.path, AppRoute.settings.path);
    await _escape(tester);
    expect(AppRouter.currentUri.path, AppRoute.home.path);
    await _escape(tester);
    expect(AppRouter.currentUri.path, AppRoute.home.path);
    expect(_shell(tester).atDestinationRoot, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Escape leaves a focused field before it leaves the page', (tester) async {
    await _mount(tester);
    await _push(tester, AppRoute.settings.path);
    final focus = FocusNode();
    final controller = TextEditingController();
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);
    final overlay = OverlayEntry(
      builder: (_) => Center(
        child: SizedBox(
          width: 200,
          child: FrostTextField(controller: controller, focusNode: focus),
        ),
      ),
    );
    AppRouter.rightNavigatorKey.currentState!.overlay!.insert(overlay);
    addTearDown(overlay.remove);
    await tester.pump();
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    expect(AppRouter.currentUri.path, AppRoute.settings.path);
  });

  testWidgets('F5 refreshes the visible page only', (tester) async {
    await _mount(tester);
    final refreshed = <String>[];
    final scope = OverlayEntry(
      builder: (_) => Align(
        alignment: Alignment.bottomCenter,
        child: AppRefreshScope(onRefresh: () async => refreshed.add('top'), child: const Text('scope')),
      ),
    );
    AppRouter.rightNavigatorKey.currentState!.overlay!.insert(scope);
    addTearDown(scope.remove);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pump();
    expect(refreshed, ['top']);
  });
}
