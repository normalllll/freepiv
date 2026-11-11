import 'package:flutter/widgets.dart';

/// How many open pages ask the shell to keep its floating entries away, such
/// as the download button, which would lie over the page's own controls.
/// The shell rebuilds as the count changes.
final immersivePageCount = ValueNotifier<int>(0);

/// Marks [child]'s page as one that needs the whole screen: while it is in the
/// tree, [immersivePageCount] is above zero. The count changes after the frame
/// that mounts or unmounts it, never during a build.
class ImmersivePage extends StatefulWidget {
  const ImmersivePage({required this.child, super.key});

  final Widget child;

  @override
  State<ImmersivePage> createState() => _ImmersivePageState();
}

class _ImmersivePageState extends State<ImmersivePage> {
  @override
  void initState() {
    super.initState();
    _change(1);
  }

  @override
  void dispose() {
    _change(-1);
    super.dispose();
  }

  static void _change(int by) => WidgetsBinding.instance.addPostFrameCallback((_) => immersivePageCount.value += by);

  @override
  Widget build(BuildContext context) => widget.child;
}
