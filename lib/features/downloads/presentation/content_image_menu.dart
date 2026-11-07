
import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
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
      artwork: AppPixivImage(url: url, headers: headers),
    );
    final file = await downloadManager.download(
      origin: DownloadOrigin.ofImageUrl(uri),
      source: source,
      url: uri,
      networkOptions: DownloadNetworkOptions(headers: headers),
      thumbnailUrl: url,
      title: title,
    );
    FrostToast.success(t.illust.toast.downloadComplete(name: p.basename(file.path)));
  } catch (error) {
    toastErrorWithCause(t.illust.toast.downloadFailed, error);
  }
}

