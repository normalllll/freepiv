import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// How many placeholders of at least [shortestExtent] fill the window from
/// top to bottom, [perRow] to a row. A skeleton always reaches past the
/// visible area, whatever the window's size.
int appSkeletonCount(BuildContext context, {required double shortestExtent, int perRow = 1}) =>
    (MediaQuery.sizeOf(context).height / shortestExtent).ceil() * perRow;

/// [appSkeletonCount] for a waterfall [width] wide of tiles no shorter than
/// [widestRatio] allows plus [footerExtent].
int appWaterfallSkeletonCount(BuildContext context, {required double width, required double widestRatio, required double footerExtent}) {
  const gap = FrostGap.grid;
  final columns = math.max(
    1,
    frostWaterfallColumnCount(width: width, preferredTileWidth: FrostMetrics.gridExtent, gap: gap, textScale: MediaQuery.textScalerOf(context).scale(1)),
  );
  final tile = (width + gap) / columns - gap;
  return appSkeletonCount(context, shortestExtent: tile / widestRatio + footerExtent + gap, perRow: columns);
}
