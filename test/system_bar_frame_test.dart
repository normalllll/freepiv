import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/navigator_stack_observer.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/core/downloads/download_manager.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/layout/fp_pinned_chrome.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';
import 'package:go_router/go_router.dart';

/// An unfolded Galaxy Z Fold: wide enough for the sidebar, with a status bar
/// and a gesture bar.
const _foldSize = Size(750, 832);
const _statusBar = 34.0;
const _gestureBar = 15.0;

void main() {
  late GoRouter router;
  late ValueNotifier<bool> canPop;

  Future<void> pumpShell(WidgetTester tester, {required TargetPlatform platform, Size size = _foldSize, double statusBar = _statusBar}) async {
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    final cacheDirectory = Directory('build/system-bar-frame-test/cache').absolute;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, (call) async => cacheDirectory.path);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, null));
    await tester.runAsync(initializeDownloadManager);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(top: statusBar, bottom: _gestureBar);
    addTearDown(tester.view.reset);

    final navigatorKey = GlobalKey<NavigatorState>();
    canPop = ValueNotifier<bool>(false);
    late final NavigatorStackObserver observer;
    observer = NavigatorStackObserver(() => canPop.value = observer.canPopPageRoute);
    router = GoRouter(
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
          routes: [GoRoute(path: '/', builder: (context, state) => const _PinnedPage())],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.dark(platform: platform, locale: const Locale('en')),
            routerConfig: router,
            builder: (context, child) => AppLayoutScope(child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposeShell(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    router.dispose();
    canPop.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  }

  Rect sidebarRect(WidgetTester tester) {
    final surfaces = find.ancestor(of: find.byType(DesktopNavItem).first, matching: find.byType(FpSurface));
    return surfaces.evaluate().map((element) => tester.getRect(find.byWidget(element.widget))).reduce((a, b) => a.height >= b.height ? a : b);
  }

  testWidgets('beside the sidebar the status bar is a title bar: panels start below it on one edge', (tester) async {
    await pumpShell(tester, platform: TargetPlatform.android);
    const frameTop = _statusBar + 8;

    final sidebar = sidebarRect(tester);
    expect(sidebar.top, frameTop);
    expect(sidebar.bottom, _foldSize.height - _gestureBar - 8, reason: 'the sidebar clears the gesture bar');

    // The page starts on the sidebar's top edge and no longer reserves the
    // status bar itself; content may still scroll under the gesture bar.
    final page = find.byKey(const ValueKey('page'));
    expect(tester.getTopLeft(page).dy, frameTop);
    final padding = MediaQuery.paddingOf(tester.element(page));
    expect(padding.bottom, _gestureBar);

    // Scrolled content brings in the floating glass, flush with the sidebar.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final glass = find.descendant(of: find.byType(PinnedChromeGlass), matching: find.byType(FpSurface));
    expect(tester.getRect(glass).top, sidebar.top);

    // Folding to the phone layout keeps the page's state.
    await tester.tap(find.text('Count: 0'));
    await tester.pump();
    tester.view.physicalSize = const Size(400, 832);
    await tester.pumpAndSettle();
    expect(find.byType(DesktopNavItem), findsNothing);
    expect(find.text('Count: 1'), findsOneWidget);
    expect(tester.getTopLeft(page).dy, 0, reason: 'the phone layout stays edge to edge under the status bar');
    await disposeShell(tester);
  });

  testWidgets('on Windows the page and sidebar still meet the title bar directly', (tester) async {
    await pumpShell(tester, platform: TargetPlatform.windows, size: const Size(1280, 800), statusBar: 0);
    expect(sidebarRect(tester).top, 0);
    expect(tester.getTopLeft(find.byKey(const ValueKey('page'))).dy, 0);
    await disposeShell(tester);
  });
}

class _PinnedPage extends StatefulWidget {
  const _PinnedPage();

  @override
  State<_PinnedPage> createState() => _PinnedPageState();
}

class _PinnedPageState extends State<_PinnedPage> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return FpPinnedChrome(
      key: const ValueKey('page'),
      chrome: SizedBox(
        height: 48,
        child: Center(
          child: TextButton(onPressed: () => setState(() => count++), child: Text('Count: $count')),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          const FpChromeSpacer(),
          SliverList.builder(itemCount: 40, itemBuilder: (context, index) => SizedBox(height: 60, child: Text('Row $index'))),
        ],
      ),
    );
  }
}
