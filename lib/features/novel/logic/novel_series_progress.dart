import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/core/services/app_settings.dart';

/// A set of novels whose reading progress is read together; equal when the
/// ids are, whatever order they came in.
class NovelIdBatch {
  NovelIdBatch(Iterable<int> ids) : ids = (ids.toSet().toList()..sort());

  final List<int> ids;

  @override
  bool operator ==(Object other) => other is NovelIdBatch && listEquals(other.ids, ids);

  @override
  int get hashCode => Object.hashAll(ids);
}

/// Where the current account stopped in each novel of the batch that it has
/// started; one query for all of them. Empty when nobody is signed in or the
/// history cannot be read.
final novelBatchReadingProgressProvider = FutureProvider.autoDispose.family<Map<int, ReadingProgress>, NovelIdBatch>((ref, batch) async {
  final account = AppSettings.accounts.activeId;
  if (account == null || batch.ids.isEmpty) return const {};
  try {
    return await historyRepository.readingProgressOf(account, batch.ids);
  } catch (_) {
    return const {};
  }
});
