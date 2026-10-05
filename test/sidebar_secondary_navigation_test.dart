import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:freepiv/core/downloads/download_manager.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('collapsed desktop navigation icons share one center line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
        home: Scaffold(
          body: SizedBox(
            width: 64,
            child: Column(
              children: [
                for (final (label, icon) in [('Home', PivIcons.home), ('Discover', PivIcons.compass), ('Activity', PivIcons.activity), ('More', PivIcons.more)])
                  FrostNavItem(label: label, icon: icon, selected: false, onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final iconCenters = <double>[];
    for (final label in ['Home', 'Discover', 'Activity', 'More']) {
      final row = find.byWidgetPredicate((widget) => widget is FrostNavItem && widget.label == label);
      iconCenters.add(tester.getCenter(find.descendant(of: row, matching: find.byType(FrostIcon))).dx);
    }
    for (final center in iconCenters.skip(1)) {
      expect(center, closeTo(iconCenters.first, .1));
    }
  });

  testWidgets('secondary navigation preserves the source page and its state', (tester) async {
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    final cacheDirectory = Directory('build/sidebar-navigation-test/cache').absolute;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, (call) async {
      if (call.method == 'getTemporaryDirectory' || call.method == 'getApplicationSupportDirectory' || call.method == 'getApplicationDocumentsDirectory') {
        return cacheDirectory.path;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, null));
    await tester.runAsync(initializeDownloadManager);
    tester.view.physicalSize = const Size(1440, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var homeMounts = 0;
    final navigatorKey = GlobalKey<NavigatorState>();
    final canPop = ValueNotifier<bool>(false);
    late final FrostNavigatorStackObserver observer;
    observer = FrostNavigatorStackObserver(() => canPop.value = observer.canPopPageRoute);
    final router = GoRouter(
      routes: [
        ShellRoute(
          navigatorKey: navigatorKey,
          observers: [observer],
          builder: (context, state, child) => RouterShell(
            canPopListenable: canPop,
            onBack: () => navigatorKey.currentState!.pop(),
            onResetRightNavigator: () => navigatorKey.currentState!.popUntil((route) => route.isFirst),
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => _Home(onMount: () => homeMounts++),
            ),
            GoRoute(
              path: '/downloads',
              builder: (context, state) => const Center(child: Text('Download destination')),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
            routerConfig: router,
            builder: (context, child) => FrostLayoutScope(child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Count: 0'));
    await tester.pump();
    expect(find.text('Count: 1'), findsOneWidget);

    await tester.tap(find.byTooltip(t.navigation.expand));
    await tester.pumpAndSettle();
    final navigationList = find.byType(ListView).first;
    final navigationScroll = find.descendant(of: navigationList, matching: find.byType(Scrollable)).first;
    expect(tester.state<ScrollableState>(navigationScroll).position.maxScrollExtent, greaterThan(0));
    expect(find.byType(Scrollbar), findsNothing);
    final downloads = find.byWidgetPredicate((widget) => widget is FrostNavItem && widget.label == t.navigation.downloads);
    await tester.tap(downloads);
    await tester.pumpAndSettle();
    expect(find.text('Download destination'), findsOneWidget);
    await tester.tap(downloads);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Count: 1'), findsOneWidget);
    expect(homeMounts, 1);
    await tester.drag(navigationList, const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(navigationScroll).position.pixels, greaterThan(0));
    expect(find.byType(Scrollbar), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    router.dispose();
    canPop.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

class _Home extends StatefulWidget {
  const _Home({required this.onMount});

  final VoidCallback onMount;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int count = 0;

  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(onPressed: () => setState(() => count++), child: Text('Count: $count')),
  );
}
