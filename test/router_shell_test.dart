import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/downloads/presentation/downloads_page.dart';
import 'package:freepiv/features/fanbox/browse_page.dart';
import 'package:freepiv/features/home/presentation/home_page.dart';
import 'package:freepiv/features/illust/presentation/illust_detail_page.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/ui/compositions/avatar_flight.dart';
import 'package:frost_ui/frost_ui.dart';

/// The app itself, with its router, shell wiring and sample data.
Future<void> _mount(WidgetTester tester, {String at = '/', Size size = const Size(1147, 717)}) async {
  tester.view.physicalSize = size;
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

/// A phone: the bottom bar layout.
const _phone = Size(390, 844);

/// The route of a secondary destination's root page.
ModalRoute<Object?> _secondaryRoute(WidgetTester tester, AppRoute route) {
  final page = switch (route) {
    AppRoute.downloads => DownloadsPage,
    AppRoute.fanbox => FanboxBrowsePage,
    _ => SettingsPage,
  };
  return ModalRoute.of(tester.element(find.byType(page, skipOffstage: false)))!;
}

/// Whether a page header paints [title]; the sidebar layout keeps a root
/// page's title for screen readers only, fully transparent.
bool _headerTitleShown(WidgetTester tester, String title) {
  final texts = find.descendant(of: find.byType(FrostPageHeader), matching: find.text(title));
  return texts.evaluate().any(
    (element) => find
        .ancestor(of: find.byElementPredicate((e) => e == element), matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0))
        .evaluate()
        .isEmpty,
  );
}

/// Whether [title] is painted in the top row, outside any page header; that is where the
/// shell's title row draws the visible page's title.
bool _titleRowShown(WidgetTester tester, String title) {
  return find.text(title).evaluate().any((element) {
    var painted = true;
    var inHeader = false;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Opacity && widget.opacity == 0) painted = false;
      if (widget is FrostPageHeader) inHeader = true;
      return painted;
    });
    return painted && !inHeader && tester.getTopLeft(find.byElementPredicate((e) => e == element)).dy < 48;
  });
}

/// Chooses a secondary destination where the layout shows it: among the
/// sidebar's destinations, or in the shell's secondary group with the bottom
/// bar.
void _chooseSecondary(WidgetTester tester, AppRoute route) {
  final shell = _shell(tester);
  final index = appSecondaryRoutes.indexOf(route);
  if (shell.secondary case final secondary?) {
    secondary.onSelected(index);
  } else {
    shell.onDestinationSelected(appRouteDestinations.length + index);
  }
}

Future<void> _selectSecondary(WidgetTester tester, AppRoute route) async {
  _chooseSecondary(tester, route);
  await _frames(tester);
}

/// The sidebar's index of a secondary destination.
int _sidebarIndex(AppRoute route) => appRouteDestinations.length + appSecondaryRoutes.indexOf(route);

Future<void> _escape(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await _frames(tester);
}

