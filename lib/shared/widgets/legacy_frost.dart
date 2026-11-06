import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

// Compositions of public Frost components that stand in for the components
// frost_ui 0.3.0 removed, so the pages built before the rebuild keep working
// until they are rebuilt. The rebuilt pages do
// not use them; this file goes with the old pages.

/// The removed `FrostCard`: a panel surface, tappable when [onTap] is set.
class PivCard extends StatelessWidget {
  const PivCard({
    required this.child,
    this.onTap,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.borderRadius = FrostRadius.lg,
    this.feedback = FrostClickFeedback.surface,
    this.accentColor,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final FrostClickFeedback feedback;

  /// Kept for the old call sites; the panel surface no longer takes a tint.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    Widget content = child;
    if (padding case final padding?) content = Padding(padding: padding, child: content);
    if (onTap case final onTap?) content = FrostClickSurface(feedback: feedback, shape: FrostClickShape.rounded(radius), onTap: onTap, child: content);
    return Padding(
      padding: margin,
      child: FrostSurface(role: FrostSurfaceRole.panel, borderRadius: radius, child: content),
    );
  }
}

/// The removed `FrostSkeletonBlock`: one bone of a fixed size.
class PivSkeletonBlock extends StatelessWidget {
  const PivSkeletonBlock({this.width = 16, this.height = 16, this.radius = FrostRadius.xs, super.key});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Semantics(
    label: FrostScope.labelsOf(context).loading,
    child: Skeletonizer.zone(
      effect: frostSkeletonEffect(context),
      child: Bone(width: width, height: height, borderRadius: BorderRadius.circular(radius)),
    ),
  );
}

/// The removed `FrostImageSkeleton`: a bone filling its box.
class PivImageSkeleton extends StatelessWidget {
  const PivImageSkeleton({this.borderRadius, super.key});

  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => Skeletonizer.zone(
    effect: frostSkeletonEffect(context),
    child: Bone(width: double.infinity, height: double.infinity, borderRadius: borderRadius ?? BorderRadius.circular(FrostRadius.lg)),
  );
}

/// Hosts a [FrostPageHeader], now a plain row, in a `Scaffold.appBar` slot.
class PivAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PivAppBar(this.header, {super.key});

  final Widget header;

  @override
  Size get preferredSize => const Size.fromHeight(FrostPageHeader.horizontalHeight);

  @override
  Widget build(BuildContext context) => SafeArea(bottom: false, child: header);
}

/// The removed `FrostSliverPagedList` for lists paged by a provider rather than
/// a `FrostListSource`: asks for the next page when the end comes into view.
class PivSliverPagedList<T> extends StatelessWidget {
  const PivSliverPagedList({
    required this.items,
    required this.hasMore,
    required this.onLoadMore,
    required this.itemBuilder,
    required this.footer,
    this.loading = false,
    this.hasError = false,
    this.padding,
    super.key,
  });

  final List<T> items;
  final bool hasMore;
  final bool loading;
  final bool hasError;
  final Future<bool> Function() onLoadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget footer;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final list = SliverList.builder(
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index < items.length) return itemBuilder(context, items[index], index);
        if (hasMore && !loading && !hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
        }
        return footer;
      },
    );
    return padding == null ? list : SliverPadding(padding: padding!, sliver: list);
  }
}
