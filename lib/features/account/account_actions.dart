import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// Switches to the stored account [id] and says how it went. On success the
/// pages above the home page are left for it, and the provider scope has
/// started over for the account (see AccountScope). An account that needs
/// signing in again opens the add page instead.
Future<void> switchToAccount(BuildContext context, String id) async {
  final target = AppSettings.accounts.entry(id);
  if (target == null || AppSettings.accounts.activeId == id) return;
  final router = GoRouter.of(context);
  if (!target.usable) {
    unawaited(router.push(AppRoute.accountsAdd.path));
    return;
  }
  final result = await switchPixivAccount(id);
  switch (result.outcome) {
    case PixivSwitchOutcome.switched:
      // The scope has started over with a router at the home page; the toast
      // waits for it to be mounted.
      announceSwitched(target.session.user.name);
    case PixivSwitchOutcome.needsSignIn || PixivSwitchOutcome.failed:
      toastErrorWithCause(t.accounts.switchFailed, result.error!);
    case PixivSwitchOutcome.unchanged:
      break;
  }
}

/// The sign-in page for another account, over the current page.
void openAddAccount(BuildContext context) => unawaited(GoRouter.of(context).push(AppRoute.accountsAdd.path));

/// Says "Switched to [name]" once the next frame, which mounts the new account
/// scope, has been built: a toast shown before it would go with the old one.
void announceSwitched(String name) {
  WidgetsBinding.instance.addPostFrameCallback((_) => FrostToast.success(t.accounts.switched(name: name)));
}
