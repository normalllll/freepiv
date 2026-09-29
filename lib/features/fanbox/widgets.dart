import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/features/downloads/presentation/content_image_menu.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'logic.dart';

Future<void> openFanboxLink(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || !['https', 'http'].contains(uri.scheme) || uri.host.isEmpty || uri.userInfo.isNotEmpty) return;
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.fanbox.unsupportedUrl)));
}

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

String fanboxDate(BuildContext context, String date) {
  final parsed = DateTime.tryParse(date)?.toLocal();
  return parsed == null ? date : MaterialLocalizations.of(context).formatMediumDate(parsed);
}

String fanboxFee(BuildContext context, int fee) => MaterialLocalizations.of(context).formatDecimal(fee);

/// FANBOX serves images to its own pages, and its own hosts need the session.
Map<String, String> fanboxImageHeaders(Uri uri, String? session) => {
  'Referer': 'https://www.fanbox.cc/',
  if (session != null && (uri.host == 'fanbox.cc' || uri.host.endsWith('.fanbox.cc'))) 'Cookie': 'FANBOXSESSID=$session',
};

class FanboxImageView extends ConsumerWidget {
  const FanboxImageView(this.url, {this.height, this.fit = BoxFit.cover, super.key});
  final String? url;
  final double? height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = Uri.tryParse(url ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Icon(Icons.image_outlined)),
      );
    }
    return ref
        .watch(fanboxSessionProvider)
        .when(
          loading: () => SizedBox(height: height ?? 100, child: const ImageLoadingSkeleton()),
          error: (_, _) => SizedBox(
            height: height ?? 100,
            child: Center(
              child: IconButton(
                tooltip: context.t.fanbox.retry,
                onPressed: () => ref.invalidate(fanboxSessionProvider),
                icon: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          data: (session) => ExtendedImage(
            image: RustExtendedNetworkImageProvider(
              request: MediaRequest(url: url!, allowDiskCache: false, accountKey: session ?? '', headers: fanboxImageHeaders(uri, session)),
              mediaStream: ref.watch(rustMediaTransportProvider).stream,
            ),
            height: height,
            width: double.infinity,
            fit: fit,
            loadStateChanged: (state) => switch (state.extendedImageLoadState) {
              LoadState.loading => SizedBox(height: height ?? 100, child: const ImageLoadingSkeleton()),
              LoadState.failed => SizedBox(
                height: height ?? 100,
                child: Center(
                  child: IconButton(tooltip: context.t.fanbox.retry, onPressed: state.reLoadImage, icon: const Icon(Icons.broken_image_outlined)),
                ),
              ),
              LoadState.completed => null,
            },
          ),
        );
  }
}

class FanboxErrorView extends ConsumerWidget {
  const FanboxErrorView(this.error, {required this.retry, super.key});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(fanboxError(context, error), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            FilledButton(onPressed: retry, child: Text(context.t.fanbox.retry)),
            if (error is FanboxSignedOut || error is PixivError && (error as PixivError).status == 401)
              TextButton(
                onPressed: () async {
                  await ref.read(fanboxOperationProvider('account').notifier).run(() => ref.read(fanboxSessionProvider.notifier).signOut());
                  if (context.mounted) context.go('/fanbox');
                },
                child: Text(context.t.fanbox.login),
              ),
          ],
        ),
        if (error is! FanboxSignedOut)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ErrorDetails(details: pixivErrorDetails(error)),
            ),
          ),
      ],
    ),
  );
}

/// A FANBOX image with the artwork image menu (download, copy on desktop).
/// It downloads through FANBOX's own downloads, which carry the session
/// without storing it, into the FANBOX folder as [filename].
class FanboxImageMenu extends ConsumerWidget {
  const FanboxImageMenu({required this.url, required this.child, this.filename, super.key});

  final String url;

  /// Defaults to the image's own file name.
  final String? filename;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(fanboxSessionProvider).value;
    final uri = Uri.parse(url);
    return ContentImageMenuRegion(
      actions: ContentImageActions(
        url: url,
        headers: fanboxImageHeaders(uri, session),
        download: (origin) async {
          final downloads = ref.read(fanboxDownloadsProvider.notifier);
          final directory = await fanboxDownloadDirectory();
          DownloadFlight.launch(origin: origin);
          await downloads.downloadPosts(directory: directory, media: [(url: url, filename: filename ?? uri.pathSegments.last)]);
        },
      ),
      child: child,
    );
  }
}
