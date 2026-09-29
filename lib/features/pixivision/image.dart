import 'package:freepiv/features/downloads/presentation/content_image_menu.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/ui/spring_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';
import 'article_images.dart';

class PixivisionImage extends ConsumerStatefulWidget {
  const PixivisionImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.aspectRatio,
    this.resolveAspectRatio = false,
    this.placeholderRatio = 16 / 9,
    this.errorWidget,
    super.key,
  });
  final String url;
  final BoxFit fit;
  final Widget? errorWidget;

  /// Known image metadata sets the media slot before bytes are fetched.
  final double? aspectRatio;
  final bool resolveAspectRatio;

  /// Slot reserved while [resolveAspectRatio] waits for the image; matches
  /// the loading skeleton so the page does not jump before the image lands.
  final double placeholderRatio;
  @override
  ConsumerState<PixivisionImage> createState() => _PixivisionImageState();
}

class _PixivisionImageState extends ConsumerState<PixivisionImage> {
  final _visibilityKey = UniqueKey();
  bool _visible = false;
  bool _onScreen = false;
  int _retry = 0;
  int _probeGeneration = 0;
  bool _probing = false;
  double? _resolvedRatio;
  double? _pendingRatio;

  @override
  void didUpdateWidget(covariant PixivisionImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _probeGeneration++;
      _resolvedRatio = null;
      _pendingRatio = null;
      _probing = false;
      _visible = false;
      _onScreen = false;
    }
  }

  Future<void> _probeRatio() async {
    if (_probing || !widget.resolveAspectRatio || widget.aspectRatio != null) return;
    _probing = true;
    final url = widget.url;
    final generation = _probeGeneration;
    double? ratio;
    try {
      ratio = await probePixivisionImageRatio(ref.read(rustMediaTransportProvider), url);
    } catch (_) {
      // The reserved media slot remains stable if the source cannot be read.
    }
    if (mounted && widget.url == url && generation == _probeGeneration && ratio != null) {
      if (_onScreen) {
        setState(() => _resolvedRatio = ratio);
      } else {
        _pendingRatio = ratio;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: (info) {
        if (!mounted) return;
        _onScreen = info.visibleFraction > 0;
        if (_onScreen) {
          if (!_visible || _pendingRatio != null) {
            setState(() {
              _visible = true;
              _resolvedRatio = _pendingRatio ?? _resolvedRatio;
              _pendingRatio = null;
            });
          }
          _probeRatio();
        }
      },
      child: _visible
          ? PixivImage(
              key: ValueKey((widget.url, _retry)),
              url: widget.url,
              fit: widget.fit,
              headers: pixivisionImageHeaders,
              placeholder: (_) => const ImageLoadingSkeleton(),
              errorBuilder: (context) =>
                  widget.errorWidget ??
                  Center(
                    child: IconButton(
                      tooltip: context.t.common.retry,
                      onPressed: () {
                        setState(() {
                          _retry++;
                          _probeGeneration++;
                          _probing = false;
                        });
                        _probeRatio();
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
            )
          : const ImageLoadingSkeleton(),
    );
    // Every article image shares one corner radius, loaded or not.
    final clipped = ClipRRect(borderRadius: BorderRadius.circular(AppMetrics.controlRadius), child: content);
    // Unknown sizes reserve the skeleton's slot, then ease once to the real
    // ratio when the image arrives.
    if ((widget.aspectRatio ?? _resolvedRatio ?? (widget.resolveAspectRatio ? widget.placeholderRatio : null)) case final ratio?) {
      return AnimatedSize(
        duration: AppMotion.duration(context, const Duration(milliseconds: 350)),
        curve: SpringCurve(AppMotion.standard, const Duration(milliseconds: 350)),
        alignment: Alignment.topCenter,
        child: AspectRatio(aspectRatio: ratio, child: clipped),
      );
    }
    return clipped;
  }
}

/// A Pixivision image with the artwork image menu (download, copy on
/// desktop); taps still reach the surrounding link.
class PixivisionImageMenu extends StatelessWidget {
  const PixivisionImageMenu({required this.url, required this.child, this.title, super.key});

  final String url;
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) => ContentImageMenuRegion(
    actions: ContentImageActions.pixivHosted(url: url, headers: pixivisionImageHeaders, title: title),
    child: child,
  );
}
