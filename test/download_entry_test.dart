import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:freepiv/core/downloads/download_manager.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/features/downloads/presentation/download_entry.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

const _work = ArtworkSource(illustId: 101, title: 'Summer sketches');
const _creator = FanboxCreatorSource(creatorId: 'kite', title: 'Studio Kite');

var _clock = 0;

DownloadTaskSnapshot _task(String filename, {DownloadStatus status = DownloadStatus.downloaded, SaveState saveState = SaveState.saved, double progress = 1}) {
  final created = DateTime(2026, 10, 5, 12, 0, _clock++);
  return DownloadTaskSnapshot(
    id: filename,
    origin: ContentFile(Uri.parse('https://example.com/$filename')),
    source: _work,
    title: filename,
    filename: filename,
    status: status,
    saveState: saveState,
    receivedBytes: 0,
    totalBytes: 100,
    progress: progress,
    localPath: null,
    error: null,
    log: null,
    createdAt: created,
    updatedAt: created,
  );
}

/// Retries that wait on [gate], then fail.
class _SlowFailingManager implements DownloadManager {
  _SlowFailingManager(this.tasks);

  final List<DownloadTaskSnapshot> tasks;
  final gate = Completer<void>();
  final retried = <String>[];

  @override
  Future<List<DownloadTaskSnapshot>> listTasks({int? illustId, DownloadStatus? status, SaveState? saveState}) async => tasks;

