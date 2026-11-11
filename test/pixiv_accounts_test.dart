import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_accounts.dart';
import 'package:freepiv/dev/sample_data.dart';

/// The stored session as the single-account app kept it.
Map<String, dynamic> _legacySession() => PixivAccountEntry(session: sampleAccount, lastUsed: DateTime.utc(2026)).toJson()['session'] as Map<String, dynamic>;

Future<SampleSettingsStore> _start(Map<String, dynamic> values) async {
  final store = SampleSettingsStore(values);
  await AppSettings.initialize(store: store);
  return store;
}

void main() {
  group('migration from a single stored session', () {
    test('the old session becomes the one active account and the old keys go', () async {
      final store = await _start({'accountSession': _legacySession(), 'themeMode': 1});

      expect(AppSettings.accounts.entries, hasLength(1));
      expect(AppSettings.accounts.activeId, sampleAccount.user.id);
      expect(AppSettings.accounts.active!.session, sampleAccount);
      expect(AppSettings.accounts.active!.state, PixivAccountState.usable);
      expect(store.values.containsKey('accountSession'), isFalse);
      expect(store.values[AppSettings.accountsKey], isNotNull, reason: 'the list is stored');
      expect(store.values['themeMode'], 1, reason: 'other settings stay');
    });

    test('the search history moves under the account', () async {
      final store = await _start({
        'accountSession': _legacySession(),
        'searchHistory': ['miku', 'cat'],
      });

      expect(AppSettings.searchHistory, ['miku', 'cat']);
      expect(store.values.containsKey('searchHistory'), isFalse);
    });

    test('a second start reads the stored list and migrates nothing again', () async {
      final store = await _start({
        'accountSession': _legacySession(),
        'searchHistory': ['miku'],
      });
      final stored = AppSettings.accounts;

      await AppSettings.initialize(store: SampleSettingsStore(store.values));
      expect(AppSettings.accounts.toJson(), stored.toJson());
    });

    test('an old session that cannot be read leaves no account and is removed', () async {
      final store = await _start({
        'accountSession': 'not a session',
        'searchHistory': ['miku'],
      });

      expect(AppSettings.accounts.isEmpty, isTrue);
      expect(AppSettings.searchHistory, isEmpty);
      expect(store.values.containsKey('accountSession'), isFalse);
    });
  });

  group('search history per account', () {
    test('each account keeps its own, and signed out has none', () async {
      await _start({});
      final other = sampleAccount.copyWith(
        user: sampleAccount.user.copyWith(id: '1001', name: 'Other'),
      );
      final at = DateTime.utc(2026, 11, 1);

      AppSettings.accounts = const PixivAccountBook().activate(sampleAccount, at);
      AppSettings.searchHistory = ['first'];
      AppSettings.accounts = AppSettings.accounts.activate(other, at);
      expect(AppSettings.searchHistory, isEmpty, reason: 'the second account starts empty');
      AppSettings.searchHistory = ['second'];

      AppSettings.accounts = AppSettings.accounts.activate(sampleAccount, at);
      expect(AppSettings.searchHistory, ['first']);
      AppSettings.accounts = AppSettings.accounts.activate(other, at);
      expect(AppSettings.searchHistory, ['second']);

      AppSettings.accounts = AppSettings.accounts.deactivated();
      expect(AppSettings.searchHistory, isEmpty);
    });
  });

  group('an account list that cannot be read', () {
    Map<String, dynamic> stored() => PixivAccountBook(
      entries: [
        PixivAccountEntry(session: sampleAccount, lastUsed: DateTime.utc(2026), searchHistory: const ['miku']),
      ],
      activeId: sampleAccount.user.id,
    ).toJson();

    for (final (name, damage) in <(String, void Function(Map<String, dynamic>))>[
      ('an entry without a session', (book) => (book['entries']! as List).first.remove('session')),
      ('an unknown state', (book) => (book['entries']! as List).first['state'] = 'gone'),
      ('a current account that is not stored', (book) => book['activeId'] = '42'),
      ('the same account twice', (book) => (book['entries']! as List).add((book['entries']! as List).first)),
    ]) {
      test('$name resets to signed out and keeps the other settings', () async {
        final book = stored();
        damage(book);
        final store = await _start({AppSettings.accountsKey: book, 'themeMode': 2, 'proxyEnabled': true});

        expect(AppSettings.accounts.isEmpty, isTrue);
        expect(AppSettings.accounts.active, isNull);
        expect(AppSettings.themeMode, 2);
        expect(AppSettings.proxyEnabled, isTrue);
        expect(store.values.containsKey(AppSettings.accountsKey), isFalse, reason: 'the unreadable list is cleared from storage');
        expect(store.values['themeMode'], 2);
      });
    }

    test('a value that is not a list at all resets too', () async {
      final store = await _start({AppSettings.accountsKey: 'garbage', 'themeMode': 1});

      expect(AppSettings.accounts.isEmpty, isTrue);
      expect(store.values.containsKey(AppSettings.accountsKey), isFalse);
      expect(store.values['themeMode'], 1);
    });

    test('signing in afterwards stores a fresh list', () async {
      final store = await _start({AppSettings.accountsKey: 'garbage'});

      AppSettings.accounts = AppSettings.accounts.activate(sampleAccount, DateTime.utc(2026));
      expect(PixivAccountBook.fromJson(store.values[AppSettings.accountsKey])?.activeId, sampleAccount.user.id);
    });
  });

  test('signing in as a stored user updates its entry instead of adding one', () {
    final at = DateTime.utc(2026, 11, 1);
    final book = const PixivAccountBook()
        .activate(sampleAccount, at)
        .withEntry(const PixivAccountBook().activate(sampleAccount, at).entries.single.copyWith(searchHistory: ['kept']));
    final renewed = sampleAccount.copyWith(accessToken: 'new token');

    final updated = book.activate(renewed, at.add(const Duration(days: 1)));

    expect(updated.entries, hasLength(1));
    expect(updated.active!.session.accessToken, 'new token');
    expect(updated.active!.searchHistory, ['kept']);
    expect(updated.active!.lastUsed, at.add(const Duration(days: 1)));
  });
}
