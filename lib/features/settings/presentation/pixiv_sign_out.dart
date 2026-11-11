import 'package:flutter/widgets.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/features/account/account_actions.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// Signs out of a Pixiv account after the user confirms; returns whether it
/// signed out. That is the current account unless [accountId] names another
/// stored one. Signing out of the current account switches to the most
/// recently used other account that can be used and opens the home page; with
/// none left it opens the login page. [signOut] stands in for the account
/// change in tests.
Future<bool> confirmPixivSignOut(BuildContext context, {String? accountId, VoidCallback? signOut}) async {
  final book = AppSettings.accounts;
  final target = accountId == null ? book.active : book.entry(accountId);
  final other = target != null && target.id != book.activeId;
  final labels = context.t;
  final confirmed = await showFrostConfirm(
    context: context,
    title: other ? labels.accounts.signOutTitle(name: target.session.user.name) : labels.signOut.title,
    message: other ? labels.accounts.signOutMessage : labels.signOut.message,
    confirmLabel: labels.signOut.confirm,
  );
  if (!confirmed || !context.mounted) return false;
  final router = GoRouter.of(context);
  if (signOut != null) {
    signOut();
    router.go(AppRoute.login.path);
    return true;
  }
  if (target == null) return true;
  await removePixivAccount(target.id);
  if (other) return true;
  // The scope starts over with a router that opens the home page, or the login
  // page when no account is left.
  if (pixivAccountNotifier.value case final account?) announceSwitched(account.user.name);
  return true;
}
