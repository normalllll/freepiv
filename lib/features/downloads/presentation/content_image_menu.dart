import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:path/path.dart' as p;

/// An image shown inside other content (a FANBOX post, a Pixivision article,
/// a novel), with what its menu needs: the request that fetches it, for
/// copying, and how it downloads.
class ContentImageActions {
  const ContentImageActions({required this.url, required this.headers, required this.download});

  /// A Pixiv-hosted image that downloads through the download manager: as
  /// its work's page when [url] is a work page image, otherwise as a
  /// content image. [headers] are stored with the task for retries, so
  /// they must not carry credentials.
  factory ContentImageActions.pixivHosted({required String url, required Map<String, String> headers, String? title}) {
    return ContentImageActions(
      url: url,
      headers: headers,
      download: (source, origin) => _downloadThroughManager(url: url, headers: headers, title: title, source: source, flightOrigin: origin),
    );
  }

  final String url;
  final Map<String, String> headers;

  /// Starts the download, filed under the page's source (see
  /// DownloadSourceScope); origin is where it was asked for, for the flight
  /// to the download badge.
  final Future<void> Function(DownloadSource source, Rect origin) download;
}

Future<void> _downloadThroughManager({
  required String url,
  required Map<String, String> headers,
  required String? title,
  required DownloadSource source,
  required Rect flightOrigin,
}) async {
  final uri = Uri.parse(url);
  try {
    await downloadManager.ensureReadyForDownloads();
    DownloadFlight.launch(
      origin: flightOrigin,
      artwork: PixivImage(url: url, headers: headers),
    );
    final file = await downloadManager.download(
      origin: DownloadOrigin.ofImageUrl(uri),
      source: source,
      url: uri,
      networkOptions: DownloadNetworkOptions(headers: headers),
      thumbnailUrl: url,
      title: title,
    );
    AppToast.success(t.illust.toast.downloadComplete(name: p.basename(file.path)));
  } catch (error) {
    AppToast.errorWithCause(t.illust.toast.downloadFailed, error);
  }
}

/// Right click (pointer) or long press (touch) on [child] opens the same
/// image menu as an artwork page: download, and on desktop copy image.
class ContentImageMenuRegion extends ConsumerWidget {
  const ContentImageMenuRegion({required this.actions, required this.child, this.onTap, super.key});

  final ContentImageActions actions;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(Offset position) => unawaited(_showMenu(context, ref.read(rustMediaTransportProvider), position));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onSecondaryTapDown: (details) => open(details.globalPosition),
      onLongPressStart: (details) => open(details.globalPosition),
      child: child,
    );
  }

  Future<void> _showMenu(BuildContext context, RustMediaTransport transport, Offset position) async {
    final overlay = Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final local = overlay.globalToLocal(position);
    final anchor = Offset(local.dx.clamp(8.0, math.max(8.0, overlay.size.width - 8)), local.dy.clamp(8.0, math.max(8.0, overlay.size.height - 8)));
    final menu = context.t.illust.contextMenu;
    final source = DownloadSourceScope.of(context);
    final action = await showMenu<_ContentImageAction>(
      context: context,
      clipBehavior: Clip.antiAlias,
      position: RelativeRect.fromRect(Rect.fromPoints(anchor, anchor), Offset.zero & overlay.size),
      items: [
        PopupMenuItem(
          value: _ContentImageAction.download,
          child: ListTile(leading: const Icon(Icons.download_outlined), title: Text(menu.download), contentPadding: EdgeInsets.zero),
        ),
        if (isDesktopPlatform)
          PopupMenuItem(
            value: _ContentImageAction.copy,
            child: ListTile(leading: const Icon(Icons.content_copy_outlined), title: Text(menu.copyImage), contentPadding: EdgeInsets.zero),
          ),
      ],
    );
    switch (action) {
      case _ContentImageAction.download:
        unawaited(actions.download(source, Rect.fromCenter(center: position, width: 48, height: 48)));
      case _ContentImageAction.copy:
        unawaited(_copy(transport));
      case null:
        break;
    }
  }

  Future<void> _copy(RustMediaTransport transport) async {
    final label = t.illust.imageLabels.image;
    try {
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in transport.stream(actions.url, actions.headers)) {
        bytes.add(chunk.bytes);
      }
      await copyImageBytesToClipboard(bytes.takeBytes(), mimeType: imageMimeTypeFromUrl(actions.url));
      unawaited(AppToast.copied(t.illust.toast.copied(label: label)));
    } catch (error) {
      AppToast.errorWithCause(t.illust.toast.copyFailed(label: label), error);
    }
  }
}

enum _ContentImageAction { download, copy }
