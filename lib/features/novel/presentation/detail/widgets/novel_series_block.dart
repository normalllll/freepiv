import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/novel/logic/novel_series_progress.dart';
import 'package:freepiv/features/series/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/core/history/history_models.dart' show ReadingProgress;
import 'package:freepiv/ui/compositions/skeletons.dart' show appBones, novelPlaceholder;
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// Where the novel stands in its series: the series' title and state, the
/// novel and its neighbours with the reading progress of each, and the way to
/// the whole series. The first page of the series' works is all it reads.
class NovelSeriesBlock extends ConsumerStatefulWidget {
  const NovelSeriesBlock({required this.novel, required this.seriesId, required this.title, super.key});

  final Novel novel;
  final int seriesId;
  final String title;

  /// Rows shown: the novel with two neighbours either side.
  static const rows = 5;

  @override
  ConsumerState<NovelSeriesBlock> createState() => _NovelSeriesBlockState();
}

class _NovelSeriesBlockState extends ConsumerState<NovelSeriesBlock> {
  NovelSeriesSource? _started;

  void _start(NovelSeriesSource source) {
    if (identical(_started, source)) return;
    _started = source;
    if (!source.initialized && !source.busy) unawaited(source.refresh(true));
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(novelSeriesWorksProvider(widget.seriesId));
    _start(source);
    return ListenableBuilder(listenable: Listenable.merge([source, source.summary]), builder: (context, _) => _content(context, source));
  }

  void _openSeries() => unawaited(GoRouter.of(context).push(AppLocations.series(AppSeriesKind.novel, widget.seriesId)));

  Widget _content(BuildContext context, NovelSeriesSource source) {
    final t = context.t;
    final summary = source.summary.value;
    final works = source.items;
    switch (source.phase) {
      case FrostLoadPhase.loading:
        // The block's own layout as bones, so what arrives changes nothing
        // below it: the same header with its subtitle, the rows, the footer.
        return appBones(
          _frame(
            header: _header(context, 1, null, total: NovelSeriesBlock.rows, placeholder: true),
            body: _RowsView(novel: widget.novel, works: _placeholderWorks(), firstNumber: 1, progress: const {}),
            footer: FrostButton.quiet(label: t.novelDetail.allParts(count: NovelSeriesBlock.rows), onPressed: null),
          ),
        );
      case FrostLoadPhase.error:
        return _frame(
          header: _header(context, null, null),
          body: Row(
            children: [
              Expanded(
                child: FrostText(t.novelDetail.seriesFailed, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
              ),
              FrostButton.quiet(label: t.common.retry, onPressed: () => unawaited(source.errorRefresh())),
            ],
          ),
        );
      case FrostLoadPhase.empty:
        return _frame(
          header: _header(context, null, summary),
          body: FrostText(t.series.empty, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
        );
      case FrostLoadPhase.content:
        break;
    }
    final index = works.indexWhere((work) => work.id == widget.novel.id);
    final shown = _window(works, index);
    final total = summary?.workCount ?? works.length;
    return _frame(
      header: _header(context, index < 0 ? null : index + 1, summary, total: total),
      body: _Rows(novel: widget.novel, works: shown, firstNumber: works.indexOf(shown.first) + 1),
      footer: FrostButton.quiet(
        label: t.novelDetail.allParts(count: total),
        onPressed: _openSeries,
      ),
    );
  }

  /// What the rows show while the series loads: [NovelSeriesBlock.rows] of them.
  List<Novel> _placeholderWorks() => [for (var i = 0; i < NovelSeriesBlock.rows; i++) novelPlaceholder()];

  /// The novel with up to two works either side of it, moved along at either
  /// end of the list to keep [NovelSeriesBlock.rows] rows; the first works
  /// when it is not in the list.
  static List<Novel> _window(List<Novel> works, int index) {
    const rows = NovelSeriesBlock.rows;
    if (works.length <= rows) return works;
    final start = index < 0 ? 0 : (index - rows ~/ 2).clamp(0, works.length - rows);
    return works.sublist(start, start + rows);
  }

  Widget _frame({required Widget header, required Widget body, Widget? footer}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FrostGap.related,
    children: [
      header,
      body,
      if (footer != null) Align(alignment: AlignmentDirectional.centerEnd, child: footer),
    ],
  );

  /// The title, linking to the series; under it "Part X of Y" and whether it
  /// has finished, as far as they are known.
  Widget _header(BuildContext context, int? part, SeriesSummary? summary, {int? total, bool placeholder = false}) {
    final t = context.t;
    final concluded = placeholder ? false : summary?.concluded;
    final subtitle = [
      if (part != null && total != null) t.novelDetail.partOf(part: part, total: total) else if (total != null) t.series.episodes(count: total),
      if (concluded != null) concluded ? t.series.concluded : t.series.ongoing,
    ].join(' · ');
    return FrostListRow(
      leading: const FrostGlyph.icon(PivIcons.bookOpen),
      title: widget.title,
      contentTitle: true,
      subtitle: subtitle.isEmpty ? null : FrostRowSubtitle(subtitle),
      accessory: FrostRowAccessory.chevron,
      onPressed: _openSeries,
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows({required this.novel, required this.works, required this.firstNumber});

  final Novel novel;
  final List<Novel> works;

  /// The number of the first row in the series.
  final int firstNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(novelBatchReadingProgressProvider(NovelIdBatch([for (final work in works) work.id]))).value ?? const {};
    return _RowsView(novel: novel, works: works, firstNumber: firstNumber, progress: progress);
  }
}

/// The rows. Each leaves room for its reading-progress bar, shown or not, so
/// the progress arriving after the rows moves nothing.
class _RowsView extends StatelessWidget {
  const _RowsView({required this.novel, required this.works, required this.firstNumber, required this.progress});

  final Novel novel;
  final List<Novel> works;
  final int firstNumber;
  final Map<int, ReadingProgress> progress;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (offset, work) in works.indexed)
          Column(
            key: ValueKey('${work.id}-$offset'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostListRow(
                leading: FrostLeading.custom(FrostText('${firstNumber + offset}', role: FrostTextRole.callout, tone: FrostTextTone.secondary, tabular: true)),
                title: work.title,
                contentTitle: true,
                subtitle: FrostRowSubtitle(t.novel.detail.totalChars(count: formatCount(work.textLength))),
                selected: work.id == novel.id,
                onPressed: work.id == novel.id ? null : () => unawaited(GoRouter.of(context).push(AppLocations.novel(work.id), extra: work)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(FrostGap.rowInset, 0, FrostGap.rowInset, FrostGap.related),
                child: ExcludeSemantics(
                  excluding: progress[work.id] == null,
                  child: Opacity(
                    opacity: progress[work.id] == null ? 0 : 1,
                    child: FrostProgressBar(value: progress[work.id]?.fraction ?? 0, semanticLabel: t.novel.reader.readingProgress),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
