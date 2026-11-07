// app-owned: 下载飞入动画的飞行图标
import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';

/// What flies to the download entry: a round copy of the
/// work in the action colour, ringed and lifted off the page, or the download
/// glyph when there is no picture.
class DownloadFlightToken extends StatelessWidget {
  const DownloadFlightToken({required this.artwork, super.key});

  final Widget? artwork;

  @override
  Widget build(BuildContext context) {
    final tokens = FrostThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.actionFill,
        border: Border.all(color: tokens.surfaceRaised, width: 2),
        boxShadow: tokens.shadowContact,
      ),
      child: ClipOval(
        child: artwork == null
            ? Center(
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(FrostGap.related),
                    child: FrostIcon(PivIcons.download, color: tokens.onAction),
                  ),
                ),
              )
            : SizedBox.expand(child: artwork),
      ),
    );
  }
}
