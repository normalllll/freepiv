import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';

/// The shared content column for novel detail blocks, whose children pad
/// their content by 20 themselves.
class NovelDetailWidthLimiter extends StatelessWidget {
  const NovelDetailWidthLimiter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => FrostContentColumn(child: child);
}

/// Reading column for novel text shown on the detail page.
class NovelReaderWidthLimiter extends StatelessWidget {
  const NovelReaderWidthLimiter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => FrostContentColumn(
    maxWidth: FrostMetrics.readingMaxWidth,
    child: SizedBox(width: double.infinity, child: child),
  );
}
