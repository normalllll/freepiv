import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/features/downloads/presentation/content_image_entries.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'package:freepiv/ui/compositions/fanbox_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import 'logic.dart';

/// What FANBOX's pages share: where its links go, what its failures say,
/// how its images are fetched, and how posts, creators and files download.

void openFanboxPost(BuildContext context, String id, {FanboxPost? summary}) => unawaited(GoRouter.of(context).push(AppLocations.fanboxPost(id), extra: summary));

void openFanboxCreator(BuildContext context, String id, {FanboxCreator? summary, bool plans = false}) =>
    unawaited(GoRouter.of(context).push(AppLocations.fanboxCreator(id, plans: plans), extra: summary));

void openFanboxTag(BuildContext context, String tag, {String creatorId = ''}) =>
    unawaited(GoRouter.of(context).push(AppLocations.fanboxTag(tag, creatorId: creatorId, section: FanboxSection.tag.name)));

/// Opens a web address outside the app; says so when nothing could.
Future<void> openFanboxLink(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || !['https', 'http'].contains(uri.scheme) || uri.host.isEmpty || uri.userInfo.isNotEmpty) return;
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Reported below as for any address nothing opened.
  }
  if (!opened && context.mounted) FrostToast.error(context.t.fanbox.unsupportedUrl);
}

/// A post's address on FANBOX.
String fanboxPostUrl(String creatorId, String postId) => 'https://www.fanbox.cc/@${Uri.encodeComponent(creatorId)}/posts/${Uri.encodeComponent(postId)}';

/// A creator's address on FANBOX.
String fanboxCreatorUrl(String creatorId) => 'https://www.fanbox.cc/@${Uri.encodeComponent(creatorId)}';

/// What a failed FANBOX request says.
String fanboxError(BuildContext context, Object error) {
  if (error is FanboxSignedOut) return context.t.fanbox.sessionExpired;
  if (error is PixivError) {
    return switch (error.status) {
      401 => context.t.fanbox.sessionExpired,
      403 => context.t.fanbox.accessDenied,
      429 => context.t.fanbox.rateLimited,
      _ => context.t.fanbox.requestFailed,
    };
  }
  return context.t.fanbox.requestFailed;
}

/// The post as the downloads list shows the files saved from it; a post
/// without a cover shows its first image.
FanboxPostSource fanboxPostDownloadSource(FanboxPost post) => FanboxPostSource(
  postId: post.id,
  title: post.title,
  subtitle: post.user.name.isEmpty ? post.creatorId : post.user.name,
  thumbnailUrl: post.coverUrl ?? post.blocks.whereType<FanboxBlock_Image>().firstOrNull?.image.thumbnailUrl,
);

/// The creator as the downloads list shows the files saved from their page.
FanboxCreatorSource fanboxCreatorDownloadSource(FanboxCreator creator) => FanboxCreatorSource(
  creatorId: creator.creatorId,
  title: creator.user.name.isEmpty ? creator.creatorId : creator.user.name,
  thumbnailUrl: creator.coverUrl ?? creator.user.iconUrl,
);

/// FANBOX serves images to its own pages, and its own hosts need the session.
Map<String, String> fanboxImageHeaders(Uri uri, String? session) => {
  'Referer': 'https://www.fanbox.cc/',
  if (session != null && (uri.host == 'fanbox.cc' || uri.host.endsWith('.fanbox.cc'))) 'Cookie': 'FANBOXSESSID=$session',
};

/// Queues every image and file of [post]. [origin] is where the download was
/// asked for; the post's cover flies from there to the download badge.
Future<void> downloadFanboxPost(WidgetRef ref, FanboxPost post, {Rect? origin}) async {
  final source = fanboxPostDownloadSource(post);
  await _downloadBatch(origin: origin, artworkUrl: source.thumbnailUrl, queue: () => ref.read(fanboxDownloadsProvider.notifier).downloadPost(post, source: source));
}

