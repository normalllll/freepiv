import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/error.dart';

class CompactMessage extends StatelessWidget {
  const CompactMessage({required this.icon, required this.message, this.actionLabel, this.onAction, this.details, super.key});

  /// Inline error from [error]: localized summary, retry, and the technical
  /// detail one tap away.
  factory CompactMessage.error({required Object error, String? actionLabel, VoidCallback? onAction, Key? key}) => CompactMessage(
    icon: Icons.error_outline,
    message: formatPixivError(error),
    details: pixivErrorDetails(error),
    actionLabel: actionLabel ?? t.common.retry,
    onAction: onAction,
    key: key,
  );

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? details;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actionLabel = this.actionLabel;

    final details = this.details;
    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.refresh_outlined, size: 16),
                    label: Text(actionLabel),
                    style: TextButton.styleFrom(
                      overlayColor: Colors.transparent,
                      minimumSize: const Size(0, AppMetrics.controlHeight),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ],
            ),
            if (details != null && details.trim().isNotEmpty) ErrorDetails(details: details),
          ],
        ),
      ),
    );
  }
}
