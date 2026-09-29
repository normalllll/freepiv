import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({required this.message, required this.onRetry, this.fullUrl, this.details, super.key});

  factory ErrorPage.fromError({required Object error, required VoidCallback onRetry, Key? key}) {
    return ErrorPage(message: formatPixivError(error), details: pixivErrorDetails(error), onRetry: onRetry, key: key);
  }

  final String message;
  final VoidCallback onRetry;
  final String? fullUrl;
  final String? details;

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool useHorizontalLayout) {
        return Scaffold(
          appBar: !useHorizontalLayout ? AppBar(title: Text(context.t.common.error)) : null,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: ErrorContent(message: message, onRetry: onRetry, fullUrl: fullUrl, details: details),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class ErrorContent extends StatelessWidget {
  const ErrorContent({required this.message, required this.onRetry, this.retryLabel, this.fullUrl, this.details, super.key});

  factory ErrorContent.fromError({required Object error, required VoidCallback onRetry, String? retryLabel, Key? key}) {
    return ErrorContent(message: formatPixivError(error), details: pixivErrorDetails(error), onRetry: onRetry, retryLabel: retryLabel, key: key);
  }

  final String message;
  final VoidCallback onRetry;
  final String? retryLabel;
  final String? fullUrl;

  /// Technical detail shown below the summary; see [pixivErrorDetails].
  final String? details;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDetailedMessage = message.contains('\n') || message.length > 120;
    final details = this.details;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.error_outline, size: 44, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: hasDetailedMessage ? TextAlign.start : TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              if (fullUrl != null) ...[const SizedBox(height: 12), _ErrorUrl(fullUrl: fullUrl!)],
              const SizedBox(height: 16),
              Center(
                child: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(retryLabel ?? context.t.common.retry)),
              ),
              if (details != null && details.trim().isNotEmpty) ...[const SizedBox(height: 16), ErrorDetails(details: details, initiallyExpanded: true)],
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable technical detail of an error with a copy action. Full-page
/// errors show it open; inline messages keep it one tap away.
class ErrorDetails extends StatefulWidget {
  const ErrorDetails({required this.details, this.initiallyExpanded = false, super.key});

  final String details;
  final bool initiallyExpanded;

  @override
  State<ErrorDetails> createState() => _ErrorDetailsState();
}

class _ErrorDetailsState extends State<ErrorDetails> {
  late bool _expanded = widget.initiallyExpanded;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.details));
    AppToast.success(t.common.detailsCopied);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
              label: Text(t.common.errorDetails),
            ),
            const Spacer(),
            TextButton.icon(onPressed: () => unawaited(_copy()), icon: const Icon(Icons.content_copy_outlined, size: 16), label: Text(t.common.copyDetails)),
          ],
        ),
        AnimatedSize(
          duration: AppMotion.duration(context, AppMotion.expand),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: tokens.surfaceInset, borderRadius: BorderRadius.circular(AppMetrics.controlRadius)),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        widget.details,
                        style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: tokens.textSecondary, height: 1.45),
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ErrorUrl extends StatelessWidget {
  const _ErrorUrl({required this.fullUrl});

  final String fullUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayUrl = formatPixivErrorUrlForDisplay(fullUrl);
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant);

    return Tooltip(
      message: displayUrl,
      child: Text(displayUrl, maxLines: 3, overflow: TextOverflow.ellipsis, style: textStyle),
    );
  }
}
