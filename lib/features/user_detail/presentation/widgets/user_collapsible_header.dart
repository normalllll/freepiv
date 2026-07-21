import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/core/utils/utils.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

class UserCollapsibleHeaderSliver extends StatelessWidget {
  const UserCollapsibleHeaderSliver({
    required this.detail,
    required this.overlapsContent,
    required this.includeTopPadding,
    required this.showBackButton,
    super.key,
  });

  final UserDetailResult detail;
  final bool overlapsContent;
  final bool includeTopPadding;
  final bool showBackButton;

  static double collapseExtentFor(BuildContext context, double width, UserDetailResult detail) {
    return expandedHeightFor(context, width, detail) - collapsedHeightFor(width);
  }

  static double expandedHeightFor(BuildContext context, double width, UserDetailResult detail) {
    final layout = UserCollapsibleHeaderLayout.forWidth(width);
    final comment = _displayCommentFor(detail.user.comment);

    return layout.expandedHeight(commentHeight: _commentHeightFor(context, comment, layout.bodyContentWidth), statsHeight: statsHeightFor(context));
  }

  static double skeletonExpandedHeightFor(BuildContext context, double width) {
    final layout = UserCollapsibleHeaderLayout.forWidth(width);

    return layout.expandedHeight(commentHeight: placeholderCommentHeightFor(context, width), statsHeight: statsHeightFor(context));
  }

  static double collapsedHeightFor(double width) {
    return UserCollapsibleHeaderLayout.forWidth(width).collapsedHeight;
  }

  static double placeholderCommentHeightFor(BuildContext context, double width) {
    final layout = UserCollapsibleHeaderLayout.forWidth(width);

    return _commentHeightFor(context, t.user.empty.comment, layout.bodyContentWidth);
  }

  static String _displayCommentFor(String? rawComment) {
    final comment = rawComment?.trim();
    if (comment != null && comment.isNotEmpty) {
      return comment;
    }

    return t.user.empty.comment;
  }

  static double _commentHeightFor(BuildContext context, String comment, double maxWidth) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.25);

    return _measureTextHeight(
      context,
      buildHtmlTextSpan(context, comment, style: style),
      maxWidth: maxWidth,
      maxLines: 2,
      ellipsis: '\u2026',
      textScaler: TextScaler.noScaling,
    );
  }

  static double statsHeightFor(BuildContext context) {
    final translations = t;
    final labels = [translations.user.stats.illustrations, translations.user.stats.manga, translations.user.stats.novels, translations.user.stats.following];
    final defaultStyle = DefaultTextStyle.of(context).style;
    final countStyle = Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700) ?? defaultStyle.copyWith(fontWeight: FontWeight.w700);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant) ?? defaultStyle;
    final countHeight = _measureTextHeight(
      context,
      TextSpan(text: '0', style: countStyle),
      maxWidth: double.infinity,
      textScaler: MediaQuery.textScalerOf(context),
    );
    final labelHeight = labels
        .map(
          (label) => _measureTextHeight(
            context,
            TextSpan(text: label, style: labelStyle),
            maxWidth: double.infinity,
            textScaler: MediaQuery.textScalerOf(context),
          ),
        )
        .fold(0.0, math.max);

    return (math.max(countHeight, labelHeight) + UserCollapsibleHeaderLayout.statVerticalPadding * 2).ceilToDouble();
  }

  static double _measureTextHeight(
    BuildContext context,
    InlineSpan text, {
    required double maxWidth,
    int? maxLines,
    String? ellipsis,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final painter = TextPainter(text: text, maxLines: maxLines, ellipsis: ellipsis, textDirection: Directionality.of(context), textScaler: textScaler)
      ..locale = Localizations.maybeLocaleOf(context)
      ..layout(maxWidth: maxWidth);

    return painter.height.ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _UserHeaderDelegate(
        detail: detail,
        topPadding: includeTopPadding ? mediaQuery.padding.top : 0,
        expandedHeight: expandedHeightFor(context, width, detail),
        collapsedHeight: collapsedHeightFor(width),
        overlapsContent: overlapsContent,
        showBackButton: showBackButton,
      ),
    );
  }
}

class UserCollapsibleHeaderLayout {
  const UserCollapsibleHeaderLayout({
    required this.availableWidth,
    required this.compact,
    required this.contentWidth,
    required this.horizontalPadding,
    required this.backgroundHeight,
    required this.avatarSize,
    required this.bodyTopPadding,
  });

