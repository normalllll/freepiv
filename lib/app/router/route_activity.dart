import 'package:flutter/widgets.dart';

/// The top route of one navigator, for pages that must pause while anything
/// covers them from another navigator (the novel reader's auto-scroll and
/// volume keys under a dialog of the root navigator). Notifies on every change.
class AppRouteActivity extends NavigatorObserver with ChangeNotifier {
  final List<Route<dynamic>> _stack = [];

  Route<dynamic>? get top => _stack.lastOrNull;

  /// Whether a popup (dialog, sheet, menu) is on top of this navigator.
  bool get popupOnTop => top is PopupRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    notifyListeners();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    notifyListeners();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    notifyListeners();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute != null) {
      if (index >= 0) {
        _stack[index] = newRoute;
      } else {
        _stack.add(newRoute);
      }
    } else if (index >= 0) {
      _stack.removeAt(index);
    }
    notifyListeners();
  }
}

/// The root navigator's routes: dialogs and sheets over the whole window.
final appRootRouteActivity = AppRouteActivity();