/// Collects and queues every post of [creator] the session can read.
Future<void> downloadFanboxCreator(WidgetRef ref, FanboxCreator creator, {Rect? origin}) async {
  final source = fanboxCreatorDownloadSource(creator);
  FrostToast.info(t.fanbox.downloadPreparing);
  await _downloadBatch(origin: origin, artworkUrl: source.thumbnailUrl, queue: () => ref.read(fanboxDownloadsProvider.notifier).downloadCreator(source));
}

Future<void> _downloadBatch({required Rect? origin, required String? artworkUrl, required Future<int> Function() queue}) async {
  try {
    await downloadManager.ensureReadyForDownloads();
    DownloadFlight.launch(origin: origin, artwork: artworkUrl == null ? null : AppFanboxImage(url: artworkUrl, radius: 0));
    final queued = await queue();
    FrostToast.info(queued > 0 ? t.fanbox.downloadQueued(count: queued) : t.fanbox.downloadNothingNew);
  } catch (error) {
    toastErrorWithCause(t.illust.toast.downloadFailed, error);
  }
}

/// Downloads one FANBOX image or attachment, filed under [source], and
/// reports the saved file. An image flies from [origin] to the download badge.
Future<void> downloadFanboxFile(WidgetRef ref, {required String url, required String filename, required DownloadSource source, bool image = true, Rect? origin}) async {
  final downloads = ref.read(fanboxDownloadsProvider.notifier);
  try {
    await downloadManager.ensureReadyForDownloads();
    DownloadFlight.launch(origin: origin, artwork: image ? AppFanboxImage(url: url, radius: 0) : null);
    final file = await downloads.downloadFile(url: url, filename: filename, source: source, image: image);
    FrostToast.success(t.illust.toast.downloadComplete(name: p.basename(file.path)));
  } on DownloadAlreadyQueued {
    FrostToast.info(t.illust.toast.alreadyDownloading);
  } catch (error) {
    toastErrorWithCause(t.illust.toast.downloadFailed, error);
  }
}

/// Opens FANBOX images in the original image viewer at [index], fetched
/// with the session and never cached on disk; the viewer offers to open the
/// shown image on the web.
void openFanboxImages(BuildContext context, WidgetRef ref, {required List<String> urls, int index = 0, required String title}) {
  final session = ref.read(fanboxSessionProvider).value;
  unawaited(
    GoRouter.of(context).push(
      AppRoute.originalImageViewer.path,
      extra: OriginalImageViewerArgs(
        title: title,
        source: DownloadSourceScope.of(context),
        initialIndex: index,
        pages: [
          for (final url in urls)
            OriginalImagePage(
              url: url,
              previewUrl: url,
              downloadOrigin: DownloadOrigin.ofImageUrl(Uri.parse(url)),
              headers: fanboxImageHeaders(Uri.parse(url), session),
              accountKey: session ?? '',
            ),
        ],
        openOriginal: OriginalImageOpenAction(label: context.t.fanbox.openOriginal, onOpen: (page) => unawaited(openFanboxLink(context, page.url))),
      ),
    ),
  );
}

/// The menu of a FANBOX image: download it into the FANBOX folder as
/// [filename] (its own file name by default), filed under the page's source,
/// and copy it on desktop. The session goes with the request, never into the
/// download record.
List<FrostMenuEntry> fanboxImageMenu(BuildContext context, WidgetRef ref, {required String url, String? filename}) {
  final t = context.t;
  final uri = Uri.parse(url);
  final source = DownloadSourceScope.of(context);
  final headers = fanboxImageHeaders(uri, ref.read(fanboxSessionProvider).value);
  return [
    FrostMenuAction(
      t.illust.contextMenu.download,
      leading: const FrostGlyph.icon(PivIcons.download),
      onSelected: () => unawaited(
        downloadFanboxFile(ref, url: url, filename: filename ?? uri.pathSegments.last, source: source, origin: DownloadFlight.originOf(context)),
      ),
    ),
    if (isDesktopPlatform)
      FrostMenuAction(
        t.illust.contextMenu.copyImage,
        leading: const FrostGlyph.icon(PivIcons.copy),
        onSelected: () => unawaited(copyContentImage(ref.read(rustMediaTransportProvider), url, headers)),
      ),
  ];
}