  static const maxContentWidth = 980.0;
  static const stackedHeaderExtraHeight = 58.0;
  static const expandedNameStartGap = 14.0;
  static const expandedNameTopOffset = 8.0;
  static const commentStatsGap = 12.0;
  static const statVerticalPadding = 7.0;
  static const flexOverflowGuard = 1.0;

  final double availableWidth;
  final bool compact;
  final double contentWidth;
  final double horizontalPadding;
  final double backgroundHeight;
  final double avatarSize;
  final double bodyTopPadding;

  static UserCollapsibleHeaderLayout forWidth(double availableWidth) {
    final compact = availableWidth < 620;
    final contentWidth = math.min(availableWidth, maxContentWidth);

    return UserCollapsibleHeaderLayout(
      availableWidth: availableWidth,
      compact: compact,
      contentWidth: contentWidth,
      horizontalPadding: math.max(16.0, (availableWidth - contentWidth) / 2 + (compact ? 16 : 20)),
      backgroundHeight: compact ? 148.0 : 172.0,
      avatarSize: compact ? 84.0 : 98.0,
      bodyTopPadding: compact ? 10.0 : 12.0,
    );
  }

  double get avatarTop => backgroundHeight - avatarSize / 2;
  double get stackedHeaderHeight => backgroundHeight + stackedHeaderExtraHeight;
  double get bodyContentWidth => math.max(0.0, availableWidth - horizontalPadding * 2);
  double get collapsedHeight => compact ? 64.0 : 70.0;

  double collapsedLeadingPadding({required bool showBackButton}) {
    if (showBackButton) {
      return compact ? 64.0 : 70.0;
    }

    return compact ? 16.0 : 20.0;
  }

  double expandedHeight({required double commentHeight, required double statsHeight}) {
    return (stackedHeaderHeight + bodyTopPadding + commentHeight + commentStatsGap + statsHeight + flexOverflowGuard).ceilToDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is UserCollapsibleHeaderLayout &&
        other.availableWidth == availableWidth &&
        other.compact == compact &&
        other.contentWidth == contentWidth &&
        other.horizontalPadding == horizontalPadding &&
        other.backgroundHeight == backgroundHeight &&
        other.avatarSize == avatarSize &&
        other.bodyTopPadding == bodyTopPadding;
  }

  @override
  int get hashCode => Object.hash(availableWidth, compact, contentWidth, horizontalPadding, backgroundHeight, avatarSize, bodyTopPadding);
}

class _UserHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _UserHeaderDelegate({
    required this.detail,
    required this.topPadding,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.overlapsContent,
    required this.showBackButton,
  });

  final UserDetailResult detail;
  final double topPadding;
  final double expandedHeight;
  final double collapsedHeight;
  final bool overlapsContent;
  final bool showBackButton;

  @override
  double get minExtent => topPadding + collapsedHeight;

  @override
  double get maxExtent => topPadding + expandedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final size = MediaQuery.sizeOf(context);
    final expandedOpacity = (1 - progress * 1.7).clamp(0.0, 1.0);
    final collapsedOpacity = ((progress - 0.58) / 0.42).clamp(0.0, 1.0);

    return Material(
      color: colorScheme.surface,
      elevation: this.overlapsContent || overlapsContent ? 1 : 0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            top: topPadding,
            child: IgnorePointer(
              ignoring: expandedOpacity < 0.35,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: expandedHeight,
                  child: SizedBox(
                    height: expandedHeight,
                    child: Opacity(
                      opacity: expandedOpacity,
                      child: _ExpandedUserHeader(detail: detail, availableWidth: size.width),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: colorScheme.surface.withValues(alpha: progress * 0.96)),
            ),
          ),
          PositionedDirectional(
            top: topPadding,
            start: 0,
            end: 0,
            height: collapsedHeight,
            child: IgnorePointer(
              ignoring: collapsedOpacity < 0.35,
              child: Opacity(
                opacity: collapsedOpacity,
                child: _CollapsedUserHeader(detail: detail, showBackButton: showBackButton),
              ),
            ),
          ),
          if (showBackButton)
            PositionedDirectional(
              top: topPadding + 8,
              start: 8,
              child: SurfaceIconButton(icon: Icons.arrow_back, tooltip: t.common.back, onPressed: () => Navigator.of(context).maybePop()),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_UserHeaderDelegate oldDelegate) {
    return oldDelegate.detail != detail ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight ||
        oldDelegate.overlapsContent != overlapsContent ||
        oldDelegate.showBackButton != showBackButton;
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({required this.url, required this.hasBackground, required this.opacity});

  final String? url;
  final bool hasBackground;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!hasBackground) {
      return ColoredBox(color: colorScheme.surfaceContainerHighest);
    }

    return Opacity(
      opacity: opacity,
      child: PixivImage(url: url!, fit: BoxFit.cover),
    );
  }
}

