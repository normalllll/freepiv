import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:frost_data/frost_data.dart';

/// The current account's browsing history, the last viewed first, as a list
/// with one page: its novels, or its illustrations, manga and animations.
class HistorySource extends FrostListSource<HistoryEntry> {
  HistorySource({required this.novels});

  final bool novels;

  /// Where the account stopped reading the listed novels, by novel ID.
  Map<int, ReadingProgress> progress = const {};

  @override
  Future<List<HistoryEntry>> initList() async {
    final account = AppSettings.accounts.activeId;
    if (account == null) return const [];
    final entries = await historyRepository.list(account, novels: novels);
    progress = novels ? await historyRepository.readingProgressOf(account, [for (final entry in entries) entry.workId]) : const {};
    return entries;
  }

  @override
  Future<List<HistoryEntry>> nextList() async => const [];

  @override
  bool hasMoreByResult(List<HistoryEntry> list) => false;

  /// Deletes [entry] from the history and from the list, the others staying
  /// where they are.
  Future<void> remove(HistoryEntry entry) async {
    final account = AppSettings.accounts.activeId;
    if (account == null) return;
    await historyRepository.remove(account, entry.kind, entry.workId);
    if (entry.kind.isNovel) progress = {...progress}..remove(entry.workId);
    removeWhere((item) => item.kind == entry.kind && item.workId == entry.workId);
  }
}

/// The history list of novels for `true`, otherwise of the other works. A new
/// one is read whenever the history page opens.
final historySourceProvider = Provider.autoDispose.family<HistorySource, bool>((ref, novels) {
  final source = HistorySource(novels: novels);
  ref.onDispose(source.dispose);
  return source;
});
