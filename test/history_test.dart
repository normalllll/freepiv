import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/account_fakes.dart';
import 'support/memory_history.dart';
import 'support/pilot_harness.dart';

HistoryEntry _entry(int workId, DateTime at, {HistoryWorkKind kind = HistoryWorkKind.illust, String title = 'A work'}) => HistoryEntry(
  kind: kind,
  workId: workId,
  title: title,
  authorId: 2000,
  authorName: 'Sample artist',
  thumbnailUrl: '',
  xRestrict: 0,
  aiGenerated: false,
  viewedAt: at,
  width: kind.isNovel ? null : 1000,
  height: kind.isNovel ? null : 1400,
  pageCount: kind.isNovel ? null : 1,
  textLength: kind.isNovel ? 9000 : null,
);

final _day = DateTime.utc(2026, 11, 1);

Future<List<int>> _ids(HistoryRepository history, String account, {bool novels = false}) async => [
  for (final entry in await history.list(account, novels: novels)) entry.workId,
];

void main() {
  late HistoryRepository history;

  setUp(() async {
    history = useMemoryHistory();
    await AppSettings.initialize(store: SampleSettingsStore(accountSettings()));
  });

  group('repository', () {
    test('viewing the same work twice keeps one entry with the newer time and snapshot', () async {
      await history.record('1000', _entry(1, _day, title: 'Before'), limit: HistoryLimit.standard);
      await history.record('1000', _entry(1, _day.add(const Duration(hours: 1)), title: 'After'), limit: HistoryLimit.standard);

      final entries = await history.list('1000', novels: false);
      expect(entries, hasLength(1));
      expect(entries.single.title, 'After');
      expect(entries.single.viewedAt.isAtSameMomentAs(_day.add(const Duration(hours: 1))), isTrue);
    });

    test('an illustration and a novel of the same ID are different works', () async {
      await history.record('1000', _entry(1, _day), limit: HistoryLimit.standard);
      await history.record('1000', _entry(1, _day, kind: HistoryWorkKind.novel), limit: HistoryLimit.standard);

      expect(await _ids(history, '1000'), [1]);
      expect(await _ids(history, '1000', novels: true), [1]);
      expect(await history.count('1000'), 2);
    });

    test('the lists run from the last viewed, illustrations and manga apart from novels', () async {
      await history.record('1000', _entry(1, _day), limit: HistoryLimit.standard);
      await history.record('1000', _entry(2, _day.add(const Duration(minutes: 2)), kind: HistoryWorkKind.manga), limit: HistoryLimit.standard);
      await history.record('1000', _entry(3, _day.add(const Duration(minutes: 1)), kind: HistoryWorkKind.ugoira), limit: HistoryLimit.standard);
      await history.record('1000', _entry(4, _day, kind: HistoryWorkKind.novel), limit: HistoryLimit.standard);

      expect(await _ids(history, '1000'), [2, 3, 1]);
      expect(await _ids(history, '1000', novels: true), [4]);
    });

    test('going past the limit deletes the oldest entries of that account only', () async {
      const limit = HistoryLimit.fiveHundred;
      await history.record('1001', _entry(9000, _day), limit: limit);
      for (var index = 0; index < limit.count + 2; index++) {
        await history.record('1000', _entry(index, _day.add(Duration(minutes: index))), limit: limit);
      }

      expect(await history.count('1000'), limit.count);
      final kept = await _ids(history, '1000');
      expect(kept.first, limit.count + 1, reason: 'the newest stays first');
      expect(kept.last, 2, reason: 'the two oldest went');
      expect(await _ids(history, '1001'), [9000]);
    });

    test('counting what a lower limit deletes adds up every account, and pruning applies it', () async {
      for (var index = 0; index < 503; index++) {
        await history.record('1000', _entry(index, _day.add(Duration(minutes: index))), limit: HistoryLimit.tenThousand);
      }
      for (var index = 0; index < 501; index++) {
        await history.record('1001', _entry(index, _day.add(Duration(minutes: index))), limit: HistoryLimit.tenThousand);
      }

      expect(await history.countBeyond(HistoryLimit.fiveHundred), 4);
      expect(await history.countBeyond(HistoryLimit.oneThousand), 0);
      await history.pruneAll(HistoryLimit.fiveHundred);
      expect(await history.count('1000'), 500);
      expect(await history.count('1001'), 500);
    });

    test('removing one entry and clearing touch only what they name', () async {
      await history.record('1000', _entry(1, _day), limit: HistoryLimit.standard);
      await history.record('1000', _entry(2, _day), limit: HistoryLimit.standard);
      await history.record('1001', _entry(1, _day), limit: HistoryLimit.standard);

      await history.remove('1000', HistoryWorkKind.illust, 1);
      expect(await _ids(history, '1000'), [2]);
      expect(await _ids(history, '1001'), [1]);

      await history.clear('1000');
      expect(await history.count('1000'), 0);
      expect(await _ids(history, '1001'), [1]);
    });
  });

  group('recording', () {
    test('a viewed illustration and novel are kept for the current account', () async {
      await recordIllustView(sampleIllusts(count: 1, kind: 'manga').single);
      await recordNovelView(sampleNovels(count: 1).single);

      final illust = (await history.list('1000', novels: false)).single;
      expect(illust.kind, HistoryWorkKind.manga);
      expect(illust.workId, 90000);
      expect(illust.title, 'Sample work 1');
      expect(illust.pageCount, 3);
      expect(illust.aspectRatio, 1);
      final novel = (await history.list('1000', novels: true)).single;
      expect(novel.workId, 70000);
      expect(novel.textLength, 12000);
    });

    test('the accounts keep their own history', () async {
      await recordIllustView(sampleIllusts(count: 1).single);
      AppSettings.accounts = AppSettings.accounts.activate(sampleSecondAccount, DateTime.now());
      await recordIllustView(sampleIllusts(count: 2).last);

      expect(await _ids(history, '1000'), [90000]);
      expect(await _ids(history, '1001'), [90001]);
    });

    test('turning recording off records nothing and deletes nothing', () async {
      await recordIllustView(sampleIllusts(count: 1).single);
      AppSettings.recordHistory = false;
      await recordIllustView(sampleIllusts(count: 2).last);
      await recordNovelView(sampleNovels(count: 1).single);

      expect(await _ids(history, '1000'), [90000]);
      expect(await history.count('1000'), 1);
      AppSettings.recordHistory = true;
      await recordNovelView(sampleNovels(count: 1).single);
      expect(await history.count('1000'), 2);
    });

    test('a work detail that loads is recorded, an illustration and a novel', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(illustDetailProvider(IllustDetailArgs(illust: sampleIllusts(count: 1).single)).future);
      await container.read(novelDetailProvider(NovelDetailArgs(novel: sampleNovels(count: 1).single)).future);
      await pumpEventQueue();
      expect(await _ids(history, '1000'), [90000]);
      expect(await _ids(history, '1000', novels: true), [70000]);
    });
    test('nothing is recorded while signed out', () async {
      AppSettings.accounts = AppSettings.accounts.deactivated();
      await recordIllustView(sampleIllusts(count: 1).single);

      expect(await history.count('1000'), 0);
    });

    test('an unknown stored limit means the standard one', () async {
      await AppSettings.initialize(store: SampleSettingsStore({...accountSettings(), 'historyLimit': 'forever'}));
      expect(AppSettings.historyLimit, HistoryLimit.standard);
      AppSettings.historyLimit = HistoryLimit.tenThousand;
      expect(AppSettings.historyLimit, HistoryLimit.tenThousand);
    });
  });

  test('signing out of an account deletes its browsing history and its search history', () async {
    final apis = FakeAccountApis();
    addTearDown(apis.restore);
    history = historyRepository;
    final book = AppSettings.accounts;
    AppSettings.accounts = book.withEntry(book.entry('1001')!.copyWith(searchHistory: const ['cat', 'miku']));
    await history.record('1001', _entry(1, _day), limit: HistoryLimit.standard);
    await history.record('1000', _entry(2, _day), limit: HistoryLimit.standard);
    expect(AppSettings.accounts.entry('1001')!.searchHistory, ['cat', 'miku']);

    await removePixivAccount('1001');

    expect(await history.count('1001'), 0);
    expect(AppSettings.accounts.entry('1001'), isNull, reason: 'the search history is part of the stored account');
    expect(await _ids(history, '1000'), [2]);
    expect(AppSettings.accounts.entry('1000')!.searchHistory, isEmpty);
  });

  group('settings', () {
    Future<void> openHistory(WidgetTester tester) async {
      await mountPilotPage(tester, const SettingsPage(), settings: accountSettings());
      await tester.tap(find.text(t.history.title).first);
      await settlePilot(tester, frames: 4);
    }

    Future<void> seed(WidgetTester tester, Future<void> Function(HistoryRepository history) fill) async {
      await tester.runAsync(() => fill(historyRepository));
    }

    Future<int> count(WidgetTester tester, String account) async => (await tester.runAsync(() => historyRepository.count(account)))!;

    Future<void> chooseLimit(WidgetTester tester, HistoryLimit limit) async {
      await tester.tap(find.byType(FrostPicker<HistoryLimit>));
      await settlePilot(tester, frames: 6);
      await tester.tap(find.text('${limit.count}').last);
      await settlePilot(tester, frames: 6);
    }

    Future<void> fillPast500(HistoryRepository history) async {
      for (var index = 0; index < 502; index++) {
        await history.record('1000', _entry(index, _day.add(Duration(minutes: index))), limit: HistoryLimit.tenThousand);
      }
    }

    testWidgets('the section sits between Downloads and Accounts and has the switch, the limit and the clear row', (tester) async {
      await mountPilotPage(tester, const SettingsPage(), size: phoneSize, settings: accountSettings());
      final rows = tester
          .widgetList<FrostListRow>(find.descendant(of: find.byType(FrostGroupedSection), matching: find.byType(FrostListRow)))
          .map((row) => row.title);
      expect(rows.toList(), [
        t.settings.theme.title,
        t.settings.language.title,
        t.settings.images.title,
        t.settings.proxy.title,
        t.settings.downloads.title,
        t.history.title,
        t.block.title,
        t.settings.account.title,
      ]);

      await openHistory(tester);
      expect(find.text(t.history.record), findsOneWidget);
      expect(find.text(t.history.limit), findsOneWidget);
      expect(find.text(t.history.clear), findsOneWidget);
      expect(AppSettings.recordHistory, isTrue, reason: 'on by default');
      expect(AppSettings.historyLimit, HistoryLimit.standard);
    });

    testWidgets('Manage accounts still opens Accounts', (tester) async {
      await mountPilotPage(tester, const SettingsPage(openAccount: true), size: phoneSize, settings: accountSettings());
      expect(find.text(t.accounts.add), findsOneWidget);
      expect(find.text(t.history.record), findsNothing);
    });

    testWidgets('the switch turns recording off and on', (tester) async {
      await openHistory(tester);
      await tester.tap(find.text(t.history.record));
      await settlePilot(tester, frames: 4);
      expect(AppSettings.recordHistory, isFalse);
      await tester.tap(find.text(t.history.record));
      await settlePilot(tester, frames: 4);
      expect(AppSettings.recordHistory, isTrue);
    });

    testWidgets('lowering the limit names how many entries go; cancelling keeps the limit and the entries', (tester) async {
      await openHistory(tester);
      await seed(tester, fillPast500);

      await chooseLimit(tester, HistoryLimit.fiveHundred);
      expect(find.text(t.history.lowerLimitMessage(count: 2)), findsOneWidget);
      await tester.tap(find.text(t.frost.cancel).last);
      await settlePilot(tester, frames: 6);

      expect(AppSettings.historyLimit, HistoryLimit.standard);
      expect(await count(tester, '1000'), 502);
    });

    testWidgets('confirming applies the lower limit and deletes the oldest entries at once', (tester) async {
      await openHistory(tester);
      await seed(tester, fillPast500);

      await chooseLimit(tester, HistoryLimit.fiveHundred);
      await tester.tap(find.text(t.history.lowerLimitConfirm).last);
      await settlePilot(tester, frames: 6);

      expect(AppSettings.historyLimit, HistoryLimit.fiveHundred);
      expect(await count(tester, '1000'), 500);
    });

    testWidgets('a limit nothing exceeds applies without a question', (tester) async {
      await openHistory(tester);
      await seed(tester, (history) => history.record('1000', _entry(1, _day), limit: HistoryLimit.standard));

      await chooseLimit(tester, HistoryLimit.fiveHundred);

      expect(find.text(t.history.lowerLimitTitle), findsNothing);
      expect(AppSettings.historyLimit, HistoryLimit.fiveHundred);
      expect(await count(tester, '1000'), 1);
    });

    testWidgets('clearing asks first and clears the current account only', (tester) async {
      await openHistory(tester);
      await seed(tester, (history) async {
        await history.record('1000', _entry(1, _day), limit: HistoryLimit.standard);
        await history.record('1001', _entry(2, _day), limit: HistoryLimit.standard);
      });

      await tester.tap(find.text(t.history.clear));
      await settlePilot(tester, frames: 6);
      expect(await count(tester, '1000'), 1, reason: 'nothing happens before the confirmation');
      await tester.tap(find.text(t.history.clearConfirm).last);
      await settlePilot(tester, frames: 6);

      expect(await count(tester, '1000'), 0);
      expect(await count(tester, '1001'), 1);
    });
  });

  test('the history strings exist in all four languages', () => expectLocalesComplete(['history', 'me']));
}
