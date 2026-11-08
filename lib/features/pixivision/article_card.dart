import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/features/pixivision/navigation.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:frost_ui/frost_ui.dart';

/// Pixivision serves its images only to requests coming from its own pages.
const pixivisionReferer = {'Referer': 'https://www.pixivision.net/'};

/// An article title without the trailing " -" some listings carry.
String pixivisionArticleTitle(String value) => value.replaceFirst(RegExp(r'\s+-\s*$'), '').trim();

/// A publish date as the day it names (2026-11-07); as given when it is not one.
String pixivisionDate(String value) {
  final parsed = DateTime.tryParse(value.replaceAll('.', '-').replaceAll('/', '-'));
  if (parsed == null) return value;
  String two(int part) => part.toString().padLeft(2, '0');
  return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)}';
}

/// An article in a Pixivision listing: its cover, its
/// title in two lines and its category and date; it opens the article.
class AppPixivisionCard extends StatelessWidget {
  const AppPixivisionCard({required this.article, super.key});

  final ArticleSummary article;

  @override
  Widget build(BuildContext context) {
    final meta = [?article.category?.title, if (article.publishDate case final date? when date.isNotEmpty) pixivisionDate(date)].join(' · ');
    return FrostMediaCard(
      media: AppPixivImage(url: article.thumbnail ?? '', aspectRatio: 16 / 9, radius: 0, headers: pixivisionReferer),
      aspectRatio: 16 / 9,
      title: pixivisionArticleTitle(article.title),
      metadata: meta.isEmpty
          ? null
          : FrostText(meta, role: FrostTextRole.footnote, tone: FrostTextTone.secondary, maxLines: 1, overflow: TextOverflow.ellipsis),
      onPressed: () => unawaited(openPixivisionLink(context, article.url, summary: article)),
    );
  }
}

/// An article to lay out and paint as bones while the real ones load.
const articleSummaryPlaceholder = ArticleSummary(
  id: 0,
  title: 'An article title over two lines, as long as the usual ones are, and a little over',
  url: '',
  publishDate: '2026-11-07',
  category: ArticleLink(title: 'Illustration', url: ''),
  tags: [],
);

/// First-load placeholders the size of the article cards.
class AppPixivisionCardsSkeleton extends StatelessWidget {
  const AppPixivisionCardsSkeleton({this.count, super.key});

  /// Null fills the window; a number is for a short fixed preview.
  final int? count;

  static const _ratio = 16 / 9;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => FrostWaterfallGrid<int>(
      items: List.generate(count ?? appWaterfallSkeletonCount(context, width: constraints.maxWidth, widestRatio: _ratio, footerExtent: 0), (index) => index),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, _, index) => appBones(const AppPixivisionCard(article: articleSummaryPlaceholder)),
    ),
  );
}
