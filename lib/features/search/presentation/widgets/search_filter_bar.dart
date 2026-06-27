import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';

class SearchFilterButton extends ConsumerWidget {
  const SearchFilterButton({required this.type, this.allowTypeSelection = true, this.compact = false, super.key});

  final SearchType type;
  final bool allowTypeSelection;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimension = compact ? 32.0 : 44.0;
    final iconSize = compact ? 18.0 : 20.0;
    final tokens = FreepivThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = type != SearchType.user;

    if (compact) {
      return SizedBox.square(
        dimension: dimension,
        child: IconButton(
          tooltip: context.t.common.filter,
          onPressed: enabled ? () => _showFilterPanel(context) : null,
          icon: Icon(Icons.tune, size: iconSize, color: enabled ? colorScheme.onSurfaceVariant : colorScheme.onSurfaceVariant.withValues(alpha: 0.42)),
          iconSize: iconSize,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? Color.alphaBlend(tokens.brand.withValues(alpha: 0.055), tokens.surfaceRaised) : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox.square(
        dimension: dimension,
        child: IconButton(
          tooltip: context.t.common.filter,
          onPressed: enabled ? () => _showFilterPanel(context) : null,
          icon: Icon(Icons.tune, size: iconSize, color: enabled ? tokens.brand : colorScheme.onSurfaceVariant.withValues(alpha: 0.42)),
          iconSize: iconSize,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Future<void> _showFilterPanel(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final panel = SearchFilterPanel(type: type, allowTypeSelection: allowTypeSelection);

    if (mobile) {
      return showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) {
          final media = MediaQuery.of(context);
          final maxHeight = math.max(120.0, media.size.height - media.viewInsets.bottom - media.padding.top - 24);

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16 + MediaQuery.viewInsetsOf(context).bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: panel,
            ),
          );
        },
      );
    }

    return showDialog<void>(
      context: context,
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
            child: Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 24), child: panel),
          ),
        );
      },
    );
  }
}

class SearchFilterPanel extends ConsumerWidget {
  const SearchFilterPanel({required this.type, required this.allowTypeSelection, super.key});

  final SearchType type;
  final bool allowTypeSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFiltersProvider);
    final draft = ref.watch(searchDraftProvider);
    final activeType = allowTypeSelection ? draft.type : type;
    final activeFilter = switch (activeType) {
      SearchType.illust => filters.illust,
      SearchType.novel => filters.novel,
      SearchType.user => const SearchFilterState(),
    };

    void setType(SearchType next) {
      ref.read(searchDraftProvider.notifier).setDraft(draft.copyWith(type: next));
    }

    void setFilter(SearchFilterState next) {
      ref.read(searchFiltersProvider.notifier).setFilter(activeType, next);
    }

    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(context.t.search.filters.title, style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (allowTypeSelection) ...[
              const SizedBox(height: 14),
              _SectionTitle(icon: Icons.category_outlined, label: context.t.common.type),
              const SizedBox(height: 8),
              SegmentedButton<SearchType>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: SearchType.illust, icon: const Icon(Icons.image_outlined), label: Text(context.t.search.type.illustManga)),
                  ButtonSegment(value: SearchType.novel, icon: const Icon(Icons.menu_book_outlined), label: Text(context.t.search.type.novel)),
                  ButtonSegment(value: SearchType.user, icon: const Icon(Icons.person_outline), label: Text(context.t.search.type.user)),
                ],
                selected: {activeType},
                onSelectionChanged: (selection) => setType(selection.single),
                style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact, textStyle: Theme.of(context).textTheme.labelMedium),
              ),
            ],
            if (activeType != SearchType.user) ...[
              const SizedBox(height: 20),
              _SectionTitle(icon: Icons.sort_outlined, label: context.t.search.filters.sort),
              const SizedBox(height: 8),
              _ChoiceWrap<SearchSort>(
                value: activeFilter.sort,
                values: SearchSort.values,
                labelBuilder: (value) => _sortLabel(context, value),
                onSelected: (value) {
                  setFilter(activeFilter.copyWith(sort: value));
                },
              ),
              const SizedBox(height: 18),
              _SectionTitle(icon: Icons.track_changes_outlined, label: context.t.search.filters.target),
              const SizedBox(height: 8),
              _ChoiceWrap<SearchTarget>(
                value: activeFilter.target,
                values: SearchTarget.values,
                labelBuilder: (value) => _targetLabel(context, value),
                onSelected: (value) {
                  setFilter(activeFilter.copyWith(target: value));
                },
              ),
              const SizedBox(height: 18),
              _SectionTitle(icon: Icons.date_range_outlined, label: context.t.search.filters.date),
              const SizedBox(height: 8),
              _ChoiceWrap<SearchDatePreset>(
                value: activeFilter.datePreset,
                values: SearchDatePreset.values,
                labelBuilder: (value) => _datePresetLabel(context, value),
                onSelected: (value) {
                  if (value == SearchDatePreset.custom) {
                    _pickDateRange(context, activeFilter, setFilter);
                    return;
                  }
                  setFilter(activeFilter.copyWith(datePreset: value, customStart: null, customEnd: null));
                },
              ),
              if (activeFilter.datePreset == SearchDatePreset.custom && activeFilter.customStart != null && activeFilter.customEnd != null) ...[
                const SizedBox(height: 8),
                Text(_dateLabel(context, activeFilter), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 18),
              _SectionTitle(icon: Icons.bookmark_outline, label: context.t.search.filters.bookmarks),
              const SizedBox(height: 8),
              _ChoiceWrap<int>(
                value: activeFilter.bookmarkTotal ?? 0,
                values: searchBookmarkTotalOptions,
                labelBuilder: (value) => _bookmarkLabel(context, value == 0 ? null : value),
                onSelected: (value) {
                  setFilter(activeFilter.copyWith(bookmarkTotal: value == 0 ? null : value));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({required this.value, required this.values, required this.labelBuilder, required this.onSelected});

  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final item in values) ChoiceChip(label: Text(labelBuilder(item)), selected: item == value, onSelected: (_) => onSelected(item))],
    );
  }
}

