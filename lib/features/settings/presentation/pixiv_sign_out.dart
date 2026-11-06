import 'package:flutter/widgets.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// Signs out of Pixiv after the user confirms and opens the login page;
/// returns whether it signed out. [signOut] stands in for the account change
/// in tests.
Future<bool> confirmPixivSignOut(BuildContext context, {VoidCallback? signOut}) async {
  final t = context.t.signOut;
  final confirmed = await showFrostConfirm(context: context, title: t.title, message: t.message, confirmLabel: t.confirm);
  if (!confirmed || !context.mounted) return false;
  (signOut ?? () => setPixivAccount(null))();
  context.go(AppRoute.login.path);
  return true;
}
