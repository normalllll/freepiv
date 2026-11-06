import 'package:freepiv/features/downloads/presentation/content_image_menu.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/shared/widgets/legacy_frost.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
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
              placeholder: (_) => const PivImageSkeleton(),
              // A failed image keeps its slot filled, like the skeleton it
              // replaced, with a clear way to try again over the whole area.
              errorBuilder: (context) =>
                  widget.errorWidget ??
                  _ImageLoadFailed(
                    onRetry: () {
                      setState(() {
                        _retry++;
                        _probeGeneration++;
                        _probing = false;
                      });
                      _probeRatio();
                    },
                  ),
            )
          : const PivImageSkeleton(),
    );
    // Every article image shares one corner radius, loaded or not.
    final clipped = ClipRRect(borderRadius: BorderRadius.circular(FrostRadius.lg), child: content);
    // Unknown sizes reserve the skeleton's slot, then ease once to the real
    // ratio when the image arrives.
    if ((widget.aspectRatio ?? _resolvedRatio ?? (widget.resolveAspectRatio ? widget.placeholderRatio : null)) case final ratio?) {
      return AnimatedSize(
        duration: FrostMotion.duration(context, const Duration(milliseconds: 350)),
        curve: FrostSpringCurve(FrostMotion.standard, const Duration(milliseconds: 350)),
        alignment: Alignment.topCenter,
        child: AspectRatio(aspectRatio: ratio, child: clipped),
      );
    }
    return clipped;
  }
}

class _ImageLoadFailed extends StatelessWidget {
  const _ImageLoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = FrostThemeTokens.of(context);
    final label = Theme.of(context).textTheme.labelMedium?.copyWith(color: tokens.textSecondary);
    return ColoredBox(
      color: tokens.surfaceInset,
      child: Material(
        type: MaterialType.transparency,
        child: Tooltip(
          message: context.t.common.retry,
          child: FrostClickSurface(
            feedback: FrostClickFeedback.quiet,
            shape: FrostClickShape.rounded(BorderRadius.zero),
            onTap: onRetry,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: tokens.textSecondary),
                  const SizedBox(height: 6),
                  Text(context.t.refresh.loadFailed, style: label, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
