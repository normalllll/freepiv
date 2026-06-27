import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_autocomplete_session.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_suggestion.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SuggestionSurface extends StatelessWidget {
  const SuggestionSurface({required this.session, required this.maxHeight, required this.onSelected, super.key});

  final SearchAutocompleteSession session;
  final double maxHeight;
  final ValueChanged<SearchSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: session,
      builder: (context, child) {
        if (!session.hasSuggestionPanelContent) {
          return const SizedBox.shrink();
        }

        final height = suggestionHeight(context, session, maxHeight);
        if (height <= 0) {
          return const SizedBox.shrink();
        }

        return Material(
          elevation: 3,
          color: colorScheme.surface,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: height,
            child: SuggestionPanelBody(session: session, onSelected: onSelected),
          ),
        );
      },
    );
  }
}

class SuggestionPanelBody extends StatelessWidget {
  const SuggestionPanelBody({required this.session, required this.onSelected, super.key});

  final SearchAutocompleteSession session;
  final ValueChanged<SearchSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, child) {
        final suggestions = session.suggestions;
        final error = session.error;

        return Column(
          children: [
            SizedBox(height: 2, child: session.loading ? const LinearProgressIndicator(minHeight: 2) : null),
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                child: CompactMessage(
                  icon: Icons.error_outline,
                  message: formatPixivError(error),
                  actionLabel: context.t.common.retry,
                  onAction: session.retry,
                ),
              ),
            Expanded(
              child: suggestions.isEmpty
                  ? SuggestionEmptyState(session: session)
                  : ListView.separated(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: suggestions.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 2);
                      },
                      itemBuilder: (context, index) {
                        return SuggestionTile(suggestion: suggestions[index], onTap: () => onSelected(suggestions[index]));
                      },
                    ),
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
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
  const SuggestionTile({required this.suggestion, required this.onTap, super.key});

  final SearchSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = suggestion.subtitle;

    return ListTile(
      dense: true,
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

double suggestionHeight(BuildContext context, SearchAutocompleteSession session, double maxHeight) {
  final suggestions = session.suggestions;
  if (maxHeight <= 0) {
    return 0;
  }

  if (suggestions.isEmpty) {
    if (session.query.isEmpty) {
      return math.min(maxHeight, 10);
    }

    if (session.loading) {
      return math.min(maxHeight, 176);
    }

    if (session.error != null) {
      return math.min(maxHeight, 78);
    }

    return math.min(maxHeight, 80);
  }

  final statusHeight = session.error == null ? 0.0 : 58.0;
  final listHeight = suggestions.length * 58.0 + 18.0;
  return math.min(maxHeight, statusHeight + listHeight + 2);
}
