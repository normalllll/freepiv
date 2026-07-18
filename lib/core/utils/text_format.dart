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

String formatPixivError(Object error) {
  if (error is PixivError) {
    final buffer = StringBuffer(error.message);

    final body = error.body;
    if (body != null && body.trim().isNotEmpty) {
      buffer
        ..write('\n\nResponse body:\n')
        ..write(body);
    }

    return buffer.toString();
  }

  return error.toString();
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
