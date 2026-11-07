import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/features/downloads/presentation/download_entry.dart';
import 'package:freepiv/features/downloads/presentation/downloads_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

var _clock = 0;

DownloadTaskSnapshot _task(
  String name, {
  int illust = 1,
  String? title,
  DownloadStatus status = DownloadStatus.downloaded,
  SaveState saveState = SaveState.saved,
  double progress = 1,
  String? path,
  String? error,
}) {
  final created = DateTime(2026, 11, 7, 10, 0, _clock++);
  return DownloadTaskSnapshot(
    id: name,
    origin: ArtworkPage(illustId: illust, pageIndex: 0),
    source: ArtworkSource(illustId: illust, title: title ?? 'Work $illust', subtitle: 'Artist'),
    title: title ?? 'Work $illust',
    filename: name,
    status: status,
    saveState: saveState,
    receivedBytes: 10,
    totalBytes: 100,
    progress: progress,
    localPath: path,
    error: error,
    log: null,
    createdAt: created,
    updatedAt: created,
  );
}

Future<void> _mount(WidgetTester tester, Stream<List<DownloadTaskSnapshot>> tasks, {Size size = desktopSize, double textScale = 1, String? focus}) =>
    mountPilotPage(
      tester,
      DownloadsPage(focusItem: focus),
      size: size,
      textScale: textScale,
      overrides: {downloadTasksProvider: downloadTasksProvider.overrideWith((ref) => tasks)},
    );

