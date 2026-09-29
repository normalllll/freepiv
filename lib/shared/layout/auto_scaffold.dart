import 'package:flutter/material.dart';

typedef AutoScaffoldBuilder = Widget Function(BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool useHorizontalLayout);

class AutoScaffold extends StatelessWidget {
  const AutoScaffold({required this.builder, this.mobileBreakpoint = 600, this.tabletBreakpoint = 900, this.desktopBreakpoint = 1200, super.key});

  final AutoScaffoldBuilder builder;
  final double mobileBreakpoint;
  final double tabletBreakpoint;
  final double desktopBreakpoint;

  static bool usesHorizontalLayoutOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShellLayout>()?.horizontal ?? isHorizontalSize(MediaQuery.sizeOf(context));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final orientation = size.width >= size.height ? Orientation.landscape : Orientation.portrait;

    final layout = AutoScaffoldLayout.fromSize(
      size,
      mobileBreakpoint: mobileBreakpoint,
      tabletBreakpoint: tabletBreakpoint,
      desktopBreakpoint: desktopBreakpoint,
    );

    final horizontal = usesHorizontalLayoutOf(context);
    return _ShellLayout(horizontal: horizontal, child: builder(context, layout, orientation, horizontal));
  }
}

// Descendants use the window's navigation mode even after ContentViewport
// subtracts the sidebar or a detail pane constrains the available content width.
class _ShellLayout extends InheritedWidget {
  const _ShellLayout({required this.horizontal, required super.child});
  final bool horizontal;

  @override
  bool updateShouldNotify(_ShellLayout oldWidget) => horizontal != oldWidget.horizontal;
}

enum AutoScaffoldSizeClass { compact, medium, expanded, large }

class AutoScaffoldLayout {
  const AutoScaffoldLayout({required this.size, required this.sizeClass});

  factory AutoScaffoldLayout.fromSize(Size size, {required double mobileBreakpoint, required double tabletBreakpoint, required double desktopBreakpoint}) {
    final width = size.width;
    final sizeClass = switch (width) {
      final value when value < mobileBreakpoint => AutoScaffoldSizeClass.compact,
      final value when value < tabletBreakpoint => AutoScaffoldSizeClass.medium,
      final value when value < desktopBreakpoint => AutoScaffoldSizeClass.expanded,
      _ => AutoScaffoldSizeClass.large,
    };

    return AutoScaffoldLayout(size: size, sizeClass: sizeClass);
  }

  final Size size;
  final AutoScaffoldSizeClass sizeClass;

  double get width => size.width;

  double get height => size.height;

  double get shortestSide => size.shortestSide;

  bool get isCompact => sizeClass == AutoScaffoldSizeClass.compact;

  bool get isMedium => sizeClass == AutoScaffoldSizeClass.medium;

  bool get isExpanded => sizeClass == AutoScaffoldSizeClass.expanded;

  bool get isLarge => sizeClass == AutoScaffoldSizeClass.large;
}

/// Navigation responds to window width, even in a short or landscape window.
bool isHorizontalSize(Size size) => size.width >= 600;

/// Install above the router so nested viewports and keyboards cannot change mode.
class AppLayoutScope extends StatelessWidget {
  const AppLayoutScope({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => _ShellLayout(horizontal: isHorizontalSize(MediaQuery.sizeOf(context)), child: child);
}
