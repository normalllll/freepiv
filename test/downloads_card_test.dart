import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/features/downloads/presentation/download_entry.dart';
import 'package:freepiv/features/downloads/presentation/downloads_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

const _standalone = StandaloneSource(taskId: 'single', title: 'A saved image');

DownloadTaskSnapshot _task(
  String name, {
  DownloadSource source = const ArtworkSource(illustId: 1, title: 'Work 1', subtitle: 'Artist'),
  DownloadStatus status = DownloadStatus.downloaded,
  SaveState saveState = SaveState.saved,
  double progress = 1,
  String? path = 'C:/Downloads/a.png',
}) => DownloadTaskSnapshot(
  id: name,
  origin: const ArtworkPage(illustId: 1, pageIndex: 0),
  source: source,
  title: 'Work 1',
  filename: name,
  status: status,
  saveState: saveState,
  receivedBytes: 2048,
  totalBytes: 2048,
  progress: progress,
  localPath: path,
  error: null,
  log: null,
  createdAt: DateTime(2026, 11, 7, 10),
  updatedAt: DateTime(2026, 11, 7, 10),
);

Future<void> _mount(
  WidgetTester tester,
  List<DownloadTaskSnapshot> tasks, {
  TargetPlatform platform = TargetPlatform.windows,
  Size size = desktopSize,
  String? focus,
}) async {
  debugDefaultTargetPlatformOverride = platform;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  await mountPilotPage(
    tester,
    DownloadsPage(focusItem: focus),
    size: size,
    overrides: {downloadTasksProvider: downloadTasksProvider.overrideWith((ref) => Stream.value(tasks))},
  );
  debugDefaultTargetPlatformOverride = null;
}

Set<String> _buttons(WidgetTester tester) => {
  for (final button in tester.widgetList<FrostButton>(find.descendant(of: find.byType(DownloadItemCard), matching: find.byType(FrostButton)))) button.label,
};

void main() {
  testWidgets('a finished item on desktop has Open, Show in folder and Open work, and More', (tester) async {
    await _mount(tester, [_task('a.png')]);
    expect(_buttons(tester), containsAll([t.settings.downloads.open, t.settings.downloads.showInFolder, t.settings.downloads.openWork]));
    expect(find.widgetWithText(FrostButton, t.settings.downloads.open), findsOneWidget, reason: 'with its words');
    expect(find.descendant(of: find.byType(DownloadItemCard), matching: find.byType(FrostMenuAnchor)), findsWidgets);
    expectNoLayoutErrors(tester);
  });

  testWidgets('a finished item on a phone has only Open work', (tester) async {
    await _mount(tester, [_task('a.png')], platform: TargetPlatform.android, size: phoneSize);
    final buttons = _buttons(tester);
    expect(buttons, contains(t.settings.downloads.openWork));
    expect(buttons, isNot(contains(t.settings.downloads.open)));
    expect(buttons, isNot(contains(t.settings.downloads.showInFolder)));
    expectNoLayoutErrors(tester);
  });

  testWidgets('a standalone file has no Open work', (tester) async {
    await _mount(tester, [_task('a.png', source: _standalone)]);
    expect(_buttons(tester), allOf(contains(t.settings.downloads.open), isNot(contains(t.settings.downloads.openWork))));
  });

  for (final (state, status, saveState, primary) in [
    ('failed', DownloadStatus.failed, SaveState.none, 'retry'),
    ('cancelled', DownloadStatus.cancelled, SaveState.none, 'retry'),
    ('running', DownloadStatus.running, SaveState.none, 'cancel'),
  ]) {
    testWidgets('a $state item keeps its one action', (tester) async {
      await _mount(tester, [_task('a.png', status: status, saveState: saveState, progress: .5)]);
      final buttons = _buttons(tester);
      expect(buttons, contains(primary == 'retry' ? t.common.retry : t.settings.downloads.cancel));
      expect(buttons, isNot(contains(t.settings.downloads.open)));
      expect(buttons, isNot(contains(t.settings.downloads.showInFolder)));
      expect(buttons, isNot(contains(t.settings.downloads.openWork)));
    });
  }

  testWidgets('the card has the thumbnail at regular size and one line of what the item is', (tester) async {
    await _mount(tester, [_task('a.png'), _task('b.png')]);
    final thumbnail = tester.widget<FrostThumbnail>(find.descendant(of: find.byType(DownloadItemCard), matching: find.byType(FrostThumbnail)));
    expect(thumbnail.size, FrostThumbnailSize.regular);
    final row = tester.widget<FrostTaskRow>(find.descendant(of: find.byType(DownloadItemCard), matching: find.byType(FrostTaskRow)).first);
    expect(
      row.detail,
      allOf(contains('Artist'), contains(t.settings.downloads.filesCount(count: 2)), contains('4.00 KB'), contains(t.settings.downloads.saved)),
    );
  });

  testWidgets('open files sit in the same card, with no second surface', (tester) async {
    const source = ArtworkSource(illustId: 1, title: 'Work 1', subtitle: 'Artist');
    await _mount(tester, [_task('a.png'), _task('b.png')], focus: source.key);
    final card = find.byType(DownloadItemCard);
    final files = find.byType(DownloadFileRow);
    expect(files, findsNWidgets(2), reason: 'a finished item lists its files');
    expect(find.descendant(of: card, matching: files), findsNWidgets(2));
    expect(find.descendant(of: find.byType(DownloadItemFilesView), matching: find.byType(FrostSurface)), findsNothing);
    expect(find.descendant(of: find.byType(DownloadItemFilesView), matching: find.byType(FrostDivider)), findsNWidgets(2));
    expect(tester.getTopLeft(files.first).dx, tester.getTopLeft(card).dx, reason: 'no indent');
    expect(tester.getSize(files.first).width, tester.getSize(card).width, reason: 'full width');
    expectNoLayoutErrors(tester);
  });

  testWidgets('on desktop a saved file has Open and Show in folder icons', (tester) async {
    const source = ArtworkSource(illustId: 1, title: 'Work 1', subtitle: 'Artist');
    await _mount(tester, [_task('a.png')], focus: source.key);
    final row = tester.widget<FrostTaskRow>(find.descendant(of: find.byType(DownloadFileRow), matching: find.byType(FrostTaskRow)));
    // The row was built under the desktop override.
    expect(row.actions.map((action) => action.label), [t.settings.downloads.open, t.settings.downloads.showInFolder]);
  });

  testWidgets('an item still going folds its saved files under a flat row', (tester) async {
    const source = ArtworkSource(illustId: 1, title: 'Work 1', subtitle: 'Artist');
    await _mount(tester, [_task('a.png'), _task('b.png', status: DownloadStatus.running, saveState: SaveState.none, progress: .5)], focus: source.key);
    expect(find.text('${t.settings.downloads.saved} · 1'), findsOneWidget);
    expect(find.byType(DownloadFileRow), findsOneWidget, reason: 'the saved file waits under its row');
    expect(find.descendant(of: find.byType(DownloadItemFilesView), matching: find.byType(FrostSurface)), findsNothing);
  });
}
