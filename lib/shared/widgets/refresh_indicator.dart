import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/data/data_list_source.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';

import 'error.dart';

typedef DataLoadingItemBuilder<T> = Widget Function(BuildContext context, T item, int index);

const dataRefreshPhysics = AlwaysScrollableClampingScrollPhysics();
const dataRefreshScrollBehavior = _DataRefreshScrollBehavior();

class _DataRefreshScrollBehavior extends MaterialScrollBehavior {
  const _DataRefreshScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };
}

class DataRefreshSliverHeader extends StatelessWidget {
  const DataRefreshSliverHeader({super.key});

  static const refreshOffset = 56.0;
  static const reachToRefreshOffset = 84.0;
  static const maxDragOffset = 120.0;

  @override
  Widget build(BuildContext context) {
    return PullToRefreshContainer((info) {
      final mode = info?.mode;
      final offset = info?.dragOffset ?? 0.0;

      if ((mode == null || mode == PullToRefreshIndicatorMode.canceled) && offset <= 0) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      return SliverToBoxAdapter(child: _DataPullRefreshHeaderBody(info: info));
    });
  }
}

class _DataPullRefreshHeaderBody extends StatelessWidget {
  const _DataPullRefreshHeaderBody({required this.info});

  final PullToRefreshScrollNotificationInfo? info;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.refresh;
    final mode = info?.mode;
    final offset = info?.dragOffset ?? 0.0;
    final height = offset.clamp(0.0, DataRefreshSliverHeader.maxDragOffset);
    final statusText = switch (mode) {
      PullToRefreshIndicatorMode.armed => translations.releaseToRefresh,
      PullToRefreshIndicatorMode.snap || PullToRefreshIndicatorMode.refresh => translations.refreshing,
      PullToRefreshIndicatorMode.done => translations.refreshComplete,
      PullToRefreshIndicatorMode.error => translations.refreshFailed,
      _ => translations.pullToRefresh,
    };

    final colorScheme = Theme.of(context).colorScheme;
    final indicator = switch (mode) {
      PullToRefreshIndicatorMode.snap ||
      PullToRefreshIndicatorMode.refresh => SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: colorScheme.primary)),
      PullToRefreshIndicatorMode.done => Icon(Icons.check_circle_outline, size: 22, color: colorScheme.primary),
      PullToRefreshIndicatorMode.error => Icon(Icons.error_outline, size: 22, color: colorScheme.error),
      _ => SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          value: (offset / DataRefreshSliverHeader.reachToRefreshOffset).clamp(0.0, 1.0),
          color: colorScheme.primary,
          backgroundColor: colorScheme.surfaceContainerHighest,
        ),
      ),
    };

    final child = SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: DataRefreshSliverHeader.refreshOffset,
          child: Center(
            child: _InlineRefreshStatus(icon: indicator, label: statusText),
          ),
        ),
      ),
    );

    if (mode == PullToRefreshIndicatorMode.error && info != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => info!.pullToRefreshNotificationState.show(notificationDragOffset: DataRefreshSliverHeader.reachToRefreshOffset),
        child: child,
      );
    }

    return child;
  }
}

class _InlineRefreshStatus extends StatelessWidget {
  const _InlineRefreshStatus({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(dimension: 22, child: Center(child: icon)),
        const SizedBox(width: 8),
        Text(label, style: textStyle),
      ],
    );
  }
}

class DataLoadingCustomScrollView extends StatelessWidget {
  const DataLoadingCustomScrollView({
    required this.slivers,
    this.controller,
    this.physics,
    this.primary,
    this.shrinkWrap = false,
    this.cacheExtent,
    this.preloadExtent = 480,
    this.clipBehavior = Clip.hardEdge,
    super.key,
  });

  final List<Widget> slivers;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool? primary;
  final bool shrinkWrap;
  final double? cacheExtent;
  final double preloadExtent;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: dataRefreshScrollBehavior,
      child: LoadingMoreCustomScrollView(
        controller: controller,
        physics: physics ?? dataRefreshPhysics,
        primary: primary,
        shrinkWrap: shrinkWrap,
        cacheExtent: cacheExtent,
        preloadExtent: preloadExtent,
        showGlowLeading: false,
        getConfigFromSliverContext: true,
        clipBehavior: clipBehavior,
        slivers: slivers,
      ),
    );
  }
}

