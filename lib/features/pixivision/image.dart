import 'package:freepiv/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';

class PixivisionImage extends StatefulWidget {
  const PixivisionImage({required this.url, this.fit = BoxFit.cover, this.aspectRatio, this.errorWidget, super.key});
  final String url;
  final BoxFit fit;
  final Widget? errorWidget;

  /// Article images receive their resolved ratio before the body is displayed.
  final double? aspectRatio;
  @override
  State<PixivisionImage> createState() => _PixivisionImageState();
}

class _PixivisionImageState extends State<PixivisionImage> {
  final _visibilityKey = UniqueKey();
  bool _visible = false;
  int _retry = 0;
  @override
  Widget build(BuildContext context) {
    final content = VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: (info) {
        if (mounted && !_visible && info.visibleFraction > 0) setState(() => _visible = true);
      },
      child: _visible
          ? PixivImage(
              key: ValueKey((widget.url, _retry)),
              url: widget.url,
              fit: widget.fit,
              headers: const {'Referer': 'https://www.pixivision.net/'},
              placeholder: (_) => const ImageLoadingSkeleton(),
              errorBuilder: (context) =>
                  widget.errorWidget ??
                  Center(
                    child: IconButton(tooltip: context.t.common.retry, onPressed: () => setState(() => _retry++), icon: const Icon(Icons.refresh)),
                  ),
            )
          : const ImageLoadingSkeleton(),
    );
    if (widget.aspectRatio case final ratio?) return AspectRatio(aspectRatio: ratio, child: content);
    return content;
  }
}
