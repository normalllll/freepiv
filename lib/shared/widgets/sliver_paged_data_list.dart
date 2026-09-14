import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:loading_more_list/loading_more_list.dart';

import 'refresh_indicator.dart';

/// Connects an immutable provider-owned collection to loading_more_list without
/// copying its items or moving request/cursor ownership into the widget.
class SliverPagedDataList<T> extends StatefulWidget {
  const SliverPagedDataList({
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
  final DataLoadingItemBuilder<T> itemBuilder;
  final Widget footer;
  final EdgeInsetsGeometry? padding;

  @override
  State<SliverPagedDataList<T>> createState() => _SliverPagedDataListState<T>();
}

class _SliverPagedDataListState<T> extends State<SliverPagedDataList<T>> {
  late final _source = _ProviderListSource<T>(() => widget, () => mounted);

  @override
  void didUpdateWidget(covariant SliverPagedDataList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.hasError && !_source.isLoading) _source.indicatorStatus = IndicatorStatus.none;
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LoadingMoreSliverList<T>(
    SliverListConfig<T>(
      sourceList: _source,
      autoRefresh: false,
      lock: widget.loading || widget.hasError,
      padding: widget.padding,
      itemBuilder: widget.itemBuilder,
      indicatorBuilder: (_, _) => widget.footer,
    ),
  );
}

class _ProviderListSource<T> extends LoadingMoreBase<T> {
  _ProviderListSource(this.current, this.isMounted) {
    indicatorStatus = IndicatorStatus.none;
  }

  final SliverPagedDataList<T> Function() current;
  final bool Function() isMounted;

  @override
  int get length => current().items.length;
  @override
  T operator [](int index) => current().items[index];
  @override
  bool get hasMore => isMounted() && current().hasMore;

  @override
  bool get hasError => isMounted() && current().hasError;

  @override
  Future<bool> loadMore() async {
    if (!isMounted() || isLoading || current().loading || !current().hasMore) return true;
    if (current().hasError) return false;
    return super.loadMore();
  }

  @override
  Future<bool> loadData([bool isLoadMoreAction = false]) async {
    // The package may request another page while laying out the final item.
    // Defer provider writes until that frame has finished.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      await SchedulerBinding.instance.endOfFrame;
    }
    if (!isMounted()) return true;
    if (current().loading || !current().hasMore) return true;
    if (current().hasError) return false;
    return current().onLoadMore();
  }
}
