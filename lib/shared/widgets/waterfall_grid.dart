import 'package:flutter/material.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

typedef WaterfallGridItemBuilder<T> = Widget Function(BuildContext context, T item, int index);

typedef LoadingWaterfallGridItemBuilder<T> = Widget Function(BuildContext context, T item, int index);

class WaterfallGrid<T> extends StatelessWidget {
  const WaterfallGrid({
    required this.items,
    required this.itemBuilder,
    this.maxCrossAxisExtent = 240,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.padding = const EdgeInsets.all(8),
    this.physics,
    this.shrinkWrap = false,
    this.sliverHeader,
    super.key,
  });

  final List<T> items;
  final WaterfallGridItemBuilder<T> itemBuilder;
  final double maxCrossAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Widget? sliverHeader;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: physics,
      shrinkWrap: shrinkWrap,
      slivers: [
        ?sliverHeader,
        SliverWaterfallGrid<T>(
          items: items,
          itemBuilder: itemBuilder,
          maxCrossAxisExtent: maxCrossAxisExtent,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          padding: padding,
        ),
      ],
    );
  }
}

class SliverWaterfallGrid<T> extends StatelessWidget {
  const SliverWaterfallGrid({
    required this.items,
    required this.itemBuilder,
    this.maxCrossAxisExtent = 240,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.padding = const EdgeInsets.all(8),
    super.key,
  });

  final List<T> items;
  final WaterfallGridItemBuilder<T> itemBuilder;
  final double maxCrossAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverWaterfallFlow(
        gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return itemBuilder(context, items[index], index);
        }, childCount: items.length),
      ),
    );
  }
}
