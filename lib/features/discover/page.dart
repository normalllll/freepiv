import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/features/pixivision/navigation.dart';
import 'package:freepiv/features/search/logic/search_history_logic.dart';
import 'package:freepiv/features/search/logic/search_trending_tags_logic.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_box.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/entry_row.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The discover page `/discover`, pushed from the search:
/// every recent search (each removable, and Clear), the entry row (ranking,
/// Pixivision, FANBOX), every trending tag as a picture card that adds the
/// tag to the search, and three Pixivision articles. Without the title-bar
/// search the header holds the page search box, focused when asked to.
class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({this.focusSearch = false, super.key});

  /// Opens with the header search focused (the bottom-bar layout's search).
  final bool focusSearch;

  /// Trending tag cards are at least this wide; two columns on a phone.
  static const tagTileWidth = 150.0;

  /// Pixivision cards are at least this wide.
  static const articleTileWidth = 240.0;

  static const _pixivisionReferer = {'Referer': 'https://www.pixivision.net/'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final inCaption = FrostShell.titleContentInCaptionOf(context);
    final actions = AppSearchActions(ref, context);
    final language = pixivisionLanguagePath(t.$meta.locale);
    final pixivision = pixivisionBrowseProvider('https://www.pixivision.net/$language/');
    Future<void> refresh() async {
      ref.invalidate(pixivision);
      await Future.wait([ref.read(searchTrendingTagsProvider.notifier).reload(keepPreviousData: true), ref.read(pixivision.future)]);
    }

    final history = ref.watch(searchHistoryProvider);
    final trending = ref.watch(searchTrendingTagsProvider);
    final articles = ref.watch(pixivision);
    Widget column(Widget child) => SliverToBoxAdapter(
      child: FrostContentColumn(maxWidth: double.infinity, child: child),
    );
    return AppRefreshScope(
      onRefresh: refresh,
      child: FrostPinnedChrome(
        chrome: FrostPageHeader(
          title: inCaption ? FrostText(t.common.discover) : null,
          middle: inCaption
              ? null
              : SearchBox(
                  onSearch: (submission) => actions.submit(text: submission.query, type: submission.type),
                  showFilters: false,
                  autofocus: focusSearch,
                ),
        ),
        body: FrostRefreshView(
          onRefresh: () async {
            await refresh();
            return true;
          },
          builder: (context, physics, locators) => FrostLoadingScrollView(
            key: const PageStorageKey('discover'),
            physics: physics,
            slivers: [
              const FrostChromeSpacer(),
              ?locators.sliverHeader,
              if (history.isNotEmpty) ...[
                column(
                  FrostSectionHeader(
                    title: t.discover.history,
                    actionLabel: t.discover.clearHistory,
                    onAction: () => ref.read(searchHistoryProvider.notifier).clear(),
                  ),
                ),
                column(
                  Wrap(
                    spacing: FrostGap.inline,
                    runSpacing: FrostGap.inline,
                    children: [
                      for (final entry in history)
                        FrostFilterChip(
                          label: entry,
                          onPressed: () => actions.submit(text: entry),
                          onClear: () => ref.read(searchHistoryProvider.notifier).remove(entry),
                        ),
                    ],
                  ),
                ),
              ],
              column(
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: FrostGap.section),
                  child: AppEntryRow(
                    entries: [
                      AppEntry(
                        icon: PivIcons.activity,
                        label: t.navigation.ranking,
                        onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.ranking())),
                      ),
                      AppEntry(
                        icon: PivIcons.newspaper,
                        label: t.pixivision.title,
                        onPressed: () => unawaited(GoRouter.of(context).push(AppRoute.pixivision.path)),
                      ),
                      AppEntry(icon: PivIcons.heart, label: t.fanbox.title, onPressed: () => unawaited(GoRouter.of(context).push(AppRoute.fanbox.path))),
                    ],
                  ),
                ),
              ),
              column(FrostSectionHeader(title: t.search.trendingTags)),
              column(switch (trending) {
                AsyncValue(:final value?) when value.isEmpty => FrostText(t.search.emptyTrendingTitle, tone: FrostTextTone.secondary),
                AsyncValue(:final value?) => FrostGrid(
                  minItemWidth: tagTileWidth,
                  aspectRatio: 1,
                  children: [
                    for (final tag in value)
                      FrostMediaCard(
                        media: AppPixivImage(url: tag.illust.imageUrls.squareMedium, aspectRatio: 1, radius: 0),
                        aspectRatio: 1,
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
                        onPressed: () => actions.insertTag(tag.tag),
                      ),
                  ],
                ),
                AsyncValue(:final error?) => FrostCompactMessage.error(
                  error: error,
                  actionLabel: t.common.retry,
                  onAction: () => unawaited(ref.read(searchTrendingTagsProvider.notifier).reload()),
                ),
                _ => const AppRowsSkeleton(count: 2, subtitle: false),
              }),
              column(
                Padding(
                  padding: const EdgeInsets.only(top: FrostGap.section),
                  child: FrostSectionHeader(
                    title: t.pixivision.title,
                    actionLabel: t.discover.viewAll,
                    onAction: () => unawaited(GoRouter.of(context).push(AppRoute.pixivision.path)),
                  ),
                ),
              ),
              column(switch (articles) {
                AsyncValue(:final value?) => switch ([...(value.page.recommended.isNotEmpty ? value.page.recommended : value.page.articles)].take(3).toList()) {
                  final shown when shown.isEmpty => FrostText(t.discoverPage.noArticles, tone: FrostTextTone.secondary),
                  final shown => FrostGrid(
                    minItemWidth: articleTileWidth,
                    children: [
                      for (final article in shown)
                        FrostMediaCard(
                          media: AppPixivImage(url: article.thumbnail ?? '', aspectRatio: 16 / 9, radius: 0, headers: _pixivisionReferer),
                          aspectRatio: 16 / 9,
                          title: article.title,
                          onPressed: () => unawaited(openPixivisionLink(context, article.url, summary: article)),
                        ),
                    ],
                  ),
                },
                AsyncValue(:final error?) => FrostCompactMessage.error(error: error, actionLabel: t.common.retry, onAction: () => ref.invalidate(pixivision)),
                _ => const AppRowsSkeleton(count: 1, subtitle: false),
              }),
            ],
          ),
        ),
      ),
    );
  }
}
