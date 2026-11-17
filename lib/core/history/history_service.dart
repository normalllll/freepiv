import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

HistoryRepository? _repository;

/// The device's browsing history; opened on first use. The sample entry and
/// tests replace it with one in memory.
HistoryRepository get historyRepository => _repository ??= HistoryRepository.open();

set historyRepository(HistoryRepository value) => _repository = value;

/// Notes that the current account viewed [illust], unless recording is off or
/// nobody is signed in. A history that cannot be kept never fails the page
/// that asked.
Future<void> recordIllustView(Illust illust) => _record((at) => HistoryEntry.ofIllust(illust, at));

/// Notes that the current account viewed [novel], as [recordIllustView] does.
Future<void> recordNovelView(Novel novel) => _record((at) => HistoryEntry.ofNovel(novel, at));

/// Where the current account stopped reading [novelId]; null when nobody is
/// signed in or it cannot be read.
Future<ReadingProgress?> loadReadingProgress(int novelId) async {
  final account = AppSettings.accounts.activeId;
  if (account == null) return null;
  try {
    return await historyRepository.readingProgress(account, novelId);
  } catch (_) {
    return null;
  }
}

/// Keeps where the current account stopped reading [novelId], whether or not
/// the history is being recorded. Signed out or unwritable, it does nothing.
Future<void> saveReadingProgress(int novelId, {required int offset, required int totalLength}) async {
  final account = AppSettings.accounts.activeId;
  if (account == null) return;
  try {
    await historyRepository.saveReadingProgress(
      account,
      novelId,
      ReadingProgress(offset: offset, totalLength: totalLength, updatedAt: DateTime.now()),
    );
  } catch (_) {
    // Losing a reading position is not worth an error.
  }
}

Future<void> _record(HistoryEntry Function(DateTime at) entry) async {
  final account = AppSettings.accounts.activeId;
  if (account == null || !AppSettings.recordHistory) return;
  try {
    await historyRepository.record(account, entry(DateTime.now()), limit: AppSettings.historyLimit);
  } catch (_) {
    // The history is a convenience; failing to keep it is not worth an error.
  }
}
