import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/features/downloads/presentation/download_dock_button.dart';
import 'package:freepiv/features/downloads/presentation/download_floating_panel.dart';
import 'package:freepiv/features/downloads/presentation/mobile_download_floating_window.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:go_router/go_router.dart';

class _NoFanboxDownloads extends FanboxDownloads {
  @override
  Map<String, FanboxCollecting> build() => const {};
}

DownloadTaskSnapshot _failedTask() => DownloadTaskSnapshot(
  id: 'illust_101_page_0',
  origin: const ArtworkPage(illustId: 101, pageIndex: 0),
  source: const ArtworkSource(illustId: 101, title: 'Artwork 101'),
  title: 'Artwork 101',
  filename: '101.png',
  status: DownloadStatus.failed,
  saveState: SaveState.none,
  receivedBytes: 0,
  totalBytes: null,
  progress: 0,
  localPath: null,
  error: 'Connection failed',
  log: null,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  Future<void> settleDock(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('desktop dock opens a real panel, closes it, and reaches full downloads', (tester) async {
    final boundary = GlobalKey();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.runAsync(() async {
      final font = File('C:/Windows/Fonts/segoeui.ttf');
      if (await font.exists()) {
        await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())))).load();
      }
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(body: DesktopDownloadDock(railWidth: 80, taskStream: Stream.value([_failedTask()]))),
        ),
        GoRoute(
          path: AppRoute.downloads.path,
          name: AppRoute.downloads.name,
          builder: (context, state) => const Scaffold(body: Text('Full downloads')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fanboxDownloadsProvider.overrideWith(_NoFanboxDownloads.new)],
        child: TranslationProvider(
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp.router(routerConfig: router, debugShowCheckedModeBanner: false),
          ),
        ),
      ),
    );
    await settleDock(tester);
    final button = find.byKey(const ValueKey('desktop-download-button'));
    await tester.tap(button);
    await settleDock(tester);
    expect(find.text('View all downloads'), findsOneWidget);
    final panel = find.byKey(const ValueKey('desktop-download-panel'));
    expect(_panelOpacity(tester, panel), 1);
    final desktopButtonFocus = tester.widget<DownloadDockButton>(find.byType(DownloadDockButton)).focusNode!;
    final desktopCloseFocus = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .singleWhere((button) => button.tooltip == const DefaultMaterialLocalizations().closeButtonTooltip)
        .focusNode!;
    expect(FocusManager.instance.primaryFocus, desktopCloseFocus);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleDock(tester);
    expect(FocusManager.instance.primaryFocus, desktopButtonFocus);
    expect(_panelOpacity(tester, panel), 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleDock(tester);
    expect(FocusManager.instance.primaryFocus, desktopCloseFocus);
    await tester.runAsync(() async {
      final image = await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('build/ui-review/download-panel-desktop.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
    });
    await tester.tap(find.byTooltip('Close'));
    await settleDock(tester);
    expect(_panelOpacity(tester, panel), 0);
    await tester.tap(button);
    await settleDock(tester);
    await tester.tap(find.text('View all downloads'));
    await settleDock(tester);
    expect(find.text('Full downloads'), findsOneWidget);
  }, skip: Platform.isAndroid);

  testWidgets('narrow desktop dock opens full downloads when the panel cannot fit', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(body: DesktopDownloadDock(railWidth: 80, taskStream: Stream.value([_failedTask()]))),
        ),
        GoRoute(
          path: AppRoute.downloads.path,
          name: AppRoute.downloads.name,
          builder: (context, state) => const Scaffold(body: Text('Full downloads')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(260, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fanboxDownloadsProvider.overrideWith(_NoFanboxDownloads.new)],
        child: TranslationProvider(child: MaterialApp.router(routerConfig: router)),
      ),
    );
    await settleDock(tester);
    await tester.tap(find.byKey(const ValueKey('desktop-download-button')));
    await settleDock(tester);
    expect(find.text('Full downloads'), findsOneWidget);
  }, skip: Platform.isAndroid);

  testWidgets('mobile floating entry remains draggable and its panel can close', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fanboxDownloadsProvider.overrideWith(_NoFanboxDownloads.new)],
        child: TranslationProvider(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(390, 844)),
              child: FrostLayoutScope(
                child: MobileDownloadFloatingWindow(
                  taskStream: Stream.value([_failedTask()]),
                  child: const Scaffold(body: Text('Browsing')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await settleDock(tester);
    final window = find.byKey(const ValueKey('mobile-download-window'));
    final button = find.byType(DownloadDockButton);
    final before = tester.getRect(window);
    await tester.drag(button, const Offset(-30, -50));
    await settleDock(tester);
    final after = tester.getRect(window);
    expect(after.topLeft, isNot(before.topLeft));
    await tester.tap(button);
    await settleDock(tester);
    expect(find.text('View all downloads'), findsOneWidget);
    final mobileButtonFocus = tester.widget<DownloadDockButton>(button).focusNode!;
    final mobileCloseFocus = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .singleWhere((button) => button.tooltip == const DefaultMaterialLocalizations().closeButtonTooltip)
        .focusNode!;
    expect(FocusManager.instance.primaryFocus, mobileCloseFocus);
    expect(mobileButtonFocus.canRequestFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNot(mobileButtonFocus));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleDock(tester);
    expect(FocusManager.instance.primaryFocus, mobileButtonFocus);
    expect(mobileButtonFocus.canRequestFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleDock(tester);
    expect(FocusManager.instance.primaryFocus, mobileCloseFocus);
    await tester.tap(find.byTooltip('Close'));
    await settleDock(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop dock button sits on the sidebar icon axis, not the sidebar centre', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Collapsed rail (80 + margins) and expanded sidebar (176 + margins),
    // with the axis the shell passes for each.
    for (final (railWidth, axis) in [(96.0, 48.0), (192.0, 40.0)]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [fanboxDownloadsProvider.overrideWith(_NoFanboxDownloads.new)],
          child: TranslationProvider(
            child: MaterialApp(
              home: Scaffold(
                body: DesktopDownloadDock(railWidth: railWidth, buttonCenterX: axis, taskStream: Stream.value([_failedTask()])),
              ),
            ),
          ),
        ),
      );
      await settleDock(tester);
      final body = find.descendant(of: find.byType(DownloadDockButton), matching: find.byType(Material)).first;
      expect(tester.getSize(body).width, 52);
      expect(tester.getCenter(body).dx, closeTo(axis, .01), reason: 'rail $railWidth');
    }
    expect(tester.takeException(), isNull);
  });
}

/// The opacity the dock panel's spring reveal paints with.
double _panelOpacity(WidgetTester tester, Finder panel) => tester
    .widget<Opacity>(
      find
          .descendant(
            of: find.descendant(of: panel, matching: find.byType(FrostSpringReveal)),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;
