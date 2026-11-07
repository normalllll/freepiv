import 'package:flutter/widgets.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:frost_ui/frost_ui.dart';

/// The labels of the search filter values, shared by the panel and the
/// filter bar.
extension SearchFilterLabels on Translations {
  String order(SearchOrder order) => switch (order) {
    SearchOrder.newest => search.sort.newest,
    SearchOrder.oldest => search.sort.oldest,
    SearchOrder.popularPreview => search.sort.popularPreview,
  };

  String target(SearchTarget target) => switch (target) {
    SearchTarget.partialMatchForTags => search.target.tags,
    SearchTarget.exactMatchForTags => search.target.exactTags,
    SearchTarget.titleAndCaption => search.target.titleAndCaption,
  };

  String novelTarget(SearchNovelTarget target) => switch (target) {
    SearchNovelTarget.partialMatchForTags => search.target.tags,
    SearchNovelTarget.exactMatchForTags => search.target.exactTags,
    SearchNovelTarget.text => search.target.text,
    SearchNovelTarget.keyword => search.target.keyword,
  };

  String datePreset(SearchDatePreset preset) => switch (preset) {
    SearchDatePreset.any => search.date.any,
    SearchDatePreset.day => search.date.today,
    SearchDatePreset.week => search.date.days7,
    SearchDatePreset.month => search.date.month1,
    SearchDatePreset.halfYear => search.date.months6,
    SearchDatePreset.year => search.date.year1,
    SearchDatePreset.custom => search.date.custom,
  };

  String bookmarkTotal(int? total) => total == null || total == 0 ? search.bookmarks.any : search.bookmarks.tagged(count: total);

  String contentType(SearchContentType? type) => switch (type) {
    null => search.contentType.any,
    SearchContentType.illust => search.contentType.illust,
    SearchContentType.manga => search.contentType.manga,
    SearchContentType.ugoira => search.contentType.ugoira,
    SearchContentType.illustAndUgoira => search.contentType.illustAndUgoira,
    SearchContentType.illustAndMangaAndUgoira => search.contentType.all,
  };

  String ratio(SearchRatio? ratio) => switch (ratio) {
    null => search.ratio.any,
    SearchRatio.landscape => search.ratio.landscape,
    SearchRatio.portrait => search.ratio.portrait,
    SearchRatio.square => search.ratio.square,
  };
}

/// The search filter panel: match, date (with a custom
/// range of at most a year), bookmark tag, and for illustrations outside a
/// popular preview the work type, shape, minimum size and tool. Nothing
/// reaches the search until Apply; Reset clears the draft.
class SearchFilterPanel extends StatefulWidget {
  const SearchFilterPanel({required this.type, required this.filter, required this.onApply, required this.onCancel, this.now, super.key});

  final SearchType type;
  final SearchFilterState filter;
  final ValueChanged<SearchFilterState> onApply;
  final VoidCallback onCancel;

  /// Today, for the custom range's limits; the clock by default.
  final DateTime? now;

  /// The widest the panel's popover gets, with two columns inside.
  static const popoverWidth = 560.0;

  /// The windows that fit two columns: above Frost's switch to a sheet.
  static const twoColumnsFrom = 640.0;

  /// From this text scale the labels need a whole line.
  static const oneColumnTextScale = 1.5;

  /// The two columns' width, inside the popover's inset. Fixed, because the
  /// popover measures its content by intrinsic width.
  static const twoColumnsWidth = 528.0;

  /// Decided from the window, since the popover measures with IntrinsicWidth.
  static bool usesTwoColumns(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= twoColumnsFrom && MediaQuery.textScalerOf(context).scale(1) < oneColumnTextScale;

  @override
  State<SearchFilterPanel> createState() => _SearchFilterPanelState();
}

class _SearchFilterPanelState extends State<SearchFilterPanel> {
  late SearchFilterState _draft = widget.filter;
  late final _tool = TextEditingController(text: widget.filter.tool ?? '');

  @override
  void dispose() {
    _tool.dispose();
    super.dispose();
  }

