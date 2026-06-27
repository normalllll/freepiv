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
    final status = error.status == null ? '' : ' (${error.status})';
    return '${error.message}$status';
  }

  return error.toString();
}
