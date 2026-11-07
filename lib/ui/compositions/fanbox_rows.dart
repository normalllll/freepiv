import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'package:freepiv/ui/compositions/fanbox_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// A FANBOX user's avatar, with their initial while there is no picture.
class AppFanboxAvatar extends StatelessWidget {
  const AppFanboxAvatar({required this.user, this.size = FrostAvatarSize.regular, super.key});

  final FanboxUser user;
  final FrostAvatarSize size;

  @override
  Widget build(BuildContext context) => user.iconUrl == null || user.iconUrl!.isEmpty
      ? FrostAvatar.person(name: user.name, colorKey: user.id, size: size)
      : FrostAvatar(
          size: size,
          semanticLabel: user.name,
          child: AppFanboxImage(url: user.iconUrl, aspectRatio: 1, radius: 0),
        );
}

/// A post in a FANBOX feed: the author line (avatar,
/// name, time, more), title and excerpt, the cover, and its access (free or
/// the plan's price) with likes and comments.
class AppFanboxPostCard extends StatelessWidget {
  const AppFanboxPostCard({required this.post, required this.onOpen, required this.onCreator, super.key});

  final FanboxPost post;
  final VoidCallback onOpen;
  final VoidCallback onCreator;

  static const coverRatio = 16 / 9;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cover = post.coverUrl;
    final access = post.feeRequired == 0 ? t.fanbox.free : t.fanbox.monthlyFee(fee: post.feeRequired);
    final radius = BorderRadius.circular(FrostRadius.lg);
    return FrostClickSurface(
      shape: FrostClickShape.rounded(radius),
      onTap: onOpen,
      child: FrostSurface(
        role: FrostSurfaceRole.module,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(FrostGap.group),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostGap.related,
            children: [
              Row(
                spacing: FrostGap.related,
                children: [
                  FrostClickSurface(
                    shape: const FrostClickShape.circle(),
                    onTap: onCreator,
                    child: AppFanboxAvatar(user: post.user, size: FrostAvatarSize.small),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FrostText(post.user.name, content: true, role: FrostTextRole.subheadline, maxLines: 1, overflow: TextOverflow.ellipsis),
                        FrostText(formatPixivDate(post.publishedDatetime), role: FrostTextRole.footnote, tone: FrostTextTone.secondary, maxLines: 1),
                      ],
                    ),
                  ),
                  FrostMenuAnchor(
                    entries: [
                      FrostMenuAction(t.fanboxPage.creatorPage, leading: const FrostGlyph.icon(PivIcons.user), onSelected: onCreator),
                      FrostMenuAction(
                        t.fanbox.openOriginal,
                        leading: const FrostGlyph.icon(PivIcons.externalLink),
                        onSelected: () =>
                            unawaited(launchUrl(Uri.parse('https://${post.creatorId}.fanbox.cc/posts/${post.id}'), mode: LaunchMode.externalApplication)),
                      ),
                    ],
                    builder: (context, focusNode, toggle) => FrostButton.icon(icon: PivIcons.more, label: FrostScope.labelsOf(context).more, onPressed: toggle),
                  ),
                ],
              ),
              FrostText(post.title, content: true, role: FrostTextRole.headline, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (post.excerpt.trim().isNotEmpty)
                FrostText(
                  post.excerpt.trim(),
                  content: true,
                  role: FrostTextRole.footnote,
                  tone: FrostTextTone.secondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (cover != null && cover.isNotEmpty) AppFanboxImage(url: cover, aspectRatio: coverRatio),
              Row(
                spacing: FrostGap.related,
                children: [
                  FrostBadge(label: access, tone: post.isRestricted ? FrostBadgeTone.caution : FrostBadgeTone.neutral),
                  Expanded(
                    child: FrostMetaLine(items: ['${t.fanbox.like} ${formatCount(post.likeCount)}', '${t.fanbox.comments} ${formatCount(post.commentCount)}']),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
