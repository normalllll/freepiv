import 'package:flutter/widgets.dart';

/// Route changes include popup menus and dialogs, unlike router URI changes.
class ReaderRouteObserver extends NavigatorObserver {
  final changes = ValueNotifier<int>(0);
  Route<dynamic>? topRoute;

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    this.topRoute = topRoute;
    changes.value++;
  }
}

final readerRootRouteObserver = ReaderRouteObserver();
final readerContentRouteObserver = ReaderRouteObserver();
