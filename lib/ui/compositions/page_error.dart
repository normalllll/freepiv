import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// A page that could not show its content: the page
/// header, so Back and the title stay, over a whole-page error. Not-found
/// pages have no retry.
class AppPageError extends StatelessWidget {
  const AppPageError.notFound({required String this.message, this.title, super.key}) : error = null, onRetry = null;

  const AppPageError.fromError({required Object this.error, required VoidCallback this.onRetry, this.title, super.key}) : message = null;

  final String? title;
  final String? message;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(bottom: false, child: FrostPageHeader(title: title == null ? null : Text(title!))),
        Expanded(
          child: error == null
              // FrostErrorContent always offers a retry; nothing retries a missing page.
              ? FrostEmptyState(icon: FrostScope.configOf(context).icons.error, title: message!)
              : FrostErrorContent.fromError(error: error, onRetry: onRetry),
        ),
      ],
    );
  }
}
