import 'package:flutter/material.dart';

class NovelDetailWidthLimiter extends StatelessWidget {
  const NovelDetailWidthLimiter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860), child: child),
    );
  }
}

class NovelReaderWidthLimiter extends StatelessWidget {
  const NovelReaderWidthLimiter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
