import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/features/downloads/presentation/download_floating_panel.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:go_router/go_router.dart';

class RouterShell extends StatelessWidget {
  const RouterShell({required this.child, required this.canPopListenable, required this.onBack, required this.onResetRightNavigator, super.key});

  final Widget child;
  final ValueListenable<bool> canPopListenable;
  final VoidCallback onBack;
  final VoidCallback onResetRightNavigator;

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (context, layout, orientation, shouldUseDesktopShell) {
        final path = GoRouterState.of(context).uri.path;
        final selectedIndex = appDestinationIndexForPath(path);

        if (shouldUseDesktopShell) {
          return _DesktopShell(
            selectedIndex: selectedIndex,
            canPopListenable: canPopListenable,
            onBack: onBack,
            onDestinationSelected: (index) => _selectIndex(context, index),
            child: child,
          );
        }

        return _MobileShell(
          selectedIndex: selectedIndex ?? 0,
          showNavigationBar: isPrimaryNavigationPath(path),
          onDestinationSelected: (index) => _selectIndex(context, index),
          child: child,
        );
      },
    );
  }

  void _selectIndex(BuildContext context, int index) {
    onResetRightNavigator();
    context.go(appRouteDestinations[index].route.path);
  }
}

class _DesktopShell extends StatefulWidget {
  const _DesktopShell({
    required this.selectedIndex,
    required this.canPopListenable,
    required this.onBack,
    required this.onDestinationSelected,
    required this.child,
  });

  final int? selectedIndex;
  final ValueListenable<bool> canPopListenable;
  final VoidCallback onBack;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell> {
  double _sidebarWidth = 96.0;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              _ReportedSize(
                onChanged: _handleSidebarSizeChanged,
                child: _DesktopSidebar(
                  selectedIndex: widget.selectedIndex,
                  canPopListenable: widget.canPopListenable,
                  onBack: widget.onBack,
                  onDestinationSelected: widget.onDestinationSelected,
                  translations: translations,
                ),
              ),
              Expanded(child: widget.child),
            ],
          ),
          DesktopDownloadDock(railWidth: _sidebarWidth),
        ],
      ),
    );
  }

  void _handleSidebarSizeChanged(Size size) {
    if ((_sidebarWidth - size.width).abs() < 0.5) {
      return;
    }

    setState(() {
      _sidebarWidth = size.width;
    });
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.canPopListenable,
    required this.onBack,
    required this.onDestinationSelected,
    required this.translations,
  });

  final int? selectedIndex;
  final ValueListenable<bool> canPopListenable;
  final VoidCallback onBack;
  final ValueChanged<int> onDestinationSelected;
  final Translations translations;

  static const _width = 96.0;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);

    return SizedBox(
      width: _width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: BorderDirectional(end: BorderSide(color: tokens.line.withValues(alpha: 0.40))),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              children: [
                _DesktopSidebarBackButton(canPopListenable: canPopListenable, onBack: onBack),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: appRouteDestinations.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final destination = appRouteDestinations[index];
                      return _DesktopNavItem(
                        label: appRouteDestinationLabel(translations, destination),
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        selected: selectedIndex == index,
                        onTap: () => onDestinationSelected(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportedSize extends StatefulWidget {
  const _ReportedSize({required this.onChanged, required this.child});

  final ValueChanged<Size> onChanged;
  final Widget child;

  @override
  State<_ReportedSize> createState() => _ReportedSizeState();
}

class _ReportedSizeState extends State<_ReportedSize> {
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
  }

  @override
  void didUpdateWidget(covariant _ReportedSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
    return widget.child;
  }

  void _reportSize() {
    if (!mounted) {
      return;
    }

    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final size = renderObject.size;
      if (_lastSize == size) {
        return;
      }

      _lastSize = size;
      widget.onChanged(size);
    }
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.selectedIndex, required this.showNavigationBar, required this.onDestinationSelected, required this.child});

  final int selectedIndex;
  final bool showNavigationBar;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return Scaffold(
      body: child,
      bottomNavigationBar: showNavigationBar
          ? _MobileNavBar(selectedIndex: selectedIndex, onDestinationSelected: onDestinationSelected, translations: translations)
          : null,
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({required this.label, required this.icon, required this.selectedIcon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = tokens.brand;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? Color.alphaBlend(accentColor.withValues(alpha: 0.11), tokens.surfaceRaised) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? accentColor.withValues(alpha: 0.28) : Colors.transparent),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 32,
                    height: 30,
                    decoration: BoxDecoration(color: selected ? accentColor : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Icon(selected ? selectedIcon : icon, size: 20, color: selected ? _onAccentColor(accentColor) : colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? accentColor : colorScheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavBar extends StatelessWidget {
  const _MobileNavBar({required this.selectedIndex, required this.onDestinationSelected, required this.translations});

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Translations translations;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(top: BorderSide(color: tokens.line.withValues(alpha: 0.56))),
        ),
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var index = 0; index < appRouteDestinations.length; index += 1)
                Expanded(
                  child: _MobileNavItem(
                    label: appRouteDestinationLabel(translations, appRouteDestinations[index]),
                    icon: appRouteDestinations[index].icon,
                    selectedIcon: appRouteDestinations[index].selectedIcon,
                    selected: selectedIndex == index,
                    onTap: () => onDestinationSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({required this.label, required this.icon, required this.selectedIcon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = FreepivThemeTokens.of(context);
    final accentColor = tokens.brand;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? selectedIcon : icon, size: 22, color: selected ? accentColor : colorScheme.onSurfaceVariant.withValues(alpha: 0.78)),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      height: 1,
                      color: selected ? accentColor : colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebarBackButton extends StatelessWidget {
  const _DesktopSidebarBackButton({required this.canPopListenable, required this.onBack});

  final ValueListenable<bool> canPopListenable;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = FreepivThemeTokens.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: canPopListenable,
      builder: (context, canPop, child) {
        return Tooltip(
          message: MaterialLocalizations.of(context).backButtonTooltip,
          child: Semantics(
            button: true,
            enabled: canPop,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canPop ? onBack : null,
              child: SizedBox(
                height: 48,
                child: Align(
                  alignment: AlignmentDirectional.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    width: 52,
                    height: 46,
                    decoration: BoxDecoration(
                      color: canPop ? tokens.brand : colorScheme.surfaceContainerHighest.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: canPop ? tokens.brand : tokens.line.withValues(alpha: 0.60)),
                    ),
                    child: Icon(Icons.arrow_back, color: canPop ? colorScheme.onPrimary : colorScheme.onSurfaceVariant.withValues(alpha: 0.42)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _onAccentColor(Color _) => Colors.white;
