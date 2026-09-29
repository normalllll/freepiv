import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/layout/shell_navigation_scope.dart';

/// A page header whose back action belongs to the shell when it is visible.
class FpPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const FpPageHeader({required this.title, this.actions, this.onBack, super.key});

  final Widget title;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  /// Width of the leading slot around [CompactBackButton]; its arrow then
  /// sits on the phone page inset instead of 16 in.
  static const leadingWidth = CompactBackButton.width + 4;

  /// Gap between a compact back button and the title.
  static const titleSpacingAfterBack = 8.0;

  /// The title spacing for a header built around [leadingFor]: tight after
  /// the compact back button, the toolbar default without one.
  static double? titleSpacingOf(BuildContext context, {VoidCallback? onBack}) => leadingFor(context, onBack: onBack) == null ? null : titleSpacingAfterBack;

  /// Use with a sliver or a custom header that cannot use [FpPageHeader].
  static Widget? leadingFor(BuildContext context, {VoidCallback? onBack}) {
    final navigation = ShellNavigationScope.maybeOf(context);
    if (navigation?.ownsBackControl ?? false) return null;
    if (navigation != null) {
      return navigation.canGoBack ? CompactBackButton(onPressed: navigation.goBack) : null;
    }
    if (onBack != null) return CompactBackButton(onPressed: onBack);
    if (Navigator.of(context).canPop()) return CompactBackButton(onPressed: () => Navigator.of(context).maybePop());
    return null;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final leading = leadingFor(context, onBack: onBack);
    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading,
      leadingWidth: leadingWidth,
      titleSpacing: leading == null ? null : titleSpacingAfterBack,
      title: title,
      actions: actions,
    );
  }
}

/// The back control on phone headers. Most people go back with the system
/// gesture, so it is drawn compact: a 40-wide target instead of Material's
/// 48 plus leading padding, leaving the width to the title or the search
/// field beside it. It keeps a full-height target and the platform tooltip.
class CompactBackButton extends StatelessWidget {
  const CompactBackButton({required this.onPressed, super.key});

  static const width = 40.0;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back, size: 22),
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(width, 44),
        fixedSize: const Size(width, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Whether the page's title already shows in the window's own caption bar:
/// only the Windows desktop layout has one. Everywhere else (phones, and the
/// sidebar layout on Android) the page shows its own header.
bool windowCaptionShowsPageTitle(BuildContext context, {required bool useHorizontalLayout}) =>
    useHorizontalLayout && Theme.of(context).platform == TargetPlatform.windows;

/// The heading of a page in the sidebar layout: a large title directly on the
/// backdrop, in the same column as the content below it. Phones use
/// [FpPageHeader] instead.
class FpInlinePageHeading extends StatelessWidget {
  const FpInlinePageHeading({required this.title, this.actions = const [], this.maxWidth = AppMetrics.contentMaxWidth, super.key});

  final String title;

  /// The content column the heading lines up with.
  final double maxWidth;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = AppMetrics.columnPadding(constraints.maxWidth, maxWidth: maxWidth).left;
        return Padding(
          padding: EdgeInsets.fromLTRB(inset, AppMetrics.sectionHeadingGap, inset - (actions.isEmpty ? 0 : 8), 0),
          child: Row(
            children: [
              Expanded(
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
              ),
              ...actions,
            ],
          ),
        );
      },
    );
  }
}