void main() {
  testWidgets('All is the first tab and the default; in progress puts failures first; completed groups by day', (tester) async {
    await _mount(
      tester,
      Stream.value([
        _task('a.png', illust: 1, status: DownloadStatus.running, saveState: SaveState.none, progress: .4),
        _task('b.png', illust: 2, status: DownloadStatus.failed, saveState: SaveState.none, progress: 0, error: 'Connection reset'),
        _task('c.png', illust: 3, path: 'C:/Downloads/c.png'),
      ]),
    );
    final bar = tester.widget<FrostTabBar>(find.byType(FrostTabBar));
    expect(bar.tabs.map((tab) => tab.label), [t.downloadsPage.all, t.downloadsPage.inProgress, t.settings.downloads.completed]);
    expect(bar.controller!.index, 0, reason: 'All by default');
    List<String?> rows() => tester.widgetList<DownloadItemRow>(find.byType(DownloadItemRow)).map((row) => row.item.source.title).toList();
    expect(rows(), ['Work 2', 'Work 1', 'Work 3'], reason: 'what is in progress, then what is done');
    await tester.tap(find.text(t.downloadsPage.inProgress).last);
    await settlePilot(tester);
    expect(rows(), ['Work 2', 'Work 1']);
    await tester.tap(find.text(t.settings.downloads.completed));
    await settlePilot(tester);
    expect(tester.widgetList<DownloadItemRow>(find.byType(DownloadItemRow)).map((row) => row.item.source.title), ['Work 3']);
  });

  testWidgets('empty: each tab says there is nothing', (tester) async {
    await _mount(tester, Stream.value(const []));
    expect(find.text(t.downloadsPage.nothingDone), findsOneWidget, reason: 'All');
    await tester.tap(find.text(t.downloadsPage.inProgress));
    await settlePilot(tester);
    expect(find.text(t.downloadsPage.nothingInProgress), findsOneWidget);
    await tester.tap(find.text(t.settings.downloads.completed));
    await settlePilot(tester);
    expect(find.text(t.downloadsPage.nothingDone), findsOneWidget);
  });

  testWidgets('the header More menu shows only its icon', (tester) async {
    await _mount(tester, Stream.value(const []));
    expectIconOnlyMore(tester);
  });

  testWidgets('loading: placeholder rows stand in', (tester) async {
    await _mount(tester, StreamController<List<DownloadTaskSnapshot>>().stream);
    expect(find.byType(FrostListRow), findsWidgets);
    expect(find.byType(DownloadItemRow), findsNothing);
  });

  testWidgets('error: records that could not be read offer a retry', (tester) async {
    await _mount(tester, Stream.error(StateError('database locked')));
    expect(find.byType(FrostErrorContent), findsOneWidget);
  });

  testWidgets('a failure after the records loaded shows above the list it keeps', (tester) async {
    final records = StreamController<List<DownloadTaskSnapshot>>();
    addTearDown(records.close);
    await _mount(tester, records.stream);
    records.add([_task('a.png', illust: 1, status: DownloadStatus.running, saveState: SaveState.none, progress: .4)]);
    await settlePilot(tester, frames: 3);
    records.addError(StateError('database locked'));
    await settlePilot(tester, frames: 3);
    expect(find.byType(FrostCompactMessage), findsOneWidget);
    expect(find.descendant(of: find.byType(FrostCompactMessage), matching: find.text(t.common.retry)), findsOneWidget);
    expect(tester.widgetList<DownloadItemRow>(find.byType(DownloadItemRow)).map((row) => row.item.source.title), ['Work 1']);
  });

  testWidgets('partial failure: a failed file shows its error in the open item while the others keep going', (tester) async {
    await _mount(
      tester,
      Stream.value([
        _task('ok.png', illust: 4, status: DownloadStatus.running, saveState: SaveState.none, progress: .5),
        _task('bad.png', illust: 4, status: DownloadStatus.failed, saveState: SaveState.none, progress: 0, error: 'HTTP 403'),
      ]),
      focus: const ArtworkSource(illustId: 4, title: 'Work 4').key,
    );
    expect(find.byType(DownloadFileRow), findsNWidgets(2), reason: 'the item the page was opened for is open');
    expect(find.textContaining('HTTP 403'), findsOneWidget);
  });

  testWidgets('/downloads?item= for a completed item opens All with that item open', (tester) async {
    const done = ArtworkSource(illustId: 3, title: 'Work 3');
    final location = Uri.parse(AppLocations.downloads(item: done.key));
    expect(location.path, AppRoute.downloads.path);
    await _mount(
      tester,
      Stream.value([
        _task('a.png', illust: 1, status: DownloadStatus.running, saveState: SaveState.none, progress: .4),
        _task('c.png', illust: 3, path: 'C:/Downloads/c.png'),
      ]),
      focus: location.queryParameters[AppRouteQuery.item],
    );
    expect(tester.widget<FrostTabBar>(find.byType(FrostTabBar)).controller!.index, 0, reason: 'All, where every item is');
    final rows = find.byType(DownloadItemRow).hitTestable();
    expect(tester.widgetList<DownloadItemRow>(rows).map((row) => row.item.source.title), ['Work 1', 'Work 3']);
    expect(tester.widgetList<DownloadItemRow>(rows).map((row) => row.open), [false, true], reason: 'the item is open');
    expect(find.byType(DownloadItemFilesView).hitTestable(), findsOneWidget);
  });

  testWidgets('long titles, file names and paths fit a phone at double text size', (tester) async {
    await _mount(
      tester,
      Stream.value([
        _task('$longText.png', illust: 5, title: longText, status: DownloadStatus.failed, saveState: SaveState.none, progress: 0, error: longText),
        _task('$longText-2.png', illust: 6, title: longText, path: 'C:/Users/$longText/Downloads/$longText.png'),
      ]),
      size: phoneSize,
      textScale: 2,
      focus: const ArtworkSource(illustId: 5, title: 'Work 5').key,
    );
    expectNoLayoutErrors(tester);
    // Three tabs at double size reach past a phone's width.
    tester.widget<FrostTabBar>(find.byType(FrostTabBar)).controller!.index = 2;
    await settlePilot(tester);
    expectNoLayoutErrors(tester);
  });

  test('the downloads strings exist in all four languages', () => expectLocalesComplete(['downloadsPage', 'downloadEntry', 'settings']));
}
