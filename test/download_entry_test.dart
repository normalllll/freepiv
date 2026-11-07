import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router_shell.dart';
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
    Future<void> mount(WidgetTester tester, List<DownloadTaskSnapshot> tasks) async {
      tester.view.physicalSize = const Size(1147, 717);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey<NavigatorState>();
      final router = GoRouter(
        routes: [
          ShellRoute(
            navigatorKey: key,
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
          overrides: [downloadTasksProvider.overrideWith((ref) => Stream.value(tasks)), fanboxDownloadsProvider.overrideWithValue(const {})],
          child: TranslationProvider(
            child: FrostApp.router(config: freepivFrostConfig, routerConfig: router, title: 'freepiv'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    FrostShell shell(WidgetTester tester) => tester.widget<FrostShell>(find.byType(FrostShell));

    testWidgets('without records the entry is hidden', (tester) async {
      await mount(tester, const []);
      expect(shell(tester).taskEntry!.visible, isFalse);
    });

    testWidgets('the entry and the downloads destination carry the same count', (tester) async {
      await mount(tester, [
        _task('b.png', status: DownloadStatus.running, saveState: SaveState.none, progress: .5),
        _task('f.png', status: DownloadStatus.failed, saveState: SaveState.none, progress: 0),
      ]);
      final entry = shell(tester).taskEntry!;
      expect(entry.visible, isTrue);
      final button = tester.widget<FrostShellTaskButton>(find.byType(FrostShellTaskButton));
      expect(button.badge, 1);
      expect(button.badgeTone, FrostCountBadgeTone.negative);
      final downloads = shell(tester).secondary!.destinations[appSecondaryRoutes.indexOf(AppRoute.downloads)];
      expect(downloads.badge, 1);
      expect(downloads.badgeTone, FrostCountBadgeTone.negative);
      expect(appDestinationIndexForPath(AppRoute.downloads.path), isNull);
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
  });
}
