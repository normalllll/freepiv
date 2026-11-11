import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/features/search/logic/search_trending_tags_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'package:freepiv/ui/compositions/entry_row.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';

/// The sections the discover page and the search dropdown's compact discover
/// share: the entries, trending tag cards and Pixivision
/// article cards. The compact discover shows fewer of each.

/// Where the discover page is opened at.
enum DiscoverSection { history, trending }

/// How long trending tags and Pixivision stay fresh for the dropdown; older
/// ones are fetched again in the background, keeping what is shown.
const discoverFreshFor = Duration(minutes: 10);

/// Pixivision articles the discover sections show.
const discoverArticleCount = 3;

/// Pixivision's front page in the interface language.
PixivisionBrowseProvider discoverPixivision(Translations t) => pixivisionBrowseProvider('https://www.pixivision.net/${pixivisionLanguagePath(t.$meta.locale)}/');

/// The articles the discover sections show: the recommended ones, else the latest.
List<ArticleSummary> discoverArticles(PixivisionListing listing) => homeArticles(listing).take(discoverArticleCount).toList();

/// Every article Home's Pixivision shelf shows: the recommended ones, else the latest.
List<ArticleSummary> homeArticles(PixivisionListing listing) => listing.page.recommended.isNotEmpty ? listing.page.recommended : listing.page.articles;

/// Ranking, Pixivision and FANBOX; [open] goes to a location.
List<AppEntry> discoverEntries(Translations t, void Function(String location) open) => [
  AppEntry(icon: PivIcons.activity, label: t.navigation.ranking, onPressed: () => open(AppLocations.ranking())),
  AppEntry(icon: PivIcons.newspaper, label: t.pixivision.title, onPressed: () => open(AppRoute.pixivision.path)),
  AppEntry(icon: PivIcons.heart, label: t.fanbox.title, onPressed: () => open(AppRoute.fanbox.path)),
];

/// Fetches trending tags and Pixivision again when they are older than
/// [discoverFreshFor], keeping them on screen meanwhile.
class DiscoverFreshness {
  DiscoverFreshness({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  DateTime? _fetchedAt;

  /// Marks the sections fetched now (on first show and after a refresh).
  void fetched() => _fetchedAt = _now();

  /// Whether the sections are due to be fetched again; marks them fetched
  /// when they are. The first show only starts the clock.
  bool takeStale() {
    final fetchedAt = _fetchedAt;
    if (fetchedAt != null && _now().difference(fetchedAt) < discoverFreshFor) return false;
    fetched();
    return fetchedAt != null;
  }

  /// Refreshes in the background when stale; true when it did.
  bool refreshIfStale(WidgetRef ref, Translations t) {
    if (!takeStale()) return false;
    unawaited(ref.read(searchTrendingTagsProvider.notifier).reload(keepPreviousData: true));
    ref.invalidate(discoverPixivision(t));
    return true;
  }
}

/// The app's one record of when the discover sections were fetched.
final discoverFreshnessProvider = Provider<DiscoverFreshness>((ref) => DiscoverFreshness());

/// A trending tag as a picture card: its work, the tag and its translation.
/// Without [onPressed] (in the dropdown, where the option selects it) the
/// card only shows.
class DiscoverTagCard extends StatelessWidget {
  const DiscoverTagCard({required this.tag, this.onPressed, this.aspectRatio = 1, super.key});

  final TrendTag tag;
  final VoidCallback? onPressed;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) => FrostMediaCard(
    media: AppPixivImage(url: tag.illust.imageUrls.squareMedium, aspectRatio: aspectRatio, radius: 0),
    aspectRatio: aspectRatio,
    semanticLabel: '#${tag.tag}',
    overlay: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FrostText('#${tag.tag}', content: true, role: FrostTextRole.subheadline, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (tag.translatedName case final name? when name.isNotEmpty)
          FrostText(name, content: true, role: FrostTextRole.footnote, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
    onPressed: onPressed,
  );
}

/// A Pixivision article as a card: its cover and title. Without [onPressed]
/// the card only shows.
class DiscoverArticleCard extends StatelessWidget {
  const DiscoverArticleCard({required this.article, this.onPressed, this.titleLines = 2, super.key});

  final ArticleSummary article;
  final VoidCallback? onPressed;
  final int titleLines;

  static const referer = {'Referer': 'https://www.pixivision.net/'};

  @override
  Widget build(BuildContext context) => FrostMediaCard(
    media: AppPixivImage(url: article.thumbnail ?? '', aspectRatio: 16 / 9, radius: 0, headers: referer),
    aspectRatio: 16 / 9,
    title: article.title,
    titleLines: titleLines,
    onPressed: onPressed,
  );
}
