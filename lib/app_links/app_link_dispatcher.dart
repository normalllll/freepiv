import 'dart:async';
import 'dart:collection';

import 'package:app_links/app_links.dart';

import 'app_link_request.dart';
import 'platform/app_link_platform_registrar.dart';

typedef AppLinkCallback = FutureOr<void> Function(AppLinkRequest request);
typedef AppLinkErrorCallback = FutureOr<void> Function(Object error);

final appLinkDispatcher = AppLinkDispatcher();

final class AppLinkDispatcher {
  AppLinkDispatcher({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  final Set<AppLinkCallback> _linkCallbacks = <AppLinkCallback>{};
  final Set<AppLinkErrorCallback> _errorCallbacks = <AppLinkErrorCallback>{};
  final Queue<AppLinkRequest> _pendingLinks = Queue<AppLinkRequest>();
  final Queue<Object> _pendingErrors = Queue<Object>();

  StreamSubscription<Uri>? _subscription;
  Future<void>? _startFuture;

  Future<void> start() {
    return _startFuture ??= _start();
  }

  AppLinkCallbackHandle registerCallback(AppLinkCallback callback) {
    _linkCallbacks.add(callback);
    _flushPendingLinks(callback);

    return AppLinkCallbackHandle(() {
      _linkCallbacks.remove(callback);
    });
  }

  AppLinkCallbackHandle registerErrorCallback(AppLinkErrorCallback callback) {
    _errorCallbacks.add(callback);
    _flushPendingErrors(callback);

    return AppLinkCallbackHandle(() {
      _errorCallbacks.remove(callback);
    });
  }

  Future<void> _start() async {
    try {
      await registerPlatformAppLinks();
    } catch (error) {
      _dispatchError(error);
    }

    _subscription = _appLinks.uriLinkStream.listen(
      _dispatchLink,
      onError: (Object error) {
        _dispatchError(error);
      },
    );
  }

  void _dispatchLink(Uri uri) {
    final request = AppLinkRequest(uri);
    if (_linkCallbacks.isEmpty) {
      _pendingLinks.add(request);
      return;
    }

    for (final callback in List<AppLinkCallback>.of(_linkCallbacks)) {
      unawaited(_invokeLinkCallback(callback, request));
    }
  }

  void _dispatchError(Object error) {
    if (_errorCallbacks.isEmpty) {
      _pendingErrors.add(error);
      return;
    }

    for (final callback in List<AppLinkErrorCallback>.of(_errorCallbacks)) {
      unawaited(_invokeErrorCallback(callback, error));
    }
  }

  void _flushPendingLinks(AppLinkCallback callback) {
    if (_pendingLinks.isEmpty) {
      return;
    }

    final pendingLinks = List<AppLinkRequest>.of(_pendingLinks);
    _pendingLinks.clear();

    for (final request in pendingLinks) {
      unawaited(_invokeLinkCallback(callback, request));
    }
  }

  void _flushPendingErrors(AppLinkErrorCallback callback) {
    if (_pendingErrors.isEmpty) {
      return;
    }

    final pendingErrors = List<Object>.of(_pendingErrors);
    _pendingErrors.clear();

    for (final error in pendingErrors) {
      unawaited(_invokeErrorCallback(callback, error));
    }
  }

  Future<void> _invokeLinkCallback(AppLinkCallback callback, AppLinkRequest request) async {
    try {
      await callback(request);
    } catch (error) {
      _dispatchError(error);
    }
  }

  Future<void> _invokeErrorCallback(AppLinkErrorCallback callback, Object error) async {
    try {
      await callback(error);
    } catch (_) {
      // Error callbacks are already the last reporting path.
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _startFuture = null;
    _pendingLinks.clear();
    _pendingErrors.clear();
  }
}

final class AppLinkCallbackHandle {
  AppLinkCallbackHandle(this._dispose);

  final void Function() _dispose;
  bool _isDisposed = false;

  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _dispose();
  }
}
