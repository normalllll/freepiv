import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

/// Clears the current account's browsing history after the user confirms;
/// returns whether it did. Other accounts keep theirs. [onCleared] runs once
/// it is cleared, for a page showing the history to follow.
Future<bool> confirmClearHistory(BuildContext context, {VoidCallback? onCleared}) async {
  final t = context.t.history;
  final account = AppSettings.accounts.activeId;
  final confirmed = await showFrostConfirm(context: context, title: t.clear, message: t.clearMessage, confirmLabel: t.clearConfirm, destructive: true);
  if (!confirmed || account == null) return false;
  await historyRepository.clear(account);
  onCleared?.call();
  return true;
}

/// Sets the history limit to [limit]. Lowering it below what some account has
/// kept asks first, naming how many of the oldest entries (over every
/// account) go; confirming applies the limit and deletes them at once, and
/// cancelling keeps the old limit.
Future<bool> changeHistoryLimit(BuildContext context, WidgetRef ref, HistoryLimit limit) async {
  final t = context.t.history;
  final notifier = ref.read(historyLimitProvider.notifier);
  final beyond = await historyRepository.countBeyond(limit);
  if (beyond > 0) {
    if (!context.mounted) return false;
    final confirmed = await showFrostConfirm(
      context: context,
      title: t.lowerLimitTitle,
      message: t.lowerLimitMessage(count: beyond),
      confirmLabel: t.lowerLimitConfirm,
      destructive: true,
    );
    if (!confirmed) return false;
    await historyRepository.pruneAll(limit);
  }
  notifier.set(limit);
  return true;
}
