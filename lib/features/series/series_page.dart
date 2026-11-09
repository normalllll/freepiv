import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/illust/presentation/illust_info.dart' show IllustAuthorLine;
import 'package:freepiv/features/series/logic.dart';
import 'package:freepiv/features/series/series_widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/compositions/pixiv_text.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// A manga or novel series: its title, author and length, Follow up, then its
/// works in order.
class SeriesPage extends ConsumerWidget {
  const SeriesPage({required this.kind, required this.seriesId, super.key});

  final AppSeriesKind kind;
  final int seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final empty = FrostEmptyState(icon: FrostIconSet.of(context).empty, title: t.series.empty);
    return switch (kind) {
      AppSeriesKind.novel => () {
        final source = ref.watch(novelSeriesWorksProvider(seriesId));
        return _SeriesScaffold(
          kind: kind,
          seriesId: seriesId,
          summary: source.summary,
          source: source,
          maxWidth: double.infinity,
          works: FrostSliverContentColumn(
            maxWidth: double.infinity,
            sliver: FrostSliverDataList<Novel>(
              source: source,
              firstLoadSkeleton: const AppNovelRowsSkeleton(showAuthor: false),
              empty: empty,
              itemBuilder: (context, novel, index) => AppNovelRow(novel: novel, rank: index + 1, showAuthor: false),
            ),
          ),
        );
      }(),
      AppSeriesKind.manga => () {
        final source = ref.watch(mangaSeriesWorksProvider(seriesId));
        return _SeriesScaffold(
          kind: kind,
          seriesId: seriesId,
          summary: source.summary,
          source: source,
          maxWidth: double.infinity,
          works: FrostSliverDataWaterfallGrid<Illust>(
            source: source,
            firstLoadSkeleton: const AppArtworkWaterfallSkeleton(),
            empty: empty,
            itemBuilder: (context, illust, index) => AppArtworkCard(illust: illust),
          ),
        );
      }(),
    };
  }
}

class _SeriesScaffold extends StatelessWidget {
  const _SeriesScaffold({required this.kind, required this.seriesId, required this.summary, required this.source, required this.maxWidth, required this.works});

  final AppSeriesKind kind;
  final int seriesId;
  final ValueNotifier<SeriesSummary?> summary;
  final FrostListSource<Object?> source;
  final double maxWidth;
  final Widget works;

  @override
  Widget build(BuildContext context) => AppRefreshScope(
    onRefresh: () => source.refresh(false),
    child: ValueListenableBuilder(
      valueListenable: summary,
      builder: (context, loaded, _) => FrostPinnedChrome(
        chrome: FrostPageHeader(title: FrostText(context.t.series.title)),
        body: FrostRefreshView(
          onRefresh: () => source.refresh(false),
          builder: (context, physics, locators) => FrostLoadingScrollView(
            physics: physics,
            slivers: [
              const FrostChromeSpacer(),
              ?locators.sliverHeader,
              if (loaded != null)
                FrostSliverContentColumn(
                  maxWidth: maxWidth,
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: FrostGap.section),
                      child: _SeriesHead(kind: kind, seriesId: seriesId, summary: loaded),
                    ),
                  ),
                ),
              works,
            ],
          ),
        ),
      ),
    ),
  );
}

class _SeriesHead extends StatelessWidget {
  const _SeriesHead({required this.kind, required this.seriesId, required this.summary});

  static const _coverWidth = 96.0;
  static const _coverRatio = 1 / 1.414;

  /// From this text size the author and length need the full width, not the
  /// column beside the cover.
  static const _besideCoverMaxTextScale = 1.5;

  final AppSeriesKind kind;
  final int seriesId;
  final SeriesSummary summary;

  void _openFirst(BuildContext context) {
    final location = switch (summary.first) {
      final Novel novel => AppLocations.novel(novel.id),
      final Illust illust => AppLocations.illust(illust.id),
      _ => null,
    };
    if (location != null) unawaited(GoRouter.of(context).push(location, extra: summary.first));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final caption = plainTextFromHtml(summary.caption).trim();
    final cover = summary.coverUrl;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= _besideCoverMaxTextScale;
    final author = IllustAuthorLine(user: summary.user);
    final meta = FrostMetaLine(
      items: [
        t.series.episodes(count: summary.workCount),
        if (summary.concluded case final concluded?) concluded ? t.series.concluded : t.series.ongoing,
        if (summary.characters case final characters?) t.novel.detail.totalChars(count: formatCount(characters)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.group,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: FrostGap.group,
          children: [
            if (cover != null && cover.isNotEmpty)
              SizedBox(
                width: _coverWidth,
                child: AppPixivImage(url: cover, aspectRatio: _coverRatio, radius: FrostRadius.md),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: FrostGap.related,
                children: [
                  FrostText(summary.title, content: true, role: FrostTextRole.title2, selectable: true),
                  if (!largeText) ...[author, meta],
                ],
              ),
            ),
          ],
        ),
        if (largeText) ...[author, meta],
        if (caption.isNotEmpty) AppPixivText(summary.caption),
        Wrap(
          spacing: FrostGap.related,
          runSpacing: FrostGap.related,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppSeriesWatchButton(kind: kind, seriesId: seriesId, watched: summary.watched),
            if (summary.first != null) FrostButton(label: t.series.startFromFirst, icon: PivIcons.bookOpen, onPressed: () => _openFirst(context)),
          ],
        ),
      ],
    );
  }
}
