import 'package:flutter/widgets.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:frost_ui/frost_ui.dart';

/// The sectioned browse page: a pinned header with the
/// section tabs (in the header row while they fit, their own pinned row
/// otherwise), and one kept-alive scroll view per section that pulls to
/// refresh on its own. F5 and the content's Refresh item refresh the section
/// on screen.
class AppSectionedPage extends StatefulWidget {
  const AppSectionedPage({
    required this.header,
    required this.tabs,
    required this.controller,
    required this.slivers,
    this.onRefresh,
    this.trailing,
    this.scrollControllers,
    this.sectionKey,
    super.key,
  });

  final Widget header;
  final List<FrostTab> tabs;
  final TabController controller;

  /// The section's slivers under the chrome spacer and the refresh header.
  final List<Widget> Function(BuildContext context, int section) slivers;

  /// Refreshes a section; null for sections that do not refresh.
  final Future<void> Function(int section)? onRefresh;

  /// The current section's menu, at the end of the tab row.
  final Widget? trailing;

  /// One per section, to scroll a section back to its top.
  final List<ScrollController>? scrollControllers;

  /// What a section shows; when it changes the section starts afresh at
  /// its top, as a new search does.
  final Object? Function(int section)? sectionKey;

  @override
  State<AppSectionedPage> createState() => _AppSectionedPageState();
}

class _AppSectionedPageState extends State<AppSectionedPage> {
  Future<void> _refreshCurrent() async => widget.onRefresh?.call(widget.controller.index);

  @override
  Widget build(BuildContext context) {
    final refresh = widget.onRefresh;
    return AppRefreshScope(
      onRefresh: _refreshCurrent,
      child: FrostPinnedChrome(
        chrome: FrostHeaderSections(
          header: widget.header,
          tabs: FrostTabBar(controller: widget.controller, scrollable: true, tabs: widget.tabs),
          trailing: widget.trailing,
        ),
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => TabBarView(
            controller: widget.controller,
            children: [
              for (var section = 0; section < widget.tabs.length; section++)
                FrostKeepAlive(
                  key: ValueKey((section, widget.sectionKey?.call(section))),
                  child: FrostChromeActiveBody(
                    active: widget.controller.index == section,
                    child: Builder(
                      builder: (context) {
                        final scroll = widget.scrollControllers?[section];
                        Widget view(ScrollPhysics? physics, Widget? refreshHeader) => FrostLoadingScrollView(
                          controller: scroll,
                          physics: physics,
                          slivers: [const FrostChromeSpacer(), ?refreshHeader, ...widget.slivers(context, section)],
                        );
                        if (refresh == null) return view(null, null);
                        return FrostRefreshView(
                          scrollController: scroll,
                          onRefresh: () async {
                            await refresh(section);
                            return true;
                          },
                          builder: (context, physics, locators) => view(physics, locators.sliverHeader),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section heading in a browse page, at the browse inset.
class AppBrowseSectionHeader extends StatelessWidget {
  const AppBrowseSectionHeader({required this.title, this.actionLabel, this.onAction, super.key});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Padding(
      padding: FrostMetrics.sectionTitlePadding(constraints.maxWidth),
      child: FrostSectionHeader(title: title, actionLabel: actionLabel, onAction: onAction),
    ),
  );
}
