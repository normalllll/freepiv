import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/features/downloads/presentation/content_image_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reading_session.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

class NovelHeader extends StatelessWidget {
  const NovelHeader({required this.novel, required this.webviewNovel, required this.onStartReading, super.key});

  final Novel novel;
  final WebviewNovel? webviewNovel;
  final VoidCallback onStartReading;

  @override
  Widget build(BuildContext context) {
    return FrostContentColumn(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = FrostAutoScaffold.usesHorizontalLayoutOf(context) && constraints.maxWidth >= 720;
          final coverUrl = novelCoverUrl(novel, webviewNovel);
          final cover = coverUrl.isEmpty ? null : LargeNovelCoverImage(url: coverUrl, desktop: desktop);
          final info = NovelHeaderInfo(novel: novel, webviewNovel: webviewNovel, onStartReading: onStartReading);

          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 18),
            child: desktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cover != null) ...[cover, const SizedBox(width: 24)],
                      Expanded(child: info),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cover != null) ...[cover, const SizedBox(width: 12)],
                          Expanded(child: _NovelTitleGroup(novel: novel)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _NovelReadButton(novel: novel, webviewNovel: webviewNovel, onStartReading: onStartReading),
                      const SizedBox(height: 14),
                      NovelHeaderInfo(novel: novel, webviewNovel: webviewNovel, onStartReading: onStartReading, supportingOnly: true),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class LargeNovelCoverImage extends StatelessWidget {
  const LargeNovelCoverImage({required this.url, required this.desktop, super.key});

  final String url;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = desktop ? 220.0 : 96.0;
    final height = desktop ? 308.0 : 136.0;
    final borderRadius = BorderRadius.circular(8);

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (colorScheme.brightness == Brightness.light ? colorScheme.surfaceContainerLow : colorScheme.surfaceContainerHighest),
          borderRadius: borderRadius,
        ),
        child: Semantics(
          image: true,
          button: true,
          label: t.novel.detail.images,
          child: FrostClickSurface(
            feedback: FrostClickFeedback.media,
            shape: FrostClickShape.rounded(borderRadius),
            onTap: () => context.push(
              AppRoute.originalImageViewer.path,
              extra: OriginalImageViewerArgs(
                title: t.novel.detail.images,
                source: DownloadSourceScope.of(context),
                initialIndex: 0,
                pages: [OriginalImagePage(url: url, previewUrl: url, downloadOrigin: DownloadOrigin.ofImageUrl(Uri.parse(url)))],
              ),
            ),
            child: ContentImageMenuRegion(
              actions: ContentImageActions.pixivHosted(url: url, headers: pixivImageHeaders, title: t.novel.detail.images),
              child: PixivImage(url: url, fit: BoxFit.contain, borderRadius: borderRadius),
            ),
          ),
        ),
      ),
    );
  }
}

class NovelHeaderInfo extends StatelessWidget {
  const NovelHeaderInfo({required this.novel, required this.webviewNovel, required this.onStartReading, this.supportingOnly = false, super.key});

  final Novel novel;
  final WebviewNovel? webviewNovel;
  final VoidCallback onStartReading;
  final bool supportingOnly;

  @override
  Widget build(BuildContext context) {
    final translations = t;
    final webCaption = webviewNovel?.caption ?? '';
    final caption = webCaption.trim().isNotEmpty ? webCaption : novel.caption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!supportingOnly) ...[
          _NovelTitleGroup(novel: novel),
          const SizedBox(height: FrostGap.group),
          _NovelReadButton(novel: novel, webviewNovel: webviewNovel, onStartReading: onStartReading),
          const SizedBox(height: 14),
        ],
        if (caption.trim().isNotEmpty) ...[
          IllustSectionTitle(title: translations.illust.section.caption, icon: Icons.notes_outlined),
          const SizedBox(height: 7),
          NovelCaptionBox(caption: caption),
          const SizedBox(height: FrostGap.group),
        ],
        NovelTagChips(tags: novel.tags, maxTags: 3),
        const SizedBox(height: FrostGap.group),
        NovelStatsStrip(novel: novel, webviewNovel: webviewNovel),
        const SizedBox(height: 8),
        NovelRestrictionBadges(novel: novel, webviewNovel: webviewNovel),
        if ((novel.series.title ?? '').isNotEmpty) NovelMetadataRow(label: translations.novel.detail.series, value: novel.series.title!),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(translations.illust.section.details),
          children: [
            if (novel.tags.length > 3) NovelTagChips(tags: novel.tags, maxTags: novel.tags.length),
            NovelMetadataRow(label: translations.common.id, value: novel.id.toString()),
            if (novel.createDate.isNotEmpty) NovelMetadataRow(label: translations.illust.metadata.created, value: formatPixivDate(novel.createDate)),
          ],
        ),
      ],
    );
  }
}

