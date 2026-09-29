import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The small, locally bundled Lucide set used for navigation and common actions.
/// Pair decorative icons with a labeled control; use [FpIcon.semanticLabel]
/// only when the icon itself conveys information outside a labeled control.
enum FpIconName {
  home,
  compass,
  activity,
  user,
  more,
  heart,
  newspaper,
  download,
  settings,
  info,
  code,
  send,
  messageCircle,
  externalLink,
  refreshCw,
  arrowLeft,
  close,
  copy,
}

class FpIcon extends StatelessWidget {
  const FpIcon(this.icon, {this.size, this.color, this.semanticLabel, this.filled = false, super.key}) : assert(!filled || icon == FpIconName.heart);

  final FpIconName icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  /// Uses the original heart outline with a matching filled center.
  final bool filled;

  String get assetPath => switch (icon) {
    FpIconName.home => 'assets/icons/house.svg',
    FpIconName.compass => 'assets/icons/compass.svg',
    FpIconName.activity => 'assets/icons/activity.svg',
    FpIconName.user => 'assets/icons/user-round.svg',
    FpIconName.more => 'assets/icons/ellipsis.svg',
    FpIconName.heart => filled ? 'assets/icons/heart-filled.svg' : 'assets/icons/heart.svg',
    FpIconName.newspaper => 'assets/icons/newspaper.svg',
    FpIconName.download => 'assets/icons/download.svg',
    FpIconName.settings => 'assets/icons/settings.svg',
    FpIconName.info => 'assets/icons/info.svg',
    FpIconName.code => 'assets/icons/code.svg',
    FpIconName.send => 'assets/icons/send.svg',
    FpIconName.messageCircle => 'assets/icons/message-circle.svg',
    FpIconName.externalLink => 'assets/icons/external-link.svg',
    FpIconName.refreshCw => 'assets/icons/refresh-cw.svg',
    FpIconName.arrowLeft => 'assets/icons/arrow-left.svg',
    FpIconName.close => 'assets/icons/x.svg',
    FpIconName.copy => 'assets/icons/copy.svg',
  };

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 20;
    final resolvedColor = color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      assetPath,
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      matchTextDirection: icon == FpIconName.arrowLeft,
    );
  }
}
