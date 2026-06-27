import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:freepiv/shared/widgets/refresh_indicator.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';

typedef DataRefreshViewBuilder = Widget Function(BuildContext context, ScrollPhysics? physics, DataRefreshLocators locators);

typedef DataNestedRefreshBodyBuilder = Widget Function(BuildContext context, DataRefreshLocators locators);

typedef DataNestedRefreshViewBuilder = Widget Function(BuildContext context, DataNestedRefreshContext refresh);

typedef DataRefreshAction = FutureOr<bool> Function();

const _dataRefreshPrimaryScrollPlatforms = <TargetPlatform>{
  TargetPlatform.android,
  TargetPlatform.fuchsia,
  TargetPlatform.iOS,
  TargetPlatform.linux,
  TargetPlatform.macOS,
  TargetPlatform.windows,
};

class DataNestedRefreshContext {
  const DataNestedRefreshContext._({required this.physics, required this.scrollController, required this.locators, required this._bodyBuilder});

  final ScrollPhysics? physics;
  final ScrollController scrollController;
  final DataRefreshLocators locators;
  final Widget Function(DataNestedRefreshBodyBuilder builder) _bodyBuilder;

  Widget body({required DataNestedRefreshBodyBuilder builder}) {
    return _bodyBuilder(builder);
  }
}

class DataRefreshLocators {
  const DataRefreshLocators._({this.sliverHeader});

  final Widget? sliverHeader;

  static const refresh = DataRefreshLocators._(sliverHeader: DataRefreshSliverHeader());
}

class DataRefreshView extends StatefulWidget {
  const DataRefreshView({required this.builder, this.scrollController, this.onRefresh, super.key});

  final ScrollController? scrollController;
  final DataRefreshAction? onRefresh;
  final DataRefreshViewBuilder builder;

  @override
  State<DataRefreshView> createState() => _DataRefreshViewState();
}

class DataNestedRefreshView extends StatefulWidget {
  const DataNestedRefreshView({required this.builder, this.onRefresh, this.headerSnapExtent, this.headerMobileSnapTriggerExtent = 64, super.key});

  final DataRefreshAction? onRefresh;
  final double? headerSnapExtent;
  final double headerMobileSnapTriggerExtent;
  final DataNestedRefreshViewBuilder builder;

  @override
  State<DataNestedRefreshView> createState() => _DataNestedRefreshViewState();
}

mixin _DataRefreshCallbackMixin<T extends StatefulWidget> on State<T> {
  DataRefreshAction? get _onRefresh;

  Future<bool> _handleRefresh() async {
    final onRefresh = _onRefresh;
    if (onRefresh == null) {
      return true;
    }

    await _waitForSafeCallbackPhase();
    try {
      return await Future<bool>.value(onRefresh());
    } catch (e, s) {
      log('Failed to refresh data view.', error: e, stackTrace: s);
      return false;
    }
  }

  Future<void> _waitForSafeCallbackPhase() async {
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      return;
    }

    await SchedulerBinding.instance.endOfFrame;
  }
}

class _DataRefreshViewState extends State<DataRefreshView> with _DataRefreshCallbackMixin<DataRefreshView> {
  late final ScrollController _ownedScrollController = ScrollController();

  ScrollController get _effectiveScrollController => widget.scrollController ?? _ownedScrollController;

  @override
  DataRefreshAction? get _onRefresh => widget.onRefresh;

  @override
  Widget build(BuildContext context) {
    final child = ScrollConfiguration(
      behavior: dataRefreshScrollBehavior,
      child: PrimaryScrollController(
        controller: _effectiveScrollController,
        automaticallyInheritForPlatforms: _dataRefreshPrimaryScrollPlatforms,
        child: widget.builder(context, dataRefreshPhysics, DataRefreshLocators.refresh),
      ),
    );

    if (widget.onRefresh == null) {
      return child;
    }

    return PullToRefreshNotification(
      color: Theme.of(context).colorScheme.primary,
      maxDragOffset: DataRefreshSliverHeader.maxDragOffset,
      refreshOffset: DataRefreshSliverHeader.refreshOffset,
      reachToRefreshOffset: DataRefreshSliverHeader.reachToRefreshOffset,
      armedDragUpCancel: false,
      pullBackOnRefresh: true,
      pullBackOnError: true,
      onRefresh: _handleRefresh,
      child: child,
    );
  }

