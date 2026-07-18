import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

const _horizontalIllustStripPadding = EdgeInsets.symmetric(horizontal: 2);
const _horizontalIllustStripSpacing = 8.0;
const _horizontalIllustStripVisibleItems = 3;
const _horizontalIllustStripMinExtent = 96.0;
const _horizontalIllustStripMaxExtent = 140.0;

class HorizontalIllustStrip extends StatefulWidget {
  const HorizontalIllustStrip({required this.illusts, required this.onIllustTap, this.itemExtent, super.key});

  final List<Illust> illusts;
  final ValueChanged<Illust> onIllustTap;
  final double? itemExtent;

  @override
  State<HorizontalIllustStrip> createState() => _HorizontalIllustStripState();
}

class _HorizontalIllustStripState extends State<HorizontalIllustStrip> {
  late final ScrollController _scrollController;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showDesktopControls = MediaQuery.sizeOf(context).width >= 900 && widget.illusts.length > 4;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemExtent = widget.itemExtent ?? _horizontalIllustItemExtent(constraints.maxWidth);

        return MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: SizedBox(
            height: itemExtent,
            child: Stack(
              children: [
                ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: _horizontalIllustStripPadding,
                  itemCount: widget.illusts.length,
                  separatorBuilder: (context, index) => const SizedBox(width: _horizontalIllustStripSpacing),
                  itemBuilder: (context, index) {
                    final illust = widget.illusts[index];

                    return SizedBox.square(
                      dimension: itemExtent,
                      child: SquareIllustTile(illust: illust, onTap: () => widget.onIllustTap(illust)),
                    );
                  },
                ),
                if (showDesktopControls) ...[
                  _StripScrollButton(
                    visible: _hovering,
                    alignment: AlignmentDirectional.centerStart,
                    icon: Icons.chevron_left,
                    tooltip: context.t.illust.tooltip.previousImage,
                    onPressed: () => _scrollBy(-itemExtent * 3),
                  ),
                  _StripScrollButton(
                    visible: _hovering,
                    alignment: AlignmentDirectional.centerEnd,
                    icon: Icons.chevron_right,
                    tooltip: context.t.illust.tooltip.nextImage,
                    onPressed: () => _scrollBy(itemExtent * 3),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollBy(double offset) {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final target = (_scrollController.offset + offset).clamp(position.minScrollExtent, position.maxScrollExtent);

    _scrollController.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
  }
}

double _horizontalIllustItemExtent(double availableWidth) {
  if (!availableWidth.isFinite || availableWidth <= 0) {
    return 116;
  }

  final usableWidth = availableWidth - _horizontalIllustStripPadding.horizontal - _horizontalIllustStripSpacing * (_horizontalIllustStripVisibleItems - 1);
  return (usableWidth / _horizontalIllustStripVisibleItems).clamp(_horizontalIllustStripMinExtent, _horizontalIllustStripMaxExtent).toDouble();
}

class _StripScrollButton extends StatelessWidget {
  const _StripScrollButton({required this.visible, required this.alignment, required this.icon, required this.tooltip, required this.onPressed});

  final bool visible;
  final AlignmentGeometry alignment;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Tooltip(
                message: tooltip,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.38),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPressed,
                    child: SizedBox.square(dimension: 28, child: Icon(icon, size: 18, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HorizontalIllustStripSkeleton extends StatelessWidget {
  const HorizontalIllustStripSkeleton({this.itemExtent, super.key});

  final double? itemExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedItemExtent = itemExtent ?? _horizontalIllustItemExtent(constraints.maxWidth);

        return SizedBox(
          height: resolvedItemExtent,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            padding: _horizontalIllustStripPadding,
            separatorBuilder: (context, index) => const SizedBox(width: _horizontalIllustStripSpacing),
            itemBuilder: (context, index) {
              return SizedBox.square(
                dimension: resolvedItemExtent,
                child: const ImageLoadingSkeleton(borderRadius: BorderRadius.all(Radius.circular(8))),
              );
            },
          ),
        );
      },
    );
  }
}

class SquareIllustTile extends ConsumerWidget {
  const SquareIllustTile({required this.illust, required this.onTap, super.key});

  final Illust illust;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewQuality = ref.watch(previewImageQualityProvider);
    final imageUrl = illustPreviewImageUrl(illust.imageUrls, previewQuality);
    final borderRadius = BorderRadius.circular(8);

    return Tooltip(
      message: illust.title,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PixivImage(url: imageUrl, fit: BoxFit.cover),
              const Positioned.fill(child: _TileHoverOverlay()),
              if (illust.pageCount > 1)
                PositionedDirectional(
                  top: 5,
                  end: 5,
                  child: _TileBadge(icon: Icons.collections_outlined, label: '${illust.pageCount}'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileHoverOverlay extends StatefulWidget {
  const _TileHoverOverlay();

  @override
  State<_TileHoverOverlay> createState() => _TileHoverOverlayState();
}

class _TileHoverOverlayState extends State<_TileHoverOverlay> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _hovering ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: DecoratedBox(decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12))),
        ),
      ),
    );
  }
}

class _TileBadge extends StatelessWidget {
  const _TileBadge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;

    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.50), borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 11, color: Colors.white), const SizedBox(width: 3)],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}
