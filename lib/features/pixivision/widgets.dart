import 'package:flutter/material.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/shared/widgets/legacy_frost.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'navigation.dart';
import 'package:freepiv/app/router/app_route.dart';

EdgeInsets pixivisionPadding(double width) => FrostMetrics.columnPadding(width).copyWith(top: 12, bottom: 12);

EdgeInsets pixivisionReadingPadding(double width) => FrostMetrics.columnPadding(width, maxWidth: FrostMetrics.readingMaxWidth).copyWith(top: 24, bottom: 24);

class PixivisionScaffold extends StatelessWidget {
  const PixivisionScaffold({required this.child, this.title = 'pixivision', super.key});
  final Widget child;
  final String title;
  @override
  Widget build(BuildContext context) => FrostAutoScaffold(
    builder: (context, layout, orientation, desktop) => Scaffold(
      body: FrostCollapsingHeader(
        header: desktop ? null : FrostPageHeader(title: Text(title), onBack: () => context.canPop() ? context.pop() : context.go(AppRoute.discover.path)),
        child: SafeArea(bottom: false, child: child),
      ),
    ),
  );
}

class PixivisionError extends StatelessWidget {
  const PixivisionError({required this.retry, this.error, super.key});
  final VoidCallback retry;
  final Object? error;
  @override
  Widget build(BuildContext context) => FrostErrorContent(
    message: context.t.pixivision.requestFailed,
    details: switch (error) {
      final error? => pixivErrorDetails(error),
      null => null,
    },
    onRetry: retry,
  );
}

class PixivisionCard extends StatelessWidget {
  const PixivisionCard({this.article, super.key}) : preview = false;
  const PixivisionCard.preview({this.article, super.key}) : preview = true;
  final ArticleSummary? article;
  final bool preview;

  static double previewHeight(BuildContext context, double width) => width * 9 / 16 + 24 + _cardTitleHeight(context);
  @override
  Widget build(BuildContext context) => Skeletonizer(
    enabled: article == null,
    child: PivCard(
      onTap: article == null ? null : () => openPixivisionLink(context, article!.url, summary: article),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = !preview && FrostAutoScaffold.usesHorizontalLayoutOf(context) && constraints.maxWidth >= FrostMetrics.gridExtent * 2;
          final image = Skeleton.replace(
            width: double.infinity,
            height: double.infinity,
            child: article?.thumbnail == null
                ? ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.article_outlined)),
                  )
                : PixivisionImage(url: article!.thumbnail!),
          );
          final details = Padding(
            padding: EdgeInsets.all(preview ? FrostGap.of(context).group : FrostGap.panelInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CardTitle(pixivisionArticleTitle(article?.title ?? 'Article title')),
                if (!preview) ...[
                  const SizedBox(height: FrostGap.group),
                  Row(
                    children: [
                      Expanded(child: Text(article?.category?.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: FrostGap.group),
                      Flexible(child: Text(pixivisionDate(context, article?.publishDate ?? ''), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ],
            ),
          );
          if (horizontal) {
            return Row(
              children: [
                SizedBox(width: FrostMetrics.gridExtent, height: FrostMetrics.gridExtent * 9 / 16, child: image),
                Expanded(child: details),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: image),
              details,
            ],
          );
        },
      ),
    ),
  );
}

String pixivisionDate(BuildContext context, String value) {
  final parsed = DateTime.tryParse(value.replaceAll('.', '-').replaceAll('/', '-'));
  return parsed == null ? value : MaterialLocalizations.of(context).formatMediumDate(parsed);
}

class PixivisionCardSkeleton extends StatelessWidget {
  const PixivisionCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < (MediaQuery.sizeOf(context).height / 240).ceil(); i++) const Padding(padding: EdgeInsets.only(bottom: 12), child: PixivisionCard()),
    ],
  );
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium!;
    final height = _cardTitleHeight(context);
    return SizedBox(
      height: height,
      child: Text(text, style: style, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

// Shared with the preview strip so loading and populated cards have equal height.
double _cardTitleHeight(BuildContext context) {
  final painter = TextPainter(
    text: TextSpan(text: 'Ag', style: Theme.of(context).textTheme.titleMedium!),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final height = painter.preferredLineHeight * 2;
  painter.dispose();
  return height;
}

String pixivisionArticleTitle(String value) => value.replaceFirst(RegExp(r'\s+-\s*$'), '').trim();