  @override
  void dispose() {
    _ownedScrollController.dispose();
    super.dispose();
  }
}

class _DataNestedRefreshViewState extends State<DataNestedRefreshView> with _DataRefreshCallbackMixin<DataNestedRefreshView> {
  final _nestedScrollController = ScrollController();
  bool _nestedHeaderSnapAnimating = false;

  @override
  DataRefreshAction? get _onRefresh => widget.onRefresh;

  @override
  Widget build(BuildContext context) {
    final refresh = DataNestedRefreshContext._(
      physics: dataRefreshPhysics,
      scrollController: _nestedScrollController,
      locators: DataRefreshLocators.refresh,
      bodyBuilder: _buildNestedBody,
    );

    Widget child = ScrollConfiguration(behavior: dataRefreshScrollBehavior, child: widget.builder(context, refresh));

    if (widget.headerSnapExtent != null) {
      child = NotificationListener<ScrollNotification>(onNotification: _handleNestedHeaderSnapNotification, child: child);
    }

    if (widget.onRefresh == null) {
      return child;
    }

    return PullToRefreshNotification(
      color: Theme.of(context).colorScheme.primary,
      maxDragOffset: DataRefreshSliverHeader.maxDragOffset,
      refreshOffset: DataRefreshSliverHeader.refreshOffset,
      reachToRefreshOffset: DataRefreshSliverHeader.reachToRefreshOffset,
      armedDragUpCancel: false,
      pullBackOnRefresh: true,
      pullBackOnError: true,
      onRefresh: _handleRefresh,
      child: child,
    );
  }

  @override
  void dispose() {
    _nestedScrollController.dispose();
    super.dispose();
  }

  Widget _buildNestedBody(DataNestedRefreshBodyBuilder builder) {
    return Builder(builder: (context) => builder(context, DataRefreshLocators.refresh));
  }

  bool _handleNestedHeaderSnapNotification(ScrollNotification notification) {
    final snapExtent = widget.headerSnapExtent;
    if (snapExtent == null || snapExtent <= 0 || notification.depth != 0 || notification.metrics.axis != Axis.vertical || _nestedHeaderSnapAnimating) {
      return false;
    }

    if (notification is! ScrollUpdateNotification || notification.dragDetails == null) {
      return false;
    }

    final scrollDelta = notification.scrollDelta;
    final pixels = notification.metrics.pixels;
    if (scrollDelta == null || scrollDelta <= 0 || pixels <= 0 || pixels >= snapExtent - 1) {
      return false;
    }

    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.linux || platform == TargetPlatform.macOS || platform == TargetPlatform.windows) {
      return false;
    }

    if (pixels >= widget.headerMobileSnapTriggerExtent) {
      _animateNestedHeaderTo(snapExtent, duration: const Duration(milliseconds: 260));
    }

    return false;
  }

  Future<void> _animateNestedHeaderTo(double target, {required Duration duration}) async {
    if (!_nestedScrollController.hasClients) {
      return;
    }

    ScrollPosition? scrollPosition;
    for (final position in _nestedScrollController.positions) {
      if (position.axis == Axis.vertical) {
        scrollPosition = position;
        break;
      }
    }

    if (scrollPosition == null || !scrollPosition.hasPixels) {
      return;
    }

    final clampedTarget = target.clamp(scrollPosition.minScrollExtent, scrollPosition.maxScrollExtent);
    if ((scrollPosition.pixels - clampedTarget).abs() < 1) {
      return;
    }

    _nestedHeaderSnapAnimating = true;
    try {
      await scrollPosition.animateTo(clampedTarget, duration: duration, curve: Curves.easeOutCubic);
    } finally {
      _nestedHeaderSnapAnimating = false;
    }
  }
}
