import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

/// Whether a stored account can be used as it is.
enum PixivAccountState {
  usable,

  /// Pixiv refused its session; the account signs in again before it is used.
  needsSignIn,
}

/// One Pixiv account the app keeps: its session, whether the session is
/// still accepted, when it was last the current account, and the searches made
/// with it.
@immutable
class PixivAccountEntry {
  const PixivAccountEntry({required this.session, required this.lastUsed, this.state = PixivAccountState.usable, this.searchHistory = const []});

  static const searchHistoryLimit = 30;

  final UserAccountResult session;
  final PixivAccountState state;
  final DateTime lastUsed;
  final List<String> searchHistory;

  String get id => session.user.id;

  bool get usable => state == PixivAccountState.usable;

  PixivAccountEntry copyWith({UserAccountResult? session, PixivAccountState? state, DateTime? lastUsed, List<String>? searchHistory}) {
    return PixivAccountEntry(
      session: session ?? this.session,
      state: state ?? this.state,
      lastUsed: lastUsed ?? this.lastUsed,
      searchHistory: searchHistory == null ? this.searchHistory : List.unmodifiable(searchHistory.take(searchHistoryLimit)),
    );
  }

  Map<String, dynamic> toJson() => {
    'session': _jsonMap(session.toJson()),
    'state': state.name,
    'lastUsed': lastUsed.millisecondsSinceEpoch,
    'searchHistory': searchHistory,
  };

  /// The entry [value] holds, or null when it is not one.
  static PixivAccountEntry? fromJson(Object? value) {
    if (value is! Map) return null;
    final session = _jsonMap(value['session']);
    final state = PixivAccountState.values.where((state) => state.name == value['state']).firstOrNull;
    final lastUsed = value['lastUsed'];
    final history = value['searchHistory'];
    if (session == null || state == null || lastUsed is! int || history is! List || !history.every((item) => item is String)) return null;
    try {
      return PixivAccountEntry(
        session: UserAccountResult.fromJson(session),
        state: state,
        lastUsed: DateTime.fromMillisecondsSinceEpoch(lastUsed),
        searchHistory: List.unmodifiable(history.cast<String>().take(searchHistoryLimit)),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  int get hashCode => Object.hash(session, state, lastUsed, Object.hashAll(searchHistory));

  @override
  bool operator ==(Object other) {
    return other is PixivAccountEntry &&
        other.session == session &&
        other.state == state &&
        other.lastUsed == lastUsed &&
        _sameStrings(other.searchHistory, searchHistory);
  }
}

/// The accounts the app keeps and which of them is current. No current
/// account means signed out, whether or not accounts are stored.
@immutable
class PixivAccountBook {
  const PixivAccountBook({this.entries = const [], this.activeId});

  final List<PixivAccountEntry> entries;
  final String? activeId;

  bool get isEmpty => entries.isEmpty;

  PixivAccountEntry? entry(String id) => entries.where((entry) => entry.id == id).firstOrNull;

  PixivAccountEntry? get active => activeId == null ? null : entry(activeId!);

  /// [updated] in place of the entry of the same account, or appended.
  PixivAccountBook withEntry(PixivAccountEntry updated) {
    final exists = entry(updated.id) != null;
    return PixivAccountBook(
      entries: List.unmodifiable(exists ? [for (final entry in entries) entry.id == updated.id ? updated : entry] : [...entries, updated]),
      activeId: activeId,
    );
  }

  /// [session] made the current account at [usedAt]: a stored account of that
  /// user is updated, a new one is added.
  PixivAccountBook activate(UserAccountResult session, DateTime usedAt) {
    final existing = entry(session.user.id);
    final updated = (existing ?? PixivAccountEntry(session: session, lastUsed: usedAt)).copyWith(
      session: session,
      state: PixivAccountState.usable,
      lastUsed: usedAt,
    );
    return PixivAccountBook(entries: withEntry(updated).entries, activeId: updated.id);
  }

  PixivAccountBook remove(String id) {
    return PixivAccountBook(entries: List.unmodifiable(entries.where((entry) => entry.id != id)), activeId: activeId == id ? null : activeId);
  }

  /// No account is current.
  PixivAccountBook deactivated() => PixivAccountBook(entries: entries);

  /// The usable accounts other than [excluding], the one used last first.
  List<PixivAccountEntry> usableByRecency({String? excluding}) {
    return entries.where((entry) => entry.usable && entry.id != excluding).toList()..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
  }

  @override
  int get hashCode => Object.hash(activeId, Object.hashAll(entries));

  @override
  bool operator ==(Object other) {
    if (other is! PixivAccountBook || other.activeId != activeId || other.entries.length != entries.length) return false;
    for (var index = 0; index < entries.length; index++) {
      if (other.entries[index] != entries[index]) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'activeId': activeId,
    'entries': [for (final entry in entries) entry.toJson()],
  };

  /// The book [value] holds, or null when it is not a readable one: an
  /// unreadable entry, a repeated account, or a current account that is not
  /// stored.
  static PixivAccountBook? fromJson(Object? value) {
    if (value is! Map) return null;
    final list = value['entries'];
    final activeId = value['activeId'];
    if (list is! List || (activeId != null && activeId is! String)) return null;
    final entries = <PixivAccountEntry>[];
    for (final item in list) {
      final entry = PixivAccountEntry.fromJson(item);
      if (entry == null || entries.any((other) => other.id == entry.id)) return null;
      entries.add(entry);
    }
    if (activeId != null && !entries.any((entry) => entry.id == activeId)) return null;
    return PixivAccountBook(entries: List.unmodifiable(entries), activeId: activeId as String?);
  }
}

/// Whether Pixiv refused the account's session itself, as opposed to the
/// request failing for another reason (the network, the server).
bool isPixivAuthError(Object error) {
  if (error is! PixivError) return false;
  if (error.kind == PixivErrorKind.missingAccount || error.status == 401) return true;
  final body = error.body ?? '';
  return error.status == 400 && (body.contains('OAuth') || body.contains('invalid_grant'));
}

bool _sameStrings(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

Map<String, dynamic>? _jsonMap(Object? value) {
  try {
    final decoded = value is String ? json.decode(value) : json.decode(json.encode(value));
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.map((key, value) => MapEntry(key.toString(), value));
  } catch (_) {
    // A value that is not JSON is not a session.
  }
  return null;
}
