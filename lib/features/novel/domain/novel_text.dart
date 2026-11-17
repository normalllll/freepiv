import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

/// A piece of a line of text. Positions in the text count characters: each
/// inline adds [length] of them.
sealed class NovelInline {
  const NovelInline();

  /// Characters this span adds to the position count.
  int get length;
}

final class NovelPlain extends NovelInline {
  const NovelPlain(this.text);

  final String text;

  @override
  int get length => text.length;
}

/// [base] shown with [reading] set over it.
final class NovelRuby extends NovelInline {
  const NovelRuby(this.base, this.reading);

  final String base;
  final String reading;

  @override
  int get length => base.length;
}

final class NovelLink extends NovelInline {
  const NovelLink(this.text, this.url);

  final String text;
  final Uri url;

  @override
  int get length => text.length;
}

/// A jump to the 1-based section [page], as Pixiv counts the `[newpage]`
/// divisions. It counts as one character.
final class NovelPageJump extends NovelInline {
  const NovelPageJump(this.page);

  final int page;

  @override
  int get length => 1;
}

/// A top-level piece of the text.
sealed class NovelBlock {
  const NovelBlock();

  /// Characters this block adds to the position count.
  int get length;
}

/// One source line. [blankLinesBefore] is how many empty source lines the
/// author left before it; [authorIndented] is whether the author started
/// it with whitespace (which stays at the start of its first plain span).
final class NovelLine extends NovelBlock {
  const NovelLine(this.spans, {this.blankLinesBefore = 0, this.authorIndented = false});

  final List<NovelInline> spans;
  final int blankLinesBefore;
  final bool authorIndented;

  @override
  int get length {
    var total = 0;
    for (final span in spans) {
      total += span.length;
    }
    return total;
  }
}

final class NovelChapterTitle extends NovelBlock {
  const NovelChapterTitle(this.title);

  final String title;

  @override
  int get length => title.length;
}

final class NovelPageBreak extends NovelBlock {
  const NovelPageBreak();

  @override
  int get length => 0;
}

/// An image uploaded with the novel; [image] is null when the novel does not
/// list it.
final class NovelUploadedImage extends NovelBlock {
  const NovelUploadedImage(this.id, this.image);

  final String id;
  final WebviewNovelImage? image;

  @override
  int get length => 1;
}

/// A Pixiv work shown in the text; [key] is the marker's payload and [work]
/// is null when the novel does not list it.
final class NovelEmbeddedWork extends NovelBlock {
  const NovelEmbeddedWork(this.key, this.illustId, this.page, this.work);

  final String key;
  final int illustId;
  final int page;
  final WebviewNovelEmbeddedWork? work;

  @override
  int get length => 1;
}

/// [parseNovelText] of the novel's text, with the images and works the
/// novel lists.
List<NovelBlock> parseWebviewNovel(WebviewNovel novel) => parseNovelText(
  novel.text,
  uploadedImages: {for (final image in novel.images) image.novelImageId: image},
  embeddedWorks: {for (final work in novel.illusts) work.key: work},
);

final _marker = RegExp(
  r'\[\[rb:(.*?)\]\]'
  r'|\[\[jumpuri:(.*?)\]\]'
  r'|\[(newpage)\]'
  r'|\[chapter:([^\]]*)\]'
  r'|\[uploadedimage:([^\]]*)\]'
  r'|\[pixivimage:([^\]]*)\]'
  r'|\[jump:([^\]]*)\]',
);
final _workPayload = RegExp(r'^(\d+)(?:-(\d+))?$');
final _digits = RegExp(r'^\d+$');
final _lineBreak = RegExp(r'\r\n|\r|\n');

/// Parses Pixiv novel markup into blocks. Unknown or malformed markers stay
/// in the text as they were written.
List<NovelBlock> parseNovelText(
  String text, {
  Map<String, WebviewNovelImage> uploadedImages = const {},
  Map<String, WebviewNovelEmbeddedWork> embeddedWorks = const {},
}) {
  final blocks = <NovelBlock>[];
  var blank = 0;
  for (final source in text.split(_lineBreak)) {
    if (source.trim().isEmpty) {
      blank++;
      continue;
    }
    final indented = source.startsWith('　') || source.startsWith(' ') || source.startsWith('\t');
    var first = true;
    final spans = <NovelInline>[];
    final plain = StringBuffer();

    void flushPlain() {
      if (plain.isEmpty) return;
      spans.add(NovelPlain(plain.toString()));
      plain.clear();
    }

    void flushLine() {
      flushPlain();
      final blankOnly = spans.every((span) => span is NovelPlain && span.text.trim().isEmpty);
      if (!blankOnly) {
        blocks.add(
          NovelLine(List.unmodifiable(spans), blankLinesBefore: first ? blank : 0, authorIndented: first && indented),
        );
      }
      spans.clear();
      first = false;
    }

    var cursor = 0;
    for (final match in _marker.allMatches(source)) {
      plain.write(source.substring(cursor, match.start));
      cursor = match.end;
      final literal = match.group(0)!;
      if (match.group(1) case final body?) {
        final split = body.indexOf('>');
        final base = split < 0 ? '' : body.substring(0, split).trim();
        final reading = split < 0 ? '' : body.substring(split + 1).trim();
        if (base.isEmpty || reading.isEmpty) {
          plain.write(literal);
        } else {
          flushPlain();
          spans.add(NovelRuby(base, reading));
        }
      } else if (match.group(2) case final body?) {
        final split = body.lastIndexOf('>');
        final label = split < 0 ? '' : body.substring(0, split).trim();
        if (label.isEmpty) {
          plain.write(literal);
        } else {
          final url = Uri.tryParse(body.substring(split + 1).trim());
          if (url != null && (url.scheme == 'http' || url.scheme == 'https') && url.host.isNotEmpty) {
            flushPlain();
            spans.add(NovelLink(label, url));
          } else {
            plain.write(label);
          }
        }
      } else if (match.group(3) != null) {
        flushLine();
        blocks.add(const NovelPageBreak());
      } else if (match.group(4) case final body?) {
        final title = body.trim();
        if (title.isEmpty) {
          plain.write(literal);
        } else {
          flushLine();
          blocks.add(NovelChapterTitle(title));
        }
      } else if (match.group(5) case final body?) {
        final id = body.trim();
        if (id.isEmpty) {
          plain.write(literal);
        } else {
          flushLine();
          blocks.add(NovelUploadedImage(id, uploadedImages[id]));
        }
      } else if (match.group(6) case final body?) {
        final parts = _workPayload.firstMatch(body);
        final illustId = int.tryParse(parts?.group(1) ?? '');
        final page = parts?.group(2) == null ? 1 : int.tryParse(parts!.group(2)!);
        if (illustId == null || illustId <= 0 || page == null || page <= 0) {
          plain.write(literal);
        } else {
          flushLine();
          blocks.add(NovelEmbeddedWork(body, illustId, page, embeddedWorks[body]));
        }
      } else {
        final body = match.group(7)!;
        final page = _digits.hasMatch(body) ? int.tryParse(body) : null;
        if (page == null || page <= 0) {
          plain.write(literal);
        } else {
          flushPlain();
          spans.add(NovelPageJump(page));
        }
      }
    }
    plain.write(source.substring(cursor));
    flushLine();
    blank = 0;
  }
  return blocks;
}
