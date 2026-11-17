import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/block/block_actions.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/bookmark_options.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:url_launcher/url_launcher.dart';

Uri novelWebUrl(int novelId) => Uri.parse('https://www.pixiv.net/novel/show.php?id=$novelId');

Future<void> copyNovelLink(int novelId) async {
  try {
    await copyTextToClipboard(novelWebUrl(novelId).toString());
    FrostToast.copied(t.illust.toast.linkCopied);
  } catch (error) {
    toastErrorWithCause(t.illust.toast.linkCopyFailed, error);
  }
}

Future<void> openNovelOnPixiv(int novelId) async {
  try {
    if (!await launchUrl(novelWebUrl(novelId), mode: LaunchMode.externalApplication)) {
      throw StateError('No external application accepted the novel URL.');
    }
  } catch (error) {
    toastErrorWithCause(t.illust.toast.openFailed, error);
  }
}

/// The More menu of a novel's page: copy the link, open it on Pixiv, and
/// blocking its author.
List<FrostMenuEntry> novelMoreMenu(BuildContext context, Novel novel) {
  final t = context.t;
  return [
    FrostMenuAction(t.illust.contextMenu.copyLink, leading: const FrostGlyph.icon(PivIcons.link), onSelected: () => unawaited(copyNovelLink(novel.id))),
    FrostMenuAction(
      t.illust.contextMenu.openOriginal,
      leading: const FrostGlyph.icon(PivIcons.externalLink),
      onSelected: () => unawaited(openNovelOnPixiv(novel.id)),
    ),
    ...blockUserMenuEntries(context, novel.user),
  ];
}

/// The menu of the bookmark button: its options, with the bookmark button's own
/// toggle left to the button.
List<FrostMenuEntry> novelBookmarkMenu(BuildContext context, Novel novel) =>
    bookmarkOptionsMenuEntries(context, workId: novel.id, initiallyBookmarked: novel.isBookmarked, novel: true);
