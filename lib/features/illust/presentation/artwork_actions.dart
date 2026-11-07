import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/illust/logic/ugoira_playback.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/api/download.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

/// The work's page on pixiv.net.
Uri artworkWebUrl(int illustId) => Uri.parse('https://www.pixiv.net/artworks/$illustId');

/// The work as the downloads list shows the pages saved from it.
ArtworkSource artworkSourceOf(Illust illust) =>
    ArtworkSource(illustId: illust.id, title: illust.title, subtitle: illust.user.name, thumbnailUrl: illust.imageUrls.squareMedium);

/// One page of a work: what the stage shows and what a download saves.
@immutable
class ArtworkPageImage {
  const ArtworkPageImage({required this.viewUrl, required this.originalUrl, required this.previewUrl});

  final String viewUrl;
  final String originalUrl;

  /// The small image shown while [viewUrl] loads; for the first page, the
  /// very preview the cards show, already cached when opened from a list.
  final String previewUrl;
}

/// The work's pages at the viewing [quality].
List<ArtworkPageImage> artworkPages(Illust illust, ViewerImageQuality quality, PreviewImageQuality previewQuality) {
  final cardPreview = illustPreviewImageUrl(illust.imageUrls, previewQuality);
  if (illust.metaPages.isNotEmpty) {
    return [
      for (final (index, page) in illust.metaPages.indexed)
        ArtworkPageImage(
          viewUrl: illustViewerImageUrl(page.imageUrls, quality),
          originalUrl: illustViewerImageUrl(page.imageUrls, ViewerImageQuality.original),
          previewUrl: index == 0 ? cardPreview : illustImagePlaceholderUrl(page.imageUrls),
        ),
    ];
  }
  return [
    ArtworkPageImage(
      viewUrl: illustViewerImageUrl(illust.imageUrls, quality, originalImageUrl: illust.metaSinglePage.originalImageUrl),
      originalUrl: illustViewerImageUrl(illust.imageUrls, ViewerImageQuality.original, originalImageUrl: illust.metaSinglePage.originalImageUrl),
      previewUrl: cardPreview,
    ),
  ];
}

Future<void> copyArtworkLink(int illustId) async {
  try {
    await copyTextToClipboard(artworkWebUrl(illustId).toString());
    FrostToast.copied(t.illust.toast.linkCopied);
  } catch (error) {
    toastErrorWithCause(t.illust.toast.linkCopyFailed, error);
  }
}

Future<void> copyArtworkId(int illustId) async {
  try {
    await copyTextToClipboard('$illustId');
    FrostToast.copied(t.illust.toast.copiedValue(label: t.common.id, value: '$illustId'));
  } catch (error) {
    toastErrorWithCause(t.illust.toast.copyFailed(label: t.common.id), error);
  }
}

Future<void> openArtworkOnPixiv(int illustId) async {
  try {
    if (!await launchUrl(artworkWebUrl(illustId), mode: LaunchMode.externalApplication)) {
      throw StateError('No external application accepted the artwork URL.');
    }
  } catch (error) {
    toastErrorWithCause(t.illust.toast.openFailed, error);
  }
}

/// Whether [pageIndex] of the work is already queued or downloading.
Future<bool> isArtworkPageDownloading(int illustId, int pageIndex) async {
  final tasks = await downloadManager.listTasks(illustId: illustId);
  return tasks.any(
    (task) =>
        task.origin == ArtworkPage(illustId: illustId, pageIndex: pageIndex) &&
        (task.status == DownloadStatus.queued ||
            task.status == DownloadStatus.running ||
            task.status == DownloadStatus.paused ||
            task.saveState == SaveState.pending ||
            task.saveState == SaveState.saving),
  );
}

/// Downloads one page; [loaded] are the bytes already shown at original
/// quality, saved instead of fetched again. A copy of the page flies from
/// [origin] to the download entry once the task is accepted.
Future<void> downloadArtworkPage(Illust illust, int pageIndex, ArtworkPageImage page, {Rect? origin, Uint8List? loaded}) async {
  try {
    if (await isArtworkPageDownloading(illust.id, pageIndex)) {
      FrostToast.info(t.illust.toast.alreadyDownloading);
      return;
    }
    await downloadManager.ensureReadyForDownloads();
    DownloadFlight.launch(
      origin: origin,
      artwork: AppPixivImage(url: page.previewUrl),
    );
    final source = artworkSourceOf(illust);
    final pageOrigin = ArtworkPage(illustId: illust.id, pageIndex: pageIndex);
    final url = Uri.parse(page.originalUrl);
    final file = loaded == null
        ? await downloadManager.download(
            origin: pageOrigin,
            source: source,
            url: url,
            networkOptions: const DownloadNetworkOptions(headers: pixivRefererHeaders),
            thumbnailUrl: page.previewUrl,
          )
        : await downloadManager.saveBytes(origin: pageOrigin, source: source, bytes: loaded, sourceUrl: url, thumbnailUrl: page.previewUrl);
    FrostToast.success(t.illust.toast.downloadComplete(name: p.basename(file.path)));
  } catch (error) {
    toastErrorWithCause(t.illust.toast.downloadFailed, error);
  }
}