class SliverDataList<T> extends StatelessWidget {
  const SliverDataList({required this.source, required this.itemBuilder, this.padding, this.itemExtent, this.autoLoadMore = true, super.key});

  final DataListSource<T> source;
  final DataLoadingItemBuilder<T> itemBuilder;
  final EdgeInsetsGeometry? padding;
  final double? itemExtent;
  final bool autoLoadMore;

  @override
  Widget build(BuildContext context) {
    return LoadingMoreSliverList<T>(
      SliverListConfig<T>(
        sourceList: source,
        itemBuilder: itemBuilder,
        indicatorBuilder: _indicatorBuilder(source),
        padding: padding,
        itemExtent: itemExtent,
        autoRefresh: false,
        autoLoadMore: autoLoadMore,
      ),
    );
  }
}

class SliverDataWaterfallGrid<T> extends StatelessWidget {
  const SliverDataWaterfallGrid({
    required this.source,
    required this.itemBuilder,
    this.maxCrossAxisExtent = 240,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.padding = const EdgeInsets.all(8),
    this.autoLoadMore = true,
    super.key,
  });

  final DataListSource<T> source;
  final DataLoadingItemBuilder<T> itemBuilder;
  final double maxCrossAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;
  final bool autoLoadMore;

  @override
  Widget build(BuildContext context) {
    return LoadingMoreSliverList<T>(
      SliverListConfig<T>(
        sourceList: source,
        itemBuilder: itemBuilder,
        indicatorBuilder: _indicatorBuilder(source),
        padding: padding,
        autoRefresh: false,
        autoLoadMore: autoLoadMore,
        extendedListDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
      ),
    );
  }
}

class DataSliverFillBody extends StatelessWidget {
  const DataSliverFillBody({required this.child, this.physics, this.sliverHeader, this.leadingSlivers = const [], super.key});

  final Widget child;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;
  final List<Widget> leadingSlivers;

  @override
  Widget build(BuildContext context) {
    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?sliverHeader,
        ...leadingSlivers,
        SliverFillRemaining(hasScrollBody: false, child: child),
      ],
    );
  }
}

LoadingMoreIndicatorBuilder _indicatorBuilder<T>(DataListSource<T> source) {
  return (context, status) {
    return DataLoadingMoreIndicator(status: status, source: source);
  };
}

class DataLoadingMoreIndicator<T> extends StatelessWidget {
  const DataLoadingMoreIndicator({required this.status, required this.source, super.key});

  final IndicatorStatus status;
  final DataListSource<T> source;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      IndicatorStatus.none => const SizedBox.shrink(),
      IndicatorStatus.loadingMoreBusying => _FooterIndicator(
        icon: const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        label: context.t.refresh.loading,
      ),
      IndicatorStatus.error => _FooterIndicator(
        icon: Icon(Icons.error_outline, size: 20, color: Theme.of(context).colorScheme.error),
        label: context.t.refresh.loadFailed,
        onTap: source.errorRefresh,
      ),
      IndicatorStatus.noMoreLoad => _FooterIndicator(
        icon: Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        label: context.t.refresh.noMoreItems,
      ),
      IndicatorStatus.fullScreenBusying => SliverFillRemaining(
        hasScrollBody: false,
        child: _FullScreenIndicator(
          icon: const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.4)),
          label: context.t.refresh.loading,
        ),
      ),
      IndicatorStatus.fullScreenError => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorContent(message: source.lastError?.toString() ?? context.t.refresh.loadFailed, onRetry: () => source.refresh(true)),
      ),
      IndicatorStatus.empty => SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyContent(icon: Icons.inbox_outlined, title: context.t.refresh.noMoreItems),
      ),
    };
  }
}

class _FooterIndicator extends StatelessWidget {
  const _FooterIndicator({required this.icon, required this.label, this.onTap});

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: 56,
      child: Center(
        child: _InlineRefreshStatus(icon: icon, label: label),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(onTap: onTap, child: child);
  }
}

class _FullScreenIndicator extends StatelessWidget {
  const _FullScreenIndicator({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _InlineRefreshStatus(icon: icon, label: label),
    );
  }
}

class EmptyContent extends StatelessWidget {
  const EmptyContent({required this.icon, required this.title, this.message, super.key});

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
