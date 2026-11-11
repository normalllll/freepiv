import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/icons.g.dart';
import 'package:freepiv/core/block/block_list.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:frost_ui/frost_ui.dart';

const _blockIcon = FrostGlyph.icon(FrostIconData.glyph(FreepivIcons.eyeOff));

/// Whether [user] is the account that is signed in.
bool isActiveAccountUser(User user) => int.tryParse(pixivAccountNotifier.value?.user.id ?? '') == user.id;

/// The menu entry that blocks the author of a work, after asking: it names
/// them. Nothing for your own works.
List<FrostMenuEntry> blockUserMenuEntries(BuildContext context, User user) => [
  if (!isActiveAccountUser(user))
    FrostMenuAction(
      context.t.block.blockUser,
      leading: _blockIcon,
      onSelected: () {
        if (context.mounted) unawaited(confirmBlockUser(context, user));
      },
    ),
];

/// The menu entry that blocks [tag] at once; the toast offers the undo.
FrostMenuAction blockTagMenuEntry(BuildContext context, String tag) =>
    FrostMenuAction(context.t.block.blockTag, leading: _blockIcon, onSelected: () => blockTag(tag));

/// The menu entry on an author's page: unblocks [user] where they are blocked,
/// else blocks them after asking.
List<FrostMenuEntry> blockUserToggleMenuEntries(BuildContext context, User user) {
  if (!AppSettings.blockList.blocksUser(user.id)) return blockUserMenuEntries(context, user);
  return [FrostMenuAction(context.t.block.unblockUser, leading: _blockIcon, onSelected: () => unblockUser(user))];
}

/// Asks whether to block [user], naming them; blocks them if confirmed.
/// Returns whether it did.
Future<bool> confirmBlockUser(BuildContext context, User user) async {
  final labels = context.t.block;
  final confirmed = await showFrostConfirm(
    context: context,
    title: labels.confirmTitle(name: user.name),
    message: labels.confirmMessage(name: user.name),
    confirmLabel: labels.confirm,
    destructive: true,
  );
  if (confirmed) blockUser(user);
  return confirmed;
}

/// Blocks [user] and says so, with an undo that takes just that entry out
/// again. Where they were blocked already nothing changes, and the notice has
/// no undo.
void blockUser(User user) {
  final name = t.block.blocked(name: user.name);
  if (AppSettings.blockList.blocksUser(user.id)) return FrostToast.success(name);
  AppSettings.blockList = AppSettings.blockList.withUser(BlockedUser(id: user.id, name: user.name));
  FrostToast.success(name, actionLabel: t.block.undo, onAction: () => AppSettings.blockList = AppSettings.blockList.withoutUser(user.id));
}

/// Blocks [tag] and says so, with an undo as [blockUser] has.
void blockTag(String tag) {
  final name = t.block.blocked(name: '#${BlockList.normalizeTag(tag)}');
  if (AppSettings.blockList.blocksTag(BlockList.normalizeTag(tag))) return FrostToast.success(name);
  AppSettings.blockList = AppSettings.blockList.withTag(tag);
  FrostToast.success(name, actionLabel: t.block.undo, onAction: () => AppSettings.blockList = AppSettings.blockList.withoutTag(BlockList.normalizeTag(tag)));
}

void unblockUser(User user) {
  AppSettings.blockList = AppSettings.blockList.withoutUser(user.id);
  FrostToast.success(t.block.unblocked(name: user.name));
}