  @override
  Future<void> retry(String jobId) async {
    retried.add(jobId);
    await gate.future;
    throw StateError('offline');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('activity', () {
    test('no record hides the entry', () {
      final activity = downloadActivityOf(const []);
      expect(activity.visible, isFalse);
      expect(activity.badge, 0);
    });

    test('finished history alone keeps the entry, without a count', () {
      final activity = downloadActivityOf([_task('a.png')]);
      expect(activity.visible, isTrue);
      expect(activity.badge, 0);
      expect(activity.progress, isNull);
    });

    test('a creator being collected shows the entry before any file', () {
      expect(downloadActivityOf(const [], collecting: [(source: _creator, posts: 3)]).visible, isTrue);
    });

    test('the count is what is still going, with the overall progress', () {
      final activity = downloadActivityOf([
        _task('a.png'),
        _task('b.png', status: DownloadStatus.running, saveState: SaveState.none, progress: .5),
        _task('c.png', status: DownloadStatus.queued, saveState: SaveState.none, progress: 0),
      ]);
      expect(activity.badge, 2);
      expect(activity.badgeTone, FrostCountBadgeTone.accent);
      expect(activity.progress, closeTo(.25, .001));
    });

    test('failures take the count over, in the negative tone', () {
      final activity = downloadActivityOf([
        _task('b.png', status: DownloadStatus.running, saveState: SaveState.none, progress: .5),
        _task('f.png', status: DownloadStatus.failed, saveState: SaveState.none, progress: 0),
        _task('g.png', status: DownloadStatus.downloaded, saveState: SaveState.failed),
      ]);
      expect(activity.badge, 2);
      expect(activity.badgeTone, FrostCountBadgeTone.negative);
    });
  });

  group('shell', () {
    // Whether the entry's panel was still up when each page was pushed.
    final panelUpAtPush = <bool>[];

    Future<void> mount(
      WidgetTester tester,
      List<DownloadTaskSnapshot> tasks, {
      DownloadManager? manager,
      Size size = const Size(1147, 717),
      double textScale = 1,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      panelUpAtPush.clear();
      final key = GlobalKey<NavigatorState>();
      final router = GoRouter(
        routes: [
          ShellRoute(
            navigatorKey: key,
            observers: [_PushProbe(() => panelUpAtPush.add(find.byType(DownloadEntryPanel).evaluate().isNotEmpty))],
            builder: (context, state, child) => RouterShell(
              location: state.uri,
              selectedIndex: 0,
              routeDepth: 0,
              onBack: () {},
              onBackToFirst: () {},
              onDestinationSelected: (_) {},
              onSecondarySelected: (route) => GoRouter.of(context).push(route.path),
              child: child,
            ),
            routes: [
              GoRoute(path: AppRoute.home.path, builder: (_, _) => const SizedBox()),
              GoRoute(path: AppRoute.downloads.path, builder: (_, state) => Text('downloads ${state.uri}')),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadTasksProvider.overrideWith((ref) => Stream.value(tasks)),
            fanboxDownloadsProvider.overrideWithValue(const {}),
            if (manager != null) downloadManagerProvider.overrideWithValue(manager),
          ],
          child: TranslationProvider(
            child: FrostApp.router(config: freepivFrostConfig, routerConfig: router, title: 'freepiv'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    FrostShell shell(WidgetTester tester) => tester.widget<FrostShell>(find.byType(FrostShell));

    testWidgets('without records the sidebar still has the one entry', (tester) async {
      await mount(tester, const []);
      expect(shell(tester).taskEntry!.visible, isTrue);
      expect(find.byType(FrostShellTaskButton), findsOneWidget);
      expect(shell(tester).secondary!.destinations.map((destination) => destination.label), isNot(contains(t.navigation.downloads)));
    });

    testWidgets('the floating placement builds nothing when idle, the button with activity or a flight', (tester) async {
      late Widget idle, flying, sidebar;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            idle = appDownloadTaskEntry(DownloadActivity.empty, revealed: false).builder(context, FrostShellTaskEntryPlacement.floating);
            flying = appDownloadTaskEntry(DownloadActivity.empty, revealed: true).builder(context, FrostShellTaskEntryPlacement.floating);
            sidebar = appDownloadTaskEntry(DownloadActivity.empty, revealed: false).builder(context, FrostShellTaskEntryPlacement.sidebar);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(idle, isNot(isA<DownloadEntryButton>()));
      expect(flying, isA<DownloadEntryButton>());
      expect(sidebar, isA<DownloadEntryButton>());
      expect(appDownloadTaskEntry(DownloadActivity.empty, revealed: false).visible, isTrue);
    });

    testWidgets('the entry carries the count', (tester) async {
      await mount(tester, [
        _task('b.png', status: DownloadStatus.running, saveState: SaveState.none, progress: .5),
        _task('f.png', status: DownloadStatus.failed, saveState: SaveState.none, progress: 0),
      ]);
      final entry = shell(tester).taskEntry!;
      expect(entry.visible, isTrue);
      final button = tester.widget<FrostShellTaskButton>(find.byType(FrostShellTaskButton));
      expect(button.badge, 1);
      expect(button.badgeTone, FrostCountBadgeTone.negative);
      expect(appDestinationIndexForPath(AppRoute.downloads.path), isNull);
    });

    testWidgets('Retry failed in the panel runs once at a time and says when it fails', (tester) async {
      final failed = _task('f.png', status: DownloadStatus.failed, saveState: SaveState.none, progress: 0);
      final manager = _SlowFailingManager([failed]);
      await mount(tester, [failed], manager: manager);
      await tester.tap(find.byType(FrostShellTaskButton));
      await tester.pumpAndSettle();
      FrostButton retryFailed() => tester.widget<FrostButton>(find.widgetWithText(FrostButton, t.downloadEntry.retryFailed).hitTestable().first);
      retryFailed().onPressed!();
      await tester.pump();
      expect(retryFailed().onPressed, isNull, reason: 'busy while it runs');
      expect(manager.retried, ['f.png']);
      manager.gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining(t.settings.downloads.actionFailed), findsOneWidget);
      expect(retryFailed().onPressed, isNotNull, reason: 'it can be tried again');
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('the sidebar entry opens its panel, and a row opens that item', (tester) async {
      await mount(tester, [_task('b.png', status: DownloadStatus.running, saveState: SaveState.none, progress: .5)]);
      await tester.tap(find.byType(FrostShellTaskButton));
      await tester.pumpAndSettle();
      expect(find.byType(DownloadEntryPanel), findsOneWidget);
      expect(find.text('1 in progress · 0 failed').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Summer sketches'));
      await tester.pumpAndSettle();
      expect(find.byType(DownloadEntryPanel), findsNothing);
      expect(find.text('downloads ${AppLocations.downloads(item: _work.key)}'), findsOneWidget);
    });

    for (final (name, size, textScale) in [
      ('the sidebar\'s anchored panel', const Size(1147, 717), 1.0),
      ('the bottom bar\'s floating panel', const Size(390, 844), 1.0),
      ('the bottom sheet at large text', const Size(390, 844), 2.5),
    ]) {
      testWidgets('$name closes before a row or See all opens the downloads page', (tester) async {
        await mount(
          tester,
          [_task('b.png', status: DownloadStatus.running, saveState: SaveState.none, progress: .5)],
          size: size,
          textScale: textScale,
        );
        for (final (target, location) in [
          (find.text('Summer sketches'), AppLocations.downloads(item: _work.key)),
          (find.text(t.downloadEntry.viewAll), AppRoute.downloads.path),
        ]) {
          await tester.tap(find.byType(FrostShellTaskButton));
          await tester.pumpAndSettle();
          expect(find.byType(DownloadEntryPanel), findsOneWidget);
          await tester.ensureVisible(target.hitTestable());
          await tester.pumpAndSettle();
          await tester.tap(target.hitTestable());
          await tester.pumpAndSettle();
          expect(find.byType(DownloadEntryPanel), findsNothing);
          expect(find.text('downloads $location'), findsOneWidget);
          expect(panelUpAtPush.last, isFalse, reason: 'the panel was closed before the page opened');
          GoRouter.of(tester.element(find.text('downloads $location'))).pop();
          await tester.pumpAndSettle();
        }
        expect(panelUpAtPush, everyElement(isFalse));
      });
    }
  });
}

/// Reports every push on the navigator it watches.
class _PushProbe extends NavigatorObserver {
  _PushProbe(this.onPush);

  final VoidCallback onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => onPush();
}
