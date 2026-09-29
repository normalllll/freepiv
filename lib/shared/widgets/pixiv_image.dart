import 'package:freepiv/shared/widgets/app_click_surface.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';

/// Pixiv's image hosts serve only requests coming from pixiv.net.
const pixivImageHeaders = {'Referer': 'https://www.pixiv.net/'};

class PixivImage extends ConsumerWidget {
  const PixivImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.headers,
    this.cache = true,
    this.placeholder,
    this.errorBuilder,
    super.key,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Map<String, String>? headers;
  final bool cache;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transport = ref.watch(rustMediaTransportProvider);
    final image = ExtendedImage(
      image: RustExtendedNetworkImageProvider(
        request: MediaRequest(url: url, headers: headers ?? pixivImageHeaders, allowDiskCache: cache),
        mediaStream: transport.stream,
        mediaStreamCacheIdentity: transport.imageCacheIdentity,
      ),
      width: width,
      height: height,
      fit: fit,
      loadStateChanged: (state) {
        return switch (state.extendedImageLoadState) {
          LoadState.loading => placeholder?.call(context) ?? const _PixivImagePlaceholder(),
          LoadState.failed => errorBuilder?.call(context) ?? _PixivImageError(error: state.lastException, onRetry: state.reLoadImage),
          LoadState.completed =>
            state.wasSynchronouslyLoaded || MediaQuery.disableAnimationsOf(context)
                ? null
                : TweenAnimationBuilder<double>(
                    key: ValueKey(url),
                    tween: Tween(begin: 0, end: 1),
                    duration: AppMotion.duration(context, const Duration(milliseconds: 160)),
                    curve: Curves.easeOutCubic,
                    builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
                    child: state.completedWidget,
                  ),
        };
      },
    );

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class _PixivImagePlaceholder extends StatelessWidget {
  const _PixivImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ImageLoadingSkeleton();
  }
}

class _PixivImageError extends StatelessWidget {
  const _PixivImageError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final error = this.error;
    final cause = error == null ? null : pixivErrorBrief(error);

    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: Tooltip(
        // The full cause is always one hover away; large tiles also show it.
        message: cause == null ? context.t.common.retry : '${context.t.common.retry} · $cause',
        child: AppClickSurface(
          onTap: onRetry,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shortestSide = constraints.biggest.shortestSide;
              final iconSize = shortestSide.isFinite ? (shortestSide * 0.45).clamp(18.0, 32.0).toDouble() : 28.0;
              final roomy = shortestSide.isFinite && shortestSide >= 120;
              final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant);

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_outlined, size: iconSize, color: colorScheme.onSurfaceVariant),
                      if (roomy) ...[
                        const SizedBox(height: 6),
                        Text(context.t.refresh.loadFailed, style: labelStyle, textAlign: TextAlign.center),
                        if (cause != null) Text(cause, style: labelStyle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
