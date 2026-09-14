import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
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
              request: MediaRequest(
                url: url!,
                allowDiskCache: false,
                accountKey: session ?? '',
                headers: {
                  'Referer': 'https://www.fanbox.cc/',
                  if (session != null && (uri.host == 'fanbox.cc' || uri.host.endsWith('.fanbox.cc'))) 'Cookie': 'FANBOXSESSID=$session',
                },
              ),
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
        Text(fanboxError(context, error)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(onPressed: retry, child: Text(context.t.fanbox.retry)),
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
      ],
    ),
  );
}
