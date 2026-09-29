import 'dart:math' as math;
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';

String formatCount(int value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().toString();
  final buffer = StringBuffer(sign);

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  return buffer.toString();
}

String formatPixivDate(String value) {
  final separatorIndex = value.indexOf('T');
  if (separatorIndex <= 0) {
    return value;
  }

  return value.substring(0, separatorIndex);
}

String plainTextFromHtml(String value) {
  return value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .trim();
}

String formatPixivError(Object error) => switch (error) {
  PixivError(status: 401) || PixivError(kind: PixivErrorKind.missingAccount) => t.errors.session,
  PixivError(status: 403) => t.errors.forbidden,
  PixivError(status: 404) => t.errors.missing,
  PixivError(kind: PixivErrorKind.httpClient) => t.errors.connection,
  _ => t.errors.generic,
};

/// One-line technical cause for toasts and inline messages, e.g.
/// "HTTP 404 · Not Found" or "httpClient · connection refused".
String pixivErrorBrief(Object error) {
  final text = switch (error) {
    PixivError(:final status?, :final message) => 'HTTP $status · $message',
    PixivError(:final kind, :final message) => '${kind.name} · $message',
    _ => error.toString(),
  };
  final line = text.split('\n').first.trim();
  return line.length > 160 ? '${line.substring(0, 157)}...' : line;
}

/// Full technical detail of an error for display and copying. freepiv is open
/// source, so nothing is withheld: kind, HTTP status, message, request URL and
/// the start of the response body.
String pixivErrorDetails(Object error) {
  if (error is! PixivError) return error.toString();
  final body = error.body?.trim() ?? '';
  return [
    'kind: ${error.kind.name}',
    if (error.status case final status?) 'status: $status',
    if (error.message.trim().isNotEmpty) 'message: ${error.message.trim()}',
    if (error.url case final url? when url.isNotEmpty) 'url: $url',
    if (body.isNotEmpty) 'body: ${body.length > 2000 ? '${body.substring(0, 2000)}…' : body}',
  ].join('\n');
}

String? pixivErrorUrl(Object? error) {
  if (error is PixivError) {
    final url = error.url;
    return url == null || url.isEmpty ? null : url;
  }

  return null;
}

String formatPixivErrorUrlForDisplay(String url) {
  try {
    return Uri.parse(url).replace(queryParameters: const <String, String>{}).toString();
  } catch (_) {
    final fragmentIndex = url.indexOf('#');
    final queryIndex = url.indexOf('?');
    if (queryIndex < 0 || (fragmentIndex >= 0 && queryIndex > fragmentIndex)) {
      return url;
    }

    return '${url.substring(0, queryIndex)}${fragmentIndex >= 0 ? url.substring(fragmentIndex) : ''}';
  }
}

String formatByteSize(int bytes) {
  if (bytes <= 0) return '0.00 B';

  const units = ['B', 'KB', 'MB', 'GB'];
  final exponent = math.min((math.log(bytes) / math.log(1024)).floor(), units.length - 1);
  final value = bytes / math.pow(1024, exponent);
  return '${value.toStringAsFixed(2)} ${units[exponent]}';
}
