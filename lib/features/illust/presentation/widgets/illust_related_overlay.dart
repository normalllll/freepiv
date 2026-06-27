import 'package:flutter/material.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_related_waterfall.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

class IllustRelatedOverlay extends StatelessWidget {
  const IllustRelatedOverlay({
    required this.visible,
    required this.source,
    required this.currentIllustId,
    required this.onIllustTap,
    required this.onClose,
    super.key,
  });

  final bool visible;
  final IllustRelatedListSource source;
  final int currentIllustId;
  final ValueChanged<Illust> onIllustTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: ColoredBox(
          color: colorScheme.surface,
          child: Stack(
            children: [
              Positioned.fill(
                child: IllustRelatedWaterfallView(source: source, currentIllustId: currentIllustId, onIllustTap: onIllustTap),
              ),
              PositionedDirectional(
                top: 16,
                end: 16,
                child: SafeArea(
                  child: SurfaceIconButton(icon: Icons.keyboard_arrow_up, tooltip: context.t.illust.tooltip.backToDetail, onPressed: onClose),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
