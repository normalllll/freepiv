import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// A number of an [AppIdentityHeader]'s stat row.
@immutable
class AppIdentityStat {
  const AppIdentityStat({required this.value, required this.caption});

  final String value;
  final String caption;
}

/// The identity header of a home page (author, FANBOX creator, "Me"):
/// avatar, name as content text, a secondary line, the
/// stat row, the primary action (follow) and a More menu. Side by side on
/// wide content, centred and stacked on narrow content, the primary action
/// then taking the whole row.
class AppIdentityHeader extends StatelessWidget {
  const AppIdentityHeader({
    required this.avatar,
    required this.name,
    this.subtitle,
    this.detail,
    this.stats = const [],
    this.statsLoading = false,
    this.primary,
    this.more = const [],
    this.moreLabel,
    super.key,
  });

  /// Narrower content than this stacks the header.
  static const stackBelow = 600.0;

  /// Usually a FrostAvatar; Frost's largest size (56) stands in for the 72
  /// the design asks for (freepiv-20261107-identity-avatar-size).
  final Widget avatar;
  final String name;
  final String? subtitle;

  /// A second, quieter line under [subtitle], such as the account's e-mail.
  final String? detail;
  final List<AppIdentityStat> stats;

  /// Placeholders the size of the stats while they load.
  final bool statsLoading;

  /// Usually FrostButton.prominent: follow, or the own page.
  final Widget? primary;
  final List<FrostMenuEntry> more;
  final String? moreLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < stackBelow;
        final alignment = narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start;
        final textAlign = narrow ? TextAlign.center : TextAlign.start;
        final identity = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          spacing: FrostGap.inline,
          children: [
            FrostText(name, content: true, role: FrostTextRole.title1, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: textAlign),
            if (subtitle case final subtitle?)
              FrostText(
                subtitle,
                role: FrostTextRole.footnote,
                tone: FrostTextTone.secondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: textAlign,
              ),
            if (detail case final detail?)
              FrostText(detail, role: FrostTextRole.footnote, tone: FrostTextTone.tertiary, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: textAlign),
            if (stats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: FrostGap.inline),
                child: Wrap(
                  alignment: narrow ? WrapAlignment.center : WrapAlignment.start,
                  spacing: FrostGap.section,
                  runSpacing: FrostGap.related,
                  children: [
                    for (final stat in stats)
                      statsLoading
                          ? FrostStat.skeleton(value: stat.value, unit: null, caption: stat.caption)
                          : FrostStat(value: stat.value, caption: stat.caption),
                  ],
                ),
              ),
          ],
        );
        final moreButton = more.isEmpty
            ? null
            : FrostMenuAnchor(
                entries: more,
                builder: (context, focusNode, toggle) =>
                    FrostButton.icon(icon: FrostScope.configOf(context).icons.more, label: moreLabel ?? FrostScope.labelsOf(context).more, onPressed: toggle),
              );
        if (narrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            spacing: FrostGap.group,
            children: [
              avatar,
              identity,
              if (primary != null || moreButton != null)
                Row(
                  spacing: FrostGap.related,
                  children: [
                    if (primary case final primary?) Expanded(child: primary),
                    ?moreButton,
                  ],
                ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: FrostGap.group,
          children: [
            avatar,
            Expanded(child: identity),
            ?primary,
            ?moreButton,
          ],
        );
      },
    );
  }
}
