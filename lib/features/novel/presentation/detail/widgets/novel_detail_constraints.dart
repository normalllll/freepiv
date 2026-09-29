import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/layout/content_viewport.dart';

/// The shared content column for novel detail blocks, whose children pad
/// their content by 20 themselves.
class NovelDetailWidthLimiter extends StatelessWidget {
  const NovelDetailWidthLimiter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ContentColumn(bleed: 20, child: child);
}

/// Reading column for novel text shown on the detail page.
class NovelReaderWidthLimiter extends StatelessWidget {
  const NovelReaderWidthLimiter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ContentColumn(
    maxWidth: AppMetrics.readingMaxWidth,
    bleed: 20,
    child: SizedBox(width: double.infinity, child: child),
  );
}