class _ExpandedUserHeader extends StatelessWidget {
  const _ExpandedUserHeader({required this.detail, required this.availableWidth});

  final UserDetailResult detail;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final layout = UserCollapsibleHeaderLayout.forWidth(availableWidth);
    final rawComment = detail.user.comment?.trim();
    final hasComment = rawComment != null && rawComment.isNotEmpty;
    final comment = hasComment ? rawComment : t.user.empty.comment;
    final commentStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: hasComment ? 1 : 0.68), height: 1.25);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: layout.stackedHeaderHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                bottom: UserCollapsibleHeaderLayout.stackedHeaderExtraHeight,
                child: _HeaderBackground(
                  url: detail.profile.backgroundImageUrl,
                  hasBackground: detail.profile.backgroundImageUrl?.isNotEmpty ?? false,
                  opacity: 1,
                ),
              ),
              PositionedDirectional(
                start: layout.horizontalPadding,
                top: layout.avatarTop,
                child: _HeaderAvatar(url: detail.user.profileImageUrls.medium, size: layout.avatarSize),
              ),
              PositionedDirectional(
                top: layout.backgroundHeight + UserCollapsibleHeaderLayout.expandedNameTopOffset,
                start: layout.horizontalPadding + layout.avatarSize + UserCollapsibleHeaderLayout.expandedNameStartGap,
                end: layout.horizontalPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ExpandedNameBlock(detail: detail)),
                    const SizedBox(width: 10),
                    UserFollowButton(userId: detail.user.id, initialIsFollowed: detail.user.isFollowed),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(layout.horizontalPadding, layout.bodyTopPadding, layout.horizontalPadding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserCommentPreview(comment: comment, plainComment: rawComment, style: commentStyle),
              const SizedBox(height: UserCollapsibleHeaderLayout.commentStatsGap),
              _UserStatsRow(profile: detail.profile),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserCommentPreview extends StatelessWidget {
  const _UserCommentPreview({required this.comment, required this.plainComment, required this.style});

  final String comment;
  final String? plainComment;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final hasComment = plainComment != null && plainComment!.isNotEmpty;
    final preview = SizedBox(
      width: double.infinity,
      child: _CommentPreviewText(comment: comment, style: style),
    );

    if (!hasComment) {
      return preview;
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(borderRadius: BorderRadius.circular(6), onTap: () => _showUserCommentDialog(context, comment), child: preview),
    );
  }
}

class _CommentPreviewText extends StatelessWidget {
  const _CommentPreviewText({required this.comment, required this.style});

  final String comment;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final direction = Directionality.of(context);
        final locale = Localizations.maybeLocaleOf(context);
        final originalText = buildHtmlTextSpan(context, comment, style: style);
        final plainText = originalText.toPlainText(includeSemanticsLabels: false, includePlaceholders: false).trimRight();
        final text = _truncateTextSpan(originalText, plainText.length);
        final textPainter = TextPainter(text: text, maxLines: 2, textDirection: direction, textScaler: TextScaler.noScaling)
          ..locale = locale
          ..layout(maxWidth: constraints.maxWidth);

        if (!textPainter.didExceedMaxLines) {
          return RichText(text: text, maxLines: 2, overflow: TextOverflow.clip, textDirection: direction, locale: locale);
        }

        final truncatedText = _truncateTextSpanToFit(text, plainText, maxWidth: constraints.maxWidth, textDirection: direction, locale: locale);

        return RichText(text: truncatedText, maxLines: 2, overflow: TextOverflow.clip, textDirection: direction, locale: locale);
      },
    );
  }
}

