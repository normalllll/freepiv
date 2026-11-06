import 'package:flutter/material.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_autocomplete_session.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_suggestion.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SuggestionSurface extends StatelessWidget {
  const SuggestionSurface({required this.session, required this.maxHeight, required this.onSelected, this.selectedIndex = -1, super.key});

  final SearchAutocompleteSession session;
  final double maxHeight;
  final ValueChanged<SearchSuggestion> onSelected;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, child) {
        if (!session.hasSuggestionPanelContent) {
          return const SizedBox.shrink();
        }

        if (maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        return FrostSurface(
          role: FrostSurfaceRole.overlay,
          borderRadius: BorderRadius.circular(FrostRadius.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SuggestionPanelBody(session: session, selectedIndex: selectedIndex, onSelected: onSelected),
          ),
        );
      },
    );
  }
}

class SuggestionPanelBody extends StatelessWidget {
  const SuggestionPanelBody({required this.session, required this.onSelected, this.selectedIndex = -1, super.key});

  final SearchAutocompleteSession session;
  final ValueChanged<SearchSuggestion> onSelected;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, child) {
        final suggestions = session.suggestions;
        final error = session.error;

        return Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                    child: FrostCompactMessage(
                      icon: FrostIconData.glyph(Icons.error_outline),
                      message: formatPixivError(error),
                      details: pixivErrorDetails(error),
                      actionLabel: context.t.common.retry,
                      onAction: session.retry,
                    ),
                  ),
                Flexible(
                  child: suggestions.isEmpty
                      ? SizedBox(
                          height: _suggestionEmptyHeight(session),
                          child: SuggestionEmptyState(session: session),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.zero,
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            return SuggestionTile(
                              suggestion: suggestions[index],
                              selected: index == selectedIndex,
                              onTap: () => onSelected(suggestions[index]),
                            );
                          },
                        ),
                ),
              ],
            ),
            // Overlay loading feedback so the first row still reaches the edge.
            if (session.loading) Positioned(top: 0, left: 0, right: 0, child: PivSkeletonBlock(width: double.infinity, height: 2)),
          ],
        );
      },
    );
  }
}

class SuggestionEmptyState extends StatelessWidget {
  const SuggestionEmptyState({required this.session, super.key});

  final SearchAutocompleteSession session;

  @override
  Widget build(BuildContext context) {
    if (session.query.isEmpty) {
      return const SizedBox.shrink();
    }

    if (session.loading) {
      return const SuggestionLoadingRows();
    }

    if (session.error != null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          context.t.search.noSuggestions,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class SuggestionLoadingRows extends StatelessWidget {
  const SuggestionLoadingRows({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 3,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Bone.circle(size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Bone.text(width: 180), SizedBox(height: 8), Bone.text(width: 120)]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SuggestionTile extends StatelessWidget {
  const SuggestionTile({required this.suggestion, required this.onTap, this.selected = false, super.key});

  final SearchSuggestion suggestion;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = suggestion.subtitle;

    return ListTile(
      shape: const RoundedRectangleBorder(),
      dense: true,
      selected: selected,
      selectedTileColor: colorScheme.surfaceContainerHighest,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant,
        child: Icon(suggestion.icon, size: 19),
      ),
      title: Text(searchSuggestionLabel(context, suggestion), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null || subtitle.isEmpty ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}

double _suggestionEmptyHeight(SearchAutocompleteSession session) {
  if (session.query.isEmpty) {
    return 10;
  }

  if (session.loading) {
    return 176;
  }

  if (session.error != null) {
    return 78;
  }

  return 80;
}
