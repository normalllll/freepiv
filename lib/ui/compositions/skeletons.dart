import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:frost_ui/frost_ui.dart';

/// How many placeholders of at least [shortestExtent] run past the bottom of
/// the window, [perRow] to a row: what fits, then a row more, so the last row
/// is cut off by the screen edge whatever the window's size.
int appSkeletonCount(BuildContext context, {required double shortestExtent, int perRow = 1}) =>
    ((MediaQuery.sizeOf(context).height / shortestExtent).ceil() + 1) * perRow;

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

/// [child], a real layout, painted as bones: nothing in it can be pressed,
/// focused or read.
Widget appBones(Widget child) => AppBonesScope(
  child: ExcludeSemantics(
    child: IgnorePointer(child: ExcludeFocus(child: child.frostSkeleton(true))),
  ),
);

/// Marks a subtree painted as bones, so a picture without an address draws
/// a filled frame like every other bone.
class AppBonesScope extends InheritedWidget {
  const AppBonesScope({required super.child, super.key});

  static bool active(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppBonesScope>() != null;

  @override
  bool updateShouldNotify(AppBonesScope oldWidget) => false;
}

/// The author of placeholder works.
const appPlaceholderUser = User(
  id: 0,
  name: 'Sample artist',
  account: 'sample',
  profileImageUrls: ProfileImageUrls(medium: ''),
);

const _noImages = ImageUrls(squareMedium: '', medium: '', large: '');

const _placeholderTags = [Tag(name: 'original'), Tag(name: 'landscape')];

/// A work of usual size standing in while the real one loads. Only its
/// geometry is ever seen: everything built from it is painted as bones.
Illust illustPlaceholder({int id = 0}) => Illust(
  id: id,
  title: 'A work title',
  kind: 'illust',
  imageUrls: _noImages,
  caption: '',
  restrict: 0,
  user: appPlaceholderUser,
  tags: _placeholderTags,
  tools: const [],
  createDate: '2026-01-01T00:00:00+09:00',
  pageCount: 1,
  width: 1000,
  height: 1000,
  sanityLevel: 2,
  xRestrict: 0,
  metaSinglePage: const MetaSinglePage(),
  metaPages: const [],
  totalView: 1000,
  totalBookmarks: 100,
  isBookmarked: false,
  visible: true,
  isMuted: false,
  illustAiType: 1,
);

/// A novel to lay out and paint as bones while the real one loads.
Novel novelPlaceholder({int id = 0}) => Novel(
  id: id,
  title: 'A novel title',
  caption: 'The first line of what the author says about this novel, as long as a usual caption, and the line after it.',
  restrict: 0,
  xRestrict: 0,
  isOriginal: true,
  imageUrls: _noImages,
  createDate: '2026-01-01T00:00:00+09:00',
  tags: _placeholderTags,
  pageCount: 1,
  textLength: 10000,
  user: appPlaceholderUser,
  series: const Series(),
  totalBookmarks: 100,
  isBookmarked: false,
  totalView: 1000,
  visible: true,
  totalComments: 0,
  isMuted: false,
  isMypixivOnly: false,
  isXRestricted: false,
  novelAiType: 0,
);

/// A user in a list, with works beside their name, painted as bones while
/// the real one loads.
UserPreview userPreviewPlaceholder() => UserPreview(
  user: appPlaceholderUser,
  illusts: [for (var id = 0; id < 3; id++) illustPlaceholder(id: id)],
  isMuted: false,
);
