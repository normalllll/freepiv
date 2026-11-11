import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/account_scope.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_accounts.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/search/logic/search_history_logic.dart';

import 'support/account_fakes.dart';
import 'support/pilot_harness.dart';

class _Marker extends Notifier<int> {
  @override
  int build() => 0;
}

final _markerProvider = NotifierProvider<_Marker, int>(_Marker.new);

final _third = sampleAccount.copyWith(
  user: sampleAccount.user.copyWith(id: '1002', name: 'Third', account: 'third_user'),
);

/// A scope whose child shows the marker of the account it is for.
Widget _blank(BuildContext context, String? accountId) => const SizedBox();

Widget _markerApp(void Function(WidgetRef ref) onBuild) => AccountScope(
  builder: (context, accountId) => Consumer(
    builder: (context, ref, _) {
      onBuild(ref);
      return Directionality(textDirection: TextDirection.ltr, child: Text('marker ${ref.watch(_markerProvider)}'));
    },
  ),
);

void main() {
  late FakeAccountApis apis;

  /// The sample settings (account 1000 current, 1001 stored), a client for
  /// the current account, and, with [withThird], a third account used
  /// between the two.
  Future<void> start({Map<String, Object> failures = const {}, bool withThird = false}) async {
    apis = FakeAccountApis(failures);
    addTearDown(apis.restore);
    await AppSettings.initialize(store: SampleSettingsStore(sampleSettings));
    if (withThird) {
      AppSettings.accounts = AppSettings.accounts.withEntry(PixivAccountEntry(session: _third, lastUsed: DateTime.utc(2026, 10, 15)));
    }
    pixivApi = apis.createFor(AppSettings.accounts.active?.session);
    pixivAccountNotifier.value = pixivApi.account();
    addTearDown(() => pixivAccountNotifier.value = null);
  }

  test('a switch builds a new client for the target, checks it as that user and makes it current', () async {
    await start();
    final before = pixivApi;
    final usedBefore = AppSettings.accounts.entry('1001')!.lastUsed;

    final result = await switchPixivAccount('1001');

    expect(result.outcome, PixivSwitchOutcome.switched);
    expect(pixivApi, isNot(same(before)), reason: 'setAccount is never called on the old client');
    expect((pixivApi as FakeAccountApi).requestedUsers, [1001]);
    expect(pixivAccountNotifier.value?.user.id, '1001');
    expect(AppSettings.accounts.activeId, '1001');
    expect(AppSettings.accounts.active!.lastUsed.isAfter(usedBefore), isTrue);
    expect(AppSettings.searchHistory, isEmpty, reason: 'the second account has its own history');
  });

  test('a refused session marks the account as needing sign-in and stays on the current one', () async {
    await start(failures: {'1001': oauthRefused});
    final before = pixivApi;

    final result = await switchPixivAccount('1001');

    expect(result.outcome, PixivSwitchOutcome.needsSignIn);
    expect(AppSettings.accounts.activeId, '1000');
    expect(AppSettings.accounts.entry('1001')!.state, PixivAccountState.needsSignIn);
    expect(pixivApi, same(before));
    expect(pixivAccountNotifier.value?.user.id, '1000');
  });

  test('a request that fails for another reason changes nothing', () async {
    await start(failures: {'1001': offline});

    final result = await switchPixivAccount('1001');

    expect(result.outcome, PixivSwitchOutcome.failed);
    expect(result.error, offline);
    expect(AppSettings.accounts.activeId, '1000');
    expect(AppSettings.accounts.entry('1001')!.state, PixivAccountState.usable);
    expect(pixivAccountNotifier.value?.user.id, '1000');
  });

  test('switching to the current account does nothing', () async {
    await start();

    expect((await switchPixivAccount('1000')).outcome, PixivSwitchOutcome.unchanged);
    expect(apis.created, hasLength(1), reason: 'only the start-up client exists');
  });

  test('the refreshed session is written back before switching away', () async {
    await start();
    (pixivApi as FakeAccountApi).refresh(sampleAccount.copyWith(accessToken: 'rotated'));

    await switchPixivAccount('1001');

    expect(AppSettings.accounts.entry('1000')!.session.accessToken, 'rotated');
  });

  test('a session of another user in the client is not written over the current entry', () async {
    await start();
    (pixivApi as FakeAccountApi).refresh(sampleSecondAccount);

    persistPixivSession();

    expect(AppSettings.accounts.entry('1000')!.session, sampleAccount);
  });

  test('signing in as a stored user updates its entry and makes it current', () async {
    await start();

    await signInPixivAccount(sampleSecondAccount.copyWith(accessToken: 'new token'));

    expect(AppSettings.accounts.entries, hasLength(2));
    expect(AppSettings.accounts.active!.session.accessToken, 'new token');
    expect(pixivAccountNotifier.value?.user.id, '1001');
    expect(pixivApi.account()?.accessToken, 'new token');
  });

  test('signing in as a new user adds an entry', () async {
    await start();

    await signInPixivAccount(_third);

    expect(AppSettings.accounts.entries.map((entry) => entry.id), ['1000', '1001', '1002']);
    expect(AppSettings.accounts.activeId, '1002');
  });

  test('signing out of the current account switches to the most recently used usable one', () async {
    await start(withThird: true);

    await removePixivAccount('1000');

    expect(AppSettings.accounts.entry('1000'), isNull);
    expect(AppSettings.accounts.activeId, '1002', reason: 'used after the second account');
    expect(pixivAccountNotifier.value?.user.id, '1002');
    expect(pixivApi.account()?.user.id, '1002');
  });

  test('an account whose session is refused is passed over on sign-out', () async {
    await start(withThird: true, failures: {'1002': oauthRefused});

    await removePixivAccount('1000');

    expect(AppSettings.accounts.activeId, '1001');
    expect(AppSettings.accounts.entry('1002')!.state, PixivAccountState.needsSignIn);
  });

  test('signing out of another account leaves the current one; of the last one signs out', () async {
    await start();

    await removePixivAccount('1001');
    expect(AppSettings.accounts.activeId, '1000');
    expect(pixivAccountNotifier.value?.user.id, '1000');

    await removePixivAccount('1000');
    expect(AppSettings.accounts.isEmpty, isTrue);
    expect(AppSettings.accounts.activeId, isNull);
    expect(pixivAccountNotifier.value, isNull);
    expect(pixivApi.account(), isNull);
  });

  test('with only accounts that need signing in left, the app is signed out and they stay listed', () async {
    await start(failures: {'1001': oauthRefused});

    await removePixivAccount('1000');

    expect(pixivAccountNotifier.value, isNull);
    expect(AppSettings.accounts.activeId, isNull);
    expect(AppSettings.accounts.entry('1001')!.state, PixivAccountState.needsSignIn);
  });

  test('a session the old client refreshed during the check is kept for the old account', () async {
    await start();
    final gate = apis.gates['1001'] = Completer<void>();

    final pending = switchPixivAccount('1001');
    await Future<void>.delayed(Duration.zero);
    (pixivApi as FakeAccountApi).refresh(sampleAccount.copyWith(accessToken: 'refreshed during the check'));
    gate.complete();
    await pending;

    expect(AppSettings.accounts.active!.id, '1001');
    expect(AppSettings.accounts.entry('1000')!.session.accessToken, 'refreshed during the check');
  });

  test('removing the account a switch is under way to leaves the previous one current and does not store it again', () async {
    await start();
    final gate = apis.gates['1001'] = Completer<void>();

    final switching = switchPixivAccount('1001');
    await Future<void>.delayed(Duration.zero);
    final removing = removePixivAccount('1001');
    gate.complete();

    expect((await switching).outcome, PixivSwitchOutcome.switched, reason: 'the switch was asked for first and runs first');
    await removing;
    expect(AppSettings.accounts.entries.map((entry) => entry.id), ['1000']);
    expect(AppSettings.accounts.activeId, '1000');
    expect(pixivAccountNotifier.value?.user.id, '1000');
  });

  test('a switch to an account removed before its turn does nothing', () async {
    await start();

    final removing = removePixivAccount('1001');
    final switching = switchPixivAccount('1001');

    await removing;
    expect((await switching).outcome, PixivSwitchOutcome.unchanged);
    expect(AppSettings.accounts.entries.map((entry) => entry.id), ['1000']);
    expect(AppSettings.accounts.activeId, '1000');
  });

  test('removing the current account while a switch is under way waits for it', () async {
    await start();
    final gate = apis.gates['1001'] = Completer<void>();

    final switching = switchPixivAccount('1001');
    await Future<void>.delayed(Duration.zero);
    final removing = removePixivAccount('1000');
    expect(AppSettings.accounts.entry('1000'), isNotNull, reason: 'nothing is removed while the switch runs');
    gate.complete();

    await switching;
    await removing;
    expect(AppSettings.accounts.entries.map((entry) => entry.id), ['1001']);
    expect(AppSettings.accounts.activeId, '1001');
    expect(pixivAccountNotifier.value?.user.id, '1001');
  });

  test('operations run in the order they were asked for, and one that fails does not stop the next', () async {
    await start(failures: {'1001': offline});

    final first = switchPixivAccount('1001');
    final second = signInPixivAccount(_third);

    expect((await first).outcome, PixivSwitchOutcome.failed);
    await second;
    expect(AppSettings.accounts.activeId, '1002');
  });

  test('a start with no current account but a usable one stored resumes the one used last', () async {
    final book = PixivAccountBook(
      entries: [
        PixivAccountEntry(session: sampleAccount, lastUsed: DateTime.utc(2026, 10, 1)),
        PixivAccountEntry(session: sampleSecondAccount, lastUsed: DateTime.utc(2026, 11, 1)),
        PixivAccountEntry(session: _third, lastUsed: DateTime.utc(2026, 11, 5), state: PixivAccountState.needsSignIn),
      ],
    );
    final store = SampleSettingsStore({AppSettings.accountsKey: book.toJson()});

    await AppSettings.initialize(store: store);

    expect(AppSettings.accounts.activeId, '1001', reason: 'usable and used last; the one that needs signing in is passed over');
    expect(PixivAccountBook.fromJson(store.values[AppSettings.accountsKey])!.activeId, '1001', reason: 'stored');
    expect(AppSettings.accounts.entry('1001')!.lastUsed.isAtSameMomentAs(DateTime.utc(2026, 11, 1)), isTrue, reason: 'no check was made, so it is not marked used');
  });

  test('a start with only accounts that need signing in stays signed out', () async {
    final book = PixivAccountBook(
      entries: [PixivAccountEntry(session: sampleAccount, lastUsed: DateTime.utc(2026), state: PixivAccountState.needsSignIn)],
    );

    await AppSettings.initialize(store: SampleSettingsStore({AppSettings.accountsKey: book.toJson()}));

    expect(AppSettings.accounts.activeId, isNull);
  });

  testWidgets('the root scope starts over for the new account: a kept-alive value of the old one is gone', (tester) async {
    await start();
    late WidgetRef ref;
    await tester.pumpWidget(_markerApp((built) => ref = built));
    ref.read(_markerProvider.notifier).state = 5;
    await tester.pump();
    expect(find.text('marker 5'), findsOneWidget);

    await switchPixivAccount('1001');
    await tester.pump();

    expect(find.text('marker 0'), findsOneWidget, reason: "account A's state did not carry over to B");
  });

  testWidgets('a change of the same account keeps the scope', (tester) async {
    await start();
    late WidgetRef ref;
    await tester.pumpWidget(_markerApp((built) => ref = built));
    ref.read(_markerProvider.notifier).state = 5;

    updatePixivAccount(sampleAccount.copyWith(user: sampleAccount.user.copyWith(name: 'Renamed')));
    await tester.pump();

    expect(find.text('marker 5'), findsOneWidget);
  });

  testWidgets('signing out starts the scope over too', (tester) async {
    await start();
    late WidgetRef ref;
    await tester.pumpWidget(_markerApp((built) => ref = built));
    ref.read(_markerProvider.notifier).state = 5;
    await tester.pump();

    await removePixivAccount('1001');
    await removePixivAccount('1000');
    await tester.pump();

    expect(find.text('marker 0'), findsOneWidget);
  });

  testWidgets('going to the background writes the refreshed session back', (tester) async {
    await start();
    await tester.pumpWidget(AccountScope(builder: _blank));
    (pixivApi as FakeAccountApi).refresh(sampleAccount.copyWith(accessToken: 'rotated'));
    expect(AppSettings.accounts.active!.session.accessToken, 'sample', reason: 'nothing is written while the app is in use');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

    expect(AppSettings.accounts.active!.session.accessToken, 'rotated');
  });

  testWidgets('staying in the foreground does not write', (tester) async {
    await start();
    await tester.pumpWidget(AccountScope(builder: _blank));
    (pixivApi as FakeAccountApi).refresh(sampleAccount.copyWith(accessToken: 'rotated'));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    expect(AppSettings.accounts.active!.session.accessToken, 'sample');
  });

  test('search history stays with its account through the provider', () async {
    await AppSettings.initialize(store: SampleSettingsStore(sampleSettings));
    final first = ProviderContainer();
    addTearDown(first.dispose);
    first.read(searchHistoryProvider.notifier).record('a new search');
    expect(AppSettings.accounts.entry('1000')!.searchHistory.first, 'a new search');
    expect(AppSettings.accounts.entry('1001')!.searchHistory, isEmpty);

    AppSettings.accounts = AppSettings.accounts.activate(sampleSecondAccount, DateTime.utc(2026, 11, 2));
    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect(second.read(searchHistoryProvider), isEmpty);
    second.read(searchHistoryProvider.notifier).record('for the second');
    expect(AppSettings.accounts.entry('1000')!.searchHistory, isNot(contains('for the second')));
    expect(AppSettings.accounts.entry('1001')!.searchHistory, ['for the second']);
  });

  test('the account strings exist in all four languages', () => expectLocalesComplete(['accounts']));
}