class _NovelTitleGroup extends StatelessWidget {
  const _NovelTitleGroup({required this.novel});

  final Novel novel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              novel.title,
              style: frostContentTextStyle(context, novel.title, Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 4),
          IllustBookmarkButton(illustId: novel.id, initialIsBookmarked: novel.isBookmarked, isNovel: true),
        ],
      ),
      const SizedBox(height: 6),
      Text(novel.user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
    ],
  );
}

/// Start or continue reading, once the text is in. A failed text leaves the
/// rest of the page usable and offers to load it again here.
class _NovelReadButton extends ConsumerWidget {
  const _NovelReadButton({required this.novel, required this.webviewNovel, required this.onStartReading});

  final Novel novel;
  final WebviewNovel? webviewNovel;
  final VoidCallback onStartReading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(novelTextProvider(novel.id));
    final readable = text.value?.text.trim().isNotEmpty ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: readable ? onStartReading : null,
          icon: const Icon(Icons.menu_book_outlined),
          label: Text(novelReadingPosition(context, novel.id) == null ? t.novel.detail.startReading : t.novel.detail.continueReading),
        ),
        if (text.hasError && !text.isLoading)
          Padding(
            padding: const EdgeInsets.only(top: FrostGap.related),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FrostText(t.novelText.loadFailed, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
                ),
                FrostButton.quiet(label: t.common.retry, onPressed: () => ref.read(novelTextProvider(novel.id).notifier).reload()),
              ],
            ),
          ),
      ],
    );
  }
}

class NovelStatsStrip extends StatelessWidget {
  const NovelStatsStrip({required this.novel, required this.webviewNovel, super.key});

  final Novel novel;
  final WebviewNovel? webviewNovel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        NovelStatPill(
          icon: Icons.text_fields,
          label: t.user.meta.novelChars(count: novel.textLength),
          value: formatCount(novel.textLength),
        ),
        NovelStatPill(
          icon: Icons.visibility_outlined,
          label: t.illust.stats.views,
          value: formatCount(math.max(novel.totalView, webviewNovel?.rating.view ?? 0)),
        ),
        NovelStatPill(icon: Icons.favorite_border, label: t.illust.stats.bookmarks, value: formatCount(novel.totalBookmarks)),
        NovelStatPill(
          icon: Icons.menu_book_outlined,
          label: t.user.meta.novelPages(count: novel.pageCount),
          value: '${novel.pageCount}',
        ),
      ],
    );
  }
}

class NovelStatPill extends StatelessWidget {
  const NovelStatPill({required this.icon, required this.label, required this.value, super.key});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class NovelRestrictionBadges extends StatelessWidget {
  const NovelRestrictionBadges({required this.novel, required this.webviewNovel, super.key});

  final Novel novel;
  final WebviewNovel? webviewNovel;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (novel.novelAiType != 0 || (webviewNovel?.aiType ?? 0) > 0) NovelInfoBadge(label: context.t.illust.badge.aiArtwork, icon: Icons.auto_awesome_outlined),
      if (novel.xRestrict > 0 || novel.isXRestricted) const NovelInfoBadge(label: 'R-18', icon: Icons.explicit_outlined),
      if (novel.isOriginal || webviewNovel?.isOriginal == true) NovelInfoBadge(label: context.t.illust.badge.original, icon: Icons.edit_note_outlined),
    ];

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 6, runSpacing: 6, children: badges);
  }
}

class NovelInfoBadge extends StatelessWidget {
  const NovelInfoBadge({required this.label, required this.icon, super.key});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(FrostRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class NovelCaptionBox extends StatelessWidget {
  const NovelCaptionBox({required this.caption, super.key});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HtmlRichText(caption, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface, height: 1.5));
  }
}

class NovelMetadataRow extends StatelessWidget {
  const NovelMetadataRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
