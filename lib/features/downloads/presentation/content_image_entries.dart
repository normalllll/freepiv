import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/features/downloads/presentation/content_image_menu.dart' show ContentImageActions;
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';

/// The menu of an image inside content (novel covers and illustrations,
/// FANBOX and Pixivision images): download it under the page's source, and
/// copy it on desktop.
List<FrostMenuEntry> contentImageMenu(BuildContext context, RustMediaTransport transport, {required String url, String? title}) {
  final t = context.t;
  final actions = ContentImageActions.pixivHosted(url: url, headers: pixivRefererHeaders, title: title);
  final source = DownloadSourceScope.of(context);
  return [
    FrostMenuAction(
      t.illust.contextMenu.download,
      leading: const FrostGlyph.icon(PivIcons.download),
      onSelected: () => unawaited(actions.download(source, DownloadFlight.originOf(context) ?? Rect.zero)),
    ),
    if (isDesktopPlatform)
      FrostMenuAction(t.illust.contextMenu.copyImage, leading: const FrostGlyph.icon(PivIcons.copy), onSelected: () => unawaited(_copy(transport, url))),
  ];
}

Future<void> _copy(RustMediaTransport transport, String url) async {
  final label = t.illust.imageLabels.image;
  try {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in transport.stream(url, pixivRefererHeaders)) {
      bytes.add(chunk.bytes);
    }
    await copyImageBytesToClipboard(bytes.takeBytes(), mimeType: imageMimeTypeFromUrl(url));
    FrostToast.copied(t.illust.toast.copied(label: label));
  } catch (error) {
    toastErrorWithCause(t.illust.toast.copyFailed(label: label), error);
  }
}
