import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_accounts.dart';
import 'package:freepiv/features/account/account_actions.dart';
import 'package:freepiv/features/account/account_row.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// "Switch account": [builder] makes the trigger, which opens a popover (a
/// sheet on a narrow screen) listing the stored accounts, adding an account
/// and the account settings.
class AccountSwitchPopover extends StatelessWidget {
  const AccountSwitchPopover({required this.builder, super.key});

  final Widget Function(BuildContext context, FocusNode focusNode, VoidCallback toggle) builder;

  @override
  Widget build(BuildContext context) {
    final t = context.t.accounts;
    return FrostPopover(
      title: t.switchAccount,
      builder: builder,
      contentBuilder: (context, close) => ValueListenableBuilder<PixivAccountBook>(
        valueListenable: AppSettings.accountsListenable,
        builder: (context, book, _) => FrostGroupedSection(
          children: [
            for (final account in book.entries) AccountRow(account: account, active: account.id == book.activeId, beforeAction: close),
            FrostListRow(
              title: t.add,
              accessory: FrostRowAccessory.chevron,
              onPressed: () {
                close();
                openAddAccount(context);
              },
            ),
            FrostListRow(
              title: t.manage,
              accessory: FrostRowAccessory.chevron,
              onPressed: () {
                close();
                unawaited(GoRouter.of(context).push(AppLocations.settings(account: true)));
              },
            ),
          ],
        ),
      ),
    );
  }
}
