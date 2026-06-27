import 'package:flutter/material.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/illust_waterfall_skeleton.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

const _relatedWaterfallPadding = EdgeInsets.fromLTRB(12, 0, 12, 24);
const _relatedWaterfallMaxCrossAxisExtent = 240.0;
const _relatedWaterfallSpacing = 8.0;

class IllustRelatedWaterfallView extends StatelessWidget {
  const IllustRelatedWaterfallView({required this.source, required this.currentIllustId, required this.onIllustTap, this.topPadding = 12, super.key});

  final IllustRelatedListSource source;
  final int currentIllustId;
  final ValueChanged<Illust> onIllustTap;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: source,
      builder: (context, child) {
        return DataLoadingCustomScrollView(
          slivers: [
            ...IllustRelatedSlivers.build(
              context: context,
              source: source,
              currentIllustId: currentIllustId,
              onIllustTap: onIllustTap,
              topPadding: topPadding,
              fullScreen: true,
            ),
          ],
        );
      },
    );
  }
}

class IllustRelatedSlivers {
  const IllustRelatedSlivers._();

  static List<Widget> build({
    required BuildContext context,
    required IllustRelatedListSource source,
    required int currentIllustId,
    required ValueChanged<Illust> onIllustTap,
    double topPadding = 0,
    bool showTitle = true,
    bool fullScreen = false,
  }) {
    final translations = t;
    final works = source.items.where((illust) => illust.id != currentIllustId).toList(growable: false);
    final lastError = source.lastError;
    final titleSliver = showTitle
        ? <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
                child: IllustSectionTitle(title: translations.illust.section.relatedWorks, icon: Icons.auto_awesome_mosaic_outlined),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ]
        : <Widget>[SliverToBoxAdapter(child: SizedBox(height: topPadding))];

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return [
        ...titleSliver,
        const SliverIllustWaterfallSkeleton(
          padding: _relatedWaterfallPadding,
          maxCrossAxisExtent: _relatedWaterfallMaxCrossAxisExtent,
          crossAxisSpacing: _relatedWaterfallSpacing,
          mainAxisSpacing: _relatedWaterfallSpacing,
        ),
      ];
    }

    if (!source.initialized && lastError != null) {
      return [
        ...titleSliver,
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CompactMessage(
              icon: Icons.error_outline,
              message: formatPixivError(lastError),
              actionLabel: translations.common.retry,
              onAction: () => source.refresh(true),
            ),
          ),
        ),
      ];
    }

    if (source.initialized && works.isEmpty) {
      return [
        ...titleSliver,
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CompactMessage(icon: Icons.image_not_supported_outlined, message: translations.illust.related.empty),
          ),
        ),
      ];
    }

    return [
      ...titleSliver,
      SliverDataWaterfallGrid<Illust>(
        source: source,
        padding: _relatedWaterfallPadding,
        maxCrossAxisExtent: _relatedWaterfallMaxCrossAxisExtent,
        crossAxisSpacing: _relatedWaterfallSpacing,
        mainAxisSpacing: _relatedWaterfallSpacing,
        itemBuilder: (context, illust, index) {
          if (illust.id == currentIllustId) {
            return const SizedBox.shrink();
          }

          return IllustPreviewer(illust: illust, onTap: () => onIllustTap(illust));
        },
      ),
    ];
  }
}