void main() {
  testWidgets('back to the first page from deep inside animates only the page on top', (tester) async {
    await _mount(tester, size: _phone);
    var firstDone = false;
    unawaited(AppRouter.router.push<void>(AppLocations.illust(sampleIllusts(count: 1).single.id)).then((_) => firstDone = true));
    await _frames(tester);
    await _push(tester, AppLocations.user(2000));
    expect(AppRouter.rightNavigatorDepth, 2);

    _shell(tester).backToFirst!.onPressed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(UserDetailPage, skipOffstage: false), findsOneWidget, reason: 'the page on top leaves with its animation');
    expect(find.byType(IllustDetailPage, skipOffstage: false), findsNothing, reason: 'the pages under it go at once');

    await _frames(tester);
    expect(find.byType(UserDetailPage, skipOffstage: false), findsNothing);
    expect(AppRouter.rightNavigatorDepth, 0);
    expect(AppRouter.currentUri.path, AppRoute.home.path);
    expect(firstDone, isTrue, reason: 'whoever opened a page hears it has closed');
  });

  testWidgets('the sidebar lists every destination; the bottom bar keeps FANBOX and settings in the secondary group', (tester) async {
    await _mount(tester);
    final shell = _shell(tester);
    expect(shell.destinations.map((destination) => destination.label), ['Home', 'Activity', 'Me', 'FANBOX', 'Settings']);
    expect(shell.secondary, isNull);
    expect(appSecondaryRoutes, [AppRoute.fanbox, AppRoute.settings]);
    expect(shell.atDestinationRoot, isTrue);
    expect(shell.canGoBack, isFalse);
    expect(shell.backToFirst, isNotNull);
    expect(shell.brand, isNotNull);

    tester.view.physicalSize = _phone;
    await _frames(tester);
    expect(_shell(tester).destinations.map((destination) => destination.label), ['Home', 'Activity', 'Me']);
    expect(_shell(tester).secondary!.destinations.map((destination) => destination.label), ['FANBOX', 'Settings']);
  });

  test('a sidebar index names its route, so a reselection past the primary destinations names FANBOX or settings', () {
    expect([for (var index = 0; index < 5; index++) appShellRouteAt(index)], [AppRoute.home, AppRoute.newest, AppRoute.me, AppRoute.fanbox, AppRoute.settings]);
    expect(_sidebarIndex(AppRoute.settings), 4);
  });

  testWidgets('a page any destination opens keeps the destination it was opened from highlighted', (tester) async {
    await _mount(tester, size: _phone);
    for (final (destination, index) in [(AppRoute.newest, 1), (AppRoute.me, 2), (AppRoute.home, 0)]) {
      await _go(tester, destination.path);
      expect(_shell(tester).selectedIndex, index, reason: destination.path);
      await _selectSecondary(tester, AppRoute.settings);
      expect(AppRouter.currentUri.path, AppRoute.settings.path);
      expect(_shell(tester).secondary!.selectedIndex, appSecondaryRoutes.indexOf(AppRoute.settings));
      expect(_shell(tester).selectedIndex, index, reason: 'the bottom bar keeps the opener of settings from ${destination.path} lit');
      await _push(tester, AppRoute.about.path);
      expect(_shell(tester).selectedIndex, index, reason: 'two pages up from ${destination.path}');
    }
    await _go(tester, AppRoute.meFollowing.path);
    expect(_shell(tester).selectedIndex, 2, reason: 'a page of Me highlights Me');
  });

  testWidgets('in the sidebar a secondary page selects its own destination, and the opener takes the highlight back', (tester) async {
    await _mount(tester);
    await _selectSecondary(tester, AppRoute.settings);
    expect(_shell(tester).selectedIndex, _sidebarIndex(AppRoute.settings));
    await _push(tester, AppLocations.fanboxPost('1001'));
    expect(_shell(tester).selectedIndex, _sidebarIndex(AppRoute.fanbox), reason: 'a FANBOX page belongs to FANBOX');
    await _escape(tester);
    await _escape(tester);
    expect(AppRouter.currentUri.path, AppRoute.settings.path);
    _shell(tester).onDestinationSelected(0);
    await _frames(tester);
    expect(_shell(tester).selectedIndex, 0);
  });

  testWidgets('with the bottom bar a FANBOX page selects FANBOX and keeps its opener, and the opener takes the highlight back', (tester) async {
    await _mount(tester, size: _phone);
    await _push(tester, AppLocations.fanboxPost('1001'));
    expect(_shell(tester).secondary!.selectedIndex, appSecondaryRoutes.indexOf(AppRoute.fanbox));
    expect(_shell(tester).selectedIndex, 0, reason: 'the bottom bar keeps Home, which opened it');
    await _escape(tester);
    expect(AppRouter.currentUri.path, AppRoute.home.path);
    expect(_shell(tester).selectedIndex, 0);
    expect(_shell(tester).secondary!.selectedIndex, isNull);
  });

  testWidgets('in the sidebar layout a secondary destination switches in with no motion', (tester) async {
    await _mount(tester);
    for (final route in appSecondaryRoutes) {
      await _go(tester, AppRoute.home.path);
      _chooseSecondary(tester, route);
      await tester.pump();
      await tester.pump();
      expect(AppRouter.currentUri.path, route.path);
      final top = _secondaryRoute(tester, route);
      expect(top.animation!.status, AnimationStatus.completed, reason: '${route.path} covers Home from its first frame');
      expect(find.byType(HomePage), findsNothing, reason: 'Home is no longer painted under ${route.path}');
      await _frames(tester);
    }
  });

  testWidgets('with the bottom bar a secondary destination is pushed as a detail page', (tester) async {
    await _mount(tester, size: _phone);
    _shell(tester).secondary!.onSelected(appSecondaryRoutes.indexOf(AppRoute.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final top = _secondaryRoute(tester, AppRoute.settings);
    expect(top.animation!.status, AnimationStatus.forward, reason: 'settings moves in');
    await _frames(tester);
    expect(top.animation!.status, AnimationStatus.completed);
    expect(_shell(tester).selectedIndex, 0, reason: 'the bottom bar keeps Home lit under settings');
  });

  testWidgets('the title row names every page in the sidebar layout; under the bottom bar only pushed pages paint their title', (tester) async {
    await _mount(tester);
    final roots = {AppRoute.home.path: 'Home', AppRoute.newest.path: 'Newest', AppRoute.me.path: 'Me'};
    for (final MapEntry(key: path, value: title) in roots.entries) {
      await _go(tester, path);
      expect(_headerTitleShown(tester, title), isFalse, reason: '$path in the sidebar layout');
      expect(_titleRowShown(tester, title), isTrue, reason: '$path in the title row');
    }
    for (final (route, title) in [(AppRoute.settings, 'Settings')]) {
      await _go(tester, AppRoute.home.path);
      await _selectSecondary(tester, route);
      expect(_headerTitleShown(tester, title), isFalse, reason: '${route.path} in the sidebar layout');
      await _push(tester, AppRoute.about.path);
      expect(_headerTitleShown(tester, 'About'), isFalse, reason: 'a pushed page hands its title to the title row');
      expect(_titleRowShown(tester, 'About'), isTrue, reason: 'the title row shows the pushed page title');
    }

    tester.view.physicalSize = _phone;
    await _go(tester, AppRoute.me.path);
    expect(_headerTitleShown(tester, 'Me'), isFalse, reason: 'the bottom bar names Me');
    await _push(tester, AppRoute.about.path);
    expect(_headerTitleShown(tester, 'About'), isTrue, reason: 'a pushed page has its title beside Back');
    await _go(tester, AppRoute.home.path);
    await _selectSecondary(tester, AppRoute.settings);
    expect(_headerTitleShown(tester, 'Settings'), isTrue, reason: 'a secondary destination pushed under the bottom bar has its title beside Back');
  });

  for (final (label, size, sidebar) in [('sidebar', const Size(1147, 717), true), ('bottom bar', _phone, false)]) {
    testWidgets('$label: a user page names its author once the identity has gone; the avatar flies only into a painted header', (tester) async {
      await _mount(tester, size: size);
      await _push(tester, AppLocations.user(3000));
      final name = tester.widget<AppFlightChrome>(find.byType(AppFlightChrome)).name!;
      final outer = tester.state<NestedScrollViewState>(find.byType(NestedScrollView)).outerController;
      final flight = AppAvatarFlight.of(tester.element(find.byType(NestedScrollView)));
      final phases = <AppAvatarFlightPhase>{};
      flight.phase.addListener(() => phases.add(flight.phase.value));
      for (var offset = 0.0; offset <= outer.position.maxScrollExtent; offset += 8) {
        outer.jumpTo(offset);
        await tester.pump();
      }
      outer.jumpTo(outer.position.maxScrollExtent);
      await _frames(tester);
      expect(tester.takeException(), isNull, reason: 'the title row builds the title outside the page');
      expect(flight.phase.value, AppAvatarFlightPhase.header);
      if (sidebar) {
        expect(phases, isNot(contains(AppAvatarFlightPhase.flying)), reason: 'the header paints no title to land in');
        expect(_titleRowShown(tester, name), isTrue);
      } else {
        expect(phases, contains(AppAvatarFlightPhase.flying), reason: 'a pushed page paints its title beside Back');
        expect(_headerTitleShown(tester, name), isTrue);
      }
    });
  }

  testWidgets('Downloads is a pushed page with Back, outside the destinations, reached by the one entry', (tester) async {
    await _mount(tester);
    expect(_shell(tester).destinations.map((destination) => destination.label), isNot(contains('Downloads')));
    expect(_shell(tester).taskEntry!.visible, isTrue);
    await _push(tester, AppRoute.downloads.path);
    expect(AppRouter.currentUri.path, AppRoute.downloads.path);
    expect(_shell(tester).selectedIndex, 0, reason: 'Downloads keeps its opener');
    expect(_shell(tester).canGoBack, isTrue);
    await _escape(tester);
    expect(AppRouter.currentUri.path, AppRoute.home.path);
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
