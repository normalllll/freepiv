import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/features/history/history_logic.dart';
import 'package:freepiv/features/history/history_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/history_card.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

final _day = DateTime.utc(2026, 11, 1);

HistoryEntry _entry(int workId, int hours, {HistoryWorkKind kind = HistoryWorkKind.illust, String? title}) => HistoryEntry(
  kind: kind,
  workId: workId,
  title: title ?? (kind.isNovel ? 'Novel $workId' : 'Work $workId'),
  authorId: 2000,
  authorName: 'Sample artist',
  thumbnailUrl: '',
  xRestrict: 0,
  aiGenerated: false,
  viewedAt: _day.add(Duration(hours: hours)),
  width: kind.isNovel ? null : 1000,
  height: kind.isNovel ? null : 1400,
  pageCount: kind.isNovel ? null : 1,
  textLength: kind.isNovel ? 9000 : null,
);

Future<void> _seed(HistoryRepository history) async {
  Future<void> add(String account, HistoryEntry entry) => history.record(account, entry, limit: HistoryLimit.standard);
  await add('1000', _entry(1, 1));
  await add('1000', _entry(2, 3, kind: HistoryWorkKind.manga));
  await add('1000', _entry(3, 2, kind: HistoryWorkKind.ugoira));
  await add('1000', _entry(10, 1, kind: HistoryWorkKind.novel));
  await add('1000', _entry(11, 2, kind: HistoryWorkKind.novel));
  await add('1001', _entry(4, 9, title: 'Other account work'));
}

Future<void> _open(WidgetTester tester, {Size size = desktopSize, double textScale = 1, Future<void> Function(HistoryRepository history)? seed = _seed}) =>
    mountPilotPage(tester, const HistoryPage(), size: size, textScale: textScale, seedHistory: seed);

Future<void> _novels(WidgetTester tester) async {
  await tester.ensureVisible(find.text(t.history.novels));
  await tester.pump();
  await tester.tap(find.text(t.history.novels));
  await settlePilot(tester, frames: 8);
}

Future<int> _count(WidgetTester tester, String account) async => (await tester.runAsync(() => historyRepository.count(account)))!;

Future<void> _menu(WidgetTester tester, Finder target, String item) async {
  await tester.tap(target, buttons: kSecondaryButton);
  await settlePilot(tester, frames: 6);
  await tester.tap(find.text(item).last);
  await settlePilot(tester, frames: 6);
}

void main() {
  testWidgets('the illustrations and manga of the current account, the last viewed first, under a line saying they stay on this device', (tester) async {
    await _open(tester);

    expect(find.text(t.history.title), findsWidgets);
    expect(find.text(t.history.localOnly), findsOneWidget);
    expect(tester.widgetList<AppHistoryCard>(find.byType(AppHistoryCard)).map((card) => card.entry.workId), [2, 3, 1]);
    expect(find.text('Other account work'), findsNothing, reason: 'another account');
    expectNoLayoutErrors(tester);
  });

  testWidgets('novels are rows, the last viewed first', (tester) async {
    await _open(tester);
    await _novels(tester);

    expect(tester.widgetList<AppHistoryNovelRow>(find.byType(AppHistoryNovelRow)).map((row) => row.entry.workId), [11, 10]);
    expect(find.text(t.history.localOnly), findsOneWidget);
    expect(find.text(t.user.meta.novelChars(count: 9000)), findsNWidgets(2));
    expectNoLayoutErrors(tester);
  });

  testWidgets('both tabs fit a phone and double text size', (tester) async {
    for (final size in [phoneSize, desktopSize]) {
      await _open(tester, size: size, textScale: 2);
      expectNoLayoutErrors(tester, where: '$size illustrations');
      await _novels(tester);
      expectNoLayoutErrors(tester, where: '$size novels');
    }
  });

  testWidgets('with nothing viewed each tab says so', (tester) async {
    await _open(tester, seed: null);
    expect(find.text(t.history.empty), findsOneWidget);
    await _novels(tester);
    expect(find.text(t.history.empty), findsOneWidget);
  });

  testWidgets('a card and a row open their work, which the page loads itself', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Work 2'));
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.illust(2));
    expect(openedExtras.last, isNull, reason: 'no model was made from the snapshot');

    await _open(tester);
    await _novels(tester);
    await tester.tap(find.text('Novel 11'));
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.novel(11));
  });

  testWidgets('removing an entry deletes it and leaves the rest where they are, without reloading', (tester) async {
    await _open(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(HistoryPage)));
    final source = container.read(historySourceProvider(false));
    final revision = source.refreshRevision;

    await _menu(tester, find.text('Work 3'), t.history.remove);

    expect(find.text('Work 3'), findsNothing);
    expect(tester.widgetList<AppHistoryCard>(find.byType(AppHistoryCard)).map((card) => card.entry.workId), [2, 1]);
    expect(source.refreshRevision, revision, reason: 'the list was not read again');
    expect(source.phase, FrostLoadPhase.content);
    expect(await _count(tester, '1000'), 4);
    expect(await _count(tester, '1001'), 1);
  });

  testWidgets('the menu of an entry opens it', (tester) async {
    await _open(tester);
    await _menu(tester, find.text('Work 1'), t.history.open);
    expect(openedLocations.last, AppLocations.illust(1));
  });

  testWidgets('clearing asks first, then empties both tabs of this account and no other', (tester) async {
    await _open(tester);
    final more = find.bySemanticsLabel(FrostScope.labelsOf(tester.element(find.byType(HistoryPage))).more).first;
    await tester.tap(more);
    await settlePilot(tester, frames: 6);
    await tester.tap(find.text(t.history.clear).last);
    await settlePilot(tester, frames: 6);
    expect(find.byType(AppHistoryCard), findsNWidgets(3), reason: 'nothing happens before the confirmation');

    await tester.tap(find.text(t.history.clearConfirm).last);
    await settlePilot(tester, frames: 8);

    expect(find.text(t.history.empty), findsOneWidget);
    await _novels(tester);
    expect(find.text(t.history.empty), findsOneWidget);
    expect(await _count(tester, '1000'), 0);
    expect(await _count(tester, '1001'), 1);
  });
}