TextSpan _truncateTextSpanToFit(TextSpan text, String plainText, {required double maxWidth, required TextDirection textDirection, required Locale? locale}) {
  final boundaries = <int>[0];
  var codeUnitOffset = 0;
  for (final rune in plainText.runes) {
    codeUnitOffset += rune > 0xFFFF ? 2 : 1;
    boundaries.add(codeUnitOffset);
  }

  var low = 0;
  var high = boundaries.length - 1;
  var fittingOffset = 0;

  while (low <= high) {
    final middle = low + (high - low) ~/ 2;
    final candidateOffset = _trimTrailingWhitespaceOffset(plainText, boundaries[middle]);
    final candidate = _appendEllipsis(_truncateTextSpan(text, candidateOffset));
    final painter = TextPainter(text: candidate, maxLines: 2, textDirection: textDirection, textScaler: TextScaler.noScaling)
      ..locale = locale
      ..layout(maxWidth: maxWidth);

    if (painter.didExceedMaxLines) {
      high = middle - 1;
    } else {
      fittingOffset = candidateOffset;
      low = middle + 1;
    }
  }

  return _appendEllipsis(_truncateTextSpan(text, fittingOffset));
}

int _trimTrailingWhitespaceOffset(String text, int end) {
  var offset = end;
  while (offset > 0) {
    final codeUnit = text.codeUnitAt(offset - 1);
    if (codeUnit != 0x09 && codeUnit != 0x0A && codeUnit != 0x0D && codeUnit != 0x20) {
      break;
    }
    offset--;
  }
  return offset;
}

TextSpan _appendEllipsis(TextSpan text) {
  return TextSpan(
    text: text.text,
    style: text.style,
    children: [
      ...?text.children,
      const TextSpan(text: '\u2026'),
    ],
  );
}

TextSpan _truncateTextSpan(TextSpan text, int maxCodeUnits) {
  var remaining = maxCodeUnits;
  String? truncatedText;
  final ownText = text.text;

  if (ownText != null && remaining > 0) {
    final length = math.min(ownText.length, remaining);
    truncatedText = ownText.substring(0, length);
    remaining -= length;
  }

  final truncatedChildren = <InlineSpan>[];
  if (remaining > 0) {
    for (final child in text.children ?? const <InlineSpan>[]) {
      if (child is! TextSpan) {
        continue;
      }

      final childLength = child.toPlainText(includeSemanticsLabels: false, includePlaceholders: false).length;
      if (remaining >= childLength) {
        truncatedChildren.add(child);
        remaining -= childLength;
      } else {
        truncatedChildren.add(_truncateTextSpan(child, remaining));
        remaining = 0;
        break;
      }
    }
  }

  return TextSpan(text: truncatedText, style: text.style, children: truncatedChildren);
}

void _showUserCommentDialog(BuildContext context, String comment) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      final plainComment = plainTextFromHtml(comment);
      final title = t.user.profile.comment;

      return AlertDialog(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 460),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: HtmlRichText(
                comment,
                selectable: true,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface, height: 1.35),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: plainComment));
            },
            child: Text(t.common.copy(label: title)),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(MaterialLocalizations.of(context).closeButtonLabel)),
        ],
      );
    },
  );
}

class _ExpandedNameBlock extends StatelessWidget {
  const _ExpandedNameBlock({required this.detail});

  final UserDetailResult detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          detail.user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w700, height: 1.08),
        ),
        const SizedBox(height: 3),
        Text(
          '@${detail.user.account}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.1),
        ),
      ],
    );
  }
}

class _CollapsedUserHeader extends StatelessWidget {
  const _CollapsedUserHeader({required this.detail, required this.showBackButton});

  final UserDetailResult detail;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarSize = 40.0;
    final start = UserCollapsibleHeaderLayout.forWidth(MediaQuery.sizeOf(context).width).collapsedLeadingPadding(showBackButton: showBackButton);

    return Row(
      children: [
        SizedBox(width: start),
        _HeaderAvatar(url: detail.user.profileImageUrls.medium, size: avatarSize),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w700, height: 1.08),
              ),
              const SizedBox(height: 2),
              Text(
                '@${detail.user.account}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.surface.withValues(alpha: 0.92), width: 3),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: ClipOval(
          child: PixivImage(url: url, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _UserStatsRow extends StatelessWidget {
  const _UserStatsRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _UserHeaderStat(value: profile.totalIllusts, label: translations.user.stats.illustrations),
          const SizedBox(width: 8),
          _UserHeaderStat(value: profile.totalManga, label: translations.user.stats.manga),
          const SizedBox(width: 8),
          _UserHeaderStat(value: profile.totalNovels, label: translations.user.stats.novels),
          const SizedBox(width: 8),
          _UserHeaderStat(value: profile.totalFollowUsers, label: translations.user.stats.following),
        ],
      ),
    );
  }
}

class _UserHeaderStat extends StatelessWidget {
  const _UserHeaderStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatCount(value), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 5),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
