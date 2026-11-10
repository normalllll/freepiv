import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:frost_ui/frost_ui.dart';

/// A part of a page that loads on its own: its
/// title, then its content, a skeleton, or its own retry.
class AppLoadingSection<T> extends StatelessWidget {
  const AppLoadingSection({
    super.key,
    required this.title,
    required this.value,
    required this.onRetry,
    required this.failed,
    required this.builder,
    this.skeleton,
    this.action,
  });

  /// Null inside something that already names it.
  final String? title;
  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final String failed;
  final Widget Function(T data) builder;
  final Widget? skeleton;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FrostGap.related,
    children: [
      if (title case final title?) FrostSectionHeader(title: title, trailing: [?action]),
      value.when(
        data: builder,
        loading: () => skeleton ?? const AppRowsSkeleton(count: 2),
        error: (error, _) => Row(
          children: [
            Expanded(
              child: FrostText(failed, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
            ),
            FrostButton.quiet(label: context.t.common.retry, onPressed: onRetry),
          ],
        ),
      ),
    ],
  );
}
