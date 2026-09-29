import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:freepiv/app/theme/app_input_feedback.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/ui/spring_builder.dart';
import 'package:freepiv/shared/widgets/app_tab_bar.dart';
import 'package:freepiv/shared/widgets/interaction_controls.dart';
import 'package:go_router/go_router.dart';

Widget _host(Widget child, {bool reduced = false, TextDirection direction = TextDirection.ltr}) => AppInputFeedback(
  child: MaterialApp(
    theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Directionality(
        textDirection: direction,
        child: Scaffold(body: child),
      ),
    ),
  ),
);

void main() {
  testWidgets('mobile capsules preserve hit areas, follow route changes and snap with reduced motion', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = FakeViewPadding(bottom: 20);
    addTearDown(tester.view.reset);
    LocaleSettings.setLocale(AppLocale.enUs);
    for (final reduced in [false, true]) {
      final canPop = ValueNotifier(false);
      final router = GoRouter(
        routes: [
          ShellRoute(
            builder: (context, state, child) => RouterShell(canPopListenable: canPop, onBack: () {}, onResetRightNavigator: () {}, child: child),
            routes: [for (final destination in appRouteDestinations) GoRoute(path: destination.route.path, builder: (_, state) => Text(state.uri.path))],
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: AppInputFeedback(
              child: MaterialApp.router(
                theme: AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en')),
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(disableAnimations: reduced, textScaler: const TextScaler.linear(2)),
                  child: AppLayoutScope(child: child!),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder column(String label) => find.ancestor(of: find.text(label), matching: find.byType(Column)).first;
      Finder capsule(String label) => find.descendant(of: column(label), matching: find.byType(SpringBuilder));
      double width(String label) => tester.getSize(find.descendant(of: capsule(label), matching: find.byType(SizedBox)).first).width;
      final homeBounds = tester.getRect(column('Home'));
      final activityBounds = tester.getRect(column('Activity'));
      expect(width('Home'), 56);
      expect(width('Activity'), 40);
      expect(homeBounds.bottom, lessThanOrEqualTo(824));
      await tester.tap(find.text('Activity'));
      await tester.pump();
      if (reduced) {
        expect(width('Activity'), 56);
      } else {
        await tester.pump(const Duration(milliseconds: 60));
        expect(width('Activity'), inExclusiveRange(40, 56));
      }
      expect(tester.getRect(column('Home')), homeBounds);
      expect(tester.getRect(column('Activity')), activityBounds);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(width('Home'), 56);
      expect(width('Activity'), 40);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      canPop.dispose();
    }
  });

  testWidgets('tab clicks redirect the spring without changing the content controller twice', (tester) async {
    final source = TabController(length: 3, vsync: tester);
    addTearDown(source.dispose);
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            AppTabBar(
              controller: source,
              onTap: (_) => taps++,
              tabs: const [
                Tab(text: 'One'),
                Tab(text: 'Longer second label'),
                Tab(text: 'Three'),
              ],
            ),
            Expanded(
              child: TabBarView(controller: source, children: const [Text('Page 1'), Text('Page 2'), Text('Page 3')]),
            ),
          ],
        ),
      ),
    );
    final visual = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    await tester.tap(find.text('Three'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final current = visual.animation!.value;
    expect(current, inExclusiveRange(0, 2));
    expect(source.index, 2);
    await tester.tap(find.text('One'));
    expect(visual.animation!.value, current, reason: 'a second click preserves the current spring position');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(visual.animation!.value, greaterThan(current), reason: 'the reversal retains its velocity while braking');
    await tester.pumpAndSettle();
    expect(visual.animation!.value, 0);
    expect(source.index, 0);
    expect(taps, 2);
    expect(find.text('Page 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tabs mounted during a content transition still settle on its target', (tester) async {
    final source = TabController(length: 6, vsync: tester, animationDuration: const Duration(milliseconds: 200));
    addTearDown(source.dispose);
    source.animateTo(5);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(
      _host(
        AppTabBar(
          controller: source,
          tabs: [for (var index = 0; index < source.length; index++) Tab(text: 'Tab $index')],
        ),
      ),
    );
    final visual = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    await tester.pumpAndSettle();
    expect(source.index, 5);
    expect(visual.animation!.value, 5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('page drag drives the indicator continuously and cancellation restores it', (tester) async {
    final source = TabController(length: 3, vsync: tester);
    addTearDown(source.dispose);
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            AppTabBar(
              controller: source,
              tabs: const [
                Tab(text: 'One'),
                Tab(text: 'Two'),
                Tab(text: 'Three'),
              ],
            ),
            Expanded(
              child: TabBarView(controller: source, children: const [Text('Page 1'), Text('Page 2'), Text('Page 3')]),
            ),
          ],
        ),
      ),
    );
    final visual = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    final gesture = await tester.startGesture(tester.getCenter(find.byType(TabBarView)));
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();
    expect(source.offset, greaterThan(0));
    expect(visual.animation!.value, source.animation!.value);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(visual.animation!.value, source.index.toDouble());
    expect(source.index, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('RTL scrollable tabs keep native bounds and reduced motion snaps', (tester) async {
    final source = TabController(length: 3, vsync: tester);
    addTearDown(source.dispose);
    await tester.pumpWidget(
      _host(
        AppTabBar(
          controller: source,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Short'),
            Tab(text: 'Longer localized label'),
            Tab(text: 'Last'),
          ],
        ),
        reduced: true,
        direction: TextDirection.rtl,
      ),
    );
    final visual = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    expect(tester.getCenter(find.text('Short')).dx, greaterThan(tester.getCenter(find.text('Last')).dx));
    await tester.tap(find.text('Last'));
    await tester.pump();
    expect(source.indexIsChanging, false);
    expect(source.index, 2);
    expect(visual.animation!.value, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('switch row and trailing control invoke once; focus Space and disabled semantics remain', (tester) async {
    var value = false;
    var changes = 0;
    late StateSetter update;
    var enabled = true;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return AppSwitchListTile(
              title: const Text('Setting'),
              value: value,
              onChanged: enabled
                  ? (next) => setState(() {
                      value = next;
                      changes++;
                    })
                  : null,
            );
          },
        ),
      ),
    );
    final semantics = tester.ensureSemantics();
    await tester.tap(find.text('Setting'));
    await tester.pumpAndSettle();
    expect(value, true);
    expect(changes, 1);
    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(value, false);
    expect(changes, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, true);
    expect(changes, 3);
    update(() => enabled = false);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppSwitch));
    await tester.pump();
    expect(changes, 3);
    final data = tester.getSemantics(find.byType(AppSwitch)).getSemanticsData();
    expect(data.flagsCollection.isToggled, Tristate.isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('switch drag is reversible, cancellation keeps caller value, RTL and reduced motion work', (tester) async {
    for (final reduced in [false, true]) {
      var value = false;
      var changes = 0;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Center(
              child: AppSwitch(
                value: value,
                onChanged: (next) => setState(() {
                  value = next;
                  changes++;
                }),
              ),
            ),
          ),
          reduced: reduced,
          direction: TextDirection.rtl,
        ),
      );
      final start = tester.getCenter(find.byType(AppSwitch));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(value, false);
      expect(changes, 0);
      await tester.drag(find.byType(AppSwitch), const Offset(-40, 0));
      await tester.pumpAndSettle();
      expect(value, true);
      expect(changes, 1);
      for (var index = 0; index < 4; index++) {
        await tester.tap(find.byType(AppSwitch));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      expect(value, true);
      expect(changes, 5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
