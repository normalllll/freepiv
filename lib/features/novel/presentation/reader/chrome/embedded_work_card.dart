import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart' show workRestrictionBadges;
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';

/// A Pixiv work embedded in the text, as a card: its thumbnail, title, author
/// and the R-18, R-18G and AI marks (badges only; nothing is hidden or
/// blurred). A tap opens the work. A work the viewer may not see is greyed
/// with Pixiv's message and goes nowhere; a work whose data is missing says
/// it is unavailable.
///
/// The card is [height] tall, the extent the layout reserves for it.
class EmbeddedWorkCard extends StatelessWidget {
  const EmbeddedWorkCard({required this.block, required this.onOpen, this.height = 112, super.key});

  final NovelEmbeddedWork block;
  final ValueChanged<int> onOpen;
  final double height;

  static const _padding = 16.0;

  @override
  Widget build(BuildContext context) {
    final t = context.t.novel.reader;
    final work = block.work;
    final visible = work != null && work.visible;
    final thumbnail = visible ? novelEmbeddedWorkImageUrl(work) : null;
    final String title;
    final String? meta;
    if (work == null) {
      title = t.workUnavailable;
      meta = null;
    } else if (!visible) {
      title = work.availableMessage?.trim().isNotEmpty == true ? work.availableMessage!.trim() : t.workHidden;
      meta = null;
    } else {
      title = work.title.trim().isEmpty ? '#${block.illustId}' : work.title;
      meta = [if (block.page > 1) t.workPage(page: block.page), if (work.userName.trim().isNotEmpty) work.userName.trim()].join(' · ');
    }
    final badges = visible ? workRestrictionBadges(context, xRestrict: work.xRestrict, aiGenerated: false) : const <Widget>[];
    final side = height - 2 * _padding;
    final body = FrostSurface(
      role: FrostSurfaceRole.module,
      borderRadius: BorderRadius.circular(FrostRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Row(
          spacing: FrostGap.group,
          children: [
            SizedBox.square(
              dimension: side,
              child: thumbnail == null
                  ? Center(child: FrostIcon(visible ? PivIcons.image : PivIcons.eye, size: 24))
                  : AppPixivImage(url: thumbnail, aspectRatio: 1, radius: FrostRadius.md, fit: BoxFit.cover),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: FrostGap.inline,
                children: [
                  FrostText(
                    title,
                    content: visible,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    tone: visible ? FrostTextTone.primary : FrostTextTone.secondary,
                  ),
                  if (meta != null && meta.isNotEmpty)
                    FrostText(meta, content: true, role: FrostTextRole.footnote, tone: FrostTextTone.secondary, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (badges.isNotEmpty) Wrap(spacing: FrostGap.inline, runSpacing: FrostGap.inline, children: badges),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return SizedBox(
      key: const ValueKey('reader-work-card'),
      height: height,
      child: visible
          ? FrostClickSurface(
              shape: FrostClickShape.rounded(BorderRadius.circular(FrostRadius.lg)),
              onTap: () => onOpen(block.illustId),
              child: Semantics(label: title, button: true, excludeSemantics: true, child: body),
            )
          : Opacity(
              opacity: .6,
              child: Semantics(label: title, excludeSemantics: true, child: body),
            ),
    );
  }
}
