import 'package:flutter/material.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({required this.message, required this.onRetry, this.fullUrl, super.key});

  factory ErrorPage.fromError({required Object error, required VoidCallback onRetry, Key? key}) {
    return ErrorPage(message: formatPixivError(error), fullUrl: pixivErrorUrl(error), onRetry: onRetry, key: key);
  }

  final String message;
  final VoidCallback onRetry;
  final String? fullUrl;

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        return Scaffold(
          appBar: !shouldUseDesktopShell ? AppBar(title: Text(context.t.common.error)) : null,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: ErrorContent(message: message, onRetry: onRetry, fullUrl: fullUrl),
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
  const ErrorContent({required this.message, required this.onRetry, this.retryLabel, this.fullUrl, super.key});

  factory ErrorContent.fromError({required Object error, required VoidCallback onRetry, String? retryLabel, Key? key}) {
    return ErrorContent(message: formatPixivError(error), fullUrl: pixivErrorUrl(error), onRetry: onRetry, retryLabel: retryLabel, key: key);
  }

  final String message;
  final VoidCallback onRetry;
  final String? retryLabel;
  final String? fullUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDetailedMessage = message.contains('\n') || message.length > 120;

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
                style: TextStyle(color: colorScheme.error),
              ),
              if (fullUrl != null) ...[const SizedBox(height: 12), _ErrorUrl(fullUrl: fullUrl!)],
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(retryLabel ?? context.t.common.retry)),
            ],
          ),
        ),
      ),
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
      message: fullUrl,
      child: Text(displayUrl, maxLines: 3, overflow: TextOverflow.ellipsis, style: textStyle),
    );
  }
}
