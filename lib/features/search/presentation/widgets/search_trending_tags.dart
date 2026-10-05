import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/search/logic/search_trending_tags_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SearchTrendingTagsSliver extends ConsumerWidget {
  const SearchTrendingTagsSliver({required this.onTagSelected, super.key});

  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingTags = ref.watch(searchTrendingTagsProvider);
    final trendTags = trendingTags.value ?? const <TrendTag>[];
    // Riverpod retries failed providers; a retry is "loading with an error",
    // so the error must win over the skeleton or a failure looks endless.
    final error = trendingTags.error;
    if (error != null && trendTags.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: FrostErrorContent.fromError(
          error: error,
          onRetry: () => unawaited(ref.read(searchTrendingTagsProvider.notifier).reload(keepPreviousData: false)),
        ),
      );
    }

    if (trendingTags.isLoading && trendTags.isEmpty) {
      return const _TrendingTagGridSkeleton();
    }

    if (trendTags.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: FrostEmptyContent(
          icon: FrostIconData.glyph(Icons.tag_outlined),
          title: context.t.search.emptyTrendingTitle,
          message: context.t.search.emptyTrendingMessage,
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, outerConstraints) {
        return SliverPadding(
          padding: FrostMetrics.columnPadding(outerConstraints.crossAxisExtent).copyWith(bottom: 24),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              return SliverGrid.builder(
                itemCount: trendTags.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _gridMaxExtent(constraints.crossAxisExtent),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final trendTag = trendTags[index];
                  return _TrendingTagCard(trendTag: trendTag, onTap: () => onTagSelected(trendTag.tag));
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _TrendingTagCard extends StatelessWidget {
  const _TrendingTagCard({required this.trendTag, required this.onTap});

  final TrendTag trendTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final translatedName = trendTag.translatedName;
    final accent = _trendAccent(context);

    return FrostCard(
      accentColor: accent,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.34), BlendMode.multiply),
            child: PixivImage(url: trendTag.illust.imageUrls.squareMedium, fit: BoxFit.cover),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x66000000), Color(0xC0000000)],
                stops: [0.38, 0.72, 1],
              ),
            ),
          ),
          PositionedDirectional(
            start: 14,
            end: 14,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#${trendTag.tag}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                if (translatedName != null && translatedName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    translatedName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingTagGridSkeleton extends StatelessWidget {
  const _TrendingTagGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, outerConstraints) {
        return SliverPadding(
          padding: FrostMetrics.columnPadding(outerConstraints.crossAxisExtent).copyWith(bottom: 24),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              return SliverGrid.builder(
                itemCount: 12,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _gridMaxExtent(constraints.crossAxisExtent),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  return const _TrendingTagSkeletonCard();
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _TrendingTagSkeletonCard extends StatelessWidget {
  const _TrendingTagSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Bone(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(8)),
          const PositionedDirectional(
            start: 14,
            end: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [Bone.text(width: 140), SizedBox(height: 8), Bone.text(width: 96)],
            ),
          ),
        ],
      ),
    );
  }
}

double _gridMaxExtent(double width) {
  if (width < 420) {
    return 220;
  }

  if (width < 900) {
    return 260;
  }

  return 286;
}

Color _trendAccent(BuildContext context) {
  final tokens = FrostThemeTokens.of(context);
  return tokens.accent;
}
