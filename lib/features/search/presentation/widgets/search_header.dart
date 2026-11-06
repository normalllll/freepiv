import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/features/search/presentation/widgets/search_filter_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_box.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

/// Where the search header offers the search type.
enum SearchTypePlacement {
  /// No type control.
  hidden,

  /// On the query's row in the sidebar layout; phones leave it out and search
  /// with the current type, switched on the results page.
  besideQuery,

  /// On the query's row in the sidebar layout; on phones a row of page tabs
  /// under the query, like the home page's type tabs.
  besideQueryOrTabs,
}

class SearchHeader extends ConsumerWidget {
  const SearchHeader({
    required this.onSearch,
    required this.onSelected,
    this.showBackButton = false,
    this.reserveBackButtonSpace = false,
    this.typePlacement = SearchTypePlacement.besideQueryOrTabs,
    this.showFilters = true,
    this.onBack,
    this.onTypeChanged,
    this.typeController,
    this.searchBoxKey,
    this.autofocusSearch = false,
    super.key,
  });

  final ValueChanged<SearchSubmission> onSearch;
  final ValueChanged<SearchSelection> onSelected;
  final bool showBackButton;
  final bool reserveBackButtonSpace;
  final SearchTypePlacement typePlacement;
  final bool showFilters;
  final VoidCallback? onBack;
  final ValueChanged<SearchType>? onTypeChanged;

  /// Drives the phone's type tabs when the page below swipes between types;
  /// the tabs then follow the page instead of the search draft.
  final TabController? typeController;
  final GlobalKey<SearchBoxState>? searchBoxKey;

  /// Focuses the search when the header first shows.
  final bool autofocusSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = FrostShellNavigationScope.maybeOf(context);
    final showLocalBack = showBackButton && !(navigation?.ownsBackControl ?? false);
    final draftType = ref.watch(searchDraftProvider.select((draft) => draft.type));
    final appliedFilters = ref.watch(searchFiltersProvider);
    final hasAppliedFilter =
        draftType != SearchType.user && (draftType == SearchType.novel ? appliedFilters.novel : appliedFilters.illust) != const SearchFilterState();
    final input = Row(
      children: [
        if (showLocalBack || (reserveBackButtonSpace && !(navigation?.ownsBackControl ?? false))) ...[
          // The compact back button reaches into the page margin so its arrow,
          // not its hit box, sits on the column edge, and the field gets the
          // width back.
          SizedBox(
            width: _backSlotWidth,
            height: FrostDensity.of(context).targetHeight,
            child: showLocalBack
                ? OverflowBox(
                    alignment: AlignmentDirectional.centerEnd,
                    minWidth: 40.0,
                    maxWidth: 40.0,
                    child: FrostCompactBackButton(onPressed: navigation?.goBack ?? onBack),
                  )
                : null,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: SearchBox(key: searchBoxKey, onSearch: onSearch, onSelected: onSelected, showFilters: showFilters, autofocus: autofocusSearch),
        ),
      ],
    );
    // Phones and the sidebar layout arrange the type differently rather than
    // squeezing one layout into both. Beside the sidebar the type shares the
    // query's row: spread-out segments only on a very wide desktop, where the
    // field stays long beside them; otherwise a dropdown at the row's end,
    // labelled while its widest label fits, else just the type's icon. A phone
    // row already holds the back button, the field and its filter action, so
    // the type moves below as page tabs (results) or is left to the results
    // page (discover).
    final sidebarLayout = FrostAutoScaffold.usesHorizontalLayoutOf(context);
    final besideQuery = sidebarLayout && typePlacement != SearchTypePlacement.hidden;
    final typeTabs = !sidebarLayout && typePlacement == SearchTypePlacement.besideQueryOrTabs;
    final showsType = besideQuery || typeTabs;
    final region = FrostSearchInputRegion(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaler = MediaQuery.textScalerOf(context);
          final segmented = constraints.maxWidth >= SearchTypeSelector.requiredWidth(context) + scaler.scale(_segmentsQueryWidth) + FrostGap.group;
          final menuWidth = SearchTypeMenuButton.labelledWidth(context);
          final labelledMenu = constraints.maxWidth >= menuWidth + scaler.scale(_minQueryWidth) + FrostGap.related;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (besideQuery)
                Row(
                  children: [
                    Expanded(child: input),
                    SizedBox(width: segmented ? FrostGap.group : FrostGap.related / 2),
                    if (segmented)
                      SearchTypeSelector(onChanged: onTypeChanged, fillWidth: false)
                    else if (labelledMenu)
                      // Sized for the widest label so switching types never
                      // moves the field's edge.
                      SizedBox(
                        width: menuWidth,
                        child: SearchTypeMenuButton(onChanged: onTypeChanged),
                      )
                    else
                      SearchTypeMenuButton(onChanged: onTypeChanged, iconOnly: true),
                  ],
                )
              else
                input,
              if (showsType && showFilters && hasAppliedFilter) const SearchFilterSummary(),
            ],
          );
        },
      ),
    );
    if (!typeTabs) return region;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        region,
        SearchTypeTabs(onChanged: onTypeChanged, controller: typeController),
      ],
    );
  }
}

/// Narrowest query field a type dropdown may leave beside it.
const _minQueryWidth = 240.0;

/// The field length the spread-out segments must still leave: segments are
/// for very wide desktop rows, where they do not crowd the query.
const _segmentsQueryWidth = 480.0;

