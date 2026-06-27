import 'dart:collection';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:loading_more_list/loading_more_list.dart';

abstract class DataListSource<T> extends LoadingMoreBase<T> implements Listenable {
  bool _initialized = false;
  bool _hasMore = true;
  bool _disposed = false;

  Object? _lastError;
  int _requestId = 0;

  final List<VoidCallback> _listeners = <VoidCallback>[];
  bool _notifyScheduled = false;

  UnmodifiableListView<T> get items => UnmodifiableListView(this);

  bool get initialized => _initialized;

  bool get refreshing => isLoading && indicatorStatus == IndicatorStatus.fullScreenBusying;

  bool get loadingMore => isLoading && indicatorStatus == IndicatorStatus.loadingMoreBusying;

  bool get busy => isLoading;

  Object? get lastError => _lastError;

  @override
  bool get hasMore => !_initialized || _hasMore;

  @override
  Future<bool> refresh([bool notifyStateChanged = false]) async {
    _requestId++;
    _lastError = null;

    if (notifyStateChanged) {
      _initialized = false;
      _hasMore = true;
    }

    final result = super.refresh(notifyStateChanged);
    _notify();

    final success = await result;
    _notify();
    return success;
  }

  @override
  Future<bool> loadMore() async {
    if (!_initialized) {
      return refresh(true);
    }

    if (!_hasMore || isLoading) {
      return true;
    }

    _lastError = null;

    final result = super.loadMore();
    _notify();

    final success = await result;
    _notify();
    return success;
  }

  @override
  Future<bool> loadData([bool isLoadMoreAction = false]) async {
    final requestId = _requestId;

    try {
      final list = isLoadMoreAction ? await nextList() : await initList();

      if (requestId != _requestId) {
        return true;
      }

      if (isLoadMoreAction) {
        if (list.isEmpty) {
          _hasMore = false;
        } else {
          addAll(list);
          _hasMore = hasMoreByResult(list);
        }
      } else {
        clear();
        addAll(list);
        _initialized = true;
        _hasMore = hasMoreByResult(list);
      }

      return true;
    } catch (e, s) {
      if (requestId != _requestId) {
        return true;
      }

      _lastError = e;
      log(isLoadMoreAction ? 'Failed to load more data list.' : 'Failed to refresh data list.', error: e, stackTrace: s);
      return false;
    }
  }

  void clearData() {
    _requestId++;
    clear();
    _initialized = false;
    _hasMore = true;
    _lastError = null;
    isLoading = false;
    indicatorStatus = IndicatorStatus.fullScreenBusying;
    _notify();
  }

  @protected
  void notifyDataChanged() {
    _notify();
  }

  @protected
  bool hasMoreByResult(List<T> list) {
    return list.isNotEmpty;
  }

  void _notify() {
    if (_disposed) {
      return;
    }

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      _scheduleNotify();
      return;
    }

    _flushNotify();
  }

  void _scheduleNotify() {
    if (_notifyScheduled) {
      return;
    }

    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      _flushNotify();
    });
  }

  void _flushNotify() {
    if (_disposed) {
      return;
    }

    super.setState();

    final localListeners = List<VoidCallback>.of(_listeners);
    for (final listener in localListeners) {
      if (_listeners.contains(listener)) {
        listener();
      }
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @override
  void dispose() {
    _disposed = true;
    _listeners.clear();
    super.dispose();
  }

  Future<List<T>> initList();

  Future<List<T>> nextList();
}
