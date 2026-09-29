import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/content_script.dart';
import 'dart:math' as math;
import 'package:html/parser.dart' as html_parser;
import 'package:skeletonizer/skeletonizer.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/energetic_card.dart';
import 'package:freepiv/shared/widgets/illust_bookmark_button.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

class NovelPreviewer extends StatelessWidget {
  const NovelPreviewer({required this.novel, this.onTap, this.rank, this.maxWidth = AppMetrics.contentMaxWidth, super.key});

  final Novel novel;
  final int? rank;
  final VoidCallback? onTap;
  final double? maxWidth;

  static double contentHeight(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Horizontal recommendation strips must reserve two title lines. Ordinary
    // list cards remain content-sized, including accessibility text scaling.
    return math.max(
      AppMetrics.novelCoverHeight,
      _lineHeight(context, text.titleSmall!) * 2 +
          _lineHeight(context, text.bodySmall!) * 3 +
          _tagHeight(context) +
          _lineHeight(context, text.labelSmall!) +
          34,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _novelAccent(context);
    final card = EnergeticCard(
      accentColor: accent,
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppMetrics.novelCoverHeight),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                NovelCoverImage(url: novel.imageUrls.medium, width: AppMetrics.novelCoverWidth, height: AppMetrics.novelCoverHeight),
                if (rank case final number?)
                  PositionedDirectional(
                    start: 4,
                    top: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: FreepivThemeTokens.of(context).surfaceRaised, borderRadius: BorderRadius.circular(6)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Text('#$number', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(child: _NovelPreviewBody(novel: novel)),
            const SizedBox(width: 8),
            IllustBookmarkButton(illustId: novel.id, initialIsBookmarked: novel.isBookmarked, isNovel: true),
          ],
        ),
      ),
    );

    final maxWidth = this.maxWidth;
    if (maxWidth == null) {
      return card;
    }

    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: card,
      ),
    );
  }
}

class NovelPreviewerSkeleton extends StatelessWidget {
  const NovelPreviewerSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppMetrics.contentMaxWidth),
      child: Skeletonizer.zone(
        child: EnergeticCard(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: NovelPreviewer.contentHeight(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(width: AppMetrics.novelCoverWidth, height: AppMetrics.novelCoverHeight, borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.text(width: double.infinity),
                      SizedBox(height: 12),
                      Bone.text(width: 120),
                      SizedBox(height: 12),
                      Bone.text(width: 160),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Bone.circle(size: AppMetrics.controlHeight),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class NovelCoverImage extends StatelessWidget {
  const NovelCoverImage({
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppMetrics.controlRadius)),
    super.key,
  });

  final String url;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: tokens.surfaceMuted, borderRadius: borderRadius),
        child: url.trim().isEmpty
            ? Center(child: Icon(Icons.menu_book_outlined, size: 28, color: tokens.textSecondary))
            : PixivImage(url: url, fit: BoxFit.cover, borderRadius: borderRadius),
      ),
    );
  }
}

class NovelTagChips extends StatelessWidget {
  const NovelTagChips({required this.tags, this.maxTags = 5, this.compact = false, super.key});

  final List<Tag> tags;
  final int maxTags;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleTags = tags.take(maxTags).toList(growable: false);
    final hiddenCount = tags.length - visibleTags.length;

    return Wrap(
      spacing: compact ? 5 : 6,
      runSpacing: compact ? 5 : 6,
      children: [
        for (final tag in visibleTags) _NovelTagChip(label: _tagLabel(tag), compact: compact),
        if (hiddenCount > 0) _NovelTagChip(label: '+$hiddenCount', compact: compact),
      ],
    );
  }
}

class _NovelPreviewBody extends StatelessWidget {
  const _NovelPreviewBody({required this.novel});

  final Novel novel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = t;
    final caption = _previewCaption(novel.caption);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppMetrics.novelCoverHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            novel.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: contentTextStyle(context, novel.title, Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 4),
          Text(
            novel.user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
          if (novel.tags.isNotEmpty) ...[const SizedBox(height: 7), _NovelPreviewTags(tags: novel.tags)],
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 6,
              children: [
                _MetaPill(text: translations.user.meta.novelChars(count: novel.textLength)),
                if (novel.pageCount > 1) _MetaPill(text: translations.user.meta.novelPages(count: novel.pageCount)),
                if (novel.xRestrict > 0) const _MetaPill(text: 'R-18'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NovelPreviewTags extends StatelessWidget {
  const _NovelPreviewTags({required this.tags});

  final List<Tag> tags;

  static const _gap = 5.0;
  static const _chipPadding = 14.0;
  static const _maxChipWidth = 112.0;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return SizedBox(height: _tagHeight(context));
    }

    final style = Theme.of(context).textTheme.labelSmall;
    final scaler = MediaQuery.textScalerOf(context);
    double chipWidth(String label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      return math.min(_maxChipWidth, painter.width.ceilToDouble() + _chipPadding);
    }

    return SizedBox(
      height: _tagHeight(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Whole chips only: those that fit, then a "+N" for the rest. The
          // first always stays, shortened with an ellipsis if it must.
          final labels = [for (final tag in tags.take(2)) _tagLabel(tag)];
          var shown = 0;
          var used = 0.0;
          for (final label in labels) {
            final next = used + (shown > 0 ? _gap : 0) + chipWidth(label);
            final hidden = tags.length - (shown + 1);
            final reserve = hidden > 0 ? _gap + chipWidth('+$hidden') : 0.0;
            if (shown > 0 && next + reserve > constraints.maxWidth) break;
            used = next;
            shown++;
          }
          final hiddenCount = tags.length - shown;

          return Row(
            children: [
              for (var index = 0; index < shown; index++) ...[
                if (index > 0) const SizedBox(width: _gap),
                Flexible(child: _NovelTagChip(label: labels[index], compact: true)),
              ],
              if (hiddenCount > 0) ...[const SizedBox(width: _gap), _NovelTagChip(label: '+$hiddenCount', compact: true)],
            ],
          );
        },
      ),
    );
  }
}

class _NovelTagChip extends StatelessWidget {
  const _NovelTagChip({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = _tagAccent(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 112 : 180),
      child: EnergeticPill(
        accentColor: accent,
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: compact ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = FreepivThemeTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.surfaceRaised, borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

String _tagLabel(Tag tag) {
  final translatedName = tag.translatedName;
  if (translatedName != null && translatedName.trim().isNotEmpty && translatedName.trim() != tag.name.trim()) {
    return '#${tag.name} · $translatedName';
  }

  return '#${tag.name}';
}

String _previewCaption(String html) {
  if (html.trim().isEmpty) return '';
  final withBreaks = html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ').replaceAll(RegExp(r'</p>', caseSensitive: false), ' ');
  return (html_parser.parseFragment(withBreaks).text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

Color _novelAccent(BuildContext context) {
  final tokens = FreepivThemeTokens.of(context);
  return tokens.brand;
}

Color _tagAccent(BuildContext context) {
  final tokens = FreepivThemeTokens.of(context);
  return tokens.brand;
}

double _lineHeight(BuildContext context, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: 'Ag', style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final height = painter.preferredLineHeight;
  painter.dispose();
  return height;
}

double _tagHeight(BuildContext context) => math.max(24, _lineHeight(context, Theme.of(context).textTheme.labelSmall!) + 6);
