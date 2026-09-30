import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// A [GoRouter] on which pushing the page that is already on top does
/// nothing, so a link to the page being viewed (its work in the download
/// list, a card of the work already open) never stacks a duplicate of it.
/// Every push, named or not, goes through [push].
class SingleTopGoRouter extends GoRouter {
  SingleTopGoRouter({required RoutingConfig config, super.navigatorKey, super.initialLocation, super.refreshListenable, super.observers})
    : super.routingConfig(routingConfig: _Constant(config));

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) async {
    if (isCurrentLocation(location)) return null;
    return super.push<T>(location, extra: extra);
  }

  /// Whether [location] names the page on top: same path and query, in any
  /// query order.
  bool isCurrentLocation(String location) {
    final current = routerDelegate.currentConfiguration;
    if (current.isEmpty) return false;
    // A pushed page keeps its own location; the configuration's uri stays
    // at the location the stack was built from.
    final top = switch (current.last) {
      ImperativeRouteMatch(:final matches) => matches.uri,
      _ => current.uri,
    };
    final target = Uri.parse(location);
    return target.path == top.path && mapEquals(target.queryParameters, top.queryParameters);
  }
}

class _Constant implements ValueListenable<RoutingConfig> {
  const _Constant(this.value);

  @override
  final RoutingConfig value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
