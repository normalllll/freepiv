import 'package:freepiv/shared/widgets/refresh_indicator.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/energetic_card.dart';
import 'image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'navigation.dart';

EdgeInsets pixivisionPadding(double width) => EdgeInsets.symmetric(horizontal: math.max(12, (width - 900) / 2 + 12), vertical: 12);

class PixivisionScaffold extends StatelessWidget {
  const PixivisionScaffold({required this.child, this.title = 'pixivision', super.key});
  final Widget child;
  final String title;
  @override
  Widget build(BuildContext context) => AutoScaffold(
    builder: (context, layout, orientation, desktop) => Scaffold(
      appBar: desktop
          ? null
          : AppBar(
              title: Text(title),
              leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/search')),
            ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: dataRefreshScrollBehavior.dragDevices),
        child: SafeArea(bottom: false, child: child),
      ),
    ),
  );
}

class PixivisionError extends StatelessWidget {
  const PixivisionError({required this.retry, super.key});
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.t.pixivision.requestFailed),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: Text(context.t.common.retry)),
      ],
    ),
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
    child: EnergeticCard(
      onTap: article == null ? null : () => openPixivisionLink(context, article!.url, summary: article),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: preview ? constraints.maxWidth * 9 / 16 : (constraints.maxWidth * 9 / 16).clamp(160, 280),
              child: Skeleton.replace(
                width: double.infinity,
                height: double.infinity,
                child: article?.thumbnail == null
                    ? ColoredBox(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Center(child: Icon(Icons.article_outlined)),
                      )
                    : PixivisionImage(url: article!.thumbnail!),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(preview ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CardTitle(article?.title ?? 'Article title'),
                if (!preview) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text(article?.category?.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 12),
                      Flexible(child: Text(pixivisionDate(context, article?.publishDate ?? ''), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
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
