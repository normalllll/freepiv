import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_box.dart';
import 'package:freepiv/i18n/strings.g.dart';

class SearchHeader extends ConsumerWidget {
  const SearchHeader({
    required this.onSearch,
    required this.onSelected,
    this.showBackButton = false,
    this.reserveBackButtonSpace = false,
    this.showTypeSelector = true,
    this.compact = false,
    this.onBack,
    this.searchBoxKey,
    super.key,
  });

  final ValueChanged<SearchSubmission> onSearch;
  final ValueChanged<SearchSelection> onSelected;
  final bool showBackButton;
  final bool reserveBackButtonSpace;
  final bool showTypeSelector;
  final bool compact;
  final VoidCallback? onBack;
  final GlobalKey<SearchBoxState>? searchBoxKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: compact ? const EdgeInsets.fromLTRB(12, 4, 12, 4) : const EdgeInsets.fromLTRB(12, 6, 12, 7),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (showBackButton || reserveBackButtonSpace) ...[
                    SizedBox.square(
                      dimension: 44,
                      child: showBackButton
                          ? IconButton(tooltip: MaterialLocalizations.of(context).backButtonTooltip, onPressed: onBack, icon: const Icon(Icons.arrow_back))
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: SearchBox(key: searchBoxKey, onSearch: onSearch, onSelected: onSelected),
                  ),
                ],
              ),
              if (showTypeSelector) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: showBackButton || reserveBackButtonSpace ? 48 : 0),
                  child: const Center(child: SearchTypeSelector()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SearchTypeSelector extends ConsumerWidget {
  const SearchTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(searchDraftProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<SearchType>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: SearchType.illust, icon: const Icon(Icons.image_outlined, size: 17), label: Text(context.t.search.type.illustManga)),
          ButtonSegment(value: SearchType.novel, icon: const Icon(Icons.menu_book_outlined, size: 17), label: Text(context.t.search.type.novel)),
          ButtonSegment(value: SearchType.user, icon: const Icon(Icons.person_outline, size: 17), label: Text(context.t.search.type.user)),
        ],
        selected: {draft.type},
        onSelectionChanged: (selection) {
          ref.read(searchDraftProvider.notifier).setDraft(draft.copyWith(type: selection.single));
        },
        style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact, textStyle: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}
