import 'dart:async';

import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_accounts.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

import 'memory_history.dart';

/// The error Pixiv answers with when a session is refused.
const oauthRefused = PixivError(
  kind: PixivErrorKind.httpStatus,
  message: 'HTTP 400',
  status: 400,
  body: '{"error":{"message":"Error occurred at the OAuth process."}}',
);

/// The error of a request that never reached Pixiv.
const offline = PixivError(kind: PixivErrorKind.httpClient, message: 'offline');

/// A client that holds an account and answers the one request an account
/// switch makes; [failure] makes it fail. Any other request is a test error.
class FakeAccountApi implements PixivApi {
  FakeAccountApi(this._account, {this.failure});

  UserAccountResult? _account;
  Object? failure;

  /// When set, the check waits for it to complete.
  Completer<void>? gate;
  final requestedUsers = <int>[];

  @override
  UserAccountResult? account() => _account;

  @override
  void setAccount({UserAccountResult? account}) => _account = account;

  /// The session as the client would have refreshed it.
  void refresh(UserAccountResult session) => _account = session;

  @override
  Future<UserDetailResult> getUserDetail({required int userId}) async {
    requestedUsers.add(userId);
    await gate?.future;
    if (failure case final failure?) throw failure;
    return sampleUserDetail;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('unexpected request: ${invocation.memberName}');
}

/// Gives every account its own [FakeAccountApi], recorded in [created], with
/// [failures] (by user ID) making their check fail. Call [restore] when done.
class FakeAccountApis {
  FakeAccountApis([Map<String, Object> failures = const {}]) : failures = Map.of(failures) {
    useMemoryHistory();
    _original = pixivApiFactory;
    pixivApiFactory = createFor;
  }

  final Map<String, Object> failures;

  /// Holds the check of the account with this user ID until completed.
  final gates = <String, Completer<void>>{};
  final created = <FakeAccountApi>[];
  late final PixivApi Function(UserAccountResult?) _original;

  FakeAccountApi createFor(UserAccountResult? account) {
    final api = FakeAccountApi(account, failure: failures[account?.user.id])..gate = gates[account?.user.id];
    created.add(api);
    return api;
  }

  void restore() => pixivApiFactory = _original;
}

/// Settings storing the two sample accounts, the first current; [secondState]
/// is the second one's state.
Map<String, dynamic> accountSettings({PixivAccountState secondState = PixivAccountState.usable}) => {
  AppSettings.accountsKey: PixivAccountBook(
    entries: [
      PixivAccountEntry(session: sampleAccount, lastUsed: DateTime.utc(2026, 11, 1)),
      PixivAccountEntry(session: sampleSecondAccount, lastUsed: DateTime.utc(2026, 10, 1), state: secondState),
    ],
    activeId: sampleAccount.user.id,
  ).toJson(),
};