/// Queues every page of the work.
Future<void> downloadArtworkPages(Illust illust, List<ArtworkPageImage> pages, {Rect? origin}) async {
  try {
    await downloadManager.ensureReadyForDownloads();
    DownloadFlight.launch(
      origin: origin,
      artwork: pages.isEmpty ? null : AppPixivImage(url: pages.first.previewUrl),
    );
    final source = artworkSourceOf(illust);
    final queued = await downloadManager.enqueue([
      for (final (index, page) in pages.indexed)
        DownloadJob.create(
          origin: ArtworkPage(illustId: illust.id, pageIndex: index),
          source: source,
          url: Uri.parse(page.originalUrl),
          networkOptions: const DownloadNetworkOptions(headers: pixivRefererHeaders),
          saveTarget: const SaveTarget.downloadsFolder(),
          thumbnailUrl: page.previewUrl,
        ),
    ]);
    FrostToast.info(t.illust.toast.downloadAllQueued(count: queued));
  } catch (error) {
    toastErrorWithCause(t.illust.toast.downloadFailed, error);
  }
}

/// Downloads a work from a card: its only page, or every page.
Future<void> downloadArtwork(Illust illust, {required ViewerImageQuality quality, required PreviewImageQuality previewQuality, Rect? origin}) {
  final pages = artworkPages(illust, quality, previewQuality);
  return pages.length == 1 ? downloadArtworkPage(illust, 0, pages.single, origin: origin) : downloadArtworkPages(illust, pages, origin: origin);
}

/// Downloads an animation as a GIF through the download manager: the task
/// shows while the frames are fetched and composed, and fails there too.
Future<void> downloadUgoiraGif(UgoiraPlayback playback, Illust illust, {required ArtworkPageImage page, Rect? origin}) {
  final previewUrl = page.previewUrl;
  return _downloadUgoiraGif(playback, illust, previewUrl: previewUrl, sourceUrl: page.originalUrl, origin: origin);
}

Future<void> _downloadUgoiraGif(UgoiraPlayback playback, Illust illust, {required String previewUrl, required String sourceUrl, Rect? origin}) async {
  try {
    await downloadManager.ensureReadyForDownloads();
    DownloadFlight.launch(
      origin: origin,
      artwork: AppPixivImage(url: previewUrl),
    );
    final filename = '${illust.id}.gif';
    final file = await downloadManager.saveGenerated(
      origin: ContentFile(generatedDownloadAddress('ugoira', filename)),
      source: artworkSourceOf(illust),
      sourceUrl: Uri.parse(sourceUrl),
      filename: filename,
      thumbnailUrl: previewUrl,
      generate: (onProgress) async {
        playback.exportProgress = onProgress;
        try {
          final bytes = await playback.gif();
          playback.saving();
          return bytes;
        } finally {
          playback.exportProgress = null;
        }
      },
    );
    playback.exported();
    FrostToast.success(t.illust.toast.downloadComplete(name: p.basename(file.path)));
  } catch (error) {
    playback.failed();
    toastErrorWithCause(t.illust.toast.downloadFailed, error);
  }
}

/// Copies an animation's GIF (desktop).
Future<void> copyUgoiraGif(UgoiraPlayback playback) async {
  const label = 'GIF';
  FrostToast.info(t.illust.toast.copying(label: label));
  try {
    final bytes = await playback.gif();
    await copyImageBytesToClipboard(bytes, mimeType: 'image/gif');
    playback.exported();
    FrostToast.copied(t.illust.toast.copied(label: label));
  } catch (error) {
    playback.failed();
    toastErrorWithCause(t.illust.toast.copyFailed(label: label), error);
  }
}

/// Copies a page's picture at viewing quality (desktop).
Future<void> copyArtworkImage(ArtworkPageImage page) async {
  final label = t.illust.imageLabels.image;
  FrostToast.info(t.illust.toast.copying(label: label));
  try {
    Uint8List? bytes;
    await for (final event in downloadToMemory(url: page.viewUrl, proxy: AppSettings.proxySettings.activeUrl)) {
      if (event case FrbDownloadBytesEvent_Done(bytes: final done)) bytes = done;
    }
    if (bytes == null) throw StateError('The image arrived without data.');
    await copyImageBytesToClipboard(bytes, mimeType: imageMimeTypeFromUrl(page.viewUrl));
    FrostToast.copied(t.illust.toast.copied(label: label));
  } catch (error) {
    toastErrorWithCause(t.illust.toast.copyFailed(label: label), error);
  }
}
