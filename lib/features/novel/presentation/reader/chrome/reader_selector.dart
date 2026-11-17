import 'package:flutter/widgets.dart';

/// Builds from one value read off a [Listenable], and rebuilds only when that
/// value changes: the chapter number, the page, the percent. A bar showing
/// the chapter does not rebuild for each line the text scrolls.
class ReaderSelector<T> extends StatefulWidget {
  const ReaderSelector({required this.listenable, required this.select, required this.builder, super.key});

  final Listenable listenable;
  final T Function() select;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<ReaderSelector<T>> createState() => _ReaderSelectorState<T>();
}

class _ReaderSelectorState<T> extends State<ReaderSelector<T>> {
  late T _value = widget.select();

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_changed);
  }

  @override
  void didUpdateWidget(ReaderSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_changed);
      widget.listenable.addListener(_changed);
    }
    _value = widget.select();
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final next = widget.select();
    if (next != _value) setState(() => _value = next);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
