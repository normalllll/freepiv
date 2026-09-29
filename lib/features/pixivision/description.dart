/// Cleans a Pixivision `meta description` for display.
///
/// The page escapes that text twice, so entities such as `&nbsp;` arrive
/// literally, and it starts with the site's own `[pixivision]` marker.
String cleanPixivisionDescription(String value) {
  final decoded = value.replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);'), (match) {
    final entity = match.group(1)!;
    if (entity.startsWith('#x') || entity.startsWith('#X')) {
      return _codePoint(int.tryParse(entity.substring(2), radix: 16)) ?? match.group(0)!;
    }
    if (entity.startsWith('#')) {
      return _codePoint(int.tryParse(entity.substring(1))) ?? match.group(0)!;
    }
    return switch (entity) {
      'nbsp' => ' ',
      'amp' => '&',
      'lt' => '<',
      'gt' => '>',
      'quot' => '"',
      'apos' => "'",
      _ => match.group(0)!,
    };
  });
  return decoded.replaceFirst(RegExp(r'^\s*(?:\[pixivision\]|【pixivision】)\s*', caseSensitive: false), '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

String? _codePoint(int? value) {
  if (value == null || value <= 0 || value > 0x10FFFF || (value >= 0xD800 && value <= 0xDFFF)) return null;
  return String.fromCharCode(value);
}
