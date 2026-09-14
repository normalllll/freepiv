import 'package:flutter/material.dart';
import 'package:freepiv/core/platform/platform_info.dart';

typedef AutoScaffoldBuilder = Widget Function(BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell);

class AutoScaffold extends StatelessWidget {
  const AutoScaffold({required this.builder, this.mobileBreakpoint = 600, this.tabletBreakpoint = 900, this.desktopBreakpoint = 1200, super.key});

  final AutoScaffoldBuilder builder;
  final double mobileBreakpoint;
  final double tabletBreakpoint;
  final double desktopBreakpoint;

  static bool usesDesktopShellOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShellLayout>()?.desktop ?? _shouldUseDesktopShell(MediaQuery.sizeOf(context));

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

    final desktop = usesDesktopShellOf(context);
    return _ShellLayout(desktop: desktop, child: builder(context, layout, orientation, desktop));
  }
}

// Descendants use the window's navigation mode even after ContentViewport
// subtracts the sidebar or a detail pane constrains the available content width.
class _ShellLayout extends InheritedWidget {
  const _ShellLayout({required this.desktop, required super.child});
  final bool desktop;

  @override
  bool updateShouldNotify(_ShellLayout oldWidget) => desktop != oldWidget.desktop;
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

bool _shouldUseDesktopShell(Size layout) {
  if (!isDesktopPlatform && layout.shortestSide < 600) {
    return false;
  }

  if (isDesktopPlatform) {
    return layout.width >= 840;
  }

  return layout.width >= 900;
}
