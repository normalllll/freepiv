import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:freepiv/app/router/app_route.dart';

/// The shell is the single owner of ordinary desktop page back navigation.
class ShellNavigationScope extends InheritedWidget {
  const ShellNavigationScope({
    required this.ownsBackControl,
    required this.canGoBack,
    required this.goBack,
    required this.primaryReselection,
    required super.child,
    super.key,
  });

  final bool ownsBackControl;
  final bool canGoBack;
  final VoidCallback goBack;
  final ValueListenable<({AppRoute route, int sequence})> primaryReselection;

  static ShellNavigationScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellNavigationScope>();

  @override
  bool updateShouldNotify(ShellNavigationScope oldWidget) =>
      ownsBackControl != oldWidget.ownsBackControl ||
      canGoBack != oldWidget.canGoBack ||
      goBack != oldWidget.goBack ||
      primaryReselection != oldWidget.primaryReselection;
}
