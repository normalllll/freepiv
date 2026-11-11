import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/block/block_actions.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

/// The right-click / long-press menu of a work's tag: copy it, or block it.
List<FrostMenuEntry> workTagMenu(BuildContext context, String tag) => [
  FrostMenuAction(context.t.illustDetail.copyTag, leading: const FrostGlyph.icon(PivIcons.copy), onSelected: () => unawaited(_copyTag(tag))),
  blockTagMenuEntry(context, tag),
];

Future<void> _copyTag(String tag) async {
  final label = t.illust.tags.tag;
  try {
    await copyTextToClipboard(tag);
    FrostToast.copied(t.illust.toast.copiedValue(label: label, value: tag));
  } catch (error) {
    toastErrorWithCause(t.illust.toast.copyFailed(label: label), error);
  }
}
