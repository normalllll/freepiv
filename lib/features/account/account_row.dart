import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/services/pixiv_accounts.dart';
import 'package:freepiv/features/account/account_actions.dart';
import 'package:freepiv/features/settings/presentation/pixiv_sign_out.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';

/// The avatar of a stored account, at the size of the other user rows.
FrostAvatar accountAvatar(WidgetRef ref, PixivAccountEntry account) {
  final user = account.session.user;
  final url = user.profileImageUrls.px50X50;
  return FrostAvatar.person(name: user.name, colorKey: user.id, image: url.isEmpty ? null : pixivImageProvider(ref, url));
}

/// One stored Pixiv account, in Settings and in the account switcher. The
/// current one is marked with a check; another that can be used switches when
/// tapped; one that needs signing in opens the add page. [beforeAction] runs
/// first, to close what the row is in. [withSignOut] adds the menu that signs
/// the account out.
class AccountRow extends ConsumerWidget {
  const AccountRow({required this.account, required this.active, this.beforeAction, this.withSignOut = false, super.key});

  final PixivAccountEntry account;
  final bool active;
  final VoidCallback? beforeAction;
  final bool withSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.accounts;
    final user = account.session.user;
    void act(VoidCallback action) {
      beforeAction?.call();
      action();
    }

    final row = FrostListRow(
      leading: FrostLeading.custom(accountAvatar(ref, account)),
      title: user.name,
      contentTitle: true,
      subtitle: FrostRowSubtitle(account.usable ? '@${user.account}' : '@${user.account} · ${t.needsSignIn}'),
      onPressed: active
          ? null
          : account.usable
          ? () => act(() => unawaited(switchToAccount(context, account.id)))
          : () => act(() => openAddAccount(context)),
      trailing: active || withSignOut
          ? Row(
              mainAxisSize: MainAxisSize.min,
              spacing: FrostGap.related,
              children: [
                if (active)
                  Semantics(
                    label: t.current,
                    child: FrostIcon(FrostIconSet.of(context).check, color: FrostThemeTokens.of(context).selectionInk),
                  ),
                if (withSignOut)
                  FrostMenuAnchor(
                    entries: [
                      FrostMenuAction(t.signOutOne, destructive: true, onSelected: () => unawaited(confirmPixivSignOut(context, accountId: account.id))),
                    ],
                    builder: (context, focusNode, toggle) =>
                        FrostButton.icon(icon: FrostScope.configOf(context).icons.more, label: FrostScope.labelsOf(context).more, onPressed: toggle),
                  ),
              ],
            )
          : null,
    );
    return active || !account.usable
        ? row
        : FrostTooltip(
            message: t.switchTo(name: user.name),
            child: row,
          );
  }
}