  void _set(SearchFilterState Function(SearchFilterState draft) change) => setState(() => _draft = change(_draft));

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final now = widget.now ?? DateTime.now();
    final illust = widget.type == SearchType.illust;
    final illustOnly = illust && !_draft.isPopularPreview;
    Widget picker<T>(String label, T value, List<T> values, String Function(T) name, ValueChanged<T> onChanged) => FrostPicker<T>.menu(
      label: label,
      value: value,
      options: [for (final value in values) FrostPickerOption(value: value, label: name(value))],
      onChanged: onChanged,
    );
    final target = illust
        ? picker(t.search.filters.target, _draft.target, SearchTarget.values, t.target, (value) => _set((draft) => draft.copyWith(target: value)))
        : picker(
            t.search.filters.target,
            _draft.novelTarget,
            SearchNovelTarget.values,
            t.novelTarget,
            (value) => _set((draft) => draft.copyWith(novelTarget: value)),
          );
    final date = picker(
      t.search.filters.date,
      _draft.datePreset,
      SearchDatePreset.values,
      t.datePreset,
      (value) => _set((draft) => draft.copyWith(datePreset: value)),
    );
    final bookmarks = picker(
      t.search.filters.bookmarks,
      _draft.bookmarkTotal ?? 0,
      searchBookmarkTotalOptions,
      t.bookmarkTotal,
      (value) => _set((draft) => draft.copyWith(bookmarkTotal: value == 0 ? null : value)),
    );
    final contentType = picker<SearchContentType?>(
      t.search.filters.contentType,
      _draft.contentType,
      [null, ...SearchContentType.values],
      t.contentType,
      (value) => _set((draft) => draft.copyWith(contentType: value)),
    );
    final ratio = picker<SearchRatio?>(
      t.search.filters.ratio,
      _draft.ratio,
      [null, ...SearchRatio.values],
      t.ratio,
      (value) => _set((draft) => draft.copyWith(ratio: value)),
    );
    final minWidth = picker<int?>(
      t.searchPage.minWidth,
      _draft.minWidth,
      [null, ...searchMinSizeOptions],
      (px) => px == null ? t.search.size.any : t.search.size.minWidth(px: px),
      (value) => _set((draft) => draft.copyWith(minWidth: value)),
    );
    final minHeight = picker<int?>(
      t.searchPage.minHeight,
      _draft.minHeight,
      [null, ...searchMinSizeOptions],
      (px) => px == null ? t.search.size.any : t.search.size.minHeight(px: px),
      (value) => _set((draft) => draft.copyWith(minHeight: value)),
    );
    final tool = FrostTextField(
      label: t.search.filters.tool,
      controller: _tool,
      placeholder: t.search.filters.toolHint,
      onChanged: (value) => _set((draft) => draft.copyWith(tool: value)),
    );
    final twoColumns = SearchFilterPanel.usesTwoColumns(context);
    // One filter on a line of two keeps to its own column.
    Widget cells(Widget first, [Widget? second]) => !twoColumns
        ? (second == null ? first : Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: FrostGap.related, children: [first, second]))
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FrostGap.group,
            children: [
              Expanded(child: first),
              Expanded(child: second ?? const SizedBox.shrink()),
            ],
          );
    final panel = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.related,
      children: [
        cells(target, date),
        if (_draft.datePreset == SearchDatePreset.custom)
          FrostDateRangePicker(
            label: t.search.date.custom,
            help: t.search.date.pickerHelp,
            showsYear: true,
            firstDate: DateTime(now.year - 20),
            lastDate: now,
            value: _draft.customStart == null || _draft.customEnd == null ? null : DateTimeRange(start: _draft.customStart!, end: _draft.customEnd!),
            onChanged: (range) => _set((draft) {
              if (range == null) return draft.copyWith(customStart: null, customEnd: null);
              final (start, end) = clampSearchRange(range.start, range.end);
              return draft.copyWith(customStart: start, customEnd: end);
            }),
          ),
        cells(bookmarks, illustOnly ? contentType : null),
        if (illustOnly) ...[cells(ratio, tool), cells(minWidth, minHeight)],
        if (_draft.isPopularPreview) FrostText(t.search.filters.previewNote, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
        // Reset at the start and the answers at the end; large text wraps them.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: FrostGap.related,
          runSpacing: FrostGap.related,
          children: [
            FrostButton.quiet(
              label: t.common.reset,
              onPressed: () {
                _tool.clear();
                setState(() => _draft = SearchFilterState(order: _draft.order));
              },
            ),
            Wrap(
              spacing: FrostGap.related,
              runSpacing: FrostGap.related,
              children: [
                FrostButton(label: t.common.cancel, role: FrostButtonRole.cancel, onPressed: widget.onCancel),
                FrostButton.prominent(label: t.common.apply, onPressed: () => widget.onApply(_draft)),
              ],
            ),
          ],
        ),
      ],
    );
    return twoColumns ? SizedBox(width: SearchFilterPanel.twoColumnsWidth, child: panel) : panel;
  }
}

/// The filters in effect, for the bar over the results: each one apart
/// from the defaults, with a way to clear it.
List<({String label, String value, SearchFilterState cleared})> activeSearchFilters(Translations t, SearchType type, SearchFilterState filter) {
  const none = SearchFilterState();
  final illust = type == SearchType.illust;
  return [
    if (illust && filter.target != none.target) (label: t.search.filters.target, value: t.target(filter.target), cleared: filter.copyWith(target: none.target)),
    if (!illust && filter.novelTarget != none.novelTarget)
      (label: t.search.filters.target, value: t.novelTarget(filter.novelTarget), cleared: filter.copyWith(novelTarget: none.novelTarget)),
    if (filter.datePreset != SearchDatePreset.any)
      (
        label: t.search.filters.date,
        value: t.datePreset(filter.datePreset),
        cleared: filter.copyWith(datePreset: SearchDatePreset.any, customStart: null, customEnd: null),
      ),
    if (filter.bookmarkTotal != null)
      (label: t.search.filters.bookmarks, value: t.bookmarkTotal(filter.bookmarkTotal), cleared: filter.copyWith(bookmarkTotal: null)),
    if (illust && filter.contentType != null)
      (label: t.search.filters.contentType, value: t.contentType(filter.contentType), cleared: filter.copyWith(contentType: null)),
    if (illust && filter.ratio != null) (label: t.search.filters.ratio, value: t.ratio(filter.ratio), cleared: filter.copyWith(ratio: null)),
    if (illust && filter.minWidth != null)
      (label: t.search.filters.size, value: t.search.size.minWidth(px: filter.minWidth!), cleared: filter.copyWith(minWidth: null)),
    if (illust && filter.minHeight != null)
      (label: t.search.filters.size, value: t.search.size.minHeight(px: filter.minHeight!), cleared: filter.copyWith(minHeight: null)),
    if (illust && (filter.tool?.trim().isNotEmpty ?? false)) (label: t.search.filters.tool, value: filter.tool!.trim(), cleared: filter.copyWith(tool: null)),
  ];
}