/// Layout width of the compact back button in the query row; the button
/// itself is [40.0] and reaches past it into the margin.
const _backSlotWidth = 31.0;

const _searchTypes = [SearchType.illust, SearchType.novel, SearchType.user];

/// The search type as page tabs under a phone's query row, styled and inset
/// like the home page's type tabs.
class SearchTypeTabs extends ConsumerStatefulWidget {
  const SearchTypeTabs({this.onChanged, this.controller, super.key});

  final ValueChanged<SearchType>? onChanged;
  final TabController? controller;

  @override
  ConsumerState<SearchTypeTabs> createState() => _SearchTypeTabsState();
}

class _SearchTypeTabsState extends ConsumerState<SearchTypeTabs> with SingleTickerProviderStateMixin {
  late final TabController? _ownController = widget.controller == null
      ? TabController(length: _searchTypes.length, initialIndex: _searchTypes.indexOf(ref.read(searchDraftProvider).type), vsync: this)
      : null;

  TabController get _controller => widget.controller ?? _ownController!;

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null) {
      ref.listen(searchDraftProvider.select((draft) => draft.type), (_, type) {
        final index = _searchTypes.indexOf(type);
        if (_controller.index != index) _controller.animateTo(index);
      });
    }
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsets.symmetric(horizontal: FrostMetrics.pageTabInset(constraints.maxWidth)),
        child: FrostTabBar(
          controller: _controller,
          scrollable: true,
          tabs: [
            FrostTab(label: context.t.search.type.illustManga),
            FrostTab(label: context.t.search.type.novel),
            FrostTab(label: context.t.search.type.user),
          ],
          onTap: (index) {
            final next = _searchTypes[index];
            // With a page-driven controller the tab bar already moves the page.
            if (widget.controller == null) {
              final draft = ref.read(searchDraftProvider);
              ref.read(searchDraftProvider.notifier).setDraft(draft.copyWith(type: next));
            }
          },
        ),
      ),
    );
  }
}

/// The search type as a dropdown at the end of the query row, for rows short
/// of the very wide desktop that shows the segments: the trigger shows the
/// current type's name, or with [iconOnly] just its icon; the menu lists the
/// full names.
class SearchTypeMenuButton extends ConsumerWidget {
  const SearchTypeMenuButton({this.onChanged, this.iconOnly = false, super.key});

  final ValueChanged<SearchType>? onChanged;
  final bool iconOnly;

  /// Width of the labelled trigger with its widest label in the text button
  /// weight: 12 padding on both sides, the 2 gap and the 18 chevron.
  static double labelledWidth(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    var widest = 0.0;
    for (final label in [context.t.search.type.illustManga, context.t.search.type.novel, context.t.search.type.user]) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    return (widest + 24 + 2 + 18 + 1).ceilToDouble();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(searchDraftProvider);
    return FrostPicker<SearchType>.menu(
      label: context.t.common.type,
      value: draft.type,
      options: [
        FrostPickerOption(
          value: SearchType.illust,
          label: context.t.search.type.illustManga,
          leading: FrostGlyph.icon(FrostIconData.glyph(Icons.image_outlined)),
        ),
        FrostPickerOption(value: SearchType.novel, label: context.t.search.type.novel, leading: FrostGlyph.icon(FrostIconData.glyph(Icons.menu_book_outlined))),
        FrostPickerOption(value: SearchType.user, label: context.t.search.type.user, leading: FrostGlyph.icon(FrostIconData.glyph(Icons.person_outline))),
      ],
      onChanged: (next) {
        if (onChanged case final callback?) {
          callback(next);
        } else {
          ref.read(searchDraftProvider.notifier).setDraft(draft.copyWith(type: next));
        }
      },
    );
  }
}

class SearchTypeSelector extends ConsumerWidget {
  const SearchTypeSelector({this.onChanged, this.fillWidth = true, super.key});
  final ValueChanged<SearchType>? onChanged;
  final bool fillWidth;

  static double requiredWidth(BuildContext context) {
    final labels = [context.t.search.type.illustManga, context.t.search.type.novel, context.t.search.type.user];
    // Measured in the selected weight, the widest a label gets.
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    var widestLabel = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      widestLabel = math.max(widestLabel, painter.width);
      painter.dispose();
    }
    // Segments share the widest label's width: each adds its 12 padding on
    // both sides, the icon and the 6 gap; the track adds 3 on each side.
    return labels.length * (widestLabel + 24 + FrostControlSize.regular.iconSize + 6) + 6 + 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(searchDraftProvider);

    final button = FrostPicker<SearchType>.segmented(
      label: context.t.common.type,
      options: [
        FrostPickerOption(
          value: SearchType.illust,
          leading: const FrostGlyph.icon(FrostIconData.glyph(Icons.image_outlined)),
          label: context.t.search.type.illustManga,
        ),
        FrostPickerOption(
          value: SearchType.novel,
          leading: const FrostGlyph.icon(FrostIconData.glyph(Icons.menu_book_outlined)),
          label: context.t.search.type.novel,
        ),
        FrostPickerOption(value: SearchType.user, leading: const FrostGlyph.icon(FrostIconData.glyph(Icons.person_outline)), label: context.t.search.type.user),
      ],
      value: draft.type,
      onChanged: (selection) {
        if (onChanged case final callback?) {
          callback(selection);
        } else {
          ref.read(searchDraftProvider.notifier).setDraft(draft.copyWith(type: selection));
        }
      },
    );
    // On its own row the selector spans the width; labels wrap instead of
    // scrolling segments out of view.
    return fillWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
