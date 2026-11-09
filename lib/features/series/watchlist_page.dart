import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/series/logic.dart';
import 'package:freepiv/features/series/series_widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The series the account follows up, manga and novels apart.
class WatchlistPage extends ConsumerStatefulWidget {
  const WatchlistPage({super.key});

  @override
  ConsumerState<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends ConsumerState<WatchlistPage> {
  var _kind = AppSeriesKind.manga;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final source = ref.watch(watchlistEntriesProvider(_kind));
    return AppRefreshScope(
      onRefresh: () => source.refresh(false),
      child: FrostPinnedChrome(
        chrome: FrostPageHeader(title: FrostText(t.watchlist.title)),
        body: FrostRefreshView(
          onRefresh: () => source.refresh(false),
          builder: (context, physics, locators) => FrostLoadingScrollView(
            physics: physics,
            slivers: [
              const FrostChromeSpacer(),
              ?locators.sliverHeader,
              FrostSliverContentColumn(
                maxWidth: double.infinity,
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: FrostGap.related),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FrostPicker<AppSeriesKind>.segmented(
                        label: t.watchlist.title,
                        value: _kind,
                        onChanged: (kind) => setState(() => _kind = kind),
                        options: [
                          FrostPickerOption(value: AppSeriesKind.manga, label: t.watchlist.manga),
                          FrostPickerOption(value: AppSeriesKind.novel, label: t.watchlist.novels),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              FrostSliverContentColumn(
                maxWidth: double.infinity,
                sliver: FrostSliverDataList<WatchlistSeries>(
                  source: source,
                  firstLoadSkeleton: const AppNovelRowsSkeleton(),
                  empty: FrostEmptyState(icon: PivIcons.clock, title: _kind == AppSeriesKind.manga ? t.watchlist.emptyManga : t.watchlist.emptyNovels),
                  itemBuilder: (context, series, index) => _WatchlistRow(kind: _kind, series: series),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({required this.kind, required this.series});

  /// The width a row needs, at the normal text size, to keep the button
  /// beside the text.
  static const _sideButtonMinWidth = 420.0;

  final AppSeriesKind kind;
  final WatchlistSeries series;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final hidden = series.maskText != null;
    final url = series.url;
    final date = series.lastPublishedContentDatetime;
    final watch = AppSeriesWatchButton(kind: kind, seriesId: series.id, watched: true);
    final row = LayoutBuilder(
      builder: (context, constraints) {
        // Beside the text while both fit; under it on a narrow column or at large text.
        final stacked = constraints.maxWidth < _sideButtonMinWidth * MediaQuery.textScalerOf(context).scale(1);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
          child: Row(
            crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            spacing: FrostGap.group,
            children: [
              SizedBox(
                width: AppNovelRow.coverWidth,
                child: url == null || url.isEmpty || hidden
                    ? AspectRatio(
                        aspectRatio: AppNovelRow.coverRatio,
                        child: FrostSurface(
                          role: FrostSurfaceRole.module,
                          edge: FrostSurfaceEdge.none,
                          elevated: false,
                          borderRadius: BorderRadius.circular(FrostRadius.md),
                          child: const SizedBox.expand(),
                        ),
                      )
                    : AppPixivImage(url: url, aspectRatio: AppNovelRow.coverRatio, radius: FrostRadius.md),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostGap.inline,
                  children: hidden
                      ? [
                          FrostText(
                            series.maskText!.isEmpty ? t.watchlist.unavailable : series.maskText!,
                            content: true,
                            role: FrostTextRole.footnote,
                            tone: FrostTextTone.secondary,
                          ),
                          if (stacked) watch,
                        ]
                      : [
                          FrostText(series.title, content: true, role: FrostTextRole.headline, maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (series.user case final user?)
                            FrostText(
                              user.name,
                              content: true,
                              role: FrostTextRole.footnote,
                              tone: FrostTextTone.secondary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          FrostMetaLine(
                            items: [
                              t.series.episodes(count: series.publishedContentCount),
                              if (date != null && date.isNotEmpty) t.watchlist.updated(date: formatPixivDate(date)),
                            ],
                          ),
                          if (stacked) watch,
                        ],
                ),
              ),
              if (!stacked) watch,
            ],
          ),
        );
      },
    );
    if (hidden) return row;
    return FrostClickSurface(onTap: () => unawaited(GoRouter.of(context).push(AppLocations.series(kind, series.id))), child: row);
  }
}