Future<void> _pickDateRange(BuildContext context, SearchFilterState filter, ValueChanged<SearchFilterState> onChanged) async {
  final today = DateTime.now();
  final end = filter.customEnd ?? DateTime(today.year, today.month, today.day);
  final start = filter.customStart ?? end.subtract(const Duration(days: 30));
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2007),
    lastDate: end.isAfter(today) ? end : today,
    initialDateRange: DateTimeRange(start: start, end: end),
  );

  if (picked == null) {
    return;
  }

  onChanged(filter.copyWith(datePreset: SearchDatePreset.custom, customStart: picked.start, customEnd: picked.end));
}

String _sortLabel(BuildContext context, SearchSort value) {
  return switch (value) {
    SearchSort.dateDesc => context.t.search.sort.newest,
    SearchSort.dateAsc => context.t.search.sort.oldest,
    SearchSort.popularDesc => context.t.search.sort.popular,
  };
}

String _targetLabel(BuildContext context, SearchTarget value) {
  return switch (value) {
    SearchTarget.partialMatchForTags => context.t.search.target.tags,
    SearchTarget.exactMatchForTags => context.t.search.target.exactTags,
    SearchTarget.titleAndCaption => context.t.search.target.titleAndCaption,
  };
}

String _dateLabel(BuildContext context, SearchFilterState filter) {
  if (filter.datePreset != SearchDatePreset.custom || filter.customStart == null || filter.customEnd == null) {
    return _datePresetLabel(context, filter.datePreset);
  }

  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatShortDate(filter.customStart!)} - '
      '${localizations.formatShortDate(filter.customEnd!)}';
}

String _datePresetLabel(BuildContext context, SearchDatePreset value) {
  return switch (value) {
    SearchDatePreset.any => context.t.search.date.any,
    SearchDatePreset.day => context.t.search.date.today,
    SearchDatePreset.week => context.t.search.date.days7,
    SearchDatePreset.month => context.t.search.date.month1,
    SearchDatePreset.halfYear => context.t.search.date.months6,
    SearchDatePreset.year => context.t.search.date.year1,
    SearchDatePreset.custom => context.t.search.date.custom,
  };
}

String _bookmarkLabel(BuildContext context, int? value) {
  if (value == null) {
    return context.t.search.bookmarks.any;
  }
  return context.t.search.bookmarks.atLeast(count: value);
}
