import 'package:flutter/material.dart';

/// Measures content in the space remaining after window navigation.
class ContentViewport extends StatelessWidget {
  const ContentViewport({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => MediaQuery(
      data: MediaQuery.of(context).copyWith(size: Size(constraints.maxWidth, constraints.maxHeight)),
      child: child,
    ),
  );
}
