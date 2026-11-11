import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:freepiv/core/downloads/downloader.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_accounts.dart';
import 'package:freepiv/core/services/pixiv_api_settings.dart';
import 'package:freepiv/src/rust/frb_generated.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

late PixivApi pixivApi;
bool _appServicesInitialized = false;
final pixivAccountNotifier = ValueNotifier<UserAccountResult?>(null);

bool get appServicesInitialized => _appServicesInitialized;

Future<void> initializeAppServices() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_appServicesInitialized) {
    return;
  }

  await AppSettings.initialize();
  await RustLib.init();
  await initializeDownloadManager();

  pixivApi = createPixivApi(account: AppSettings.accounts.active?.session);
  pixivAccountNotifier.value = pixivApi.account();
  _appServicesInitialized = true;
}

/// How the client of an account is built; the sample entry and tests replace
/// it with one that answers from memory.
PixivApi Function(UserAccountResult? account) pixivApiFactory = _buildPixivApi;

/// A new client for [account], or for no account.
PixivApi createPixivApi({UserAccountResult? account}) => pixivApiFactory(account);

PixivApi _buildPixivApi(UserAccountResult? account) => PixivApi(config: buildPixivApiConfig(account: account));

/// The current account's session changed (its name, for one): the same user,
/// so the client and the stored entry take it over.
void updatePixivAccount(UserAccountResult account) {
  pixivApi.setAccount(account: account);
  AppSettings.accounts = AppSettings.accounts.activate(account, DateTime.now());
  pixivAccountNotifier.value = account;
}

/// Signs in as [account], which becomes the current account. A stored account
/// of the same user is updated, not added again. The previous account's
/// refreshed session is kept first. Runs after the account operations already
/// under way.
Future<void> signInPixivAccount(UserAccountResult account) => _serial(() async {
  persistPixivSession();
  _activate(createPixivApi(account: account), account);
});

/// pixiv_rs refreshes the session inside the client without telling the app;
/// this writes the client's session back to the current account's entry when
/// it differs, so a rotated token is not lost.
void persistPixivSession() {
  final book = AppSettings.accounts;
  final active = book.active;
  if (active == null) return;
  final session = pixivApi.account();
  if (session == null || session.user.id != active.id || session == active.session) return;
  AppSettings.accounts = book.withEntry(active.copyWith(session: session));
}

/// How a switch to another account ended.
enum PixivSwitchOutcome {
  switched,

  /// The account is already the current one, or it was removed before its
  /// turn.
  unchanged,

  /// Pixiv refused the account's session; it stays stored, marked as needing
  /// sign-in, and the current account is unchanged.
  needsSignIn,

  /// The check could not be made (the network, the server); nothing changed.
  failed,
}

class PixivSwitchResult {
  const PixivSwitchResult(this.outcome, {this.error});

  final PixivSwitchOutcome outcome;
  final Object? error;
}

/// The account operations (switch, remove, sign in) run one after another, in
/// the order they were asked for, so that none of them acts on a state another
/// one is still changing.
bool _operationRunning = false;
final _operationsWaiting = Queue<Completer<void>>();

Future<T> _serial<T>(Future<T> Function() operation) async {
  if (_operationRunning) {
    final turn = Completer<void>();
    _operationsWaiting.add(turn);
    await turn.future;
  }
  _operationRunning = true;
  try {
    return await operation();
  } finally {
    // The next one in line takes over; without one the queue is idle.
    if (_operationsWaiting.isEmpty) {
      _operationRunning = false;
    } else {
      _operationsWaiting.removeFirst().complete();
    }
  }
}

/// Makes the stored account [id] the current one. A fresh client is built for
/// it and one request as that account confirms the session; pixiv_rs refreshes
/// a session at most once a minute per client, so a client that has just
/// refreshed another account's session could not refresh this one's. An
/// account removed before its turn is not switched to, nor stored again.
Future<PixivSwitchResult> switchPixivAccount(String id) => _serial(() async {
  final target = AppSettings.accounts.entry(id);
  if (target == null || AppSettings.accounts.activeId == id) return const PixivSwitchResult(PixivSwitchOutcome.unchanged);
  persistPixivSession();
  final api = createPixivApi(account: target.session);
  try {
    await _confirm(api, id);
  } catch (error) {
    if (!isPixivAuthError(error)) return PixivSwitchResult(PixivSwitchOutcome.failed, error: error);
    _markNeedsSignIn(id);
    return PixivSwitchResult(PixivSwitchOutcome.needsSignIn, error: error);
  }
  // The old client may have refreshed its session while the request ran.
  persistPixivSession();
  _activate(api, api.account() ?? target.session);
  return const PixivSwitchResult(PixivSwitchOutcome.switched);
});

/// Removes the stored account [id]. When it is the current one, the most
/// recently used other usable account becomes current, or with none left the
/// app is signed out. An account whose session Pixiv refuses is marked as
/// needing sign-in and passed over; one that could not be checked for lack of
/// a network is used as at a cold start.
Future<void> removePixivAccount(String id) => _serial(() async {
  final book = AppSettings.accounts;
  if (book.entry(id) == null) return;
  // The entry carries the account's search history; its browsing history is
  // kept apart and goes with it.
  AppSettings.accounts = book.remove(id);
  try {
    await historyRepository.clear(id);
  } catch (_) {
    // A history that cannot be cleared does not keep the account from signing out.
  }
  if (book.activeId != id) return;
  for (final candidate in AppSettings.accounts.usableByRecency()) {
    final api = createPixivApi(account: candidate.session);
    try {
      await _confirm(api, candidate.id);
    } catch (error) {
      if (isPixivAuthError(error)) {
        _markNeedsSignIn(candidate.id);
        continue;
      }
    }
    persistPixivSession();
    _activate(api, api.account() ?? candidate.session);
    return;
  }
  pixivApi = createPixivApi();
  pixivAccountNotifier.value = null;
});

/// One request as the account itself, which fails when its session is refused.
Future<void> _confirm(PixivApi api, String id) async {
  await api.getUserDetail(userId: int.parse(id));
}

void _activate(PixivApi api, UserAccountResult session) {
  pixivApi = api;
  AppSettings.accounts = AppSettings.accounts.activate(session, DateTime.now());
  pixivAccountNotifier.value = session;
}

void _markNeedsSignIn(String id) {
  final book = AppSettings.accounts;
  final entry = book.entry(id);
  if (entry != null) AppSettings.accounts = book.withEntry(entry.copyWith(state: PixivAccountState.needsSignIn));
}

void refreshPixivApiLanguage() {
  if (!_appServicesInitialized) {
    return;
  }

  pixivApi = createPixivApi(account: pixivApi.account());
}

void refreshPixivApiProxy() {
  if (!_appServicesInitialized) {
    return;
  }

  pixivApi = createPixivApi(account: pixivApi.account());
}
