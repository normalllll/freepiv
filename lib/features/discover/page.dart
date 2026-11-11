import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/discover/discover_sections.dart';
import 'package:freepiv/features/pixivision/navigation.dart';
import 'package:freepiv/features/search/logic/search_history_logic.dart';
import 'package:freepiv/features/search/logic/search_trending_tags_logic.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_box.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/entry_row.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:freepiv/features/pixivision/article_card.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The discover page `/discover`, pushed from the search:
/// every recent search (each removable, and Clear), the entry row (ranking,
/// Pixivision, FANBOX), every trending tag as a picture card that adds the
/// tag to the search, and three Pixivision articles. Without the title-bar
/// search the header holds the page search box, focused when asked to. It
/// opens scrolled to [section] when given one.
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({this.focusSearch = false, this.section, super.key});

  /// Opens with the header search focused (the bottom-bar layout's search).
  final bool focusSearch;

  /// The section to open at: "All history" and "All trending tags".
  final DiscoverSection? section;

  /// Trending tag cards are at least this wide; two columns on a phone.
  static const tagTileWidth = 150.0;

  /// Pixivision cards are at least this wide.
  static const articleTileWidth = 240.0;

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _scroll = ScrollController();
  final _spacer = GlobalKey();
  final _sections = {for (final section in DiscoverSection.values) section: GlobalKey()};

  /// The section still to reveal, once the content above it has loaded.
  late DiscoverSection? _pending = widget.section;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls [section]'s heading to just under the pinned header.
  void _reveal(DiscoverSection section) {
    if (!mounted) return;
    final heading = _sections[section]!.currentContext?.findRenderObject();
    final spacer = _spacer.currentContext?.findRenderObject();
    if (heading == null || !_scroll.hasClients) return;
    final viewport = RenderAbstractViewport.of(heading);
    final chrome = spacer is RenderSliver ? spacer.geometry?.scrollExtent ?? 0 : 0;
    final offset = viewport.getOffsetToReveal(heading, 0).offset - chrome;
    _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final inCaption = FrostShell.titleContentInCaptionOf(context);
    final actions = AppSearchActions(ref, context);
    final pixivision = discoverPixivision(t);
    Future<void> refresh() async {
      ref.read(discoverFreshnessProvider).fetched();
      ref.invalidate(pixivision);
      await Future.wait([ref.read(searchTrendingTagsProvider.notifier).reload(keepPreviousData: true), ref.read(pixivision.future)]);
    }

    final history = ref.watch(searchHistoryProvider);
    final trending = ref.watch(searchTrendingTagsProvider);
    final articles = ref.watch(pixivision);
    // Trending tags sit under history and the entries, both shown at once; once
    // the tags have loaded, their heading is where it stays.
    if (_pending case final section? when section == DiscoverSection.history || trending.hasValue || trending.hasError) {
      _pending = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(section));
    }
    Widget column(Widget child) => SliverToBoxAdapter(
      child: FrostContentColumn(maxWidth: double.infinity, child: child),
    );
    return AppRefreshScope(
      onRefresh: refresh,
      child: FrostPinnedChrome(
        chrome: FrostPageHeader(
          title: FrostText(t.common.discover),
          middle: inCaption
              ? null
              : SearchBox(
                  onSearch: (submission) => actions.submit(text: submission.query, type: submission.type),
                  autofocus: widget.focusSearch,
                ),
        ),
        body: FrostRefreshView(
          scrollController: _scroll,
          onRefresh: () async {
            await refresh();
            return true;
          },
          builder: (context, physics, locators) => FrostLoadingScrollView(
            key: const PageStorageKey('discover'),
            controller: _scroll,
            physics: physics,
            slivers: [
              FrostChromeSpacer(key: _spacer),
              ?locators.sliverHeader,
              if (history.isNotEmpty) ...[
                column(
                  FrostSectionHeader(
                    key: _sections[DiscoverSection.history],
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
                  // The gap above only divides them from the history.
                  padding: EdgeInsets.only(top: history.isEmpty ? 0 : FrostGap.section, bottom: FrostGap.section),
                  child: AppEntryRow(entries: discoverEntries(t, (location) => unawaited(GoRouter.of(context).push(location)))),
                ),
              ),
              column(FrostSectionHeader(key: _sections[DiscoverSection.trending], title: t.search.trendingTags)),
              column(switch (trending) {
                AsyncValue(:final value?) when value.isEmpty => FrostText(t.search.emptyTrendingTitle, tone: FrostTextTone.secondary),
                AsyncValue(:final value?) => FrostGrid(
                  minItemWidth: DiscoverPage.tagTileWidth,
                  aspectRatio: 1,
                  children: [for (final tag in value) DiscoverTagCard(tag: tag, onPressed: () => actions.insertTag(tag.tag))],
                ),
                AsyncValue(:final error?) => FrostCompactMessage.error(
                  error: error,
                  actionLabel: t.common.retry,
                  onAction: () => unawaited(ref.read(searchTrendingTagsProvider.notifier).reload()),
                ),
                _ => const _TrendingSkeleton(),
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
                AsyncValue(:final value?) => switch (discoverArticles(value)) {
                  final shown when shown.isEmpty => FrostText(t.discoverPage.noArticles, tone: FrostTextTone.secondary),
                  final shown => FrostGrid(
                    minItemWidth: DiscoverPage.articleTileWidth,
                    children: [
                      for (final article in shown)
                        DiscoverArticleCard(
                          article: article,
                          onPressed: () => unawaited(openPixivisionLink(context, article.url, summary: article)),
                        ),
                    ],
                  ),
                },
                AsyncValue(:final error?) => FrostCompactMessage.error(error: error, actionLabel: t.common.retry, onAction: () => ref.invalidate(pixivision)),
                _ => const _ArticlesSkeleton(),
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// The trending tags while they load: the same grid of square cards.
class _TrendingSkeleton extends StatelessWidget {
  const _TrendingSkeleton();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final tiles = appSkeletonCount(
        context,
        shortestExtent: DiscoverPage.tagTileWidth,
        perRow: math.max(1, (constraints.maxWidth / DiscoverPage.tagTileWidth).floor()),
      );
      return FrostGrid(
        minItemWidth: DiscoverPage.tagTileWidth,
        aspectRatio: 1,
        children: [for (var index = 0; index < tiles; index++) FrostMediaCard.skeleton(aspectRatio: 1, footer: null)],
      );
    },
  );
}

/// The Pixivision picks while they load: the same grid of article cards.
class _ArticlesSkeleton extends StatelessWidget {
  const _ArticlesSkeleton();

  @override
  Widget build(BuildContext context) => appBones(
    FrostGrid(
      minItemWidth: DiscoverPage.articleTileWidth,
      children: [for (var index = 0; index < discoverArticleCount; index++) DiscoverArticleCard(article: articleSummaryPlaceholder)],
    ),
  );
}
