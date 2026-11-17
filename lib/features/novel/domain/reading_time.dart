/// Characters a reader gets through in a minute, by the novel's language tag:
/// Chinese 400, Japanese 500, anything else 900 (words of Latin script run
/// longer in characters). A missing tag reads as Chinese.
int readingCharactersPerMinute(String? language) {
  final tag = language?.trim().toLowerCase();
  if (tag == null || tag.isEmpty || tag.startsWith('zh')) return 400;
  if (tag.startsWith('ja')) return 500;
  return 900;
}

/// Whole minutes needed to read [characters], rounded up; 0 only for none.
int readingMinutes(int characters, {String? language}) {
  if (characters <= 0) return 0;
  final rate = readingCharactersPerMinute(language);
  return (characters + rate - 1) ~/ rate;
}
