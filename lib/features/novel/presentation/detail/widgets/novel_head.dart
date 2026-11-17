import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/features/downloads/presentation/content_image_entries.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart' show workRestrictionBadges;
import 'package:freepiv/ui/compositions/content_rows.dart' show AppUserAvatar;
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/ui/compositions/work_actions.dart' show AppFollowButton;
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// Opens the original-image viewer on [urls], starting at [index].
void openNovelImages(BuildContext context, Novel novel, List<String> urls, int index) => unawaited(
  GoRouter.of(context).push(
    AppRoute.originalImageViewer.path,
    extra: OriginalImageViewerArgs(
      title: novel.title,
      source: DownloadSourceScope.of(context),
      initialIndex: index,
      pages: [for (final url in urls) OriginalImagePage(url: url, previewUrl: url, downloadOrigin: DownloadOrigin.ofImageUrl(Uri.parse(url)))],
    ),
  ),
);

/// The cover in a frame of a book cover's proportions whatever the picture's
/// own, drawn whole and centred. A cover carries its title, so it is not
/// cropped, and the frame does not wait for the picture, so nothing below it
/// moves when it loads.
class NovelCover extends ConsumerWidget {
  const NovelCover({required this.novel, required this.webview, required this.width, super.key});

  final Novel novel;
  final WebviewNovel? webview;
  final double width;

  /// The width of the frame to its height.
  static const ratio = 1 / 1.414;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = novelCoverUrl(novel, webview);
    final medium = novel.imageUrls.medium;
    return SizedBox(
      width: width,
      child: FrostContextMenuRegion(
        entries: contentImageMenu(context, ref.read(rustMediaTransportProvider), url: url, title: novel.title),
        child: FrostMediaCard(
          aspectRatio: ratio,
          semanticLabel: novel.title,
          media: AppPixivImage(url: url, aspectRatio: ratio, radius: 0, fit: BoxFit.contain, placeholderUrl: medium == url ? null : medium),
          onPressed: () => openNovelImages(context, novel, [url], 0),
        ),
      ),
    );
  }
}

/// R-18, R-18G, AI and original as marks; they inform and hide nothing.
class NovelBadges extends StatelessWidget {
  const NovelBadges({required this.novel, required this.webview, super.key});

  final Novel novel;
  final WebviewNovel? webview;

  /// The marks a novel carries; empty for one with none.
  static bool hasAny(Novel novel, WebviewNovel? webview) => novel.xRestrict > 0 || _ai(novel, webview) || _original(novel, webview);

  static bool _ai(Novel novel, WebviewNovel? webview) => novel.novelAiType == 2 || webview?.aiType == 2;

  static bool _original(Novel novel, WebviewNovel? webview) => novel.isOriginal || (webview?.isOriginal ?? false);

  @override
  Widget build(BuildContext context) {
    final badges = [
      ...workRestrictionBadges(context, xRestrict: novel.xRestrict, aiGenerated: _ai(novel, webview)),
      if (_original(novel, webview)) FrostBadge(label: context.t.novelDetail.original),
    ];
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: FrostGap.related, runSpacing: FrostGap.related, children: badges);
  }
}

/// Badges, the title and the author line with Follow.
class NovelTitleBlock extends StatelessWidget {
  const NovelTitleBlock({required this.novel, required this.webview, this.titleRole = FrostTextRole.title2, super.key});

  final Novel novel;
  final WebviewNovel? webview;
  final FrostTextRole titleRole;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FrostGap.group,
    children: [
      if (NovelBadges.hasAny(novel, webview)) NovelBadges(novel: novel, webview: webview),
      FrostText(novel.title, content: true, role: titleRole, selectable: true),
      NovelAuthorRow(user: novel.user),
    ],
  );
}

/// The author with Follow at the row's trailing edge. Follow moves to a line
/// of its own, rather than shortening the name below about ten characters.
class NovelAuthorRow extends StatelessWidget {
  const NovelAuthorRow({required this.user, super.key});

  final User user;

  static const _minNameCharacters = 10;
  static const _avatar = 32.0;

  /// What Follow takes of the row at normal text size, "Follow" and its padding.
  static const _followWidth = 88.0;

  @override
  Widget build(BuildContext context) {
    void open() => unawaited(GoRouter.of(context).push(AppLocations.user(user.id)));
    final scaler = MediaQuery.textScalerOf(context);
    final nameFloor = scaler.scale(FrostTypography.of(context).style(FrostTextRole.headline).fontSize ?? 16) * _minNameCharacters;
    final avatar = Semantics(
      button: true,
      label: user.name,
      excludeSemantics: true,
      child: FrostClickSurface(
        shape: const FrostClickShape.circle(),
        onTap: open,
        child: AppUserAvatar(user: user),
      ),
    );
    final name = FrostClickSurface(
      onTap: open,
      child: FrostText(user.name, content: true, role: FrostTextRole.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final followWidth = math.min(scaler.scale(_followWidth), constraints.maxWidth / 2);
        final sideBySide = constraints.maxWidth - _avatar - 2 * FrostGap.related - followWidth >= nameFloor;
        final follow = AppFollowButton(user: user, prominent: false);
        if (sideBySide) {
          return Row(
            spacing: FrostGap.related,
            children: [
              avatar,
              Expanded(child: name),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: follow,
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: FrostGap.related,
          children: [
            Row(
              spacing: FrostGap.related,
              children: [
                avatar,
                Expanded(child: name),
              ],
            ),
            follow,
          ],
        );
      },
    );
  }
}
