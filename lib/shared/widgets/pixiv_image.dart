import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';

class PixivImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final image = ExtendedImage.network(
      url,
      width: width,
      height: height,
      fit: fit,
      cache: cache,
      cacheKey: base64Url.encode(url.codeUnits),
      headers: headers ?? const {'Referer': 'https://www.pixiv.net/'},
      retries: 0,
      loadStateChanged: (state) {
        return switch (state.extendedImageLoadState) {
          LoadState.loading => placeholder?.call(context) ?? const _PixivImagePlaceholder(),
          LoadState.failed => errorBuilder?.call(context) ?? _PixivImageError(onRetry: state.reLoadImage),
          LoadState.completed => null,
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
  const _PixivImageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: Tooltip(
        message: context.t.common.retry,
        child: InkWell(
          onTap: onRetry,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shortestSide = constraints.biggest.shortestSide;
              final iconSize = shortestSide.isFinite ? (shortestSide * 0.45).clamp(18.0, 32.0).toDouble() : 28.0;

              return Center(
                child: Icon(Icons.refresh_outlined, size: iconSize, color: colorScheme.onSurfaceVariant),
              );
            },
          ),
        ),
      ),
    );
  }
}
