import 'package:flutter/widgets.dart';

/// Keeps a [TabBarView] page built after it has been shown, so swiping away
/// and back preserves its scroll position and loaded content.
class KeepAliveTab extends StatefulWidget {
  const KeepAliveTab({required this.child, super.key});

  final Widget child;

  @override
  State<KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<KeepAliveTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
