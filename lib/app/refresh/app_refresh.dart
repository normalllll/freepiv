import 'package:flutter/widgets.dart';

/// Makes [onRefresh] the page's refresh for the shell's F5 (and, later, the
/// content's "Refresh" context menu item). Of the registered scopes, the one
/// on the current route in the visible branch refreshes; pages hidden in
/// another destination's branch or covered by a pushed page do not.
class AppRefreshScope extends StatefulWidget {
  const AppRefreshScope({required this.onRefresh, required this.child, super.key});

  final Future<void> Function() onRefresh;
  final Widget child;

  static final List<_AppRefreshScopeState> _scopes = [];

  /// Refreshes the visible page. Returns whether a page took the refresh.
  static bool refreshVisible() {
    for (final scope in _scopes.reversed) {
      if (scope._visible) {
        scope.widget.onRefresh();
        return true;
      }
    }
    return false;
  }

  @override
  State<AppRefreshScope> createState() => _AppRefreshScopeState();
}

class _AppRefreshScopeState extends State<AppRefreshScope> {
  bool get _visible {
    if (!mounted) return false;
    // An inactive destination branch keeps its pages with tickers muted.
    if (!TickerMode.valuesOf(context).enabled) return false;
    return ModalRoute.isCurrentOf(context) ?? true;
  }

  @override
  void initState() {
    super.initState();
    AppRefreshScope._scopes.add(this);
  }

  @override
  void dispose() {
    AppRefreshScope._scopes.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
