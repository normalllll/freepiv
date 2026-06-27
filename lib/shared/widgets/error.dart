import 'package:flutter/material.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        return Scaffold(
          appBar: !shouldUseDesktopShell ? AppBar(title: Text(context.t.common.error)) : null,
          body: SafeArea(
            child: ErrorContent(message: message, onRetry: onRetry),
          ),
        );
      },
    );
  }
}

class ErrorContent extends StatelessWidget {
  const ErrorContent({required this.message, required this.onRetry, this.retryLabel, super.key});

  final String message;
  final VoidCallback onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
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
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(retryLabel ?? context.t.common.retry)),
            ],
          ),
        ),
      ),
    );
  }
}
